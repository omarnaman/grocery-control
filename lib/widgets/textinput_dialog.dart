import 'package:flutter/material.dart';

class TextInputDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String okOption;
  TextInputDialog({Key key, this.hint, this.title, this.okOption}) : super(key: key);

  @override
  _TextInputDialogState createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  final TextEditingController _textEditingController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        autofocus: true,
        onChanged: (value) {},
        controller: _textEditingController,
        decoration: InputDecoration(hintText: widget.hint),
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              Navigator.of(context).pop(_textEditingController.text);
            },
            child: Text(widget.okOption)),
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("Cancel")),
      ],
    );
  }
}
