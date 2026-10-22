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

class CommunityRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  CommunityRepository(this.firestore, this.auth);

  static const _harmfulTerms = [
    'kill yourself',
    'hurt yourself',
    'self harm instructions',
    'buy drugs',
    'child sexual',
    'doxx',
    'credit card',
  ];

  CollectionReference<Map<String, dynamic>> get _posts =>
      firestore.collection('communityPosts');

  User _requireUser() {
    final user = auth.currentUser;
    if (user == null) throw StateError('Sign in to join the community.');
    return user;
  }

  String _moderationStatus(String body) {
    final normalized = body.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final hasHarmfulTerm = _harmfulTerms.any(normalized.contains);
    final linkCount = RegExp(r'https?://').allMatches(normalized).length;
    return hasHarmfulTerm || linkCount > 2 ? 'needs_review' : 'approved';
  }

  Future<List<CommunityPost>> getPosts({String? category}) async {
    Query<Map<String, dynamic>> query = _posts
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .limit(50);
    if (category != null) query = query.where('category', isEqualTo: category);
    final snapshot = await query.get();
    return snapshot.docs
        .map(CommunityPost.fromDocument)
        .where((post) => post.status != 'rejected')
        .toList();
  }

  Future<void> createPost({
    required String body,
    required String category,
  }) async {
    _requireUser();
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty || trimmedBody.length > 2000) {
      throw ArgumentError('Post must contain between 1 and 2000 characters.');
    }
    await _posts.doc().set({
      'body': trimmedBody,
      'category': category,
      'authorId': auth.currentUser!.uid,
      'anonymousName': 'Anonymous',
      'createdAt': FieldValue.serverTimestamp(),
      'likedBy': <String>[],
      'commentCount': 0,
      'status': _moderationStatus(trimmedBody),
    });
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
        .where('status', isEqualTo: 'approved')
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
    final postReference = _posts.doc(postId);
    final commentReference = postReference.collection('comments').doc();
    final status = _moderationStatus(trimmedBody);
    await firestore.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postReference);
      if (!postSnapshot.exists) throw StateError('Post no longer exists.');
      transaction.set(commentReference, {
        'body': trimmedBody,
        'authorId': auth.currentUser!.uid,
        'anonymousName': 'Anonymous',
        'createdAt': FieldValue.serverTimestamp(),
        'status': status,
      });
      if (status == 'approved') {
        transaction.update(postReference, {
          'commentCount': FieldValue.increment(1),
        });
      }
    });
  }
}
