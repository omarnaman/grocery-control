import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  String groupId;
  String name;
  String owner;

  GroupModel({
    required this.groupId,
    required this.name,
    required this.owner,
  });

  GroupModel.fromDocumentSnapshot({required DocumentSnapshot documentSnapshot})
      : groupId = documentSnapshot.id,
        name = (documentSnapshot.data() as Map<String, dynamic>)['name'] as String,
        owner =
            (documentSnapshot.data() as Map<String, dynamic>)['owner'] as String;

  @override
  bool operator ==(Object other) =>
      other is GroupModel && groupId == other.groupId;

  @override
  int get hashCode => groupId.hashCode;
}
