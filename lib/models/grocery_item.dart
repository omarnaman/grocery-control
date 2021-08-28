import 'package:cloud_firestore/cloud_firestore.dart';

class GroceryItemModel {
  String itemId;
  String name;
  bool checked;
  String group;
  List<String> tags;

  GroceryItemModel(
      {this.itemId, this.name, this.checked, this.group, this.tags});

  GroceryItemModel.fromDocumentSnapshot(
      {DocumentSnapshot documentSnapshot, String group}) {
    itemId = documentSnapshot.id;
    name = (documentSnapshot.data() as Map<String, dynamic>) ['Name'] as String;
    checked = (documentSnapshot.data() as Map<String, dynamic>)['Checked'] as bool;
    group = group;
    if ( (documentSnapshot.data() as Map<String, dynamic>).containsKey("Tags")) {
      tags = List.from( (documentSnapshot.data() as Map<String, dynamic>)['Tags']);
    } else {
      tags = [];
    }
  }
}
