import 'dart:io';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class StorageService {
  
  static Future<bool> requestPermissions() async {
    // Gal handles write permissions automatically, but strictly speaking:
    // Android < 10 needs storage permission
    // Android 13+ needs photos permission
    
    // We rely on Gal.hasAccess() or similar if available, or just try/catch save.
    // Explicit permission request:
    bool granted = false;
    if (Platform.isAndroid) {
        // Simple check, in real app handle SDK versions
        // storage is for <= 12
        // photos is for >= 13
        final status = await Permission.storage.status;
        if (status.isDenied) {
           // Try photos if storage failed (Android 13 logic)
           // Actually permission_handler handles SDK logic partially
           if (await Permission.photos.request().isGranted) return true;
           if (await Permission.storage.request().isGranted) return true;
        } else if (status.isGranted) {
           return true;
        }
        // If photos...
        if (await Permission.photos.isGranted) return true;
    } else if (Platform.isIOS) {
        if (await Permission.photos.request().isGranted) return true;
        if (await Permission.photosAddOnly.request().isGranted) return true;
    }
    return granted;
  }

  static Future<void> saveImageToGallery(String filePath) async {
    try {
      // Gal automatically requests permission if needed
      await Gal.putImage(filePath, album: 'AI Photo Enhancer');
    } catch (e) {
      print('Error saving image: $e');
      throw Exception('Failed to save image to gallery');
    }
  }

  static Future<String> getTempPath() async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }
}
