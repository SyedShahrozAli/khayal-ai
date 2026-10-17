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
    state = await AsyncValue.guard(() => _repository.getPosts(category: category));
  }

  Future<void> createPost({required String body, required String category}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.createPost(body: body, category: category);
      return _repository.getPosts(category: _category);
    });
  }

  Future<void> toggleLike(CommunityPost post) async {
    await _repository.toggleLike(post);
    state = await AsyncValue.guard(() => _repository.getPosts(category: _category));
  }

  Future<void> reportPost({required String postId, required String reason}) {
    return _repository.reportPost(postId: postId, reason: reason);
  }
}
