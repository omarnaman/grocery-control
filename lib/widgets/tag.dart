import 'package:flutter/material.dart';

class Tag extends StatefulWidget {
  final String content;
  final VoidCallback onDelete;
  Tag({Key key, this.content, this.onDelete}) : super(key: key);

  @override
  _TagCardState createState() => _TagCardState();
}

class _TagCardState extends State<Tag> {
  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.content,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                child: Icon(Icons.close),
                onTap: () {
                  widget.onDelete();
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
