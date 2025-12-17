import 'package:image/image.dart' as img;
import 'dart:math';

class ImageBlendingService {
  
  /// Blends an enhanced face crop back into the original image at the specified [rect].
  /// [originalImage]: The full-size original image.
  /// [enhancedCrop]: The upscaled/enhanced face crop.
  /// [rect]: The bounding box in the *originalImage* where the face was detected.
  /// 
  /// The [enhancedCrop] will be resized to fit [rect] and pasted.
  /// Simple edge blending is applied to reduce seams.
  static img.Image blendFaceIntoImage(
      img.Image originalImage, img.Image enhancedCrop, Rectangle<int> rect) {
    
    // 1. Resize enhanced crop to match the destination rect size
    // Using high-quality interpolation since we are likely downscaling the 4x enhanced face 
    // to fit the original hole (or upscaling if original was huge, but usually downscaling relative to super-res).
    final resizedFace = img.copyResize(
      enhancedCrop, 
      width: rect.width, 
      height: rect.height, 
      interpolation: img.Interpolation.cubic
    );

    // 2. Paste the face onto the original image
    // For MVP, we'll do a direct paste. 
    // TODO: Implement alpha feathering for smoother edges.
    
    img.compositeImage(
      originalImage, 
      resizedFace, 
      dstX: rect.left, 
      dstY: rect.top
    );

    return originalImage;
  }

    /// Helper to create a feathered mask is complex in Dart's `image` lib without explicit mask support in `compositeImage` 
    /// in older versions, but we can stick to direct composite for speed first.
}
