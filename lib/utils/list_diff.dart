import 'package:grocery_control/models/grocery_item.dart';
import 'package:grocery_control/models/list_change.dart';

class ListDiffResult {
  /// Change type per item id (live items and deleted ghosts).
  final Map<String, ChangeType> changes;

  /// Ghost rows for items present in [baseline] but missing from [current].
  final List<GroceryItemModel> deletedGhosts;

  const ListDiffResult({
    required this.changes,
    required this.deletedGhosts,
  });
}

/// Diff [current] live items against [baseline] by stable itemId.
///
/// Precedence when multiple fields changed: deleted > renamed > checked > added.
ListDiffResult diffGroceryLists({
  required Map<String, SnapshotItem> baseline,
  required List<GroceryItemModel> current,
  required String groupId,
}) {
  final changes = <String, ChangeType>{};
  final currentIds = <String>{};

  for (final item in current) {
    currentIds.add(item.itemId);
    final previous = baseline[item.itemId];
    if (previous == null) {
      changes[item.itemId] = ChangeType.added;
      continue;
    }
    final renamed = previous.name != item.name;
    final checkedChanged = previous.checked != item.checked;
    if (renamed) {
      changes[item.itemId] = ChangeType.renamed;
    } else if (checkedChanged) {
      changes[item.itemId] = ChangeType.checked;
    }
  }

  final deletedGhosts = <GroceryItemModel>[];
  for (final entry in baseline.entries) {
    if (currentIds.contains(entry.key)) continue;
    changes[entry.key] = ChangeType.deleted;
    deletedGhosts.add(
      GroceryItemModel(
        itemId: entry.key,
        name: entry.value.name,
        checked: entry.value.checked,
        group: groupId,
        tags: const [],
      ),
    );
  }

  deletedGhosts.sort((a, b) => a.name.compareTo(b.name));

  return ListDiffResult(changes: changes, deletedGhosts: deletedGhosts);
}

Map<String, SnapshotItem> snapshotFromItems(List<GroceryItemModel> items) {
  return {
    for (final item in items)
      item.itemId: SnapshotItem(name: item.name, checked: item.checked),
  };
}
