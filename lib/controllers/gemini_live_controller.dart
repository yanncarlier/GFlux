import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';

enum GeminiState { idle, connecting, active, error }
enum BackendType { vertex, direct }

class GeminiLiveController extends ChangeNotifier {
  // CONFIGURATION
  String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
  String _modelName = "gemini-2.5-flash-native-audio-latest";
  // Alternate model names: 'gemini-2.0-flash-exp', 'gemini-2.0-flash'

  // Choose backend: direct (Free Tier) or vertex (Paid/Enterprise)
  BackendType _backendType = BackendType.direct;

  // Multi-Endpoint Hub configs
  String _baseUrl = "wss://generativelanguage.googleapis.com";

  String get apiKey => _apiKey;
  String get modelName => _modelName;
  BackendType get backendType => _backendType;
  String get baseUrl => _baseUrl;

  void updateConfig({
    String? apiKey,
    String? modelName,
    BackendType? backendType,
    String? baseUrl,
  }) {
    if (apiKey != null) _apiKey = apiKey;
    if (modelName != null) _modelName = modelName;
    if (backendType != null) _backendType = backendType;
    if (baseUrl != null) _baseUrl = baseUrl;
    notifyListeners();
  }

  GeminiState _state = GeminiState.idle;
  final List<String> _transcript = [];
  String? _lastError;
  bool _useFallbackEndpoint = false;

  // Resources
  WebSocketChannel? _directChannel;
  StreamSubscription? _socketSubscription;
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription? _recorderSubscription;

  // Audio Player (flutter_sound for low-latency streaming)
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlayerInitialized = false;

  // ── VISION ──────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  bool _isCameraOn = false;
  Timer? _frameSendTimer;
  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0; // 0 = back, 1 = front (if available)

  CameraController? get cameraController => _cameraController;
  bool get isCameraOn => _isCameraOn;
  // ────────────────────────────────────────────────────────────────────────

  // Getters
  GeminiState get state => _state;
  bool get isActive => _state == GeminiState.active;
  List<String> get transcript => _transcript;
  String? get lastError => _lastError;

  GeminiLiveController() {
    _initPlayer();
    _discoverCameras();
  }

  Future<void> _initPlayer() async {
    try {
      await _player.openPlayer();
      _isPlayerInitialized = true;
      print("GFlux: Audio player initialized.");
    } catch (e) {
      print("GFlux: Player init error: $e");
    }
  }

  Future<void> _discoverCameras() async {
    try {
      _availableCameras = await availableCameras();
      
      // Default to front camera if available
      for (int i = 0; i < _availableCameras.length; i++) {
        if (_availableCameras[i].lensDirection == CameraLensDirection.front) {
          _selectedCameraIndex = i;
          break;
        }
      }
      
      print("GFlux: Discovered ${_availableCameras.length} camera(s). Defaulting to index $_selectedCameraIndex.");
    } catch (e) {
      print("GFlux: Camera discovery error: $e");
    }
  }

  // ── CAMERA CONTROLS ────────────────────────────────────────────────────

  Future<void> toggleCamera() async {
    if (_isCameraOn) {
      if (_availableCameras.length > 1) {
        _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
        _addLog("Vision: Switching camera...");
        
        // Notify UI that the camera is momentarily unavailable during switch
        _isCameraOn = false;
        _cameraController = null;
        notifyListeners();
        
        await _startCamera(isSwitching: true);
      } else {
        await stopCamera();
      }
    } else {
      await _startCamera();
    }
  }

  Future<void> _startCamera({bool isSwitching = false}) async {
    if (_availableCameras.isEmpty) {
      _addLog("Error: No cameras found on device.");
      return;
    }

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _addLog("Error: Camera permission denied.");
      return;
    }

    try {
      if (isSwitching) {
        _stopFrameStreaming();
        if (_cameraController != null) {
          await _cameraController?.dispose();
          _cameraController = null;
          notifyListeners(); // Ensure UI clears the view
        }
        // Small delay to allow hardware release
        await Future.delayed(const Duration(milliseconds: 250));
      }

      final camera = _availableCameras[_selectedCameraIndex];
      _cameraController = CameraController(
        camera,
        ResolutionPreset.low, 
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      _isCameraOn = true;
      notifyListeners();
      _addLog("Vision: Camera ON (${camera.lensDirection.toString().split('.').last}).");

      if (_state == GeminiState.active) {
        _startFrameStreaming();
      }
    } catch (e) {
      print("GFlux: Camera start error: $e");
      _addLog("Vision Error: $e");
      _cameraController = null;
      _isCameraOn = false;
      notifyListeners();
    }
  }

  Future<void> stopCamera() async {
    if (!_isCameraOn) return;
    _stopFrameStreaming();
    await _cameraController?.dispose();
    _cameraController = null;
    _isCameraOn = false;
    notifyListeners();
    _addLog("Vision: Camera OFF.");
  }

  void _startFrameStreaming() {
    _frameSendTimer?.cancel();
    // Send a frame every 1 second (1 fps) — sufficient for Gemini to "see"
    _frameSendTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await _captureAndSendFrame();
    });
    print("GFlux: Vision frame streaming started.");
  }

  void _stopFrameStreaming() {
    _frameSendTimer?.cancel();
    _frameSendTimer = null;
  }

  Future<void> _captureAndSendFrame() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _state != GeminiState.active ||
        _directChannel == null) return;

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      final msg = {
        "realtimeInput": {
          "mediaChunks": [
            {
              "data": base64Image,
              "mimeType": "image/jpeg",
            }
          ]
        }
      };
      _directChannel!.sink.add(jsonEncode(msg));
      debugPrint("GFlux: Sent camera frame (${imageBytes.length} bytes).");
    } catch (e) {
      // Non-fatal — just log and skip this frame
      print("GFlux: Frame capture error: $e");
    }
  }

  // ── SESSION MANAGEMENT ─────────────────────────────────────────────────

  Future<void> startSession() async {
    if (_state == GeminiState.connecting || _state == GeminiState.active) return;

    print("GFlux: startSession called using $_backendType");
    _state = GeminiState.connecting;
    _transcript.clear();
    _lastError = null;
    _addLog("Initializing session...");
    notifyListeners();

    try {
      if (_backendType == BackendType.vertex) {
        _addLog("Vertex AI not fully implemented for direct streaming. Use Direct mode.");
        _state = GeminiState.error;
      } else {
        await _connectDirect();
      }
    } catch (e) {
      print("GFlux Session Error: $e");
      _addLog("Error: $e");
      _state = GeminiState.error;
    }
    notifyListeners();
  }

  Future<void> _connectDirect() async {
    final endpointStr = _useFallbackEndpoint ? "v1alpha" : "v1beta";
    final uri = Uri.parse(
      '$_baseUrl/ws/google.ai.generativelanguage.$endpointStr.GenerativeService.BidiGenerateContent?key=$_apiKey'
    );

    print("GFlux: Attempting connection to $uri");
    print("GFlux: API Key starts with: ${_apiKey.substring(0, 5)}...");

    try {
      _directChannel = WebSocketChannel.connect(uri);

      // Setup Message
      final setupMsg = {
        "setup": {
          "model": "models/$_modelName",
          "generationConfig": {
            "responseModalities": ["AUDIO"]
          }
        }
      };

      final jsonSetup = jsonEncode(setupMsg);
      print("DEBUG: Sending setup message: $jsonSetup");
      _directChannel!.sink.add(jsonSetup);

      _listenToDirectEvents();

      // Timeout for feedback
      Future.delayed(const Duration(seconds: 10), () {
        if (_state == GeminiState.connecting) {
          _addLog("Error: Handshake timeout. Check internet or API state.");
          _state = GeminiState.error;
          notifyListeners();
        }
      });
    } catch (e) {
      print("GFlux Connection Exception: $e");
      _addLog("Connection failed: $e");
      _state = GeminiState.error;
      notifyListeners();
    }
  }

  void _listenToDirectEvents() {
    _socketSubscription = _directChannel!.stream.listen((data) {
      String jsonStr = "";
      try {
        if (data is String) {
          jsonStr = data;
        } else if (data is List<int>) {
          jsonStr = utf8.decode(data);
        }

        final Map<String, dynamic> json = jsonDecode(jsonStr);

        if (json.containsKey('setupComplete')) {
          _addLog("Gemini: Connection established (setupComplete).");
          _state = GeminiState.active;
          notifyListeners();
          _startRecording();
          // If camera was already on before session started, begin streaming
          if (_isCameraOn) {
            _startFrameStreaming();
          }
        }

        if (json.containsKey('serverContent')) {
          final serverContent = json['serverContent'];

          if (serverContent.containsKey('modelTurn')) {
            final modelTurn = serverContent['modelTurn'];

            if (modelTurn.containsKey('parts')) {
              final parts = modelTurn['parts'] as List;
              for (var part in parts) {
                if (part.containsKey('text')) {
                  final text = part['text'];
                  _addLog("Gemini (text): $text");
                }
                if (part.containsKey('inlineData')) {
                  final inlineData = part['inlineData'];
                  final base64Audio = inlineData['data'];

                  if (base64Audio != null) {
                    final audioData = base64Decode(base64Audio);
                    _playAudioChunk(audioData);
                  }
                }
              }
            }
          }

          if (serverContent.containsKey('interrupted')) {
            _addLog("Gemini: Interrupted.");
            _player.stopPlayer();
          }

          if (serverContent.containsKey('turnComplete')) {
            debugPrint("DEBUG: Server turnComplete received");
          }
        }

        if (json.containsKey('usageMetadata')) {
          // debugPrint("DEBUG: usageMetadata: ${json['usageMetadata']}");
        }
      } catch (e, stack) {
        print("GFlux Parse Error: $e");
        debugPrint("Error for data: $jsonStr");
        debugPrint(stack.toString());
      }
    }, onError: (e) {
      print("DEBUG: WebSocket Error: $e");
      _lastError = "Socket Error: $e";
      _addLog("Error: $e");
      _state = GeminiState.error;
      notifyListeners();
    }, onDone: () {
      final code = _directChannel?.closeCode;
      final reason = _directChannel?.closeReason;
      print("DEBUG: WebSocket Closed. Code: $code, Reason: $reason");

      if (_state != GeminiState.idle) {
        _lastError = "Connection closed ($code: $reason).";
        _addLog(_lastError!);
        _state = GeminiState.error;
        notifyListeners();
      }
    });
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        const config = RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        );

        final stream = await _recorder.startStream(config);
        int chunkCount = 0;
        _recorderSubscription = stream.listen((data) {
          if (_state == GeminiState.active && _directChannel != null) {
            chunkCount++;
            if (chunkCount % 50 == 0) {
              debugPrint("DEBUG: Sent 50 audio chunks (total: $chunkCount)");
            }

            final msg = {
              "realtimeInput": {
                "mediaChunks": [
                  {
                    "data": base64Encode(data),
                    "mimeType": "audio/pcm;rate=16000"
                  }
                ]
              }
            };
            _directChannel!.sink.add(jsonEncode(msg));
          }
        });
        print("GFlux: Recording started and streaming chunks.");
        _addLog("System: Microphone ON.");
      } else {
        _addLog("Error: Mic permission denied.");
      }
    } catch (e) {
      print("GFlux Recorder Error: $e");
      _addLog("Recorder Error: $e");
    }
  }

  final List<Uint8List> _audioQueue = [];
  bool _isProcessingQueue = false;

  void _playAudioChunk(Uint8List data) {
    if (!_isPlayerInitialized) return;
    _audioQueue.add(data);
    if (!_isProcessingQueue) {
      _processAudioQueue();
    }
  }

  Future<void> _processAudioQueue() async {
    _isProcessingQueue = true;
    while (_audioQueue.isNotEmpty) {
      final data = _audioQueue.removeAt(0);
      try {
        await _player.startPlayer(
          fromDataBuffer: data,
          codec: Codec.pcm16,
          sampleRate: 24000,
          numChannels: 1,
          whenFinished: () {},
        );

        // PCM 16-bit Mono: duration = length / (sampleRate * 2)
        final durationMs = (data.length / (24000 * 2)) * 1000;
        await Future.delayed(Duration(milliseconds: durationMs.toInt() - 5));
      } catch (e) {
        print("GFlux Playback Error: $e");
      }
    }
    _isProcessingQueue = false;
  }

  void stopSession() {
    print("GFlux: stopSession called.");
    _state = GeminiState.idle;

    _stopFrameStreaming();

    _recorderSubscription?.cancel();
    _recorderSubscription = null;
    _recorder.stop();

    _socketSubscription?.cancel();
    _socketSubscription = null;
    _directChannel?.sink.close();
    _directChannel = null;

    _player.stopPlayer();

    notifyListeners();
  }

  void sendTestMessage(String text) {
    if (_state != GeminiState.active || _directChannel == null) return;
    print("GFlux: Sending test message: $text");
    final clientContentMsg = {
      "clientContent": {
        "turns": [
          {
            "role": "user",
            "parts": [{"text": text}]
          }
        ],
        "turnComplete": true
      }
    };
    _directChannel!.sink.add(jsonEncode(clientContentMsg));
    _addLog("Sent text: $text");
  }

  void _addLog(String text) {
    print("GFlux Log: $text");
    _transcript.add(text);
    notifyListeners();
  }

  @override
  void dispose() {
    stopCamera();
    _player.closePlayer();
    _recorder.dispose();
    super.dispose();
  }
}
