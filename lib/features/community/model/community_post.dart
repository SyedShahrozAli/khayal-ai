import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String category;
  final String body;
  final String anonymousName;
  final DateTime createdAt;
  final List<String> likedBy;
  final int commentCount;
  final String status;

  const CommunityPost({
    required this.id,
    required this.category,
    required this.body,
    required this.anonymousName,
    required this.createdAt,
    this.likedBy = const [],
    this.commentCount = 0,
    this.status = 'approved',
  });

  CommunityPost copyWith({
    String? id,
    String? category,
    String? body,
    String? anonymousName,
    DateTime? createdAt,
    List<String>? likedBy,
    int? commentCount,
    String? status,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      category: category ?? this.category,
      body: body ?? this.body,
      anonymousName: anonymousName ?? this.anonymousName,
      createdAt: createdAt ?? this.createdAt,
      likedBy: likedBy ?? this.likedBy,
      commentCount: commentCount ?? this.commentCount,
      status: status ?? this.status,
    );
  }

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
      commentCount: data['commentCount'] as int? ?? 0,
      status: data['status'] as String? ?? 'approved',
    );
  }

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class CommunityComment {
  final String id;
  final String body;
  final String anonymousName;
  final DateTime createdAt;

  const CommunityComment({
    required this.id,
    required this.body,
    required this.anonymousName,
    required this.createdAt,
  });

  factory CommunityComment.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final timestamp = data['createdAt'];
    return CommunityComment(
      id: document.id,
      body: data['body'] as String? ?? '',
      anonymousName: data['anonymousName'] as String? ?? 'Anonymous',
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
