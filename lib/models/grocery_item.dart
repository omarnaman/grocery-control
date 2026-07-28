import 'package:cloud_firestore/cloud_firestore.dart';

class GroceryItemModel {
  String itemId;
  String name;
  bool checked;
  String group;
  List<String> tags;

  GroceryItemModel({
    required this.itemId,
    required this.name,
    required this.checked,
    required this.group,
    required this.tags,
  });

  factory GroceryItemModel.fromDocumentSnapshot({
    required DocumentSnapshot documentSnapshot,
    required String group,
  }) {
    final data = documentSnapshot.data() as Map<String, dynamic>;
    return GroceryItemModel(
      itemId: documentSnapshot.id,
      name: data['Name'] as String,
      checked: data['Checked'] as bool,
      group: group,
      tags: data.containsKey('Tags') ? List<String>.from(data['Tags']) : [],
    );
  }
}
