import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repository/community_repository.dart';
import 'view_model/community_view_model.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  static const categories = ['All', 'Support', 'Stories', 'Self-care'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(communityViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final selected = index == 0;
                return ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  onSelected: (_) => ref
                      .read(communityViewModelProvider.notifier)
                      .setCategory(selected ? null : category),
                );
              },
            ),
          ),
          Expanded(
            child: posts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (items) => items.isEmpty
                  ? const Center(child: Text('No posts yet. Start the conversation.'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final post = items[index];
                        final user = ref.read(communityRepositoryProvider).auth.currentUser;
                        final liked = user != null && post.likedBy.contains(user.uid);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(post.category, style: Theme.of(context).textTheme.labelLarge)),
                                    PopupMenuButton<String>(
                                      onSelected: (reason) async {
                                        await ref.read(communityViewModelProvider.notifier).reportPost(
                                              postId: post.id,
                                              reason: reason,
                                            );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted.')));
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: 'Harmful content', child: Text('Report harmful content')),
                                        PopupMenuItem(value: 'Spam', child: Text('Report spam')),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(post.body),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(post.anonymousName, style: Theme.of(context).textTheme.bodySmall),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () => ref.read(communityViewModelProvider.notifier).toggleLike(post),
                                      icon: Icon(liked ? Icons.favorite : Icons.favorite_border),
                                    ),
                                    Text('${post.likedBy.length}'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showComposer(context, ref),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Post'),
      ),
    );
  }

  Future<void> _showComposer(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    var category = categories[1];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: category,
                items: categories.skip(1).map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                onChanged: (value) => setState(() => category = value ?? category),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLength: 2000,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Share something supportive', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  await ref.read(communityViewModelProvider.notifier).createPost(body: controller.text, category: category);
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                },
                child: const Text('Publish anonymously'),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
  }
}
