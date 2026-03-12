import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/gemini_live_controller.dart';
import 'config_dialog.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GeminiLiveController>();

    const deepCharcoal = Color(0xFF121212);
    const accentPurple = Color(0xFFA855F7);
    const deepPurple = Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: deepCharcoal,
      body: GestureDetector(
        // ── MASTER GESTURE DETECTOR ───────────────────────────────────────
        // This handles tapping ANYWHERE (frame or background) to start/stop.
        // Nested buttons (like Camera Toggle) will intercept hits first.
        behavior: HitTestBehavior.opaque,
        onTap: () {
          debugPrint("GFlux: Session toggle triggered. State: ${controller.state}");
          if (controller.isActive || controller.state == GeminiState.connecting) {
            controller.stopSession();
          } else {
            controller.startSession();
          }
        },
        onDoubleTap: () {
          debugPrint("GFlux: Screen double-tapped.");
          controller.sendTestMessage("Hello Gemini! What can you see through the camera right now?");
        },
        child: Stack(
          children: [
            // UI Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context, controller, accentPurple),
                    const Spacer(),
                    _buildCentralFrame(context, controller, accentPurple, deepPurple),
                    const Spacer(),
                    _buildFooter(context, controller, accentPurple),
                  ],
                ),
              ),
            ),

            // Home Indicator (Visual only, no interaction)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: IgnorePointer(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, GeminiLiveController controller, Color accent) {
    final isConnecting = controller.state == GeminiState.connecting;
    final isActive = controller.isActive;
    final isCameraOn = controller.isCameraOn;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Settings Button
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const ConfigDialog(),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.settings, color: Colors.white.withValues(alpha: 0.5), size: 20),
                ),
              ),
              const SizedBox(width: 8),
              // Camera Toggle Button - Has its own GestureDetector
              _buildCameraToggle(context, controller, accent, isCameraOn),
            ],
          ),

          // Status Badge
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

  Widget _buildCameraToggle(
    BuildContext context,
    GeminiLiveController controller,
    Color accent,
    bool isCameraOn,
  ) {
    return GestureDetector(
      onTap: () {
        debugPrint("GFlux: Camera Toggle tapped.");
        controller.toggleCamera();
      },
      onLongPress: () {
        debugPrint("GFlux: Camera Long Press - Stopping.");
        controller.stopCamera();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isCameraOn ? accent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCameraOn ? accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
          ),
          boxShadow: isCameraOn
              ? [BoxShadow(color: accent.withValues(alpha: 0.2), blurRadius: 12)]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCameraOn ? Icons.flip_camera_ios : Icons.videocam_off,
              color: isCameraOn ? accent : Colors.white.withValues(alpha: 0.3),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              isCameraOn ? "SWITCH / HOLD OFF" : "VISION OFF",
              style: TextStyle(
                color: isCameraOn ? accent : Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCentralFrame(BuildContext context, GeminiLiveController controller, Color accent, Color deep) {
    final isActive = controller.isActive;
    final isCameraOn = controller.isCameraOn;
    final camCtrl = controller.cameraController;

    return Container(
      width: double.infinity,
      height: 520,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isCameraOn ? accent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isCameraOn ? accent.withValues(alpha: 0.15) : deep.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(31),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Camera Preview
            if (isCameraOn && camCtrl != null && camCtrl.value.isInitialized)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.85,
                  child: CameraPreview(camCtrl),
                ),
              ),

            // Gradient Overlay
            if (isCameraOn && camCtrl != null && camCtrl.value.isInitialized)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),

            // Corner brackets
            ..._buildBrackets(isCameraOn ? accent : Colors.white),

            // Scan-line
            if (isCameraOn && isActive) _buildVisionScanOverlay(accent),

            // Content
            if (!isActive && controller.state != GeminiState.connecting)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (controller.lastError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        controller.lastError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (!isCameraOn)
                    Text(
                      "TAP TO INITIALIZE",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.1),
                        fontSize: 12,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                ],
              )
            else if (isActive && !isCameraOn)
              _buildListeningAnimation(accent),

            // Badge
            if (isCameraOn)
              Positioned(
                bottom: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.remove_red_eye, color: accent, size: 12),
                      const SizedBox(width: 5),
                      Text(
                        isActive ? "GEMINI IS WATCHING" : "VISION READY",
                        style: TextStyle(
                          color: accent,
                          fontSize: 9,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisionScanOverlay(Color accent) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      curve: Curves.linear,
      onEnd: () {},
      builder: (context, value, child) {
        return Positioned(
          top: 520 * value - 2,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  accent.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildBrackets(Color bracketColor) {
    return [
      _bracket(top: 24, left: 24, isTop: true, isLeft: true, color: bracketColor),
      _bracket(top: 24, right: 24, isTop: true, isLeft: false, color: bracketColor),
      _bracket(bottom: 24, left: 24, isTop: false, isLeft: true, color: bracketColor),
      _bracket(bottom: 24, right: 24, isTop: false, isLeft: false, color: bracketColor),
    ];
  }

  Widget _bracket({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool isTop,
    required bool isLeft,
    Color color = Colors.white,
  }) {
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
            top: isTop ? BorderSide(color: color.withValues(alpha: 0.4)) : BorderSide.none,
            bottom: !isTop ? BorderSide(color: color.withValues(alpha: 0.4)) : BorderSide.none,
            left: isLeft ? BorderSide(color: color.withValues(alpha: 0.4)) : BorderSide.none,
            right: !isLeft ? BorderSide(color: color.withValues(alpha: 0.4)) : BorderSide.none,
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
                  color: accent.withValues(alpha: 0.1 * value),
                  blurRadius: 40 * value,
                  spreadRadius: 10 * value,
                ),
              ],
            ),
          ),
        );
      },
      onEnd: () {},
    );
  }

  Widget _buildFooter(BuildContext context, GeminiLiveController controller, Color accent) {
    final isActive = controller.isActive;

    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        children: [
          Container(
            width: 280,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  isActive ? accent : Colors.white.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
              boxShadow: isActive
                  ? [BoxShadow(color: accent.withValues(alpha: 0.8), blurRadius: 12)]
                  : [],
            ),
          ),
          if (isActive)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                width: 200,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Center(
                  child: Container(
                    width: 100,
                    height: 2,
                    color: accent.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
