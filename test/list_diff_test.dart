import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_control/models/grocery_item.dart';
import 'package:grocery_control/models/list_change.dart';
import 'package:grocery_control/utils/list_diff.dart';

void main() {
  GroceryItemModel item({
    required String id,
    required String name,
    bool checked = false,
  }) {
    return GroceryItemModel(
      itemId: id,
      name: name,
      checked: checked,
      group: 'g1',
      tags: const [],
    );
  }

  test('detects added, renamed, checked, and deleted', () {
    final baseline = {
      'a': const SnapshotItem(name: 'Milk', checked: false),
      'b': const SnapshotItem(name: 'Eggs', checked: false),
      'c': const SnapshotItem(name: 'Bread', checked: true),
    };
    final current = [
      item(id: 'a', name: 'Almond milk'), // renamed
      item(id: 'b', name: 'Eggs', checked: true), // checked
      item(id: 'd', name: 'Butter'), // added
      // c deleted
    ];

    final result = diffGroceryLists(
      baseline: baseline,
      current: current,
      groupId: 'g1',
    );

    expect(result.changes['a'], ChangeType.renamed);
    expect(result.changes['b'], ChangeType.checked);
    expect(result.changes['d'], ChangeType.added);
    expect(result.changes['c'], ChangeType.deleted);
    expect(result.deletedGhosts, hasLength(1));
    expect(result.deletedGhosts.first.itemId, 'c');
    expect(result.deletedGhosts.first.name, 'Bread');
  });

  test('rename takes precedence over checked', () {
    final baseline = {
      'a': const SnapshotItem(name: 'Milk', checked: false),
    };
    final current = [
      item(id: 'a', name: 'Oat milk', checked: true),
    ];

    final result = diffGroceryLists(
      baseline: baseline,
      current: current,
      groupId: 'g1',
    );

    expect(result.changes['a'], ChangeType.renamed);
  });
}
