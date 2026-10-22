import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../extensions/build_context_extension.dart';
import '../../../routing/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../activity/model/exercise_session.dart';
import '../../common/ui/widgets/scenic_sun_illustration.dart';
import 'state/progress_state.dart';
import 'view_model/progress_view_model.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(progressViewModelProvider);

    return Scaffold(
      backgroundColor: context.isDarkMode
          ? const Color(0xFF161722)
          : const Color(0xFFF6F2EB),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFF7A81B),
          onRefresh: () => ref.refresh(progressViewModelProvider.future),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── Header & Banner ───────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pill tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE09B).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Your Journey & Growth 🌱',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF996800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Headline + Side Graphic
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Consistency beats\nintensity.',
                                  style: AppTheme.title32.copyWith(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: context.primaryTextColor,
                                    height: 1.25,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Small intentional steps become lifelong patterns of calm.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.secondaryTextColor,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 80,
                            height: 80,
                            child: ScenicSunIllustration(
                              height: 80,
                              compactSun: true,
                              showHills: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content or States ─────────────────────────────────────────
              progressAsync.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFF7A81B)),
                  ),
                ),
                error: (error, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(
                    onRetry: () =>
                        ref.refresh(progressViewModelProvider.future),
                  ),
                ),
                data: (state) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 1. Streak Cards (Terracotta & Amber, borderless)
                      _buildStreakSection(context, state),
                      const SizedBox(height: 14),

                      // 2. Summary Card (Avocado Olive, borderless)
                      _buildSummaryCard(state),
                      const SizedBox(height: 14),

                      // 3. Weekly Rhythm Card (Almond Cream, borderless)
                      _buildWeeklyRhythmCard(context, state),
                      const SizedBox(height: 28),

                      // 4. Recent Sessions
                      Text(
                        'Recent Sessions',
                        style: AppTheme.title18.copyWith(
                          fontWeight: FontWeight.w800,
                          color: context.primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (state.sessions.isEmpty)
                        const _EmptyState()
                      else
                        ...state.sessions
                            .take(10)
                            .map((session) => _SessionCard(session: session)),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Streak Section (Current in #DE6B48, Best in #F7A81B) ───────────────────

  Widget _buildStreakSection(BuildContext context, ProgressState state) {
    return Row(
      children: [
        // Current Streak
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFDE6B48),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDE6B48).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🔥', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Current streak',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFBE8E2),
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    text: '${state.streak.current}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    children: const [
                      TextSpan(
                        text: ' days',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFBE8E2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Best Streak
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF7A81B),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF7A81B).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🏆', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Best streak',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A3105),
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    text: '${state.streak.best}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF221400),
                    ),
                    children: const [
                      TextSpan(
                        text: ' days',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A3105),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Summary Card (Avocado Olive #90A959, borderless) ──────────────────────

  Widget _buildSummaryCard(ProgressState state) {
    final minutes = state.weekSessions.fold<int>(
      0,
      (total, s) => total + (s.durationSeconds ~/ 60),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF90A959),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF90A959).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('${state.weekSessions.length}', 'Sessions'),
          Container(
            height: 36,
            width: 1,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          _buildSummaryItem('$minutes', 'Minutes'),
          Container(
            height: 36,
            width: 1,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          _buildSummaryItem('${state.moods.length}', 'Moods logged'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEFF5E5),
          ),
        ),
      ],
    );
  }

  // ── Weekly Rhythm Card (Warm Almond Cream #EBDCCB, borderless) ────────────

  Widget _buildWeeklyRhythmCard(BuildContext context, ProgressState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEBDCCB),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEBDCCB).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('✨', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Weekly Mindful Rhythm',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF382A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            state.moods.isNotEmpty
                ? 'You recorded ${state.moods.length} mood check-in(s) recently. Showing up regularly anchors emotional stability.'
                : 'Complete your daily check-in on the Home page to track emotional trends here.',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5A442E),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ExerciseSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final mins = session.durationSeconds ~/ 60;
    final secs = session.durationSeconds % 60;
    final durationText = mins > 0 ? '$mins min' : '$secs sec';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? context.secondaryWidgetColor
            : const Color(0xFFEDE6DA),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF90A959),
            child: const Icon(Icons.air_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  durationText,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF90A959),
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? context.secondaryWidgetColor
            : const Color(0xFFEDE6DA),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: ScenicSunIllustration(
              height: 80,
              compactSun: true,
              showHills: true,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises yet',
            style: AppTheme.title16.copyWith(
              fontWeight: FontWeight.w800,
              color: context.primaryTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Complete your first breathing exercise to start tracking your mindfulness streak.',
            style: TextStyle(
              fontSize: 13,
              color: context.secondaryTextColor,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => context.push(Routes.wellnessSession),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF7A81B),
              foregroundColor: const Color(0xFF221400),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            icon: const Icon(
              Icons.play_arrow_rounded,
              color: Color(0xFF221400),
            ),
            label: const Text(
              'Start Breathing',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF221400),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDE6B48).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFDE6B48),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load progress',
              style: AppTheme.title18.copyWith(
                fontWeight: FontWeight.w800,
                color: context.primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We were unable to read your activity statistics. Please try refreshing.',
              style: TextStyle(fontSize: 13, color: context.secondaryTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF7A81B),
                foregroundColor: const Color(0xFF221400),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
