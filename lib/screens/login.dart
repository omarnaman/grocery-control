import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grocery_control/services/auth.dart';

class Login extends StatefulWidget {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  const Login({
    Key key,
    @required this.auth,
    @required this.firestore,
  }) : super(key: key);
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  FocusNode _passwordFocus;
  @override
  void initState() {
    super.initState();
    _passwordFocus = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();
    _passwordFocus.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(60.0),
          child: Builder(builder: (BuildContext context) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  key: const ValueKey("username"),
                  textAlign: TextAlign.center,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    _passwordFocus.requestFocus();
                  },
                  autofocus: true,
                  decoration: const InputDecoration(hintText: "Username"),
                  controller: _emailController,
                ),
                TextFormField(
                  key: const ValueKey("password"),
                  obscureText: true,
                  focusNode: _passwordFocus,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) async {
                    _login();
                  },
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(hintText: "Password"),
                  controller: _passwordController,
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  key: const ValueKey("signIn"),
                  onPressed: () async {_login();},
                  child: const Text("Sign In"),
                ),
                TextButton(
                  key: const ValueKey("createAccount"),
                  onPressed: () async {
                    final String retVal =
                        await Auth(auth: widget.auth).createAccount(
                      email: _emailController.text,
                      password: _passwordController.text,
                    );
                    if (retVal == "Success") {
                      _emailController.clear();
                      _passwordController.clear();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(retVal),
                        ),
                      );
                    }
                  },
                  child: const Text("Create Account"),
                )
              ],
            );
          }),
        ),
      ),
    );
  }

  _login() async {
    final String retVal = await Auth(auth: widget.auth).signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (retVal == "Success") {
      _emailController.clear();
      _passwordController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(retVal),
        ),
      );
    }
  }
}
