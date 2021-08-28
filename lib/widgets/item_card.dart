import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grocery_control/models/grocery_item.dart';
import 'package:grocery_control/services/db.dart';
import 'package:grocery_control/widgets/aqel_checkbox.dart';

class GroceryItemCard extends StatefulWidget {
  final GroceryItemModel item;
  final FirebaseFirestore firestore;
  final String selectedKey;
  final Function(String, String, List<String>) onSelectItem;
  GroceryItemCard(
      {Key key,
      this.item,
      this.firestore,
      @required String group,
      this.onSelectItem,
      this.selectedKey})
      : super(key: key) {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Item Deletion"),
                content: Text(
                    "Are you sure you want to delete ${{widget.item.name}}?"),
                actions: [
                  TextButton(
                      onPressed: () {
                        Database(firestore: widget.firestore)
                            .deleteItem(item: widget.item);
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
      onTap: () {
        GroceryItemModel item = widget.item;
        String name = item.name;
        String key = item.itemId;
        List<String> tags = item.tags.toList();
        widget.onSelectItem(key, name, tags);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        shape: RoundedRectangleBorder(
            side: _isSelected
                ? BorderSide(color: Theme.of(context).accentColor)
                : BorderSide(color: Theme.of(context).primaryColor),
            borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AqelCheckbox(
                value: widget.item.checked,
                onChanged: (newValue) {
                  Database(firestore: widget.firestore).updateItem(
                    group: widget.item.group,
                    name: widget.item.name,
                    itemId: widget.item.itemId,
                    checked: newValue,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
