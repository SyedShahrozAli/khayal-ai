import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/community_post.dart';
import '../../repository/community_repository.dart';

final communityViewModelProvider =
    AsyncNotifierProvider<CommunityViewModel, List<CommunityPost>>(
      CommunityViewModel.new,
    );

class CommunityViewModel extends AsyncNotifier<List<CommunityPost>> {
  CommunityRepository get _repository => ref.read(communityRepositoryProvider);
  String? _category;

  @override
  Future<List<CommunityPost>> build() => _repository.getPosts();

  Future<void> setCategory(String? category) async {
    _category = category;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.getPosts(category: category),
    );
  }

  Future<void> createPost({
    required String body,
    required String category,
  }) async {
    final createdPost = await _repository.createPost(
      body: body,
      category: category,
    );
    final previousList = state.value ?? [];
    state = AsyncData([
      createdPost,
      ...previousList.where((p) => p.id != createdPost.id),
    ]);

    try {
      final refreshed = await _repository.getPosts(category: _category);
      state = AsyncData(refreshed);
    } catch (_) {
      // Retain optimistic list
    }
  }

  Future<void> toggleLike(CommunityPost post) async {
    final uid = _repository.auth.currentUser?.uid;
    final currentList = state.value ?? [];
    if (uid != null) {
      final updated = currentList.map((p) {
        if (p.id == post.id) {
          final isLiked = p.likedBy.contains(uid);
          final newLikedBy = isLiked
              ? p.likedBy.where((id) => id != uid).toList()
              : [...p.likedBy, uid];
          return p.copyWith(likedBy: newLikedBy);
        }
        return p;
      }).toList();
      state = AsyncData(updated);
    }
    await _repository.toggleLike(post);
  }

  Future<void> reportPost({required String postId, required String reason}) {
    return _repository.reportPost(postId: postId, reason: reason);
  }

  Future<List<CommunityComment>> getComments(String postId) {
    return _repository.getComments(postId);
  }

  Future<void> addComment({
    required String postId,
    required String body,
  }) async {
    await _repository.addComment(postId: postId, body: body);
    final currentList = state.value ?? [];
    final updated = currentList.map((p) {
      if (p.id == postId) {
        return p.copyWith(commentCount: p.commentCount + 1);
      }
      return p;
    }).toList();
    state = AsyncData(updated);
  }

  Future<void> reportComment({
    required String commentId,
    required String reason,
  }) {
    return _repository.reportComment(commentId: commentId, reason: reason);
  }
}
