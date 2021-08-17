import 'package:flutter/material.dart';
import 'tag.dart';

class TagList extends StatefulWidget {
  final List<String> tags;
  final Function(int) onTagDelete;
  TagList({Key key, this.tags, this.onTagDelete}) : super(key: key);

  @override
  _TagListState createState() => _TagListState();
}

// TODO: make number of tags per row flexible

class _TagListState extends State<TagList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemBuilder: (_, index) {
        if (index * 2 >= widget.tags.length) {
          return SizedBox();
        }
        List<Tag> rowTags = [];
        rowTags.add(Tag(
          content: widget.tags[index * 2],
          onDelete: () {
            widget.onTagDelete(index * 2);
          },
        ));
        if (index * 2 + 1 < widget.tags.length) {
          rowTags.add(Tag(
            content: widget.tags[index * 2 + 1],
            onDelete: () {
              widget.onTagDelete(index * 2 + 1);
            },
          ));
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: rowTags,
        );
      },
      itemCount: (widget.tags.length + 1 ~/ 2), //ceil integer division
    );
  }
}
