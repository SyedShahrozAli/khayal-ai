import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String category;
  final String body;
  final String anonymousName;
  final DateTime createdAt;
  final List<String> likedBy;

  const CommunityPost({
    required this.id,
    required this.category,
    required this.body,
    required this.anonymousName,
    required this.createdAt,
    this.likedBy = const [],
  });

  factory CommunityPost.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    return CommunityPost(
      id: document.id,
      category: data['category'] as String? ?? 'General',
      body: data['body'] as String? ?? '',
      anonymousName: data['anonymousName'] as String? ?? 'Anonymous',
      createdAt: _readDate(data['createdAt']),
      likedBy: (data['likedBy'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
