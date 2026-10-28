import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../core/app_exception.dart';
import '../providers/visitor_provider.dart';
import '../widgets/app_feedback.dart';
import 'visitor_details_screen.dart';

/// Scans a visitor QR (which encodes the visitor id), looks the visitor up through
/// the API and opens the details screen where check-in / check-out happens.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  /// Guards against the scanner firing many callbacks for one QR code.
  bool _handling = false;
  String? _feedback;
  bool _feedbackIsError = true;

  // Visitor ids are server generated; accept only simple id-like strings.
  static final _validId = RegExp(r'^[A-Za-z0-9_\-]{1,64}$');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (raw == null) return;

    _handling = true;
    final provider = context.read<VisitorProvider>();
    final navigator = Navigator.of(context);
    final id = raw.trim();

    if (!_validId.hasMatch(id)) {
      _setFeedback('Invalid QR code. This is not a visitor pass.');
      await _cooldown();
      return;
    }

    _setFeedback('Looking up visitor...', error: false);
    try {
      final visitor = await provider.fetchById(id);
      if (!mounted) return;
      _setFeedback(null);
      await _controller.stop();
      await navigator.push(
        MaterialPageRoute(builder: (_) => VisitorDetailsScreen(visitorId: visitor.id)),
      );
      if (!mounted) return;
      await _controller.start();
    } on NotFoundException {
      _setFeedback('Visitor does not exist for this QR code.');
    } on AppException catch (e) {
      _setFeedback(e.message);
    } catch (_) {
      _setFeedback('Could not read this QR code. Please try again.');
    }
    await _cooldown();
  }

  /// Short pause so the same code in view is not processed again immediately.
  Future<void> _cooldown() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _handling = false;
    if (_feedbackIsError) _setFeedback(null);
  }

  void _setFeedback(String? message, {bool error = true}) {
    if (!mounted) return;
    setState(() {
      _feedback = message;
      _feedbackIsError = error;
    });
    if (message != null && error) showAppSnackBar(context, message, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            tooltip: 'Toggle torch',
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: 'Switch camera',
            icon: const Icon(Icons.cameraswitch_outlined),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) => _CameraError(error: error),
          ),
          // Scanning area guide.
          IgnorePointer(
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _feedback != null && _feedbackIsError
                      ? scheme.errorContainer
                      : Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _feedback ?? 'Point the camera at a visitor QR code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _feedback != null && _feedbackIsError
                        ? scheme.onErrorContainer
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: Theme.of(context).colorScheme.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            denied ? Icons.no_photography_outlined : Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            denied ? 'Camera permission denied' : 'Camera unavailable',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            denied
                ? 'Allow camera access in your phone\'s Settings > Apps > Visitor Management > Permissions to scan QR codes.'
                : 'The camera could not be started. Close other apps using the camera and try again.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
