# GFlux  
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](pubspec.yaml)

### First Release:  
https://github.com/yanncarlier/GFlux/releases/tag/v1.0.0 

**GFlux** is a high-performance, real-time multimodal AI agent built for the **Gemini Live Agent Challenge**. It leverages the cutting-edge Gemini Multimodal Live API to provide seamless, low-latency bidirectional voice and text interactions in a premium mobile environment.

> [!NOTE]
> This documentation and its associated files will be improved and expanded over time as the project evolves.

---

## ✨ Features

- **🎙️ Live Audio Streaming**: Bidirectional, low-latency audio capture and playback using raw PCM 16-bit streams.
- **⚡ Sequential Playback Queue**: Optimized audio handling to ensure smooth, non-overlapping responses from the AI.
- **🔐 Secure Architecture**: Environment-based API key management using `flutter_dotenv` to protect sensitive credentials.
- **🎨 Premium UI/UX**: A dark, modern aesthetic featuring:
  - Custom animations reacting to session states.
  - Typography powered by **Space Grotesk**.
  - A glassmorphism-inspired design system.
- **🛠️ Clean Agentic Logic**: Separated controller logic for easy scaling and integration with Google Cloud services.

---

## 🚀 Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **AI Core**: [Gemini Multimodal Live API](https://ai.google.dev/gemini-api/docs/multimodal-live) (WebSocket Service)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Audio Engine**: `record` for capture and `flutter_sound` for low-latency playback.
- **Backend Infrastructure**: Firebase (initialized for future cloud capability).

---

## 🛠️ Installation & Setup

### Prerequisites
- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install) (Version >= 3.5.0 recommended).
- **Android Studio / VS Code**: Ensure the Flutter and Dart plugins are installed.
- **Git**: For version control.
- **Hardware**: A real Android or iOS device is highly recommended for testing real-time audio latency (Emulators may have high audio jitter).

### Setup

1. **Clone the Project**:
   ```bash
   git clone https://github.com/yanncarlier/GFlux.git
   cd GFlux
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Environment Secrets**:
   GFlux uses `flutter_dotenv` to protect API keys.
   - Create a file named `.env` in the project root.
   - Add your Gemini API key from [Google AI Studio](https://aistudio.google.com/):
     ```env
     GEMINI_API_KEY=your_actual_api_key_here
     ```

4. **Android Native Configuration**:
   Ensure your `android/app/build.gradle` has:
   - `minSdkVersion 21` (or higher)
   - `targetSdkVersion 34` (or higher)
   - Proper permissions in `AndroidManifest.xml` (RECORD_AUDIO, INTERNET).

5. **Run the Application**:
   Connect your device and run:
   ```bash
   flutter run
   ```

---

## 🏗️ Development Guide

### Key Modules
- **[`lib/controllers/gemini_live_controller.dart`](lib/controllers/gemini_live_controller.dart)**: The heart of the app. Manages the WebSocket connection, audio capture stream, and the sequential playback queue.
- **[`lib/views/home_view.dart`](lib/views/home_view.dart)**: Contains the UI and the state-driven animations.

### Audio Pipeline
GFlux processes raw PCM data to minimize latency. 
- **Mic Input**: Captured using `record` and sent as Base64 encoded chunks via the `realtimeInput` WebSocket event.
- **Audio Output**: Bytes received from `serverContent -> modelTurn` are pushed into a `List<Uint8List> _audioQueue` and played sequentially using `flutter_sound`.

---

## 📱 Interaction Guide

- **Single Tap**: Initialize/Start the session. The central frame will pulse when Gemini is listening.
- **Double Tap**: Send a test prompt to verify the text-to-speech visualizer.
- **Listen**: Speak naturally; Gemini will respond in real-time.

---

## 🛠️ Troubleshooting

### Audio Issues
- **Problem**: No audio playback on Android.
- **Solution**: Ensure your device is not on "Silent" mode and has the necessary permissions granted. Also, check that the `minSdkVersion` is at least **21**.

### Connection Failures
- **Problem**: WebSocket fails with `404` or `401`.
- **Solution**: Double-check your `.env` file for a valid **GEMINI_API_KEY**. Also, ensure you have an active internet connection.

### Device Detection
- **Problem**: `flutter devices` doesn't see your phone.
- **Solution**: Enable **USB Debugging** in Developer Options. For Android, you may need to use `adb kill-server` and `adb start-server` if the connection is erratic.

---

## 🤝 Contributing
1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

---

## 📝 License
This project is built for the Gemini Live Agent Challenge and follows the competition's submission guidelines.

---

*Built with ❤️ for the future of Agentic AI.*
