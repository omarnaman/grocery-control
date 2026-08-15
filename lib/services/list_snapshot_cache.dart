import 'dart:convert';

import 'package:grocery_control/models/grocery_item.dart';
import 'package:grocery_control/models/list_change.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local last-seen grocery list snapshots keyed by uid + groupId.
class ListSnapshotCache {
  static const _keyPrefix = 'list_last_seen_';

  String _storageKey(String uid, String groupId) =>
      '$_keyPrefix${uid}_$groupId';

  /// Returns null if this user has never viewed this group on this device.
  Future<Map<String, SnapshotItem>?> load(String uid, String groupId) async {
    if (uid.isEmpty || groupId.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    print('loading snapshot for ${uid} ${groupId}');
    final raw = prefs.getString(_storageKey(uid, groupId));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(
          key,
          SnapshotItem.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save({
    required String uid,
    required String groupId,
    required List<GroceryItemModel> items,
  }) async {
    if (uid.isEmpty || groupId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{
      for (final item in items)
        item.itemId: SnapshotItem(name: item.name, checked: item.checked)
            .toJson(),
    };
    await prefs.setString(_storageKey(uid, groupId), jsonEncode(map));
  }

  Future<void> clear(String uid, String groupId) async {
    if (uid.isEmpty || groupId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey(uid, groupId));
  }
}
