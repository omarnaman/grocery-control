import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QRCodeScanner extends StatefulWidget {
  final Function(Map<String, dynamic>)? onCodeDetected;
  QRCodeScanner({super.key, this.onCodeDetected});
  @override
  State<StatefulWidget> createState() => _QRCodeScannerState();
}

class _QRCodeScannerState extends State<QRCodeScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      controller?.pauseCamera();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      controller?.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text('Scan a code'),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        final code = scanData.code;
        if (code != null) {
          controller.stopCamera();
          Map<String, dynamic> resultData = jsonDecode(code);
          widget.onCodeDetected?.call(resultData);
          Navigator.of(context).pop(resultData);
        }
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
