# Setup Guide

## 1. Initialize Project Infrastructure
Since this project was generated in an environment without the Flutter SDK, the platform-specific build files (Android/iOS/Web) are missing.

**Run the following command in the project root:**
```bash
flutter create . --org com.antigravity.enhancer
```
*This will generate the `android`, `ios`, `inputs`, `windows`, etc. directories while keeping the `lib` and `pubspec.yaml` I created.*

## 2. Install Dependencies
```bash
flutter pub get
```

## 3. Configure Permissions

### Android
Open `android/app/src/main/AndroidManifest.xml` and add the following lines inside the `<manifest>` tag, above `<application>`:

```xml
<!-- Android 13+ -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<!-- Android 12 and below -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS
Open `ios/Runner/Info.plist` and add the following keys inside the `<dict>` tag:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your gallery to select photos for enhancement.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to save enhanced photos to your gallery.</string>
```

## 4. Add AI Model
> [!NOTE]
> **Done!** The model `RealESRGAN.tflite` (Real-ESRGAN-x4plus_w8a8) has been automatically downloaded to `assets/models/`.
> You can verify it exists by checking the directory.

## 5. Build and Run
```bash
flutter run
```
