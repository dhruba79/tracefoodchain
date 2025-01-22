import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/services.dart';

int moveSpeed = 500; // Increased default display time to 500ms
int chunkSize = 500; // Reduced chunk size for less dense QR codes

class QRCodeSender extends StatefulWidget {
  final String data;

  const QRCodeSender({super.key, required this.data});

  @override
  _QRCodeSenderState createState() => _QRCodeSenderState();
}

class _QRCodeSenderState extends State<QRCodeSender> {
  List<String> _chunks = [];
  int _currentChunkIndex = 0;
  Timer? _timer;
  double _currentSpeed = moveSpeed.toDouble();
  double _qrSize = 400.0;

  @override
  void initState() {
    super.initState();
    _chunks = _splitData(widget.data);
    // Set maximum brightness when QR sender starts
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  List<String> _splitData(String data) {
    return List.generate(
      (data.length / chunkSize).ceil(),
      (index) {
        final start = index * chunkSize;
        final end = (index + 1) * chunkSize;
        String chunk =
            data.substring(start, end > data.length ? data.length : end);
        // Pad last chunk with spaces to match chunkSize
        if (chunk.length < chunkSize) {
          chunk = chunk.padRight(chunkSize);
        }
        return '${index + 1}/${(data.length / chunkSize).ceil()}:$chunk';
      },
    );
  }

  void _startQRMovie() {
    _currentChunkIndex = 0;
    _timer = Timer.periodic(Duration(milliseconds: moveSpeed), (timer) {
      setState(() {
        _currentChunkIndex = (_currentChunkIndex + 1) % _chunks.length;
      });
    });
  }

  void _stopQRMovie() {
    _timer?.cancel();
    _timer = null;
  }

  void _updateSpeed(double newSpeed) {
    setState(() {
      _currentSpeed = newSpeed;
      moveSpeed = newSpeed.toInt();
      if (_timer != null) {
        _stopQRMovie();
        _startQRMovie();
      }
    });
  }

  @override
  void dispose() {
    // Restore system UI when widget is disposed
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    _stopQRMovie();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Colors.black, // Add black background for better contrast
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_timer != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 20),
              ),
              child: SizedBox(
                height: _qrSize,
                width: _qrSize,
                child: QrImageView(
                  data: _chunks[_currentChunkIndex],
                  version: QrVersions.auto,
                  size: _qrSize,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF000000), // Pure black
                ),
              ),
            )
          else
            Text(
              l10n.waitingForData,
              style: const TextStyle(color: Colors.white),
            ),
          const SizedBox(height: 20),
          if (kDebugMode) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Speed: ', style: TextStyle(color: Colors.white)),
                Slider(
                  value: _currentSpeed,
                  min: 300, // Increased minimum speed
                  max: 2000, // Increased maximum speed
                  divisions: 17,
                  label: '${_currentSpeed.round()} ms',
                  onChanged: _updateSpeed,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Size: ', style: TextStyle(color: Colors.white)),
                Slider(
                  value: _qrSize,
                  min: 200,
                  max: 600,
                  divisions: 8,
                  label: '${_qrSize.round()} px',
                  onChanged: (value) => setState(() => _qrSize = value),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _timer == null ? _startQRMovie : _stopQRMovie,
            child:
                Text(_timer == null ? l10n.startScanning : l10n.stopScanning),
          ),
        ],
      ),
    );
  }
}
