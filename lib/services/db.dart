import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grocery_control/models/grocery_item.dart';

class Database {
  final FirebaseFirestore firestore;

  Database({this.firestore});

  Stream<List<GroceryItemModel>> streamItems({String group}) {
    try {
      return firestore
          .collection("items")
          .doc(group)
          .collection("items")
          .snapshots()
          .map((query) {
        final List<GroceryItemModel> retVal = <GroceryItemModel>[];
        for (final DocumentSnapshot doc in query.docs) {
          retVal.add(GroceryItemModel.fromDocumentSnapshot(documentSnapshot: doc, group: group));
        }
        return retVal;
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addItem({String group, String name}) async {
    try {
      firestore.collection("items").doc(group).collection("items").add({
        "Name": name,
        "Checked": false,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateItem({String group, String itemId, String name, bool checked}) async {
    try {
      firestore
          .collection("items")
          .doc(group)
          .collection("items")
          .doc(itemId)
          .update({
        "Checked": checked,
        "Name": name,
      });
    } catch (e) {
      rethrow;
    }
  }
}