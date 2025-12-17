import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

import 'package:offline_ai_enhancer/data/services/image_service.dart';
import 'package:offline_ai_enhancer/data/services/face_detection_service.dart';
import 'package:offline_ai_enhancer/data/services/image_blending_service.dart';

class AiInferenceService {
  // Using RealESRGAN for the face crops as agreed in plan
  static const String modelPath = 'assets/models/RealESRGAN.tflite';

  // Public method to call from UI
  Future<img.Image?> enhanceImage(String imagePath) async {
    print('LOG: Starting Face Enhancement Pipeline...');
    
    // 1. Detect Faces (Main Thread - heuristic based)
    final File imageFile = File(imagePath);
    print('LOG: Detecting faces...');
    
    final stopwatch = Stopwatch()..start();
    final faceRects = await FaceDetectionService.detectFaces(imageFile);
    print('LOG: Detection took ${stopwatch.elapsedMilliseconds}ms');
    
    // Convert FaceRect objects to serializable coordinates for Isolate
    // For center-region heuristic, we'll calculat coordinates in the isolate based on actual image size
    final List<Map<String, dynamic>> faceData = faceRects.map((f) => {
      'isCenterRegion': f.isCenterRegion,
      'left': f.left,
      'top': f.top,
      'width': f.width,
      'height': f.height,
    }).toList();

    // 2. Load model bytes in main isolate
    final ByteData modelData = await rootBundle.load(modelPath);
    final Uint8List modelBytes = modelData.buffer.asUint8List();

    // 3. Offload heavy processing to background isolate
    return await compute(_runFacePipeline, _PipelineRequest(imagePath, modelBytes, faceData));
  }
}

class _PipelineRequest {
  final String imagePath;
  final Uint8List modelBytes;
  final List<Map<String, dynamic>> faceData;
  _PipelineRequest(this.imagePath, this.modelBytes, this.faceData);
}

// Top-level function running in Isolate
Future<img.Image?> _runFacePipeline(_PipelineRequest request) async {
  try {
    print('ISOLATE: Starting Background Enhancement...');
    
    // Initialize Interpreter with GPU Acceleration
    late Interpreter interpreter;
    bool usingGPU = false;
    
    // Try GPU delegate first
    try {
      final options = InterpreterOptions();
      final gpuDelegate = GpuDelegateV2(
        options: GpuDelegateOptionsV2(
          isPrecisionLossAllowed: false, // Use FP16 precision
        ),
      );
      options.addDelegate(gpuDelegate);
      
      // Try to create interpreter with GPU
      interpreter = Interpreter.fromBuffer(request.modelBytes, options: options);
      usingGPU = true;
      print('ISOLATE: GPU delegate enabled (FP16 precision)');
    } catch (e) {
      // GPU failed, fall back to CPU
      print('ISOLATE: GPU failed, using CPU fallback: $e');
      final cpuOptions = InterpreterOptions();
      interpreter = Interpreter.fromBuffer(request.modelBytes, options: cpuOptions);
      usingGPU = false;
    }

    // Load Image
    final originalImage = await ImageService.loadImage(request.imagePath);
    if (originalImage == null) throw Exception("Failed to load image");
    print('ISOLATE: Image loaded [${originalImage.width}x${originalImage.height}]');
    
    // If no faces, return original
    if (request.faceData.isEmpty) {
      print('ISOLATE: No faces to enhance.');
      return originalImage;
    }

    print('ISOLATE: Enhancing ${request.faceData.length} face region(s) [${usingGPU ? "GPU" : "CPU"}]...');
    
    // Model Constants (RealESRGAN)
    const int modelInputSize = 128; 
    const int modelOutputSize = 512; // 4x upscale

    // Resize input tensor once 
    try {
       interpreter.resizeInputTensor(0, [1, modelInputSize, modelInputSize, 3]);
       interpreter.allocateTensors();
    } catch(e) {
       print("ISOLATE: Tensor resize failed: $e");
    }

    // Process each face region
    for (int i = 0; i < request.faceData.length; i++) {
      final faceInfo = request.faceData[i];
      
      // Calculate actual region based on heuristic type
      int x, y, w, h;
      
      if (faceInfo['isCenterRegion'] == true) {
        // Use center 50% of image as the "face region"
        w = (originalImage.width * 0.5).toInt();
        h = (originalImage.height * 0.5).toInt();
        x = (originalImage.width - w) ~/ 2;
        y = (originalImage.height - h) ~/ 2;
        print('ISOLATE: Using center region heuristic: ${w}x${h} at ($x,$y)');
      } else {
        // Use provided coordinates
        x = faceInfo['left'] as int;
        y = faceInfo['top'] as int;
        w = faceInfo['width'] as int;
        h = faceInfo['height'] as int;
      }
      
      // Ensure bounds
      x = x.clamp(0, originalImage.width - 1);
      y = y.clamp(0, originalImage.height - 1);
      
      // Ensure width/height doesn't exceed image
      int maxW = originalImage.width - x;
      int maxH = originalImage.height - y;
      
      w = w.clamp(1, maxW);
      h = h.clamp(1, maxH);
      
      print('ISOLATE: Processing Face $i [${w}x${h}] at ($x,$y)');

      // 1. Crop
      final faceCrop = img.copyCrop(originalImage, x: x, y: y, width: w, height: h);
      
      // 2. Resize to Model Input (128x128)
      final inputImage = img.copyResize(faceCrop, width: modelInputSize, height: modelInputSize, interpolation: img.Interpolation.cubic);
      
      // 3. Prepare Input Buffer
      final inputBytes = ImageService.imageToUint8List(inputImage);
      var inputTensor = List.generate(1, (b) => 
        List.generate(modelInputSize, (y) =>
          List.generate(modelInputSize, (x) {
             int index = (y * modelInputSize + x) * 3;
             return [
               inputBytes[index],
               inputBytes[index+1],
               inputBytes[index+2]
             ];
          })
        )
      );

      // 4. Prepare Output Buffer
      var outputTensor = List.generate(1, (_) => 
        List.generate(modelOutputSize, (_) => 
          List.generate(modelOutputSize, (_) => List.filled(3, 0))
        )
      );

      // 5. Run Inference
      interpreter.run(inputTensor, outputTensor);

      // 6. Post-process Output
      final flatOutput = Float32List(modelOutputSize * modelOutputSize * 3);
      int ptr = 0;
      for (var oy = 0; oy < modelOutputSize; oy++) {
        for (var ox = 0; ox < modelOutputSize; ox++) {
          for (var c = 0; c < 3; c++) {
              flatOutput[ptr++] = outputTensor[0][oy][ox][c] / 255.0; 
          }
        }
      }
    
      final enhancedFace = ImageService.float32ListToImage(flatOutput, modelOutputSize, modelOutputSize);
      if (enhancedFace == null) {
         print("ISOLATE: Failed to reconstruct face image");
         continue;
      }

      // 7. Blend back
      ImageBlendingService.blendFaceIntoImage(
        originalImage, 
        enhancedFace, 
        Rectangle<int>(x, y, w, h)
      );
    }

    interpreter.close();
    print('ISOLATE: Pipeline complete.');
    return originalImage;

  } catch (e, stack) {
    print("ISOLATE Error: $e");
    print(stack);
    return null;
  }
}

