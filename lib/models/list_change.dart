/// Visual change type since the user last viewed the list.
/// Precedence when multiple apply: deleted > renamed > checked > added.
enum ChangeType {
  deleted,
  renamed,
  checked,
  added,
}

/// Minimal fields stored in the last-seen snapshot for an item.
class SnapshotItem {
  final String name;
  final bool checked;

  const SnapshotItem({
    required this.name,
    required this.checked,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'checked': checked,
      };

  factory SnapshotItem.fromJson(Map<String, dynamic> json) {
    return SnapshotItem(
      name: json['name'] as String? ?? '',
      checked: json['checked'] as bool? ?? false,
    );
  }
}
