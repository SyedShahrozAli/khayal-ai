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
  final VoidCallback? onTap;

  const JournalEntryCard({
    super.key,
    required this.entry,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d · h:mm a').format(entry.createdAt.toLocal());

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.secondaryWidgetColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date + Delete Action Row
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 12,
                  color: context.secondaryTextColor,
                ),
                const SizedBox(width: 6),
                Text(
                  dateStr,
                  style: AppTheme.body12.copyWith(
                    color: context.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedDelete02,
                      color: AppColors.rambutan80.withOpacity(0.7),
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Title (if exists)
            if (entry.title != null && entry.title!.isNotEmpty) ...[
              Text(
                entry.title!,
                style: AppTheme.title18.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
            ],

            // Content preview
            Text(
              entry.content,
              style: AppTheme.body14.copyWith(
                color: context.secondaryTextColor,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // Tags row (if exists)
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: entry.tags.map((tag) => _TagChip(label: tag)).toList(),
              ),
            ],

            // Sentiment indicator (if processed)
            if (entry.sentimentScore != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (entry.sentimentScore! >= 0 
                      ? AppColors.watermelon100 
                      : AppColors.rambutan80).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(width: 6),
                    Text(
                      'Reflecting: ${(entry.sentimentScore! * 100).toStringAsFixed(0)}%',
                      style: AppTheme.body12.copyWith(
                        color: entry.sentimentScore! >= 0
                            ? AppColors.watermelon100
                            : AppColors.rambutan80,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.blueberry100.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '#$label',
        style: AppTheme.body12.copyWith(
          color: AppColors.blueberry100,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}