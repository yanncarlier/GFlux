# GFlux Contributor & Installation Guide 🏗️

Welcome to GFlux! This guide is intended for developers who wish to contribute or build further on top of the GFlux architecture.

## 🛠️ Environment Prerequisites

- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install) (Version >= 3.5.0 recommended).
- **Android Studio / VS Code**: Ensure the Flutter and Dart plugins are installed.
- **Git**: For version control.
- **Hardware**: A real Android or iOS device is highly recommended for testing real-time audio latency (Emulators may have high audio jitter).

## 📥 Installation Steps

1. **Clone the Project**:
   ```bash
   git clone https://github.com/yanncarlier/GFlux.git
   cd GFlux
   ```

2. **Initialize Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Environment Secrets**:
   GFlux uses `flutter_dotenv` to protect API keys.
   - Create a file named `.env` in the project root.
   - Add your Gemini API key:
     ```env
     GEMINI_API_KEY=AIzaSy...your_key...
     ```

4. **Android Native Configuration**:
   The project is pre-configured for the Gemini Live Agent Challenge, but ensure your `android/app/build.gradle` has:
   - `minSdkVersion 21` (or higher)
   - `targetSdkVersion 34` (or higher)
   - Proper permissions in `AndroidManifest.xml` (RECORD_AUDIO, INTERNET).

## 🧪 Development Workflow

### Running in Debug Mode
To run the app on your connected hardware with full logging:
```bash
flutter run
```

### Key Modules to Explore
- **[`lib/controllers/gemini_live_controller.dart`](file:///home/y/MY_AI_PROJECTS/gemini-live-agent-challenge/GFlux/lib/controllers/gemini_live_controller.dart)**: The heart of the app. Manages the WebSocket connection, audio capture stream, and the sequential playback queue.
- **[`lib/views/home_view.dart`](file:///home/y/MY_AI_PROJECTS/gemini-live-agent-challenge/GFlux/lib/views/home_view.dart)**: Contains the UI and the state-driven animations.

## 📡 Understanding the Audio Pipeline

GFlux processes raw PCM data to minimize latency. 
- **Mic Input**: Captured using `record` and sent as Base64 encoded chunks via the `realtimeInput` WebSocket event.
- **Audio Output**: Bytes received from `serverContent -> modelTurn` are pushed into a `List<Uint8List> _audioQueue` and played sequentially using `flutter_sound`.

## 🤝 Contributing
1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

---
*Questions? Reach out via the Gemini Live Agent Challenge community or open an issue.*
