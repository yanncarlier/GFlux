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
                    const SizedBox(height: 24),
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
    final isCameraOn = controller.isCameraOn;
    final isConnecting = controller.state == GeminiState.connecting;

    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSquareButton(
                icon: Icons.settings,
                label: "SETTINGS",
                color: Colors.white.withValues(alpha: 0.05),
                iconColor: Colors.white.withValues(alpha: 0.6),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const ConfigDialog(),
                  );
                },
              ),
              const SizedBox(width: 16),
              _buildSquareButton(
                icon: Icons.psychology,
                label: isConnecting ? "CONNECT" : (isActive ? "LISTEN" : "GFLUX"),
                color: (isActive || isConnecting) ? accent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                iconColor: (isActive || isConnecting) ? accent : Colors.white.withValues(alpha: 0.6),
                borderColor: (isActive || isConnecting) ? accent.withValues(alpha: 0.5) : Colors.transparent,
                onTap: () {
                  if (isActive || isConnecting) {
                    controller.stopSession();
                  } else {
                    controller.startSession();
                  }
                },
              ),
              const SizedBox(width: 16),
              _buildSquareButton(
                icon: isCameraOn ? Icons.flip_camera_ios : Icons.videocam_off,
                label: isCameraOn ? "SWITCH" : "VISION",
                color: isCameraOn ? accent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                iconColor: isCameraOn ? accent : Colors.white.withValues(alpha: 0.6),
                borderColor: isCameraOn ? accent.withValues(alpha: 0.5) : Colors.transparent,
                onTap: () {
                  controller.toggleCamera();
                },
                onLongPress: () {
                  controller.stopCamera();
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
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

  Widget _buildSquareButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    Color borderColor = Colors.transparent,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: iconColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
