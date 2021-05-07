import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grocery_control/models/grocery_item.dart';
import 'package:grocery_control/services/db.dart';
import 'package:grocery_control/widgets/aqel_checkbox.dart';

class GroceryItemCard extends StatefulWidget {
  final GroceryItemModel item;
  final FirebaseFirestore firestore;

  GroceryItemCard({Key key, this.item, this.firestore, String group})
      : super(key: key){
        item.group = group;
      }
  
  @override
  _GroceryItemCardState createState() => _GroceryItemCardState();
}

class _GroceryItemCardState extends State<GroceryItemCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
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
                setState(() {});
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
    );
  }
}