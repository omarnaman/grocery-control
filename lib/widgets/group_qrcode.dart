import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_control/models/group.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GroupQRCodeDialog extends StatefulWidget {
  final GroupModel groupModel;
  GroupQRCodeDialog({super.key, required this.groupModel});

  @override
  _GroupQRCodeDialogState createState() => _GroupQRCodeDialogState();
}

class _GroupQRCodeDialogState extends State<GroupQRCodeDialog> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final inviteCode = widget.groupModel.groupId;
    return AlertDialog(
      title: Text("Share ${widget.groupModel.name}"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 220,
              width: 220,
              child: QrImageView(
                data: _getGroupJSON(widget.groupModel),
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Invite code",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              inviteCode,
              style: const TextStyle(fontFamily: "monospace", fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: inviteCode));
                if (!mounted) return;
                setState(() {
                  _copied = true;
                });
              },
              icon: Icon(_copied ? Icons.check : Icons.copy),
              label: Text(_copied ? "Copied" : "Copy invite code"),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Exit")),
      ],
    );
  }

  String _getGroupJSON(GroupModel groupModel) {
    return jsonEncode({
      "Id": groupModel.groupId,
      "Action": "Join group ${groupModel.name}",
    });
  }
}
