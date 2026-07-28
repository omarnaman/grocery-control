import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grocery_control/models/grocery_item.dart';
import 'package:grocery_control/models/group.dart';
import 'package:grocery_control/utils/constants.dart';

class Database {
  final FirebaseFirestore firestore;

  Database({required this.firestore});

  Future<List<GroupModel>> streamGroups({required String uid}) async {
    try {
      DocumentSnapshot userDoc =
          await firestore.collection("users").doc(uid).get();

      final List<GroupModel> retVal = <GroupModel>[];
      final data = userDoc.data() as Map<String, dynamic>;
      final List<DocumentReference> groupRefs =
          (data["group_ref_array"] as List).cast<DocumentReference>();
      for (DocumentReference documentRef in groupRefs) {
        retVal.add(GroupModel.fromDocumentSnapshot(
            documentSnapshot: await documentRef.get()));
      }
      return retVal;
    } catch (e) {
      rethrow;
    }
  }

  Future<GroupModel> getLastGroup({required String uid}) async {
    try {
      var doc = await firestore.collection("users").doc(uid).get();
      final data = doc.data() as Map<String, dynamic>;
      DocumentReference groupRef = data["last_group"] as DocumentReference;
      return GroupModel.fromDocumentSnapshot(
          documentSnapshot: await groupRef.get());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setLastGroup({
    required String uid,
    required GroupModel group,
  }) async {
    try {
      await firestore.collection("users").doc(uid).update(
          {"last_group": firestore.collection("groups").doc(group.groupId)});
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<GroceryItemModel>> streamItems({
    required String group,
    required SortDirection sortDirection,
  }) {
    try {
      return firestore
          .collection("items")
          .doc(group)
          .collection("items")
          .orderBy("Name",
              descending: sortDirection == SortDirection.Decsending)
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

  Future<void> updateGroupName({
    required GroupModel group,
    required String newName,
    required String uid,
  }) async {
    try {
      if (group.owner != uid) {
        return;
      }
      if (group.name == newName) {
        return;
      }

      DocumentReference groupDoc =
          firestore.collection("groups").doc(group.groupId);
      await groupDoc.update({
        "name": newName,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addItem({
    required String group,
    required String name,
    required List<String> tags,
  }) async {
    try {
      await firestore
          .collection("items")
          .doc(group)
          .collection("items")
          .add({"Name": name, "Checked": false, "Tags": tags});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateItem({
    required String group,
    required String itemId,
    String? name,
    bool? checked,
    List<String>? tags,
  }) async {
    try {
      final Map<String, dynamic> doc = {};
      if (name != null) {
        doc["Name"] = name;
      }
      if (tags != null) {
        doc["Tags"] = tags;
      }
      if (checked != null) {
        doc["Checked"] = checked;
      }
      await firestore
          .collection("items")
          .doc(group)
          .collection("items")
          .doc(itemId)
          .update(doc);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteItem({required GroceryItemModel item}) async {
    try {
      await firestore
          .collection("items")
          .doc(item.group)
          .collection("items")
          .doc(item.itemId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }
}
