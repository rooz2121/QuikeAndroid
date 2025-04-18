# Quike AI

![Quike AI Logo](assets/images/logo.png)

An intelligent assistant application built with Flutter that provides AI-powered conversations and assistance.

## Download and Installation

### Download Options

#### Direct APK Download
1. **Latest Release**: Download the latest APK directly from our GitHub repository:
   - Go to the [QuikeAndroid](https://github.com/rooz2121/QuikeAndroid/build/app/outputs/flutter-apk) repository
   - Download `quike_ai_v1.0.0.apk`
2. **Build Version**: The current stable version is v1.0.0

#### Google Play Store
*Coming soon!* The app will be available on Google Play Store in the near future.

### Installation Instructions

#### Android
1. **Enable Unknown Sources**:
   - Go to **Settings** > **Security** (or **Privacy**)
   - Enable **Install from Unknown Sources** or **Install Unknown Apps**
   - On Android 8.0+, you may need to grant permission to your browser or file manager

2. **Install the APK**:
   - Locate the downloaded APK file
   - Tap on it to begin installation
   - Follow the on-screen prompts
   - Once installed, you'll find Quike AI in your app drawer

#### iOS
*Coming soon!* iOS version is under development.

## Features

- AI-powered conversations
- Intelligent responses
- Clean, intuitive interface
- Fast performance

## Requirements

- Android 5.0 (Lollipop) or higher
- 50MB free storage space
- Internet connection required

## Production Build Instructions

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / Xcode
- JDK 8 or higher

### Android Production Build

1. **Create a keystore file**:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Configure signing**:
   - Create a `key.properties` file in the `android/` folder (use the template provided)
   - Fill in your keystore details

3. **Enable signing in gradle**:
   - Uncomment the signing config in `android/app/build.gradle`

4. **Build the release APK**:
   ```bash
   flutter build apk --release
   ```
   The APK will be available at `build/app/outputs/flutter-apk/app-release.apk`

5. **Build App Bundle for Play Store**:
   ```bash
   flutter build appbundle --release
   ```
   The bundle will be available at `build/app/outputs/bundle/release/app-release.aab`

### iOS Production Build

1. **Configure signing in Xcode**:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Set up your team and signing certificate

2. **Build the release IPA**:
   ```bash
   flutter build ios --release
   ```

3. **Archive and upload using Xcode**

## Performance Optimization

- The app uses ProGuard rules for Android to minimize APK size
- Images are optimized for production
- Release builds have debugging disabled

## Troubleshooting

### Common Installation Issues

1. **"App not installed" error**:
   - Make sure you have enough storage space
   - Try uninstalling any previous version first
   - Restart your device and try again

2. **"Blocked by Play Protect" warning**:
   - This is normal for apps not yet on Play Store
   - Tap "Install Anyway" to proceed

3. **App crashes on startup**:
   - Ensure your Android version is 5.0 or higher
   - Try clearing cache and data for the app
   - Reinstall the application

### Getting Help

If you encounter any issues, please:
1. Check the [Issues](https://github.com/rooz2121/QuikeAndroid/issues) page for known problems
2. Create a new issue with detailed information about your problem

## Privacy and Permissions

Quike AI requires the following permissions:
- **Internet access**: For AI functionality and updates

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For support or inquiries, please open an issue on GitHub.
