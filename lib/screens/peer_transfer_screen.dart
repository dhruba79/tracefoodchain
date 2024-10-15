import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:trace_foodchain_app/widgets/qr_code_receiver.dart';

import '../widgets/qr_code_sender.dart';

class PeerTransferScreen extends StatefulWidget {
  final String transferMode;
  final List<Map<String, dynamic>> transferredDataOutgoing;

  const PeerTransferScreen(
      {Key? key,
      required this.transferMode,
      required this.transferredDataOutgoing})
      : super(key: key);

  @override
  _PeerTransferScreenState createState() => _PeerTransferScreenState();
}

class _PeerTransferScreenState extends State<PeerTransferScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.peerTransfer)),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: widget.transferMode == "send"
                  ? QRCodeSender(
                      data: json.encode(widget.transferredDataOutgoing))
                  : QRCodeReceiver(),
            ),
          ],
        ),
      ),
    );
  }

 
}
