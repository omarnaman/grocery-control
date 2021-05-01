import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grocery_control/models/grocery_item.dart';
import 'package:grocery_control/models/group.dart';

class Database {
  final FirebaseFirestore firestore;

  Database({this.firestore});

  Stream<List<GroupModel>> streamGroups({String uid}) {
    try {
      return firestore
          .collection("users")
          .doc(uid)
          .collection("groups")
          .snapshots()
          .map((query) {
        final List<GroupModel> retVal = <GroupModel>[];
        for (final DocumentSnapshot doc in query.docs) {
          retVal.add(GroupModel.fromDocumentSnapshot(documentSnapshot: doc));
        }
        return retVal;
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<GroupModel> getLastGroup({String uid}) async {
    try {
      var doc = await firestore.collection("users").doc(uid).get();
      return GroupModel(
          groupId: doc["last_group"]["Id"], name: doc["last_group"]["name"]);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setLastGroup({String uid, GroupModel group}) async {
    try {
      firestore.collection("users").doc(uid).update({
        "last_group": {"name": group.name, "Id": group.groupId}
      });
    } catch (e) {
      rethrow;
    }
  }

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
          retVal.add(GroceryItemModel.fromDocumentSnapshot(
              documentSnapshot: doc, group: group));
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

  Future<void> updateItem(
      {String group, String itemId, String name, bool checked}) async {
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
