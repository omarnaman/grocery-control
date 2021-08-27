/* eslint-disable camelcase */
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


export const CreateGroup = functions.https.onCall((data, context) => {
  if (context == null) {
    return;
  }
  if (context.auth == null) {
    return;
  }
  const userId = context.auth?.uid;
  const groupName = data.groupName;
  const groupDocumentRef =
    admin.firestore().collection("groups").doc();
  const userDocumentRef =
    admin.firestore().collection("users").doc(userId);
  groupDocumentRef.create({
    owner: userId,
    name: groupName,
  });
  return userDocumentRef.get().then((doc) => {
    let groups = doc.data()?.group_ref_array || null;
    if (groups == null) {
      groups = [groupName];
    } else {
      groups = groups.concat(groupDocumentRef);
    }
    userDocumentRef.update({
      group_ref_array: groups,
    });
    return {text: "Done", id: groupDocumentRef};
  }).catch((err) => {
    return {error: err};
  });
});
