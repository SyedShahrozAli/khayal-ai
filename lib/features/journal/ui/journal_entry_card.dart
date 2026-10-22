import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../extensions/build_context_extension.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../model/journal_entry.dart';

class JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final int cardIndex;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;

  const JournalEntryCard({
    super.key,
    required this.entry,
    this.cardIndex = 0,
    this.onDelete,
    this.onEdit,
    this.onTap,
  });

  bool get _isUrdu => entry.language == 'ur';

  static const _palette = [
    _CardStyle(
      bg: Color(0xFFDE6B48),
      titleColor: Colors.white,
      subtitleColor: Color(0xFFFBE8E2),
      tagTextColor: Color(0xFFDE6B48),
      isDark: true,
    ),
    _CardStyle(
      bg: Color(0xFFBDDC90),
      titleColor: Color(0xFF1E390E),
      subtitleColor: Color(0xFF33541B),
      tagTextColor: Color(0xFF1E390E),
      isDark: false,
    ),
    _CardStyle(
      bg: Color(0xFFEBDCCB),
      titleColor: Color(0xFF382A1A),
      subtitleColor: Color(0xFF5A442E),
      tagTextColor: Color(0xFF382A1A),
      isDark: false,
    ),
    _CardStyle(
      bg: Color(0xFF90A959),
      titleColor: Colors.white,
      subtitleColor: Color(0xFFEFF5E5),
      tagTextColor: Color(0xFF43581E),
      isDark: true,
    ),
    _CardStyle(
      bg: Color(0xFFEF798A),
      titleColor: Colors.white,
      subtitleColor: Color(0xFFFDE8EC),
      tagTextColor: Color(0xFFB52E42),
      isDark: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final style = _palette[cardIndex % _palette.length];
    final dateStr = DateFormat(
      'EEE, MMM d · h:mm a',
    ).format(entry.createdAt.toLocal());
    final isVoice = entry.entryType == 'voice';

    return InkWell(
      onTap: onTap ?? onEdit,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: style.bg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: style.bg.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Badges + Date + Menu Actions
            Row(
              children: [
                // Entry Type Badge (FE-1 / FE-2)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: isVoice
                            ? HugeIcons.strokeRoundedMic02
                            : HugeIcons.strokeRoundedEdit02,
                        size: 13,
                        color: style.tagTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isVoice ? 'Voice' : 'Text',
                        style: TextStyle(
                          fontSize: 10,
                          color: style.tagTextColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Language Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.language.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: style.tagTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Offline Draft Badge (FE-5, REL-1)
                if (entry.isDraft) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 12,
                          color: Color(0xFFF7A81B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Draft',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // More Menu Button (Edit / Delete)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: style.subtitleColor,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (val) {
                    if (val == 'edit' && onEdit != null) {
                      onEdit!();
                    } else if (val == 'delete' && onDelete != null) {
                      onDelete!();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedEdit02,
                            size: 16,
                            color: context.primaryTextColor,
                          ),
                          const SizedBox(width: 8),
                          Text('Edit', style: AppTheme.body14),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedDelete02,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: AppTheme.body14.copyWith(
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Date Row
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 11,
                  color: style.subtitleColor.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 5),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: style.subtitleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title (FE-1, LOC-1, LOC-2)
            if (entry.title != null && entry.title!.isNotEmpty) ...[
              Directionality(
                textDirection: _isUrdu ? TextDirection.rtl : TextDirection.ltr,
                child: Text(
                  entry.title!,
                  style: _isUrdu
                      ? GoogleFonts.notoNastaliqUrdu(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.8,
                          color: style.titleColor,
                        )
                      : TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: style.titleColor,
                          letterSpacing: -0.2,
                        ),
                ),
              ),
              const SizedBox(height: 6),
            ],

            // Content preview (FE-1, LOC-1, LOC-2)
            Directionality(
              textDirection: _isUrdu ? TextDirection.rtl : TextDirection.ltr,
              child: Text(
                entry.content,
                style: _isUrdu
                    ? GoogleFonts.notoNastaliqUrdu(
                        fontSize: 14,
                        color: style.subtitleColor,
                        height: 1.8,
                      )
                    : TextStyle(
                        fontSize: 13,
                        color: style.subtitleColor,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Tags row (if present)
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: entry.tags
                    .map(
                      (tag) =>
                          _TagChip(label: tag, textColor: style.tagTextColor),
                    )
                    .toList(),
              ),
            ],

            // Detected Keywords / Sentiment indicator (if processed)
            if (entry.primaryEmotion != null ||
                entry.detectedKeywords.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (entry.primaryEmotion != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedSmile,
                            color: style.tagTextColor,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.primaryEmotion!,
                            style: TextStyle(
                              fontSize: 10,
                              color: style.tagTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (entry.detectedKeywords.isNotEmpty)
                    Text(
                      'Keywords: ${entry.detectedKeywords.take(3).join(', ')}',
                      style: TextStyle(
                        fontSize: 10,
                        color: style.subtitleColor.withValues(alpha: 0.85),
                        fontStyle: FontStyle.italic,
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
  final Color textColor;

  const _TagChip({required this.label, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        '#$label',
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CardStyle {
  final Color bg;
  final Color titleColor;
  final Color subtitleColor;
  final Color tagTextColor;
  final bool isDark;

  const _CardStyle({
    required this.bg,
    required this.titleColor,
    required this.subtitleColor,
    required this.tagTextColor,
    required this.isDark,
  });
}
