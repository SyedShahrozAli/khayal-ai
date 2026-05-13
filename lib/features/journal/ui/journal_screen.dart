import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../extensions/build_context_extension.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import 'view_model/journal_view_model.dart';
import 'journal_entry_card.dart';
import 'journal_write_screen.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  late final AnimationController _fabAnimationController;
  late final Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void didUpdateWidget(covariant JournalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animate FAB when entries appear (from empty to non-empty)
    final journal = ref.read(journalViewModelProvider);
    if (journal.entries.isNotEmpty) {
      _fabAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(journalViewModelProvider.notifier).loadMore();
    }
  }

  void _openWriteScreen() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const JournalWriteScreen()),
    );
    if (result == true) {
      // Refresh the journal entries if a new entry was added
      await ref.read(journalViewModelProvider.notifier).refresh();
      if (mounted && ref.read(journalViewModelProvider).entries.isNotEmpty) {
        _fabAnimationController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final journal = ref.watch(journalViewModelProvider);
    final hasEntries = journal.entries.isNotEmpty;

    // Handle FAB animation when entries are loaded
    if (hasEntries && !_fabAnimationController.isAnimating &&
        _fabAnimationController.status != AnimationStatus.forward) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _fabAnimationController.status == AnimationStatus.dismissed) {
          _fabAnimationController.forward();
        }
      });
    }

    return Scaffold(
      backgroundColor: context.secondaryBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── Enhanced Sticky Header ─────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: context.secondaryBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Journal',
                              style: AppTheme.title32.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_getEntryCountText(journal.entries.length)} • Your sacred space',
                              style: AppTheme.body12.copyWith(
                                color: context.secondaryTextColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasEntries)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blueberry100.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 14,
                                color: AppColors.blueberry100,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${journal.entries.length} entries',
                                style: AppTheme.body12.copyWith(
                                  color: AppColors.blueberry100,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              if (journal.isSaving && hasEntries)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.blueberry100,
                        ),
                      ),
                    ),
                  ),
                )
              else if (hasEntries)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: IconButton(
                    onPressed: () async {
                      await ref.read(journalViewModelProvider.notifier).refresh();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Journal refreshed ✨'),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                  ),
                ),
            ],
          ),

          // ── Loading State ──────────────────────────────────────────────────
          if (journal.isSaving && journal.entries.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading your memories...'),
                  ],
                ),
              ),
            )

          // ── Empty State with Animation (NO FAB when empty) ─────────────────
          else if (journal.entries.isEmpty)
            SliverFillRemaining(
              child: AnimationLimiter(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 500),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.blueberry100.withOpacity(0.1),
                              AppColors.rambutan100.withOpacity(0.05),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedBook02,
                          color: AppColors.blueberry100.withOpacity(0.6),
                          size: 80,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No entries yet',
                        style: AppTheme.title24.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.primaryTextColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          'Your journal is waiting for your first thought. Every entry is a step towards clarity ✨',
                          textAlign: TextAlign.center,
                          style: AppTheme.body14.copyWith(
                            color: context.secondaryTextColor,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _openWriteScreen,
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Write Your First Entry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blueberry100,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )

          // ── Journal Entries List with Staggered Animation ─────────────────
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList.separated(
                itemCount: journal.entries.length + (journal.hasMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == journal.entries.length) {
                    // Loading indicator at the bottom
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: SizedBox(
                          height: 32,
                          width: 32,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }

                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50,
                      child: FadeInAnimation(
                        child: JournalEntryCard(
                          entry: journal.entries[index],
                          onDelete: () => _showDeleteConfirmationDialog(
                            journal.entries[index].id,
                          ),
                          onTap: () => _openEditScreen(journal.entries[index]),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),

      // ── Animated FAB (ONLY shown when there are entries) ───────────────────

        floatingActionButton: hasEntries
      ? Padding(
      padding: const EdgeInsets.only(bottom: 67.0),
      child: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _openWriteScreen,
          backgroundColor: AppColors.blueberry100,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.edit_rounded, size: 20),
          label: Text(
            'New Entry',
            style: AppTheme.label14.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    )
        : null,


      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  String _getEntryCountText(int count) {
    if (count == 0) return 'Begin your journey';
    if (count == 1) return '1 beautiful memory';
    return '$count beautiful memories';
  }

  Future<void> _showDeleteConfirmationDialog(String entryId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text('Delete Entry'),
        content: const Text(
          'Are you sure you want to delete this entry? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await ref.read(journalViewModelProvider.notifier).deleteEntry(entryId);
      if (mounted) {
        // Check if after deletion there are no entries left
        final remainingEntries = ref.read(journalViewModelProvider).entries.length;
        if (remainingEntries == 0) {
          // Reset FAB animation controller when going back to empty state
          _fabAnimationController.reset();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry deleted 🗑️'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openEditScreen(dynamic entry) {
    // Implement edit functionality if needed
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => JournalWriteScreen(entry: entry),
    //   ),
    // );
  }
}