import 'dart:io';
import 'dart:math';

/// Simplified face detection using heuristics.
/// Since ML Kit had persistent build issues, this provides a working fallback.
class FaceDetectionService {
  
  /// Detects "likely face regions" using center-crop heuristic.
  /// Most portrait photos have faces in the center third of the image.
  /// Returns a list of rectangles representing estimated face locations.
  static Future<List<FaceRect>> detectFaces(File imageFile) async {
    // For MVP: Return center region as the "detected face"
    // In a real implementation with a working detection lib, this would use actual detection
    
    print('LOG: Using heuristic face detection (center region)');
    
    // Return a single "face" in the center of the image
    // The actual dimensions will be determined from the loaded image in the AI service
    return [FaceRect.centerRegion()];
  }

  static void dispose() {
    // No resources to dispose in heuristic mode
  }
}

/// Simple data class to represent a detected face region
class FaceRect {
  final bool isCenterRegion;
  final int? left;
  final int? top;
  final int? width;
  final int? height;

  FaceRect({this.left, this.top, this.width, this.height}) : isCenterRegion = false;
  FaceRect.centerRegion() : isCenterRegion = true, left = null, top = null, width = null, height = null;
}
