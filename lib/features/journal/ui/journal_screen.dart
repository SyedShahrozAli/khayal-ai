import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../extensions/build_context_extension.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../common/ui/widgets/scenic_sun_illustration.dart';
import '../model/journal_entry.dart';
import 'journal_entry_card.dart';
import 'journal_write_screen.dart';
import 'view_model/journal_view_model.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late final AnimationController _fabAnimationController;
  late final Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void didUpdateWidget(covariant JournalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final journal = ref.read(journalViewModelProvider);
    if (journal.entries.isNotEmpty) {
      _fabAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(journalViewModelProvider.notifier).loadMore();
    }
  }

  void _openWriteScreen({
    bool startWithVoice = false,
    JournalEntry? existing,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => JournalWriteScreen(
          existing: existing,
          startWithVoice: startWithVoice,
        ),
      ),
    );
    if (result == true) {
      await ref.read(journalViewModelProvider.notifier).refresh();
      if (mounted && ref.read(journalViewModelProvider).entries.isNotEmpty) {
        _fabAnimationController.forward();
      }
    }
  }

  void _showCreateOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Create Reflection', style: AppTheme.title18),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7A81B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedEdit02,
                    color: Color(0xFFC47B00),
                    size: 22,
                  ),
                ),
                title: Text('Text Journal', style: AppTheme.label14),
                subtitle: const Text(
                  'Write thoughts in Urdu or English',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openWriteScreen(startWithVoice: false);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDE6B48).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedMic02,
                    color: Color(0xFFDE6B48),
                    size: 22,
                  ),
                ),
                title: Text('Voice Journal (STT)', style: AppTheme.label14),
                subtitle: const Text(
                  'Record spoken Urdu or English thoughts',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openWriteScreen(startWithVoice: true);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final journal = ref.watch(journalViewModelProvider);
    final displayedEntries = journal.filteredEntries;
    final hasEntries = journal.entries.isNotEmpty;

    if (hasEntries &&
        !_fabAnimationController.isAnimating &&
        _fabAnimationController.status != AnimationStatus.forward) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _fabAnimationController.status == AnimationStatus.dismissed) {
          _fabAnimationController.forward();
        }
      });
    }

    return Scaffold(
      backgroundColor: context.isDarkMode
          ? const Color(0xFF161722)
          : const Color(0xFFF6F2EB),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(journalViewModelProvider.notifier).refresh();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ── Sticky Header ───────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              expandedHeight: 120,
              backgroundColor: context.isDarkMode
                  ? const Color(0xFF161722)
                  : const Color(0xFFF6F2EB),
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(
                  left: 20,
                  bottom: 12,
                  right: 20,
                ),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Journal',
                      style: AppTheme.title32.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: context.primaryTextColor,
                      ),
                    ),
                    Text(
                      '${journal.entries.length} reflections • Urdu & English',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (journal.isSaving || journal.isSyncing)
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  IconButton(
                    onPressed: () async {
                      await ref
                          .read(journalViewModelProvider.notifier)
                          .refresh();
                      await ref
                          .read(journalViewModelProvider.notifier)
                          .syncDrafts();
                      if (context.mounted) {
                        context.showSuccessSnackBar('Journal updated ✨');
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh & Sync',
                  ),
              ],
            ),

            // ── Morning Reflection Banner (Matching screenshot) ─────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: GestureDetector(
                  onTap: () => _openWriteScreen(),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF9B828), Color(0xFFF5A310)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFF5A310,
                          ).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Let's start your day ☀️",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF221400),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Begin with a mindful morning reflection or gratitude note.",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF4A3105),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Write Reflection',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF221400),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 14,
                                      color: Color(0xFF221400),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const SizedBox(
                          width: 82,
                          height: 82,
                          child: ScenicSunIllustration(
                            height: 82,
                            compactSun: true,
                            showHills: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Search & Filter Bar ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    // Search Field (borderless, with soft shadow)
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? context.secondaryWidgetColor
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          ref
                              .read(journalViewModelProvider.notifier)
                              .setSearchQuery(val);
                        },
                        style: AppTheme.body14,
                        decoration: InputDecoration(
                          hintText: 'Search memories, reflections, tags...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: context.secondaryTextColor,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: context.secondaryTextColor,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref
                                        .read(journalViewModelProvider.notifier)
                                        .setSearchQuery('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter Chips (All, Text, Voice, Drafts)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip(
                            'All',
                            'all',
                            journal.selectedFilter,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Text Only',
                            'text',
                            journal.selectedFilter,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Voice Only',
                            'voice',
                            journal.selectedFilter,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Offline Drafts${journal.pendingDraftsCount > 0 ? ' (${journal.pendingDraftsCount})' : ''}',
                            'drafts',
                            journal.selectedFilter,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Offline Sync Banner (FE-5, REL-1) ───────────────────────────
            if (journal.pendingDraftsCount > 0)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBDCCB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        color: Color(0xFF5A442E),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${journal.pendingDraftsCount} offline draft(s) stored locally',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF382A1A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: journal.isSyncing
                            ? null
                            : () async {
                                final count = await ref
                                    .read(journalViewModelProvider.notifier)
                                    .syncDrafts();
                                if (context.mounted) {
                                  context.showSuccessSnackBar(
                                    'Synced $count draft(s) with cloud database ✓',
                                  );
                                }
                              },
                        child: journal.isSyncing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Sync Now',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFDE6B48),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Loading Initial State ────────────────────────────────────────
            if (journal.isSaving && journal.entries.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFF7A81B)),
                ),
              )
            // ── Empty State ──────────────────────────────────────────────────
            else if (displayedEntries.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 90,
                          height: 90,
                          child: ScenicSunIllustration(
                            height: 90,
                            compactSun: true,
                            showHills: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          journal.searchQuery.isNotEmpty
                              ? 'No matching reflections'
                              : 'No reflections yet',
                          style: AppTheme.title20.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          journal.searchQuery.isNotEmpty
                              ? 'Try searching with another keyword or tag.'
                              : 'Express your thoughts in Urdu or English, speak or type your daily reflections ✨',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.secondaryTextColor,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showCreateOptionsBottomSheet,
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text('Start Daily Reflection'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF7A81B),
                            foregroundColor: const Color(0xFF221400),
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            // ── Journal List with Staggered Animation ────────────────────────
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                sliver: SliverList.builder(
                  itemCount:
                      displayedEntries.length + (journal.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == displayedEntries.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFF7A81B),
                            ),
                          ),
                        ),
                      );
                    }

                    final entry = displayedEntries[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 300),
                      child: SlideAnimation(
                        verticalOffset: 20,
                        child: FadeInAnimation(
                          child: JournalEntryCard(
                            entry: entry,
                            cardIndex: index,
                            onTap: () => _openWriteScreen(existing: entry),
                            onEdit: () => _openWriteScreen(existing: entry),
                            onDelete: () =>
                                _showDeleteConfirmationDialog(entry.id),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),

      // ── Floating Action Button (Center bottom) ─────────────────────────────
      floatingActionButton: hasEntries
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ScaleTransition(
                scale: _fabAnimation,
                child: FloatingActionButton.extended(
                  onPressed: _showCreateOptionsBottomSheet,
                  backgroundColor: const Color(0xFFF7A81B),
                  foregroundColor: const Color(0xFF221400),
                  elevation: 4,
                  icon: const Icon(
                    Icons.add_rounded,
                    size: 22,
                    color: Color(0xFF221400),
                  ),
                  label: const Text(
                    'New Reflection',
                    style: TextStyle(
                      color: Color(0xFF221400),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
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

  Widget _buildFilterChip(String label, String value, String currentFilter) {
    final isSelected = currentFilter == value;
    return GestureDetector(
      onTap: () {
        ref.read(journalViewModelProvider.notifier).setFilter(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF7A81B)
              : (context.isDarkMode
                    ? context.secondaryWidgetColor
                    : const Color(0xFFEDE6DA)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? const Color(0xFF221400)
                : context.secondaryTextColor,
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(String entryId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Reflection?'),
        content: const Text(
          'This entry will be safely removed from your journal.',
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
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await ref.read(journalViewModelProvider.notifier).deleteEntry(entryId);
      if (mounted) {
        final remaining = ref.read(journalViewModelProvider).entries.length;
        if (remaining == 0) {
          _fabAnimationController.reset();
        }
        context.showSuccessSnackBar('Entry deleted 🗑️');
      }
    }
  }
}
