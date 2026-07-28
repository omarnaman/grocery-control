import 'package:flutter/material.dart';
import 'package:grocery_control/models/group.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GroupQRCodeDialog extends StatefulWidget {
  final GroupModel groupModel;
  GroupQRCodeDialog({super.key, required this.groupModel});

  @override
  _GroupQRCodeDialogState createState() => _GroupQRCodeDialogState();
}

class _GroupQRCodeDialogState extends State<GroupQRCodeDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Join Group"),
      content: Container(
        height: 280,
        width: 280,
        child: QrImageView(
          data: _getGroupJSON(widget.groupModel),
          version: QrVersions.auto,
          size: 320,
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
      actions: <Widget>[
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("Exit")),
      ],
    );
  }

  String _getGroupJSON(GroupModel groupModel) {
    var result = '''{
      "Id": "${groupModel.groupId}",
      "Action": "Join group ${groupModel.name}"
    }''';
    return result;
  }
}
