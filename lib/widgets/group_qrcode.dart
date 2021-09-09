import 'package:flutter/material.dart';
import 'package:grocery_control/models/group.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GroupQRCodeDialog extends StatefulWidget {
  final GroupModel groupModel;
  GroupQRCodeDialog({Key key, this.groupModel}) : super(key: key);

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
        child: QrImage(
          data: _getGroupJSON(this.widget.groupModel),
          version: QrVersions.auto,
          size: 320,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
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
