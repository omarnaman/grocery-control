import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grocery_control/screens/home.dart';
import 'package:grocery_control/screens/login.dart';
import 'package:grocery_control/services/auth.dart';
import 'package:grocery_control/services/db.dart';
import 'package:grocery_control/models/group.dart';
import 'package:grocery_control/firebase_options.dart';

Future<void> main() async {
  runApp(App());
}

/// Debug-only auto-login via:
/// `flutter run --dart-define=AUTO_LOGIN_EMAIL=... --dart-define=AUTO_LOGIN_PASSWORD=...`
Future<void> _maybeAutoLogin() async {
  const email = String.fromEnvironment('AUTO_LOGIN_EMAIL');
  const password = String.fromEnvironment('AUTO_LOGIN_PASSWORD');
  if (!kDebugMode || email.isEmpty || password.isEmpty) {
    return;
  }

  final auth = FirebaseAuth.instance;
  if (auth.currentUser != null) {
    return;
  }

  await Auth(auth: auth).signIn(email: email, password: password);
}

Future<FirebaseApp> _bootstrapFirebase() async {
  final app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _maybeAutoLogin();
  return app;
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: FutureBuilder(
        future: _bootstrapFirebase(),
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
    return StreamBuilder<User?>(
      stream: Auth(auth: _auth).user,
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return Login(
              auth: _auth,
              firestore: _firestore,
            );
          } else {
            return FutureBuilder<GroupModel>(
                future: Database(firestore: _firestore)
                    .getLastGroup(uid: user.uid),
                builder: (BuildContext context,
                    AsyncSnapshot<GroupModel> groupSnapshot) {
                  if (groupSnapshot.connectionState == ConnectionState.done) {
                    final group = groupSnapshot.data;
                    if (group != null) {
                      return Home(
                          auth: _auth,
                          firestore: _firestore,
                          group: group);
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
