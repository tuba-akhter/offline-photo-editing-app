import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageService {
  static const int maxDimension = 2048;

  /// Loads an image from a file, resizes it if necessary, and returns the [img.Image].
  static Future<img.Image?> loadImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) return null;

    if (image.width > maxDimension || image.height > maxDimension) {
      return img.copyResize(
        image, 
        width: image.width > image.height ? maxDimension : null,
        height: image.height > image.width ? maxDimension : null,
        interpolation: img.Interpolation.linear,
      );
    }
    return image;
  }

  /// Converts [img.Image] to a Float32List for TFLite input.
  /// Assuming model expects [1, height, width, 3] in RGB format.
  /// Returns a flat list or shaped list depending on tflite_flutter requirements.
  /// For this implementation, we'll return the raw bytes or structured input.
  static Float32List imageToFloat32List(img.Image image) {
    // Normalization logic depends on the model.
    // Real-ESRGAN often expects values in [0, 1] or [-1, 1].
    // We will assume [0, 1] for now.
    
    final Float32List convertedBytes = Float32List(1 * image.height * image.width * 3);
    int bufferIndex = 0;

    for (var i = 0; i < image.height; i++) {
        for (var j = 0; j < image.width; j++) {
            final pixel = image.getPixel(j, i);
            convertedBytes[bufferIndex++] = pixel.r / 255.0;
            convertedBytes[bufferIndex++] = pixel.g / 255.0;
            convertedBytes[bufferIndex++] = pixel.b / 255.0;
        }
    }
    return convertedBytes;
  }

  /// Converts [img.Image] to a Uint8List for TFLite input (0-255).
  static Uint8List imageToUint8List(img.Image image) {
    final Uint8List convertedBytes = Uint8List(1 * image.height * image.width * 3);
    int bufferIndex = 0;

    for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
            final pixel = image.getPixel(x, y);
            convertedBytes[bufferIndex++] = pixel.r.toInt();
            convertedBytes[bufferIndex++] = pixel.g.toInt();
            convertedBytes[bufferIndex++] = pixel.b.toInt();
        }
    }
    return convertedBytes;
  }
  /// Converts output tensor buffer back to [img.Image].
  static img.Image float32ListToImage(Float32List buffer, int width, int height) {
     final image = img.Image(width: width, height: height);
     int bufferIndex = 0;

     for (var i = 0; i < height; i++) {
        for (var j = 0; j < width; j++) {
           final r = (buffer[bufferIndex++] * 255.0).clamp(0, 255).toInt();
           final g = (buffer[bufferIndex++] * 255.0).clamp(0, 255).toInt();
           final b = (buffer[bufferIndex++] * 255.0).clamp(0, 255).toInt();
           image.setPixelRgb(j, i, r, g, b);
        }
     }
     return image;
  }
}
