import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(journalViewModelProvider.notifier).loadMore();
    }
  }

  void _openWriteScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const JournalWriteScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final journal = ref.watch(journalViewModelProvider);

    return Scaffold(
      backgroundColor: context.secondaryBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── Sticky Header ─────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            backgroundColor: context.secondaryBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Journal', style: AppTheme.title24),
                  Text(
                    'Your thoughts, safely stored',
                    style: AppTheme.body12.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (journal.isSaving)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: IconButton(
                    onPressed: () =>
                        ref.read(journalViewModelProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
            ],
          ),

          // ── Body ──────────────────────────────────────────────────────────
          if (journal.isSaving && journal.entries.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (journal.entries.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedBook02,
                      color: AppColors.blueberry40,
                      size: 72,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No entries yet',
                      style: AppTheme.title18.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Tap the button below to write your first entry.',
                        textAlign: TextAlign.center,
                        style: AppTheme.body14.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              sliver: SliverList.separated(
                itemCount: journal.entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => JournalEntryCard(
                  entry: journal.entries[i],
                  onDelete: () => ref
                      .read(journalViewModelProvider.notifier)
                      .deleteEntry(journal.entries[i].id),
                ),
              ),
            ),
        ],
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: FloatingActionButton.extended(
          onPressed: _openWriteScreen,
          backgroundColor: AppColors.blueberry100,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.edit_rounded),
          label: Text(
            'New Entry',
            style: AppTheme.label14.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
