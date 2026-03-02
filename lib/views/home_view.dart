import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/gemini_live_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GeminiLiveController>();
    
    // Design colors from stitch/code.html
    const deepCharcoal = Color(0xFF121212);
    const accentPurple = Color(0xFFA855F7);
    const deepPurple = Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: deepCharcoal,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Header
                  _buildHeader(context, controller, accentPurple),
                  
                  const Spacer(),
                  
                  // Central Frame
                  _buildCentralFrame(context, controller, accentPurple, deepPurple),
                  
                  const Spacer(),
                  
                  // Waveform/Glow Footer
                  _buildFooter(context, controller, accentPurple),
                ],
              ),
            ),
          ),
          
          // Interaction Overlay (Tap to Start/Stop)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (controller.isActive || controller.state == GeminiState.connecting) {
                    controller.stopSession();
                  } else {
                    controller.startSession();
                  }
                },
                overlayColor: MaterialStateProperty.all(accentPurple.withOpacity(0.02)),
                highlightColor: Colors.transparent,
              ),
            ),
          ),
          
          // Home Indicator
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                width: 120,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, GeminiLiveController controller, Color accent) {
    final isConnecting = controller.state == GeminiState.connecting;
    final isActive = controller.isActive;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "GFLUX: ",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  isConnecting ? "CONNECTING..." : (isActive ? "LISTENING..." : "IDLE"),
                  style: TextStyle(
                    color: (isActive || isConnecting) ? accent : Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.psychology,
                  color: (isActive || isConnecting) ? accent : Colors.white.withOpacity(0.2),
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCentralFrame(BuildContext context, GeminiLiveController controller, Color accent, Color deep) {
    final isActive = controller.isActive;

    return Container(
      width: double.infinity,
      height: 580,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: deep.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Corner Brackets
          ..._buildBrackets(),
          
          // Concentric Circles
          Opacity(
            opacity: 0.2,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
              ),
            ),
          ),
          
          // Live Indicator or Prompt
          if (!isActive && controller.state != GeminiState.connecting)
             Text(
              "TAP TO INITIALIZE",
              style: TextStyle(
                color: Colors.white.withOpacity(0.1),
                fontSize: 12,
                letterSpacing: 4,
                fontWeight: FontWeight.w300,
              ),
            )
          else if (isActive)
            _buildListeningAnimation(accent),
        ],
      ),
    );
  }

  List<Widget> _buildBrackets() {
    return [
      _bracket(top: 24, left: 24, isTop: true, isLeft: true),
      _bracket(top: 24, right: 24, isTop: true, isLeft: false),
      _bracket(bottom: 24, left: 24, isTop: false, isLeft: true),
      _bracket(bottom: 24, right: 24, isTop: false, isLeft: false),
    ];
  }

  Widget _bracket({double? top, double? bottom, double? left, double? right, required bool isTop, required bool isLeft}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? BorderSide(color: Colors.white.withOpacity(0.2)) : BorderSide.none,
            bottom: !isTop ? BorderSide(color: Colors.white.withOpacity(0.2)) : BorderSide.none,
            left: isLeft ? BorderSide(color: Colors.white.withOpacity(0.2)) : BorderSide.none,
            right: !isLeft ? BorderSide(color: Colors.white.withOpacity(0.2)) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildListeningAnimation(Color accent) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOutSine,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.1 * value),
                  blurRadius: 40 * value,
                  spreadRadius: 10 * value,
                ),
              ],
            ),
          ),
        );
      },
      onEnd: () {}, // Handled by builder if looping manually, use a proper animation controller for production
    );
  }

  Widget _buildFooter(BuildContext context, GeminiLiveController controller, Color accent) {
    final isActive = controller.isActive;

    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        children: [
          // Waveform line
          Container(
            width: 280,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  isActive ? accent : Colors.white.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
              boxShadow: isActive ? [
                BoxShadow(
                  color: accent.withOpacity(0.8),
                  blurRadius: 12,
                )
              ] : [],
            ),
          ),
          if (isActive)
            Container(
              width: 200,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(100)),
                child: Opacity(
                  opacity: 0.5,
                  child: BlurEffect(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BlurEffect extends StatelessWidget {
  const BlurEffect({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0xFFA855F7),
            blurRadius: 40,
            spreadRadius: 20,
          )
        ]
      ),
    );
  }
}

