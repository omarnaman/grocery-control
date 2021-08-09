import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
admin.initializeApp();


export const SignUp = functions.auth.user().onCreate((user) => {
  const userId = user.uid;
  const usersCollection =
    admin.firestore().collection("users");
  const userDocumentRef =
    usersCollection.doc(userId);
  const groupDocumentRef =
    admin.firestore().collection("groups").doc();
  const groupId = groupDocumentRef.id;
  const itemsDocumentRef =
    admin.firestore().collection("items").doc(groupId);
  const groupName = "Default Group";

  groupDocumentRef.create({owner: userId, name: groupName});
  userDocumentRef.create({
    last_group: groupDocumentRef,
    group_ref_array: [groupDocumentRef]});
  itemsDocumentRef.create({});
});
