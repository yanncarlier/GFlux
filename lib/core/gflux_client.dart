import 'dart:async';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

/// The core engine for GFlux. 
/// Handles the real-time WebSocket connection to Gemini 2.0/3.0.
class GFluxClient extends ChangeNotifier {
  final String _modelName = 'gemini-2.0-flash-exp';
  
  LiveSession? _session;
  bool _isConnecting = false;
  bool _isConnected = false;
  
  final List<String> _transcript = [];

  // Getters for the UI to bind to
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  List<String> get transcript => List.unmodifiable(_transcript);

  /// Initializes the session with the system instructions defined for GFlux.
  Future<void> startStreaming() async {
    if (_isConnected || _isConnecting) return;

    _isConnecting = true;
    notifyListeners();

    try {
      final model = FirebaseAI.instance.googleAI().liveGenerativeModel(
        model: _modelName,
        systemInstruction: Content.text(
          "You are GFlux, a real-time AI agent. Your goal is to provide fluid, "
          "multimodal assistance. Be concise and proactive."
        ),
      );

      _session = await model.connect();
      _isConnected = true;
      _isConnecting = false;
      notifyListeners();

      // Start listening to the bidirectional stream
      _listenToStream();
      
      print("GFlux: Connection established.");
    } catch (e) {
      _isConnecting = false;
      print("GFlux Error: $e");
      notifyListeners();
    }
  }

  void _listenToStream() async {
    if (_session == null) return;

    await for (final event in _session!.receive()) {
      final message = event.message;
      if (message is LiveServerContent) {
        final text = message.modelTurn?.parts
            .whereType<TextPart>()
            .map((p) => p.text)
            .join();
        
        if (text != null && text.isNotEmpty) {
          _transcript.add("Gemini: $text");
          notifyListeners();
        }
      }
    }
  }

  /// Sends a text command to the agent
  Future<void> sendCommand(String text) async {
    if (_session != null && _isConnected) {
      _transcript.add("You: $text");
      notifyListeners();
      await _session!.send(Content.text(text));
    }
  }

  /// Properly closes the stream when the app is disposed
  Future<void> stopStreaming() async {
    await _session?.close();
    _isConnected = false;
    notifyListeners();
  }
}