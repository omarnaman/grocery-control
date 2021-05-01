
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  String groupId;
  String name;

  GroupModel({
    this.groupId,
    this.name,
  });

  GroupModel.fromDocumentSnapshot({DocumentSnapshot documentSnapshot}) {
    groupId = documentSnapshot.id;
    name = documentSnapshot.data()['name'] as String;
  }

  bool operator ==(dynamic other) =>
      other != null && other is GroupModel && this.groupId == other.groupId;
  
  @override
  int get hashCode => super.hashCode;

}
