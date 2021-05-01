import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grocery_control/models/grocery_item.dart';
import 'package:grocery_control/models/group.dart';
import 'package:grocery_control/services/auth.dart';
import 'package:grocery_control/services/db.dart';
import 'package:grocery_control/widgets/item_card.dart';

class Home extends StatefulWidget {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final GroupModel group;
  const Home({Key key, this.auth, this.firestore, this.group})
      : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _itemController = TextEditingController();
  GroupModel _group;
  @override
  void initState() {
    super.initState();
    _group = widget.group;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Grocery Control"),
        centerTitle: true,
        actions: [
          IconButton(
            key: const ValueKey("changeGroup"),
            icon: const Icon(Icons.people_alt_outlined),
            color: Colors.white,
            onPressed: () {},
          ),
          IconButton(
            key: const ValueKey("signOut"),
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              Auth(auth: widget.auth).signOut();
            },
          ),
        ],
      ),
      drawer: Drawer(
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 8),
              child: Column(
                children: <Widget>[
                  const SizedBox(
                    height: 30,
                  ),
                  StreamBuilder(
                    stream: Database(firestore: widget.firestore)
                        .streamGroups(uid: widget.auth.currentUser.uid),
                    builder: (BuildContext context,
                        AsyncSnapshot<List<GroupModel>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.active) {
                        if (snapshot.data.isEmpty) {
                          return const Center(
                            child: Text("No groups available"),
                          );
                        }
                        if (snapshot.data.length == 1) {
                          return Center(
                            child: Text(snapshot.data.first.name),
                          );
                        }
                        return DropdownButton<GroupModel>(
                          value: _group,
                          icon: const Icon(
                            Icons.people_alt_outlined,
                            color: Colors.white,
                          ),
                          iconSize: 24,
                          elevation: 16,
                          style: const TextStyle(
                              color: Colors.purple,
                              fontSize: 20,
                              fontFamily: "Trebuchet MS"),
                          underline: Container(
                            height: 2,
                            color: Colors.purpleAccent,
                          ),
                          hint: Container(
                            child: Text(_group.name),
                          ),
                          items: snapshot.data
                              .map<DropdownMenuItem<GroupModel>>((value) {
                            return DropdownMenuItem<GroupModel>(
                              value: value,
                              child: Text(value.name),
                            );
                          }).toList(),
                          isExpanded: true,
                          onChanged: (GroupModel newValue) {
                            setState(() {
                              _group = newValue;
                              Database(firestore: widget.firestore)
                                  .setLastGroup(
                                      uid: widget.auth.currentUser.uid,
                                      group: _group);
                            });
                            Navigator.pop(context);
                          },
                        );
                      } else {
                        return const Center(
                          child: Text("loading..."),
                        );
                      }
                    },
                  )
                ],
              ))),
      body: Column(
        children: <Widget>[
          const SizedBox(
            height: 20,
          ),
          const Text(
            "Add item:",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Card(
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey("addField"),
                      controller: _itemController,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey("addButton"),
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (_itemController.text != "") {
                        setState(() {
                          Database(firestore: widget.firestore).addItem(
                              group: _group.groupId,
                              name: _itemController.text);
                          _itemController.clear();
                        });
                      }
                    },
                  )
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          const Text(
            "Your Items",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: Database(firestore: widget.firestore)
                  .streamItems(group: _group.groupId),
              builder: (BuildContext context,
                  AsyncSnapshot<List<GroceryItemModel>> snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.data.isEmpty) {
                    return const Center(
                      child: Text("You don't have any unchecked items"),
                    );
                  }
                  return ListView.builder(
                    itemCount: snapshot.data.length,
                    itemBuilder: (_, index) {
                      return GroceryItemCard(
                        firestore: widget.firestore,
                        item: snapshot.data[index],
                        group: _group.groupId,
                      );
                    },
                  );
                } else {
                  return const Center(
                    child: Text("loading..."),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.navigation),
        backgroundColor: Colors.purple,
      ),
    );
  }
}
