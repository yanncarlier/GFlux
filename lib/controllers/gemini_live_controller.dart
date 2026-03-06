import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';
import 'package:flutter_sound/flutter_sound.dart';

enum GeminiState { idle, connecting, active, error }
enum BackendType { vertex, direct }

class GeminiLiveController extends ChangeNotifier {
  // CONFIGURATION
  final String _apiKey = "AIzaSyAfv4F3u_l0AmYlH7rUt8guQk8cHInZQrs";
  final String _modelName = "gemini-2.5-flash-native-audio-latest";
  // Alternate model names to try: 'gemini-2.0-flash', 'gemini-2.0-flash-exp'
  
  // Choose backend: direct (Free Tier) or vertex (Paid/Enterprise)
  BackendType _backendType = BackendType.direct;
  
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

  // Getters
  GeminiState get state => _state;
  bool get isActive => _state == GeminiState.active;
  List<String> get transcript => _transcript;
  String? get lastError => _lastError;
  BackendType get backendType => _backendType;

  GeminiLiveController() {
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      // await _player.setLogLevel(Level.error);
      await _player.openPlayer();
      _isPlayerInitialized = true;
      print("GFlux: Audio player initialized.");
    } catch (e) {
      print("GFlux: Player init error: $e");
    }
  }

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
        _addLog("Vertex AI not fully implemented for direct streaming in this test. Use Direct mode.");
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
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.$endpointStr.GenerativeService.BidiGenerateContent?key=$_apiKey'
    );
    // Note: If v1beta returns 404, we'll try v1alpha in the next attempt.
    
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
      // Data might be String or List<int> depending on platform/socket
      String jsonStr = "";
      try {
        if (data is String) {
          jsonStr = data;
        } else if (data is List<int>) {
          jsonStr = utf8.decode(data);
        }
        
        // Very verbose, but helpful for debugging
        // print("DEBUG: Received raw data: $jsonStr");
        
        final Map<String, dynamic> json = jsonDecode(jsonStr);
        
        if (json.containsKey('setupComplete')) {
          _addLog("Gemini: Connection established (setupComplete).");
          _state = GeminiState.active;
          notifyListeners();
          _startRecording();
        }

        if (json.containsKey('serverContent')) {
          final serverContent = json['serverContent'];
          // debugPrint("DEBUG: serverContent received");
          
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
                  final mimeType = inlineData['mimeType'] ?? "unknown";
                  final base64Audio = inlineData['data'];
                  // debugPrint("DEBUG: Received audio chunk. MIME: $mimeType, Size: ${base64Audio?.length}");
                  
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
          sampleRate: 24000, // Gemini usually sends 24kHz
          numChannels: 1,
          whenFinished: () {
            // This callback is sometimes unreliable for super fast chunks
          }
        );
        
        // Wait for the duration of the audio to avoid overlapping next startPlayer
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
    _player.closePlayer();
    _recorder.dispose();
    super.dispose();
  }
}
