import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:trace_foodchain_app/services/service_functions.dart';

bool _isProcessing = false;

class QRCodeReceiver extends StatefulWidget {
  const QRCodeReceiver({Key? key}) : super(key: key);

  @override
  _QRCodeReceiverState createState() => _QRCodeReceiverState();
}

class _QRCodeReceiverState extends State<QRCodeReceiver> {
  final Map<int, String> _receivedChunks = {};
  int _totalChunks = 0;
  bool _isReceiving = true;

  void _processScannedCode(String? code) {
    if (!_isReceiving) return;

    if (code != null && code.contains(':')) {
      //we have to separate
      _isProcessing = true;
      int colonIndex = code.indexOf(':');
      final headerAll = code.substring(0, colonIndex);
      String payload = code.substring(colonIndex + 1);
      // debugPrint("Payload: ${payload}");
      debugPrint("Header: ${headerAll}");
      final header = headerAll.split('/');
      final chunkIndex = int.parse(header[0]);
      _totalChunks = int.parse(header[1]);
      final data = payload;
      _isProcessing = false;
      setState(() {
        _receivedChunks[chunkIndex] = data;
      });

      if (_receivedChunks.length == _totalChunks) {
        _assembleData();
      }
    }
  }

  void _assembleData() {
    final assembledData =
        List.generate(_totalChunks, (index) => _receivedChunks[index + 1] ?? '')
            .join();

    setState(() {
      _isReceiving = false;
    });

    // Use a post-frame callback to ensure the dialog is shown after the current frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final receivedProcessList = json.decode(assembledData);
       
        Navigator.of(context).pop(receivedProcessList);
      } catch (e) {
        debugPrint(assembledData);
        fshowInfoDialog(context, "Sorry, this QR code contained no valid data");
      }
    });
  }

  void _resetReceiver() {
    setState(() {
      _receivedChunks.clear();
      _totalChunks = 0;
      _isReceiving = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _isReceiving
              ? MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      _processScannedCode(barcode.rawValue);
                    }
                  },
                )
              : Center(child: Text('Reception complete')),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
              'Received ${_receivedChunks.length} out of $_totalChunks chunks',
              style: TextStyle(color: Colors.black)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: _resetReceiver,
            child: Text('Clear and Restart'),
          ),
        ),
      ],
    );
  }
}
