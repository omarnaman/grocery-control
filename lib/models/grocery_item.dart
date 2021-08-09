import 'package:cloud_firestore/cloud_firestore.dart';

class GroceryItemModel {
  String itemId;
  String name;
  bool checked;
  String group;

  GroceryItemModel({
    this.itemId,
    this.name,
    this.checked,
    this.group,
  });

  GroceryItemModel.fromDocumentSnapshot({DocumentSnapshot documentSnapshot, String group}) {
    itemId = documentSnapshot.id;
    name = documentSnapshot.data()['Name'] as String;
    checked = documentSnapshot.data()['Checked'] as bool;
    group = group;
  }

}