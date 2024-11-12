import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

int moveSpeed = 200; //time in ms between 2 "frames"
int chunkSize = 1000;

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

  @override
  void initState() {
    super.initState();
    _chunks = _splitData(widget.data);
  }

  List<String> _splitData(String data) {
    return List.generate(
      (data.length / chunkSize).ceil(),
      (index) =>
          '${index + 1}/${(data.length / chunkSize).ceil()}:${data.substring(index * chunkSize, (index + 1) * chunkSize > data.length ? data.length : (index + 1) * chunkSize)}',
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

  @override
  void dispose() {
    _stopQRMovie();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_timer != null)
          SizedBox(
            height: 300,
            width: 300,
            child: QrImageView(
              data: _chunks[_currentChunkIndex],
              version: QrVersions.auto,
              size: 300.0,
            ),
          )
        else
          Text(l10n.waitingForData),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _timer == null ? _startQRMovie : _stopQRMovie,
          child: Text(_timer == null ? l10n.startScanning : l10n.stopScanning),
        ),
      ],
    );
  }
}
