import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../extensions/build_context_extension.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../common/ui/widgets/common_header.dart';
import '../../wellness/ui/widgets/crisis_resources_sheet.dart';
import '../model/community_post.dart';
import '../repository/community_repository.dart';
import 'view_model/community_view_model.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  static const categories = [
    'All',
    'Support',
    'Stories',
    'Self-care',
    'Daily wins',
  ];

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(communityViewModelProvider);

    return Scaffold(
      backgroundColor: context.secondaryBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const CommonHeader(header: 'Community', isShowBack: false),

            // Welcome banner
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cempedak80,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'A softer place to be',
                            style: AppTheme.title20.copyWith(
                              color: AppColors.mono100,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Share gently. Listen without judgement.',
                            style: AppTheme.body14.copyWith(
                              color: AppColors.mono90,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.cempedak20,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.forum_outlined,
                        color: AppColors.mono100,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'A quiet place to share, listen, and feel less alone.',
                  style: AppTheme.body14.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
              ),
            ),

            // Category filters
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: CommunityScreen.categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = CommunityScreen.categories[index];
                  final isSelected = category == _selectedCategory;

                  return ChoiceChip(
                    label: Text(
                      category,
                      style: AppTheme.body14.copyWith(
                        color: isSelected
                            ? Colors.black
                            : context.primaryTextColor,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                    selectedColor: AppColors.cempedak20,
                    backgroundColor: context.secondaryWidgetColor,
                    checkmarkColor: Colors.black,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : context.primaryTextColor,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.cempedak80
                          : context.dividerColor,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Persistent Quick Create Post Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showComposer(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: context.secondaryWidgetColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                AppColors.watermelon100.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.watermelon100,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Share a thought or feeling...',
                            style: AppTheme.body14.copyWith(
                              color: context.secondaryTextColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.watermelon100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Post',
                            style: AppTheme.body12.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Posts
            Expanded(
              child: postsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => _CommunityError(
                  message: _friendlyError(error),
                  onRetry: () {
                    ref.invalidate(communityViewModelProvider);
                  },
                ),
                data: (posts) {
                  final filteredPosts = posts.where((post) {
                    return _selectedCategory == 'All' ||
                        post.category == _selectedCategory;
                  }).toList();

                  if (filteredPosts.isEmpty) {
                    return _EmptyCommunityState(
                      onCreate: () => _showComposer(context),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(communityViewModelProvider);
                      await ref.read(communityViewModelProvider.future);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                      itemCount: filteredPosts.length,
                      itemBuilder: (context, index) {
                        final post = filteredPosts[index];

                        return _PostCard(
                          post: post,
                          onLike: () {
                            ref
                                .read(communityViewModelProvider.notifier)
                                .toggleLike(post);
                          },
                          onComment: () => _showComments(context, post),
                          onReport: (reason) => _report(post, reason),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Create post button (lifted above the bottom navigation bar)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.extended(
          onPressed: () => _showComposer(context),
          backgroundColor: AppColors.watermelon100,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Share anonymously'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _report(CommunityPost post, String reason) async {
    try {
      await ref
          .read(communityViewModelProvider.notifier)
          .reportPost(postId: post.id, reason: reason);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks. Your report was submitted.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    }
  }

  String _friendlyError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _showComposer(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.secondaryWidgetColor,
      builder: (_) => const _ComposerSheet(),
    );
  }

  Future<void> _showComments(BuildContext context, CommunityPost post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.secondaryWidgetColor,
      builder: (_) => _CommentsSheet(
        post: post,
        onSubmit: (body) async {
          await ref
              .read(communityViewModelProvider.notifier)
              .addComment(postId: post.id, body: body);
        },
        onReport: (commentId, reason) {
          return ref
              .read(communityViewModelProvider.notifier)
              .reportComment(commentId: commentId, reason: reason);
        },
      ),
    );
  }
}

class _CommunityError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CommunityError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerSheet extends ConsumerStatefulWidget {
  const _ComposerSheet();

  @override
  ConsumerState<_ComposerSheet> createState() => _ComposerSheetState();
}

class _ComposerSheetState extends ConsumerState<_ComposerSheet> {
  final _controller = TextEditingController();

  String _category = 'Support';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _friendlyError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _submit() async {
    final body = _controller.text.trim();

    if (body.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(communityViewModelProvider.notifier)
          .createPost(body: body, category: _category);

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      if (error is CommunityModerationException && error.isCrisis) {
        Navigator.of(context).pop();
        CrisisResourcesSheet.show(context);
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldDecoration = InputDecoration(
      filled: true,
      fillColor: AppColors.cempedak20.withValues(
        alpha: context.isDarkMode ? 0.15 : 0.45,
      ),
      labelStyle: AppTheme.body14.copyWith(
        color: context.secondaryTextColor,
      ),
      hintStyle: AppTheme.body14.copyWith(
        color: context.secondaryTextColor.withValues(alpha: 0.6),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.cempedak80.withValues(alpha: 0.35),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.watermelon100,
          width: 1.5,
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: context.secondaryWidgetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Share anonymously',
                    style: AppTheme.title20.copyWith(
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cempedak20.withValues(
                      alpha: context.isDarkMode ? 0.2 : 0.6,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.cempedak80.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Private by default',
                    style: AppTheme.label12.copyWith(
                      color: context.isDarkMode
                          ? AppColors.cempedak40
                          : const Color(0xFF7A5800),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Your identity is never shown in the community.',
              style: AppTheme.body12.copyWith(
                color: context.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _category,
              dropdownColor: context.secondaryWidgetColor,
              style: AppTheme.body14.copyWith(
                color: context.primaryTextColor,
              ),
              items: CommunityScreen.categories
                  .skip(1)
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: TextStyle(color: context.primaryTextColor),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _category = value);
                      }
                    },
              decoration: fieldDecoration.copyWith(labelText: 'Support space'),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _controller,
              enabled: !_isSubmitting,
              maxLength: 2000,
              maxLines: 6,
              cursorColor: AppColors.watermelon100,
              style: AppTheme.body16.copyWith(
                color: context.primaryTextColor,
              ),
              decoration: fieldDecoration.copyWith(
                labelText: 'What would you like to share?',
                counterStyle: AppTheme.body12.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ),

            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.watermelon100,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.shield_outlined),
              label: Text(
                _isSubmitting ? 'Checking your post...' : 'Post anonymously',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final ValueChanged<String> onReport;

  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.secondaryWidgetColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  post.category,
                  style: AppTheme.label12.copyWith(
                    color: AppColors.watermelon70,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: onReport,
                icon: const Icon(Icons.more_horiz),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'Harmful or unsafe content',
                    child: Text('Report harmful content'),
                  ),
                  PopupMenuItem(
                    value: 'Spam or irrelevant content',
                    child: Text('Report spam'),
                  ),
                  PopupMenuItem(
                    value: 'Something else',
                    child: Text('Report something else'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post.body,
            style: AppTheme.body16.copyWith(
              color: context.primaryTextColor,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.visibility_off_outlined,
                size: 16,
                color: context.secondaryTextColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  post.anonymousName,
                  style: AppTheme.body12.copyWith(
                    color: context.secondaryTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: onLike,
                tooltip: 'React',
                icon: const Icon(Icons.favorite_border),
              ),
              Text('${post.likedBy.length}'),
              IconButton(
                onPressed: onComment,
                tooltip: 'Comments',
                icon: const Icon(Icons.chat_bubble_outline),
              ),
              Text('${post.commentCount}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentsSheet extends ConsumerStatefulWidget {
  final CommunityPost post;
  final Future<void> Function(String body) onSubmit;
  final Future<void> Function(String commentId, String reason) onReport;

  const _CommentsSheet({
    required this.post,
    required this.onSubmit,
    required this.onReport,
  });

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _controller = TextEditingController();

  late Future<List<CommunityComment>> _comments;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  void _loadComments() {
    _comments = ref
        .read(communityViewModelProvider.notifier)
        .getComments(widget.post.id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();

    if (body.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      await widget.onSubmit(body);

      if (!mounted) return;

      _controller.clear();

      setState(() {
        _sending = false;
        _loadComments();
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _sending = false);

      if (error is CommunityModerationException && error.isCrisis) {
        Navigator.of(context).pop();
        CrisisResourcesSheet.show(context);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Comments',
                    style: AppTheme.title20.copyWith(
                      color: context.primaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.watermelon100.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.post.commentCount}',
                      style: AppTheme.label12.copyWith(
                        color: AppColors.watermelon100,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: context.secondaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              minHeight: 140,
            ),
            child: FutureBuilder<List<CommunityComment>>(
              future: _comments,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load comments.',
                      style: AppTheme.body14.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  );
                }

                final comments = snapshot.data ?? <CommunityComment>[];

                if (comments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 36,
                            color: context.secondaryTextColor.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No responses yet',
                            style: AppTheme.subtitle14.copyWith(
                              color: context.primaryTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Be the first to share a kind, supportive thought.',
                            style: AppTheme.body12.copyWith(
                              color: context.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: comments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final comment = comments[index];

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? const Color(0xFF222433)
                            : AppColors.cempedak10.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.isDarkMode
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.cempedak80.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: AppColors.watermelon100
                                    .withValues(alpha: 0.15),
                                child: const Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: AppColors.watermelon100,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  comment.anonymousName,
                                  style: AppTheme.subtitle14.copyWith(
                                    color: context.primaryTextColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.more_horiz,
                                  size: 18,
                                  color: context.secondaryTextColor,
                                ),
                                onSelected: (reason) async {
                                  try {
                                    await widget.onReport(comment.id, reason);

                                    if (!context.mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Report submitted.'),
                                      ),
                                    );
                                  } catch (error) {
                                    if (!context.mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Unable to submit report.'),
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'Harmful or unsafe content',
                                    child: Text('Report'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            comment.body,
                            style: AppTheme.body14.copyWith(
                              color: context.primaryTextColor,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_sending,
                  maxLength: 1000,
                  style: AppTheme.body14.copyWith(
                    color: context.primaryTextColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Write a supportive reply...',
                    hintStyle: AppTheme.body14.copyWith(
                      color: context.secondaryTextColor,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.cempedak20.withValues(
                      alpha: context.isDarkMode ? 0.12 : 0.4,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: AppColors.cempedak80.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: AppColors.cempedak80.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: AppColors.watermelon100,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.watermelon100,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _sending ? null : _send,
                  color: Colors.white,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCommunityState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyCommunityState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 48, color: AppColors.blueberry100),
            const SizedBox(height: 12),
            Text('No conversations here yet', style: AppTheme.title18),
            const SizedBox(height: 8),
            Text(
              'Start a kind, anonymous conversation '
              'for this support space.',
              textAlign: TextAlign.center,
              style: AppTheme.body14.copyWith(color: AppColors.mono60),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Share anonymously'),
            ),
          ],
        ),
      ),
    );
  }
}
