import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:offline_ai_enhancer/data/services/image_service.dart';
import 'package:image/image.dart' as img;

class AiInferenceService {
  static const String modelPath = 'assets/models/RealESRGAN.tflite';
  Interpreter? _interpreter;

  Future<void> initialize() async {
    try {
      final options = InterpreterOptions();
      if (Platform.isAndroid) {
        options.addDelegate(NnApiDelegate());
      }
      // Metal delegate for iOS would be added here if available
      
      _interpreter = await Interpreter.fromAsset(modelPath, options: options);
      // print('Model loaded successfully');
    } catch (e) {
      // print('Error loading model: $e');
    }
  }

  Future<img.Image?> enhanceImageSync(String imagePath) async {
      if (_interpreter == null) await initialize();
      
      final image = await ImageService.loadImage(imagePath);
      if (image == null) throw Exception("Failed to load image");

      final inputData = ImageService.imageToFloat32List(image);
      
      // Reshape logic: TFLite Flutter expects Multi-dimensional lists or specialized buffers
      // For simplicity in this non-runnable env, we'll assume we can pass the specific shape
      // via a detailed implementation that creates the List structure.
      // Or we can use the `reshape` from a matrix library if imported.
      // Here we will use a flat buffer approach if the interpreter supports it, 
      // or simplistic nested loops to create the structure for clarity.
      
      // Creating [1, h, w, 3] structure
      var input = List.generate(1, (b) => 
        List.generate(image.height, (y) =>
          List.generate(image.width, (x) {
             int index = (y * image.width + x) * 3;
             return [
               inputData[index],
               inputData[index+1],
               inputData[index+2]
             ];
          })
        )
      );

      const scale = 2; // Make dynamic based on model
      final outHeight = image.height * scale;
      final outWidth = image.width * scale;
      
      // Output buffer: [1, outHeight, outWidth, 3]
      var output = List.generate(1, (_) => 
        List.generate(outHeight, (_) => 
          List.generate(outWidth, (_) => List.filled(3, 0.0))
        )
      );

      try {
        _interpreter!.run(input, output);
      } catch (e) {
        throw e;
      }

      // Flatten output to convert back
      final flatOutput = Float32List(outHeight * outWidth * 3);
      int ptr = 0;
      for (var y = 0; y < outHeight; y++) {
        for (var x = 0; x < outWidth; x++) {
          for (var c = 0; c < 3; c++) {
             flatOutput[ptr++] = output[0][y][x][c];
          }
        }
      }
      return ImageService.float32ListToImage(flatOutput, outWidth, outHeight);
  }

  void close() {
    _interpreter?.close();
  }
}
