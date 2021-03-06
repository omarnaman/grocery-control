import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import 'package:grocery_control/screens/home.dart';
import 'package:grocery_control/screens/login.dart';
import 'package:grocery_control/services/auth.dart';
import 'package:grocery_control/services/db.dart';
import 'package:grocery_control/models/group.dart';

Future<void> main() async{
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: FutureBuilder(
        // Initialize FlutterFire:
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          // Check for errors
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Text("Error"),
              ),
            );
          }

          // Once complete, show your application
          if (snapshot.connectionState == ConnectionState.done) {
            return Root();
          }

          // Otherwise, show something whilst waiting for initialization to complete
          return const Scaffold(
            body: Center(
              child: Text("Loading..."),
            ),
          );
        },
      ),
    );
  }
}

class Root extends StatefulWidget {
  @override
  _RootState createState() => _RootState();
}

class _RootState extends State<Root> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Auth(auth: _auth).user,
      builder: (BuildContext context, AsyncSnapshot<User> snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.data?.uid == null) {
            return Login(
              auth: _auth,
              firestore: _firestore,
            );
          } else {
            return FutureBuilder(
                future: Database(firestore: _firestore)
                    .getLastGroup(uid: _auth.currentUser.uid),
                builder: (BuildContext context,
                    AsyncSnapshot<GroupModel> groupSnapshot) {
                  if (groupSnapshot.connectionState == ConnectionState.done) {
                    if (groupSnapshot.data != null) {
                      return Home(
                          auth: _auth,
                          firestore: _firestore,
                          group: groupSnapshot.data);
                    }
                    return const Scaffold(
                      body: Center(
                        child: Text("Error - No Group Found"),
                      ),
                    );
                  } else {
                    return const Scaffold(
                      body: Center(
                        child: Text("Loading..."),
                      ),
                    );
                  }
                });
          }
        } else {
          return const Scaffold(
            body: Center(
              child: Text("Loading..."),
            ),
          );
        }
      }, //Auth stream
    );
  }
}
