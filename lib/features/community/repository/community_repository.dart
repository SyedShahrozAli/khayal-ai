import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/remote/firebase_provider.dart';
import '../model/community_post.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(
    ref.watch(firebaseFirestoreProvider),
    FirebaseAuth.instance,
  );
});

class CommunityModerationException implements Exception {
  final String message;
  final bool isCrisis;

  const CommunityModerationException(this.message, {this.isCrisis = false});

  @override
  String toString() => message;
}

class CommunityRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  CommunityRepository(this.firestore, this.auth);

  static const _crisisTerms = [
    'kill myself',
    'kill yourself',
    'suicide',
    'want to die',
    'wanna die',
    'end my life',
    'hang myself',
    'cut myself',
    'cutting myself',
    'hurt myself',
    'hurt yourself',
    'self harm',
    'overdose',
    'take my life',
    // Roman Urdu / Urdu crisis terms
    'khudkushi',
    'khud kushi',
    'jaan de dunga',
    'jaan deni',
    'mar jana chahta',
    'mar jaun',
    'mar jao',
    'zindagi khatam',
  ];

  static const _prohibitedTerms = [
    'buy drugs',
    'sell drugs',
    'child sexual',
    'doxx',
    'credit card',
    'cvv',
    'chutiya',
    'harami',
    'kutta',
    'kamine',
    'bitch',
    'bastard',
    'asshole',
    'fuck',
  ];

  static void validateContent(String text) {
    final normalized = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    final hasCrisisTerm = _crisisTerms.any((term) => normalized.contains(term));
    if (hasCrisisTerm) {
      throw const CommunityModerationException(
        'It looks like you may be going through a difficult time. Your safety and well-being matter most. Please reach out to someone who can support you right now.',
        isCrisis: true,
      );
    }

    final hasProhibitedTerm = _prohibitedTerms.any(
      (term) => normalized.contains(term),
    );
    if (hasProhibitedTerm) {
      throw const CommunityModerationException(
        'Your content contains prohibited or offensive language. Please keep Khayal a safe and empathetic space.',
      );
    }

    final linkCount = RegExp(r'https?://').allMatches(normalized).length;
    if (linkCount > 2) {
      throw const CommunityModerationException(
        'To prevent spam, posts cannot contain more than 2 web links.',
      );
    }
  }

  CollectionReference<Map<String, dynamic>> get _posts =>
      firestore.collection('communityPosts');

  User _requireUser() {
    final user = auth.currentUser;
    if (user == null) throw StateError('Sign in to join the community.');
    return user;
  }

  Future<List<CommunityPost>> getPosts({String? category}) async {
    final snapshot = await _posts
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map(CommunityPost.fromDocument)
        .where((post) => post.status != 'rejected')
        .where((post) {
          if (category == null || category == 'All') return true;
          return post.category == category;
        })
        .toList();
  }

  Future<CommunityPost> createPost({
    required String body,
    required String category,
  }) async {
    _requireUser();
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty || trimmedBody.length > 2000) {
      throw ArgumentError('Post must contain between 1 and 2000 characters.');
    }

    // Local moderation validation before database insert
    validateContent(trimmedBody);

    final docRef = _posts.doc();
    final now = Timestamp.now();

    await docRef.set({
      'body': trimmedBody,
      'category': category,
      'authorId': auth.currentUser!.uid,
      'anonymousName': 'Anonymous',
      'createdAt': now,
      'likedBy': <String>[],
      'commentCount': 0,
      'status': 'approved',
    });

    return CommunityPost(
      id: docRef.id,
      category: category,
      body: trimmedBody,
      anonymousName: 'Anonymous',
      createdAt: now.toDate(),
      likedBy: const [],
      commentCount: 0,
      status: 'approved',
    );
  }

  Future<void> toggleLike(CommunityPost post) async {
    _requireUser();
    final reference = _posts.doc(post.id);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) throw StateError('Post no longer exists.');
      final likedBy =
          (snapshot.data()?['likedBy'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toSet();
      final uid = auth.currentUser!.uid;
      if (likedBy.contains(uid)) {
        likedBy.remove(uid);
      } else {
        likedBy.add(uid);
      }
      transaction.update(reference, {'likedBy': likedBy.toList()});
    });
  }

  Future<void> reportPost({
    required String postId,
    required String reason,
  }) async {
    _requireUser();
    await firestore.collection('communityReports').add({
      'targetType': 'post',
      'targetId': postId,
      'postId': postId,
      'reporterId': auth.currentUser!.uid,
      'reason': reason.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reportComment({
    required String commentId,
    required String reason,
  }) async {
    _requireUser();
    await firestore.collection('communityReports').add({
      'targetType': 'comment',
      'targetId': commentId,
      'commentId': commentId,
      'reporterId': auth.currentUser!.uid,
      'reason': reason.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<CommunityComment>> getComments(String postId) async {
    final snapshot = await _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .limit(100)
        .get();
    return snapshot.docs.map(CommunityComment.fromDocument).toList();
  }

  Future<void> addComment({
    required String postId,
    required String body,
  }) async {
    _requireUser();
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty || trimmedBody.length > 1000) {
      throw ArgumentError(
        'Comment must contain between 1 and 1000 characters.',
      );
    }

    // Local moderation validation before comment insert
    validateContent(trimmedBody);

    final postReference = _posts.doc(postId);
    final commentReference = postReference.collection('comments').doc();
    final now = Timestamp.now();

    // Directly save comment document
    await commentReference.set({
      'body': trimmedBody,
      'authorId': auth.currentUser!.uid,
      'anonymousName': 'Anonymous',
      'createdAt': now,
      'status': 'approved',
    });

    // Try incrementing comment count on parent post
    try {
      await postReference.update({
        'commentCount': FieldValue.increment(1),
      });
    } catch (_) {
      // Non-fatal if parent post update rule is restricted
    }
  }
}
