import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../controllers/gemini_live_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GeminiLiveController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blueGrey.shade900,
              Colors.black,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildTranscript(context, controller)),
              _buildStatusIndicator(context, controller),
              _buildControls(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flash_on,
              color: Colors.cyan,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "GFLUX // STREAMS",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscript(BuildContext context, GeminiLiveController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListView.builder(
        reverse: true,
        itemCount: controller.transcript.length,
        itemBuilder: (context, i) {
          final content = controller.transcript.reversed.toList()[i];
          final isGemini = content.startsWith("Gemini:");
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: isGemini ? MainAxisAlignment.start : MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isGemini 
                          ? Colors.cyan.withOpacity(0.1) 
                          : Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isGemini 
                          ? Colors.cyan.withOpacity(0.3) 
                          : Colors.purple.withOpacity(0.3)
                      ),
                    ),
                    child: Text(
                      content.replaceFirst(RegExp(r'^(Gemini|You|Error|System):\s*'), ''),
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context, GeminiLiveController controller) {
    if (controller.state == GeminiState.idle) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          if (controller.state == GeminiState.connecting)
            const SpinKitWave(
              color: Colors.cyan,
              size: 50.0,
            )
          else if (controller.isActive)
            _buildActiveVisualizer(),
          const SizedBox(height: 16),
          Text(
            controller.state == GeminiState.connecting 
                ? "Connecting to Gemini..." 
                : "Active Listening",
            style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.w300),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveVisualizer() {
    return Container(
      height: 80,
      width: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 10,
          )
        ],
      ),
      child: const SpinKitDoubleBounce(
        color: Colors.cyanAccent,
        size: 80.0,
      ),
    );
  }

  Widget _buildControls(BuildContext context, GeminiLiveController controller) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (controller.state == GeminiState.error)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                controller.errorMessage ?? "Unknown Error",
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),
          GestureDetector(
            onTap: () {
              if (controller.isActive || controller.state == GeminiState.connecting) {
                controller.stopSession();
              } else {
                controller.startSession();
              }
            },
            child: _buildActionBtn(controller),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(GeminiLiveController controller) {
    final isActive = controller.isActive || controller.state == GeminiState.connecting;

    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive 
              ? [Colors.redAccent, Colors.red.shade900]
              : [Colors.cyan.shade400, Colors.blue.shade900],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: (isActive ? Colors.red : Colors.cyan).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? Icons.stop : Icons.mic,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Text(
            isActive ? "END INTERACTION" : "ESTABLISH LINK",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
