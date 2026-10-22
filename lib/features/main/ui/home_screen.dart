import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../constants/constants.dart';
import '../../../extensions/build_context_extension.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../common/ui/widgets/scenic_sun_illustration.dart';
import '../../journal/model/journal_entry.dart';
import '../../journal/ui/journal_write_screen.dart';
import 'view_model/home_state.dart';
import 'view_model/home_view_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final void Function(int tabIndex)? onTabChange;

  const HomeScreen({super.key, this.onTabChange});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const List<_MoodOption> _moods = [
    _MoodOption(emoji: '😢', label: 'Very Sad', color: Color(0xFF7B9ACC)),
    _MoodOption(emoji: '😔', label: 'Sad', color: Color(0xFF91A7D0)),
    _MoodOption(emoji: '😊', label: 'Okay', color: Color(0xFF8AC6B8)),
    _MoodOption(emoji: '😄', label: 'Happy', color: Color(0xFFFFB38A)),
    _MoodOption(emoji: '🤩', label: 'Excited', color: Color(0xFFFF8FA3)),
  ];

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(homeViewModelProvider);

    return Scaffold(
      backgroundColor: context.isDarkMode
          ? const Color(0xFF161722)
          : const Color(0xFFF6F2EB),
      body: SafeArea(
        child: homeAsync.when(
          loading: () => _buildBody(context, const HomeState()),
          error: (_, __) => _buildBody(context, const HomeState()),
          data: (state) => _buildBody(context, state),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    final displayName = (state.userName != null && state.userName!.isNotEmpty)
        ? state.userName!
        : 'Jose Maria';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Top Header (Name + Avatar) ──────────────────────────────────
          _buildHeader(displayName),
          const SizedBox(height: 20),

          // ── 2. Horizontal Week Calendar Strip ─────────────────────────────
          _buildWeekCalendarStrip(state.weekStatus),
          const SizedBox(height: 28),

          // ── 3. Today's Check-in Hero Section ──────────────────────────────
          _buildCheckInSection(state),
          const SizedBox(height: 28),

          // ── 4. Quick Journal Section ──────────────────────────────────────
          _buildQuickJournalSection(),
          const SizedBox(height: 28),

          // ── 5. Mindful Reset & AI Companion Shortcuts ──────────────────────
          _buildMindfulShortcuts(state.streakCount),
        ],
      ),
    );
  }

  // ── 1. Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(String displayName) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'J';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, $displayName',
              style: AppTheme.title32.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: context.primaryTextColor,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => widget.onTabChange?.call(6),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFE5B4),
              border: Border.all(color: const Color(0xFFFDBB3B), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFDBB3B).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: AppTheme.title18.copyWith(
                  color: const Color(0xFF8A5300),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    ).animate().fade(duration: 400.ms).slideY(begin: -0.1);
  }

  // ── 2. Week Calendar Strip ────────────────────────────────────────────────

  Widget _buildWeekCalendarStrip(List<bool> weekStatus) {
    final now = DateTime.now();
    // Weekday: 1 = Mon, ..., 7 = Sun
    final monday = now.subtract(Duration(days: now.weekday - 1));
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayDate = monday.add(Duration(days: index));
        final isToday = (index == now.weekday - 1);
        final hasActiveCheckin =
            (index < weekStatus.length && weekStatus[index]);

        return Column(
          children: [
            Text(
              dayLabels[index],
              style: AppTheme.body12.copyWith(
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isToday
                    ? context.primaryTextColor
                    : context.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday
                    ? const Color(0xFFF7A81B)
                    : (context.isDarkMode
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFEDE6DA)),
                border: isToday
                    ? Border.all(color: const Color(0xFFD68A04), width: 1.5)
                    : Border.all(
                        color: context.isDarkMode
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFDFD5C6),
                        width: 1,
                      ),
                boxShadow: isToday
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFFF7A81B,
                          ).withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Center(
                child: Text(
                  '${dayDate.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                    color: isToday
                        ? const Color(0xFF221400)
                        : context.primaryTextColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Tiny status indicator dot
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasActiveCheckin
                    ? const Color(0xFF6C9E37)
                    : Colors.transparent,
              ),
            ),
          ],
        );
      }),
    ).animate().fade(delay: 150.ms);
  }

  // ── 3. Today's Check-in Hero Section ──────────────────────────────────────

  Widget _buildCheckInSection(HomeState state) {
    final hasCheckedIn = state.selectedMoodIndex != null;
    final selectedMood = hasCheckedIn ? _moods[state.selectedMoodIndex!] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Check-in",
              style: AppTheme.title18.copyWith(
                fontWeight: FontWeight.w800,
                color: context.primaryTextColor,
              ),
            ),
            GestureDetector(
              onTap: () => widget.onTabChange?.call(4), // Progress
              child: Text(
                'See all',
                style: AppTheme.body14.copyWith(
                  color: context.secondaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF9B828), Color(0xFFF5A310)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFDF9100), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF5A310).withValues(alpha: 0.35),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasCheckedIn
                          ? "You're feeling ${selectedMood?.label} ${selectedMood?.emoji}"
                          : "How are you feeling right now?",
                      style: AppTheme.title20.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF221400),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasCheckedIn
                          ? "Check-in logged for today. Tap below to reflect or update."
                          : "Take a breath and choose one option.",
                      style: AppTheme.body14.copyWith(
                        color: const Color(0xFF4E3003),
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ScenicSunIllustration(height: 145),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _showMoodCheckInModal(context, state),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF221400),
                      elevation: 3,
                      shadowColor: Colors.black.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          hasCheckedIn ? 'Update Check-in' : 'Check-in',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF221400),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: Color(0xFF221400),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fade(delay: 250.ms).slideY(begin: 0.05);
  }

  // ── Mood Check-in Modal ───────────────────────────────────────────────────

  void _showMoodCheckInModal(BuildContext context, HomeState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.secondaryBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.paddingOf(ctx).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: context.dividerColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'How are you feeling right now?',
                style: AppTheme.title20.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Your honest check-in helps Khayal tailor gentle support.',
                style: AppTheme.body14.copyWith(
                  color: context.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_moods.length, (index) {
                  final mood = _moods[index];
                  final isSelected = state.selectedMoodIndex == index;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      ref.read(homeViewModelProvider.notifier).saveMood(index);
                      Navigator.pop(ctx);
                      context.showSuccessSnackBar(
                        'Logged: ${mood.label} ${mood.emoji} ✨',
                      );
                    },
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? mood.color.withValues(alpha: 0.25)
                                : context.secondaryWidgetColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? mood.color
                                  : context.dividerColor.withValues(alpha: 0.4),
                              width: isSelected ? 2.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              mood.emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mood.label,
                          style: AppTheme.body12.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? mood.color
                                : context.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ── 4. Quick Journal Section ──────────────────────────────────────────────

  Widget _buildQuickJournalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Journal',
              style: AppTheme.title18.copyWith(
                fontWeight: FontWeight.w800,
                color: context.primaryTextColor,
              ),
            ),
            GestureDetector(
              onTap: () => widget.onTabChange?.call(1), // Journal
              child: Text(
                'See all',
                style: AppTheme.body14.copyWith(
                  color: context.secondaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildJournalCard(
                title: 'Pause & reflect 🌱',
                subtitle: 'What are you grateful for today?',
                tag1: 'Today',
                tag2: 'Personal',
                backgroundColor: const Color(0xFFDE6B48),
                titleColor: Colors.white,
                subtitleColor: Colors.white.withValues(alpha: 0.92),
                tagTextColor: const Color(0xFFDE6B48),
                prompt: 'What are you grateful for today?',
              ),
              const SizedBox(width: 14),
              _buildJournalCard(
                title: 'Set Intentions 🙃',
                subtitle: 'How do you want to feel?',
                tag1: 'Today',
                tag2: 'Family',
                backgroundColor: const Color(0xFFBDDC90),
                titleColor: const Color(0xFF20380E),
                subtitleColor: const Color(0xFF33521A),
                tagTextColor: const Color(0xFF20380E),
                prompt: 'How do you want to feel today?',
              ),
              const SizedBox(width: 14),
              _buildJournalCard(
                title: 'Empty mind 🕊️',
                subtitle: 'Let it out and breathe...',
                tag1: 'Today',
                tag2: 'Peace',
                backgroundColor: const Color(0xFFEBDCCB),
                titleColor: const Color(0xFF362818),
                subtitleColor: const Color(0xFF56432D),
                tagTextColor: const Color(0xFF362818),
                prompt: 'A space to let out all your thoughts freely...',
              ),
            ],
          ),
        ),
      ],
    ).animate().fade(delay: 350.ms);
  }

  Widget _buildJournalCard({
    required String title,
    required String subtitle,
    required String tag1,
    required String tag2,
    required Color backgroundColor,
    required Color titleColor,
    required Color subtitleColor,
    required Color tagTextColor,
    required String prompt,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => JournalWriteScreen(
              existing: JournalEntry(
                id: '',
                userId: '',
                entryType: 'text',
                contentText: '',
                title: prompt,
                language: 'en',
                tags: [tag2],
                isDraft: false,
                isDeleted: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
          ),
        );
      },
      child: Container(
        width: 180,
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTheme.body14.copyWith(
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                subtitle,
                style: AppTheme.body12.copyWith(
                  color: subtitleColor,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                Text(
                  tag1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    tag2,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: tagTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 5. Mindful Shortcuts (Breathe + Chat + Streak) ─────────────────────────

  Widget _buildMindfulShortcuts(int streakCount) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onTabChange?.call(3), // Wellness
                child: Container(
                  height: 110,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF90A959),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF90A959).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.air_rounded,
                          size: 18,
                          color: Color(0xFF90A959),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Breathe',
                            style: AppTheme.body14.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '60s calm reset',
                            style: AppTheme.body12.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onTabChange?.call(2), // Chat
                child: Container(
                  height: 110,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF798A),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF798A).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: Color(0xFFEF798A),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Khayal AI',
                            style: AppTheme.body14.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Gentle companion',
                            style: AppTheme.body12.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => widget.onTabChange?.call(4), // Progress
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? context.secondaryWidgetColor
                  : const Color(0xFFEFE8DD),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: context.isDarkMode
                    ? context.dividerColor.withValues(alpha: 0.4)
                    : const Color(0xFFDDD2C2),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$streakCount Day Streak',
                        style: AppTheme.body14.copyWith(
                          fontWeight: FontWeight.w800,
                          color: context.primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Consistency beats intensity. You showed up!',
                        style: AppTheme.body14.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: context.secondaryTextColor,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: context.secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fade(delay: 450.ms);
  }
}

class _MoodOption {
  final String emoji;
  final String label;
  final Color color;

  const _MoodOption({
    required this.emoji,
    required this.label,
    required this.color,
  });
}
