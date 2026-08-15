import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grocery_control/models/grocery_item.dart';
import 'package:grocery_control/models/group.dart';
import 'package:grocery_control/models/list_change.dart';
import 'package:grocery_control/services/auth.dart';
import 'package:grocery_control/services/db.dart';
import 'package:grocery_control/services/grocery_catalog.dart';
import 'package:grocery_control/services/list_snapshot_cache.dart';
import 'package:grocery_control/utils/constants.dart';
import 'package:grocery_control/utils/list_diff.dart';
import 'package:grocery_control/widgets/aqel_checkbox.dart';
import 'package:grocery_control/widgets/item_card.dart';
import 'package:grocery_control/widgets/tag_list.dart';
import 'package:grocery_control/widgets/textinput_dialog.dart';
import 'package:grocery_control/widgets/group_qrcode.dart';
import 'package:grocery_control/screens/qr_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final GroupModel group;
  const Home({
    super.key,
    required this.auth,
    required this.firestore,
    required this.group,
  });

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final FocusNode _itemFocusNode = FocusNode();
  final GroceryCatalog _groceryCatalog = GroceryCatalog();
  final ListSnapshotCache _snapshotCache = ListSnapshotCache();
  late GroupModel _group;
  SortDirection _sortDirection = SortDirection.Ascending;
  bool _filterChecked = false;
  bool _isOwner = false;
  bool _isItemSelected = false;
  String _selectedKey = '';
  late ScrollController _scrollController;
  late double _height;
  List<String> _newTagList = [];
  bool _visibleHeader = true;
  List<GroceryItemCard> _itemList = [];
  List<String> _itemHistory = [];

  /// In-memory baseline used for diffing; updated on self-edits.
  Map<String, SnapshotItem> _workingBaseline = {};

  /// False on first visit (no persisted snapshot) so nothing highlights.
  bool _highlightingEnabled = false;
  List<GroceryItemModel> _latestLiveItems = [];

  String get _uid => widget.auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();
    _group = widget.group;
    _isOwner = _group.owner == widget.auth.currentUser?.uid;
    _newTagList = [];
    _groceryCatalog.load().then((_) {
      if (mounted) setState(() {});
    });
    _initializePreferences().whenComplete(() {
      _loadBaseline();
    });
    _scrollController.addListener(() {
      if (_isItemSelected) {
        if (!_visibleHeader) {
          setState(() {
            _visibleHeader = true;
          });
        }
        return;
      }
      if (_scrollController.position.pixels ==
          _scrollController.position.minScrollExtent) {
        if (_visibleHeader != true) {
          _visibleHeader = true;
          setState(() {});
        }
      } else if (_scrollController.position.pixels > _height * 0.5 &&
          _visibleHeader == true) {
        if (_visibleHeader != false) {
          _visibleHeader = false;
          setState(() {});
        }
      }
    });
  }

  Future<void> _initializePreferences() async {
    final prefs = await SharedPreferences.getInstance();
  }

  Future<void> _loadBaseline() async {
    final loaded = await _snapshotCache.load(_uid, _group.groupId);
    if (!mounted) return;
    setState(() {
      if (loaded == null) {
        _workingBaseline = {};
        _highlightingEnabled = false;
      } else {
        _workingBaseline = Map<String, SnapshotItem>.from(loaded);
        _highlightingEnabled = true;
      }
    });
  }

  Future<void> _persistBaseline({List<GroceryItemModel>? items}) async {
    final toSave = items ?? _latestLiveItems;
    await _snapshotCache.save(
      uid: _uid,
      groupId: _group.groupId,
      items: toSave,
    );
  }

  void _acknowledgeLocalItem({
    required String itemId,
    required String name,
    required bool checked,
  }) {
    _workingBaseline[itemId] = SnapshotItem(name: name, checked: checked);
  }

  void _acknowledgeLocalDelete(String itemId) {
    _workingBaseline.remove(itemId);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _persistBaseline();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _persistBaseline();
    _scrollController.dispose();
    _itemController.dispose();
    _tagsController.dispose();
    _itemFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _height = MediaQuery.of(context).size.height;
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
                            okOption: "Change",
                          );
                        }).then((value) {
                      if (value != null) {
                        Database(firestore: widget.firestore).updateGroupName(
                            group: _group,
                            newName: value.trim(),
                            uid: widget.auth.currentUser?.uid ?? '');
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
              _persistBaseline();
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
                        .streamGroups(uid: widget.auth.currentUser?.uid ?? ''),
                    builder: (BuildContext context,
                        AsyncSnapshot<List<GroupModel>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        final groups = snapshot.data;
                        if (groups == null || groups.isEmpty) {
                          return const Center(
                            child: Text("No groups available"),
                          );
                        }
                        if (groups.length == 1) {
                          return Center(
                            child: Text(groups.first.name),
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
                          items: groups
                              .map<DropdownMenuItem<GroupModel>>(
                                  (GroupModel value) {
                            return DropdownMenuItem<GroupModel>(
                              value: value,
                              child: Text(value.name),
                            );
                          }).toList(),
                          isExpanded: true,
                          onChanged: (GroupModel? newValue) async {
                            if (newValue == null) return;
                            await _persistBaseline();
                            setState(() {
                              _group = newValue;
                              _isOwner =
                                  _group.owner == widget.auth.currentUser?.uid;
                              _selectedKey = '';
                              _isItemSelected = false;
                              _itemController.clear();
                              _newTagList.clear();
                              Database(firestore: widget.firestore)
                                  .setLastGroup(
                                      uid: widget.auth.currentUser?.uid ?? '',
                                      group: _group);
                            });
                            await _loadBaseline();
                            if (mounted) Navigator.pop(context);
                          },
                        );
                      } else {
                        return const Center(
                          child: Text("loading..."),
                        );
                      }
                    },
                  ),
                  Row(
                    children: [
                      IconButton(
                          onPressed: () => {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return TextInputDialog(
                                        okOption: "Create",
                                        title: "Create New Group",
                                        hint: "New Group Name",
                                      );
                                    }).then((value) async {
                                  if (value != null) {
                                    HttpsCallable callable = FirebaseFunctions
                                        .instance
                                        .httpsCallable("CreateGroup");
                                    HttpsCallableResult result = await callable
                                        .call({"groupName": value});
                                    if (result.data.err) {
                                      final snackBar =
                                          SnackBar(content: Text('Error'));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(snackBar);
                                    } else {
                                      final snackBar = SnackBar(
                                          content: Text('$value Created'));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(snackBar);
                                    }
                                  }
                                })
                              },
                          icon: Icon(Icons.add))
                    ],
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Card(
                      margin: const EdgeInsets.all(1),
                      color: Theme.of(context).cardColor,
                      child: Padding(
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
                  IconButton(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return GroupQRCodeDialog(
                                groupModel: _group,
                              );
                            });
                      },
                      icon: Icon(Icons.qr_code)),
                  const SizedBox(
                    height: 30,
                  ),
                  IconButton(
                      onPressed: () async {
                        final codeData = await Navigator.of(context).push<
                            Map<String, dynamic>>(
                          MaterialPageRoute(builder: (_) => QRCodeScanner()),
                        );
                        if (codeData == null) {
                          return;
                        }
                        HttpsCallable callable = FirebaseFunctions.instance
                            .httpsCallable("JoinGroup");
                        await callable.call(codeData);
                      },
                      icon: Icon(Icons.qr_code_scanner)),
                ],
              ))),
      body: Column(
        children: <Widget>[
          const SizedBox(
            height: 20,
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _isVisible() ? 50 : 0,
            child: Text(
              "Add item to ${_group.name}:",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _isVisible() ? _height * 0.1 : 0,
            child: Visibility(
              visible: _isVisible(),
              child: Card(
                margin: const EdgeInsets.only(
                    top: 20, left: 20, right: 20, bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: RawAutocomplete<String>(
                          textEditingController: _itemController,
                          focusNode: _itemFocusNode,
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            return _groceryCatalog.suggest(
                              textEditingValue.text,
                              history: _itemHistory,
                            );
                          },
                          onSelected: (String selection) {
                            _itemController.text = selection;
                            _itemController.selection =
                                TextSelection.collapsed(
                                    offset: selection.length);
                          },
                          fieldViewBuilder: (context, textEditingController,
                              focusNode, onFieldSubmitted) {
                            return TextFormField(
                              key: const ValueKey("addField"),
                              controller: textEditingController,
                              focusNode: focusNode,
                              onFieldSubmitted: (_) {
                                onFieldSubmitted();
                                _saveItem();
                              },
                              decoration: const InputDecoration(
                                  hintText: "New Item Name"),
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                      maxHeight: 240, maxWidth: 400),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        dense: true,
                                        title: Text(option),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      IconButton(
                        key: const ValueKey("addButton"),
                        icon: _isItemSelected
                            ? const Icon(Icons.save)
                            : const Icon(Icons.add),
                        onPressed: () {
                          _saveItem();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _isVisible() ? _height * 0.1 : 0,
            child: Visibility(
              visible: _isVisible(),
              child: Card(
                margin: const EdgeInsets.only(
                    top: 0, left: 20, right: 20, bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const ValueKey("addTagField"),
                          controller: _tagsController,
                          decoration: const InputDecoration(
                              hintText: "Comma separated tags"),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey("addTagButton"),
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (_tagsController.text != "") {
                            List<String> tags = _tagsController.text
                                .split(",")
                                .map((e) => e.trim())
                                .toList();
                            setState(() {
                              _newTagList.addAll(tags);
                              _tagsController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _isVisible() ? 10 : 0,
            child: TagList(
              tags: _newTagList,
              onTagDelete: (int index) {
                setState(() {
                  _newTagList.removeAt(index);
                });
              },
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
                  group: _group.groupId, sortDirection: _sortDirection),
              builder: (BuildContext context,
                  AsyncSnapshot<List<GroceryItemModel>> snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  _itemList.clear();
                  final items = snapshot.data ?? [];
                  _latestLiveItems = List<GroceryItemModel>.from(items);
                  if (items.isNotEmpty) {
                    _itemHistory = items
                        .map((e) => e.name)
                        .where((name) => name.trim().isNotEmpty)
                        .toList();
                  } else {
                    _itemHistory = [];
                  }

                  final ListDiffResult? diff = _highlightingEnabled
                      ? diffGroceryLists(
                          baseline: _workingBaseline,
                          current: items,
                          groupId: _group.groupId,
                        )
                      : null;

                  final displayItems = <GroceryItemModel>[
                    ...items,
                    if (diff != null) ...diff.deletedGhosts,
                  ];
                  final ghostIds = {
                    if (diff != null)
                      for (final g in diff.deletedGhosts) g.itemId,
                  };

                  if (displayItems.isEmpty) {
                    return const Center(
                      child: Text("You don't have any unchecked items"),
                    );
                  }
                  return ListView.builder(
                    key: PageStorageKey("itemList"),
                    itemCount: displayItems.length,
                    controller: _scrollController,
                    itemBuilder: (_, index) {
                      final item = displayItems[index];
                      final isGhost = ghostIds.contains(item.itemId);
                      if (!isGhost && _filterChecked && item.checked) {
                        return SizedBox.shrink();
                      }
                      var card = GroceryItemCard(
                        key: ValueKey('${item.itemId}_$isGhost'),
                        firestore: widget.firestore,
                        item: item,
                        group: _group.groupId,
                        selectedKey: _selectedKey,
                        changeType: diff?.changes[item.itemId],
                        isGhost: isGhost,
                        onCheckedLocally: (itemId, checked) {
                          setState(() {
                            _acknowledgeLocalItem(
                              itemId: itemId,
                              name: item.name,
                              checked: checked,
                            );
                          });
                        },
                        onDeletedLocally: (itemId) {
                          setState(() {
                            _acknowledgeLocalDelete(itemId);
                          });
                        },
                        onSelectItem:
                            (String key, String name, List<String> tags) {
                          setState(() {
                            if (key == _selectedKey) {
                              _selectedKey = "";
                              _isItemSelected = false;
                              _newTagList.clear();
                              _itemController.text = "";
                            } else {
                              _selectedKey = key;
                              _isItemSelected = true;
                              _newTagList = tags.toList();
                              _itemController.text = name;
                            }
                          });
                        },
                      );
                      _itemList.add(card);
                      return card;
                    },
                  );
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return ListView(
                    key: PageStorageKey("itemList"),
                    controller: _scrollController,
                    children: _itemList,
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

  Future<void> _saveItem() async {
    if (_itemController.text == "") return;
    final name = _itemController.text;
    final tags = _newTagList.toList();
    if (_isItemSelected) {
      final itemId = _selectedKey;
      await Database(firestore: widget.firestore).updateItem(
          group: _group.groupId,
          name: name,
          itemId: itemId,
          tags: tags);
      setState(() {
        bool previousChecked = false;
        for (final e in _latestLiveItems) {
          if (e.itemId == itemId) {
            previousChecked = e.checked;
            break;
          }
        }
        previousChecked =
            _workingBaseline[itemId]?.checked ?? previousChecked;
        _acknowledgeLocalItem(
          itemId: itemId,
          name: name,
          checked: previousChecked,
        );
      });
    } else {
      final itemId = await Database(firestore: widget.firestore).addItem(
          group: _group.groupId, name: name, tags: tags);
      setState(() {
        _acknowledgeLocalItem(itemId: itemId, name: name, checked: false);
        _itemController.clear();
        _newTagList.clear();
        _tagsController.clear();
      });
    }
  }

  bool _isVisible() {
    return _isItemSelected || _visibleHeader;
  }
}
