import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../../extensions/build_context_extension.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../model/journal_entry.dart';

class JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback? onDelete;

  const JournalEntryCard({super.key, required this.entry, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'EEE, MMM d · h:mm a',
    ).format(entry.createdAt.toLocal());

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.rambutan100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete entry?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.rambutan100),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete?.call(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.secondaryWidgetColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date + tag row
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 12,
                  color: context.secondaryTextColor,
                ),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: AppTheme.body12.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
                const Spacer(),
                if (entry.tags.isNotEmpty)
                  ...entry.tags.take(2).map((tag) => _TagChip(label: tag)),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete entry?'),
                        content: const Text('This cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: AppColors.rambutan100),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      onDelete?.call();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedDelete02,
                      color: AppColors.rambutan80,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            if (entry.title != null && entry.title!.isNotEmpty) ...[
              Text(entry.title!, style: AppTheme.title16),
              const SizedBox(height: 4),
            ],

            // Content preview
            Text(
              entry.content,
              style: AppTheme.body14.copyWith(
                color: context.secondaryTextColor,
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),

            // Sentiment score (shown if AI has processed it)
            if (entry.sentimentScore != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  HugeIcon(
                    icon: entry.sentimentScore! >= 0
                        ? HugeIcons.strokeRoundedSmile
                        : HugeIcons.strokeRoundedSad01,
                    color: entry.sentimentScore! >= 0
                        ? AppColors.watermelon100
                        : AppColors.rambutan80,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Sentiment: ${(entry.sentimentScore! * 100).toStringAsFixed(0)}%',
                    style: AppTheme.body12.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.blueberry10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '#$label',
        style: AppTheme.body12.copyWith(color: AppColors.blueberry100),
      ),
    );
  }
}
