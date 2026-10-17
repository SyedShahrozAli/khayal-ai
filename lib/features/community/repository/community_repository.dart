import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

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
  static const _uuid = Uuid();

  CommunityRepository(this.firestore, this.auth);

  CollectionReference<Map<String, dynamic>> get _posts =>
      firestore.collection('communityPosts');

  User _requireUser() {
    final user = auth.currentUser;
    if (user == null) throw StateError('Sign in to join the community.');
    return user;
  }

  Future<List<CommunityPost>> getPosts({String? category}) async {
    Query<Map<String, dynamic>> query =
        _posts.orderBy('createdAt', descending: true).limit(50);
    if (category != null) query = query.where('category', isEqualTo: category);
    final snapshot = await query.get();
    return snapshot.docs.map(CommunityPost.fromDocument).toList();
  }

  Future<void> createPost({
    required String body,
    required String category,
  }) async {
    final user = _requireUser();
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty || trimmedBody.length > 2000) {
      throw ArgumentError('Post must contain between 1 and 2000 characters.');
    }
    await _posts.doc(_uuid.v4()).set({
      'body': trimmedBody,
      'category': category,
      'anonymousName': 'Anonymous ${user.uid.substring(0, 4)}',
      'createdAt': FieldValue.serverTimestamp(),
      'likedBy': <String>[],
    });
  }

  Future<void> toggleLike(CommunityPost post) async {
    final user = _requireUser();
    final reference = _posts.doc(post.id);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final data = snapshot.data() ?? <String, dynamic>{};
      final likedBy = (data['likedBy'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toSet();
      if (!likedBy.add(user.uid)) likedBy.remove(user.uid);
      transaction.update(reference, {'likedBy': likedBy.toList()});
    });
  }

  Future<void> reportPost({required String postId, required String reason}) async {
    final user = _requireUser();
    await firestore.collection('communityReports').add({
      'postId': postId,
      'reporterId': user.uid,
      'reason': reason.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }
}
