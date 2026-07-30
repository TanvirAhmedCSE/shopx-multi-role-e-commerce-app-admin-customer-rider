class RiderInfo {
  final String uid;
  final String name;
  final String avatarPath;
  final bool blocked;

  RiderInfo({
    required this.uid,
    required this.name,
    required this.avatarPath,
    required this.blocked,
  });

  factory RiderInfo.fromMap(String uid, Map<String, dynamic> m) => RiderInfo(
    uid: uid,
    name: ((m['name'] as String?)?.trim().isNotEmpty ?? false)
        ? m['name'] as String
        : 'Rider',
    avatarPath: (m['avatarPath'] as String?) ?? '',
    blocked: m['blocked'] as bool? ?? false,
  );
}
