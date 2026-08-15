import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grocery_control/models/grocery_item.dart';
import 'package:grocery_control/models/list_change.dart';
import 'package:grocery_control/services/db.dart';
import 'package:grocery_control/widgets/aqel_checkbox.dart';

class GroceryItemCard extends StatefulWidget {
  final GroceryItemModel item;
  final FirebaseFirestore firestore;
  final String selectedKey;
  final Function(String, String, List<String>) onSelectItem;
  final ChangeType? changeType;
  final bool isGhost;
  final void Function(String itemId, bool checked)? onCheckedLocally;
  final void Function(String itemId)? onDeletedLocally;

  GroceryItemCard({
    super.key,
    required this.item,
    required this.firestore,
    required String group,
    required this.onSelectItem,
    required this.selectedKey,
    this.changeType,
    this.isGhost = false,
    this.onCheckedLocally,
    this.onDeletedLocally,
  }) {
    item.group = group;
  }

  @override
  _GroceryItemCardState createState() => _GroceryItemCardState();
}

class _GroceryItemCardState extends State<GroceryItemCard> {
  bool _isSelected = false;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.selectedKey == widget.item.itemId;
  }

  @override
  void didUpdateWidget(covariant GroceryItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _isSelected = widget.selectedKey == widget.item.itemId;
  }

  Color? _highlightColor(BuildContext context) {
    switch (widget.changeType) {
      case ChangeType.added:
        return Colors.green.withValues(alpha: 0.22);
      case ChangeType.checked:
        return Colors.lightBlue.withValues(alpha: 0.22);
      case ChangeType.renamed:
        return Colors.amber.withValues(alpha: 0.22);
      case ChangeType.deleted:
        return Colors.red.withValues(alpha: 0.22);
      case null:
        return null;
    }
  }

  Color _borderColor(BuildContext context) {
    if (_isSelected) {
      return Theme.of(context).colorScheme.secondary;
    }
    switch (widget.changeType) {
      case ChangeType.added:
        return Colors.green;
      case ChangeType.checked:
        return Colors.lightBlue;
      case ChangeType.renamed:
        return Colors.amber;
      case ChangeType.deleted:
        return Colors.redAccent;
      case null:
        return Theme.of(context).primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final highlight = _highlightColor(context);
    return GestureDetector(
      onLongPress: widget.isGhost
          ? null
          : () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Item Deletion"),
                      content: Text(
                          "Are you sure you want to delete ${widget.item.name}?"),
                      actions: [
                        TextButton(
                            onPressed: () {
                              Database(firestore: widget.firestore)
                                  .deleteItem(item: widget.item);
                              widget.onDeletedLocally?.call(widget.item.itemId);
                              Navigator.of(context).pop();
                            },
                            child: const Text("Delete")),
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Cancel")),
                      ],
                    );
                  });
            },
      onTap: widget.isGhost
          ? null
          : () {
              GroceryItemModel item = widget.item;
              String name = item.name;
              String key = item.itemId;
              List<String> tags = item.tags.toList();
              widget.onSelectItem(key, name, tags);
            },
      child: Card(
        color: highlight,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        shape: RoundedRectangleBorder(
            side: BorderSide(color: _borderColor(context)),
            borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.item.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    decoration: widget.isGhost
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: widget.isGhost
                        ? Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.6)
                        : null,
                  ),
                ),
              ),
              if (!widget.isGhost)
                AqelCheckbox(
                  value: widget.item.checked,
                  onChanged: (newValue) {
                    widget.onCheckedLocally?.call(widget.item.itemId, newValue);
                    Database(firestore: widget.firestore).updateItem(
                      group: widget.item.group,
                      name: widget.item.name,
                      itemId: widget.item.itemId,
                      checked: newValue,
                    );
                    // widget.onCheckedLocally?.call(widget.item.itemId, newValue);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
