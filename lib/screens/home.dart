import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grocery_control/models/grocery_item.dart';
import 'package:grocery_control/models/group.dart';
import 'package:grocery_control/services/auth.dart';
import 'package:grocery_control/services/db.dart';
import 'package:grocery_control/utils/constants.dart';
import 'package:grocery_control/widgets/aqel_checkbox.dart';
import 'package:grocery_control/widgets/item_card.dart';
import 'package:grocery_control/widgets/textinput_dialog.dart';

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
  SortDirection _sortDirection = SortDirection.Ascending;
  bool _filterChecked = false;
  bool _isOwner = false;
  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _isOwner = _group.owner == widget.auth.currentUser.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Grocery Control"),
        centerTitle: true,
        actions: [
          IconButton(
            key: const ValueKey("editGroup"),
            icon: const Icon(Icons.edit),
            onPressed: _isOwner
                ? () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return TextInputDialog(
                            title: "Edit Group Name",
                            hint: "New Group Name",
                          );
                        }).then((value) {
                      if (value != null) {
                        Database(firestore: widget.firestore).updateGroupName(
                            group: _group,
                            newName: value.trim(),
                            uid: widget.auth.currentUser.uid);
                        setState(() {});
                      }
                    });
                  }
                : null,
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
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
              child: Column(
                children: <Widget>[
                  const SizedBox(
                    height: 30,
                  ),
                  FutureBuilder(
                    future: Database(firestore: widget.firestore)
                        .streamGroups(uid: widget.auth.currentUser.uid),
                    builder: (BuildContext context,
                        AsyncSnapshot<List<GroupModel>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
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
                              _isOwner =
                                  _group.owner == widget.auth.currentUser.uid;
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
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  // Row(
                  //   children: <Widget>[
                  //     Text("Ascending order"),
                  //     AqelCheckbox(
                  //       value: _sortDirection == SortDirection.Ascending,
                  //       onChanged: (newValue) {
                  //         setState(() {
                  //           _sortDirection = newValue
                  //               ? SortDirection.Ascending
                  //               : SortDirection.Decsending;
                  //         });
                  //       },
                  //     ),
                  //   ],
                  // ),
                  Card(
                      margin: const EdgeInsets.all(1),
                      color: Theme.of(context).cardColor,
                      child: Padding (
                        padding: const EdgeInsets.all(15),
                        child: Row(
                        children: <Widget>[
                          Expanded(child: Text("Filter out Checked")),
                          AqelCheckbox(
                            value: _filterChecked,
                            onChanged: (newValue) {
                              setState(() {
                                _filterChecked = newValue;
                              });
                            },
                          ),
                        ],
                      ))),
                ],
              ))),
      body: Column(
        children: <Widget>[
          const SizedBox(
            height: 20,
          ),
          Text(
            "Add item to ${_group.name}:",
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
                      decoration:
                          const InputDecoration(hintText: "New Item Name"),
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
              stream: Database(firestore: widget.firestore).streamItems(
                  group: _group.groupId,
                  sortDirection: _sortDirection,
                  filterChecked: _filterChecked),
              builder: (BuildContext context,
                  AsyncSnapshot<List<GroceryItemModel>> snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.data == null || snapshot.data.isEmpty) {
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
    );
  }
}
