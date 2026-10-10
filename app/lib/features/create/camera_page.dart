import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/config.dart';
import '../../core/format.dart';

/// Live capture only: there is deliberately no gallery picker anywhere in the app.
class CameraPage extends StatefulWidget {
  const CameraPage({required this.onCaptured, super.key});
  final void Function(String path, DateTime capturedAt) onCaptured;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

enum _CameraIssue { none, denied, unavailable }

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  _CameraIssue _issue = _CameraIssue.none;
  bool _flash = false;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_init());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (state == AppLifecycleState.inactive && c != null) {
      _controller = null;
      unawaited(c.dispose());
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      unawaited(_init());
    }
  }

  Future<void> _init() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _issue = _CameraIssue.unavailable);
        return;
      }
      final back = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first);
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _issue = _CameraIssue.none;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(
        () => _issue = e.code.contains('Denied') || e.code.contains('Restricted')
            ? _CameraIssue.denied
            : _CameraIssue.unavailable,
      );
    }
  }

  Future<void> _toggleFlash() async {
    final c = _controller;
    if (c == null) return;
    _flash = !_flash;
    await c.setFlashMode(_flash ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || _capturing || c.value.isTakingPicture) return;
    setState(() => _capturing = true);
    unawaited(HapticFeedback.mediumImpact());
    try {
      final capturedAt = DateTime.now();
      final shot = await c.takePicture();
      final path = await _compress(shot.path);
      widget.onCaptured(path, capturedAt);
    } on CameraException catch (e) {
      if (mounted) showMessage(context, e.description ?? context.l10n.errorGeneric);
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  /// Re-encodes to a ~1600px JPEG and strips EXIF (device model, original GPS, timestamps).
  static Future<String> _compress(String source) async {
    final target = '${File(source).parent.path}/sajag_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final out = await FlutterImageCompress.compressAndGetFile(
      source,
      target,
      minWidth: 1600,
      minHeight: 1600,
      quality: 82,
    );
    return out?.path ?? source;
  }

  /// Demo builds on devices without a camera (e.g. the iOS Simulator) get a generated test
  /// image so the rest of the flow can be exercised. Never available with a real backend.
  Future<void> _useDemoImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(1200, 750);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, size.bottomRight(Offset.zero), [
          const Color(0xFF6B7F86),
          const Color(0xFF2F3E44),
        ]),
    );
    canvas.drawCircle(const Offset(600, 375), 160, Paint()..color = const Color(0xFF1B1B1B));
    canvas.drawCircle(
      const Offset(600, 375),
      160,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..color = const Color(0xFF9AA5A9),
    );
    final image = await recorder.endRecording().toImage(size.width.toInt(), size.height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${Directory.systemTemp.path}/sajag_demo_${DateTime.now().microsecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    widget.onCaptured(file.path, DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (c != null && c.value.isInitialized)
            ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: c.value.previewSize?.height ?? 1,
                  height: c.value.previewSize?.width ?? 1,
                  child: CameraPreview(c),
                ),
              ),
            )
          else if (_issue != _CameraIssue.none)
            _CameraProblem(
              message: _issue == _CameraIssue.denied ? l.cameraDenied : l.cameraUnavailable,
              onSettings: _issue == _CameraIssue.denied ? Geolocator.openAppSettings : null,
              onDemo: AppConfig.isDemo && _issue == _CameraIssue.unavailable ? _useDemoImage : null,
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close),
                      ),
                      const Spacer(),
                      if (c != null)
                        IconButton.filledTonal(
                          tooltip: l.flash,
                          onPressed: _toggleFlash,
                          icon: Icon(_flash ? Icons.flash_on : Icons.flash_off),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                if (c != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      l.captureHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 15, shadows: [Shadow(blurRadius: 6)]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Semantics(
                    button: true,
                    label: l.navReport,
                    child: GestureDetector(
                      onTap: _capture,
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 5),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _capturing ? Colors.white54 : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraProblem extends StatelessWidget {
  const _CameraProblem({required this.message, this.onSettings, this.onDemo});
  final String message;
  final Future<bool> Function()? onSettings;
  final Future<void> Function()? onDemo;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 17),
          ),
          if (onSettings != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: onSettings, child: Text(context.l10n.openSettings)),
          ],
          if (onDemo != null) ...[
            const SizedBox(height: 20),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
              onPressed: onDemo,
              child: const Text('Use a test image (demo only)'),
            ),
          ],
        ],
      ),
    ),
  );
}
