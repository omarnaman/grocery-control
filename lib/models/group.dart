
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  String groupId;
  String name;
  String owner;

  GroupModel({
    this.groupId,
    this.name,
    this.owner,
  });

  GroupModel.fromDocumentSnapshot({DocumentSnapshot documentSnapshot}) {
    groupId = documentSnapshot.id;
    name = (documentSnapshot.data() as Map<String, dynamic>)['name'] as String;
    owner = (documentSnapshot.data() as Map<String, dynamic>)['owner'] as String;

  }

  bool operator ==(dynamic other) =>
      other != null && other is GroupModel && this.groupId == other.groupId;
  
  @override
  int get hashCode => super.hashCode;

}
