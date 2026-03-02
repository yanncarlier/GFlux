import 'dart:async';
import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

enum GeminiState { idle, connecting, active, error }

class GeminiLiveController extends ChangeNotifier {
  final String _modelName = 'gemini-2.0-flash-exp';
  
  LiveSession? _session;
  GeminiState _state = GeminiState.idle;
  String? _errorMessage;
  
  final List<String> _transcript = [];
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  
  StreamSubscription? _recorderSubscription;

  // Getters for the UI
  GeminiState get state => _state;
  String? get errorMessage => _errorMessage;
  List<String> get transcript => List.unmodifiable(_transcript);
  bool get isActive => _state == GeminiState.active;

  /// Starts the live session and handles audio I/O
  Future<void> startSession() async {
    if (_state != GeminiState.idle) return;

    _state = GeminiState.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      final model = FirebaseAI.instance.googleAI().liveGenerativeModel(
        model: _modelName,
        systemInstruction: Content.text(
          "You are GFlux, a real-time AI voice assistant. "
          "Speak naturally and briefly. Help the user with their requests."
        ),
      );

      _session = await model.connect();
      _state = GeminiState.active;
      notifyListeners();

      // Start processing incoming stream (text and audio)
      _listenToEvents();

      // Start microphone recording
      await _startRecording();
      
      _addLog("System: Connection established and microphone active.");
    } catch (e) {
      _state = GeminiState.error;
      _errorMessage = e.toString();
      _addLog("Error: $_errorMessage");
      notifyListeners();
    }
  }

  void _listenToEvents() async {
    if (_session == null) return;

    try {
      await for (final event in _session!.receive()) {
        final message = event.message;
        if (message is LiveServerContent) {
          // Handle text parts
          final text = message.modelTurn?.parts
              .whereType<TextPart>()
              .map((p) => p.text)
              .join();
          
          if (text != null && text.isNotEmpty) {
            _addLog("Gemini: $text");
          }

          // Handle audio parts
          final audioParts = message.modelTurn?.parts.whereType<InlineDataPart>() ?? [];
          for (var part in audioParts) {
            if (part.mimeType.contains('audio')) {
              await _playAudioChunk(part.data);
            }
          }
        }
      }
    } catch (e) {
      _addLog("Stream Error: $e");
      stopSession();
    }
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );

      final stream = await _recorder.startStream(config);
      _recorderSubscription = stream.listen((data) {
        if (_session != null && _state == GeminiState.active) {
          _session!.send(Content.inlineData('audio/pcm;rate=16000', data));
        }
      });
    } else {
      throw Exception("Microphone permission denied");
    }
  }

  Future<void> _playAudioChunk(Uint8List data) async {
    // Note: This is a simplified playback. 
    // For production-grade smooth audio, one should use a buffered stream player.
    // audioplayers might have latency here. Just_audio with a custom source is better.
    // However, for this scaffold, we'll use Source.binary
    await _player.play(BytesSource(data));
  }

  void _addLog(String text) {
    _transcript.add(text);
    notifyListeners();
  }

  /// Sends a text command explicitly (optional for voice)
  Future<void> sendText(String text) async {
    if (_session != null && _state == GeminiState.active) {
      _addLog("You (text): $text");
      await _session!.send(Content.text(text));
    }
  }

  /// Properly closes everything
  Future<void> stopSession() async {
    await _recorderSubscription?.cancel();
    await _recorder.stop();
    await _session?.close();
    await _player.stop();
    
    _state = GeminiState.idle;
    _session = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopSession();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }
}
