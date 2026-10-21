import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../extensions/build_context_extension.dart';
import '../../../routing/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../common/ui/widgets/scenic_sun_illustration.dart';
import '../model/breathing_exercise.dart';
import '../model/wellness_catalog.dart';
import 'view_model/wellness_library_view_model.dart';
import 'widgets/crisis_resources_sheet.dart';

class WellnessLibraryScreen extends ConsumerStatefulWidget {
  const WellnessLibraryScreen({super.key});

  @override
  ConsumerState<WellnessLibraryScreen> createState() =>
      _WellnessLibraryScreenState();
}

class _WellnessLibraryScreenState extends ConsumerState<WellnessLibraryScreen> {
  int? _selectedCalmRating;

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(wellnessLibraryViewModelProvider);

    return Scaffold(
      backgroundColor: context.isDarkMode
          ? const Color(0xFF161722)
          : const Color(0xFFFAF7F2),
      body: SafeArea(
        child: library.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFDBB3B)),
          ),
          error: (_, __) => Center(
            child: ElevatedButton.icon(
              onPressed: () =>
                  ref.refresh(wellnessLibraryViewModelProvider.future),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ),
          data: (state) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Top Bar (Pill tag + Safety Helpline Action) ────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCE09B).withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFDBB3B).withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Mindful Practices & Reset 🌿',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF996800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => CrisisResourcesSheet.show(context),
                            tooltip: 'Crisis Helplines',
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              child: const Icon(
                                Icons.health_and_safety_outlined,
                                color: Color(0xFF048665),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ── Main Bold Headline ────────────────────────────────
                      Text(
                        'A letter to your mind:\nCalm is infrastructure.',
                        style: AppTheme.title32.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: context.primaryTextColor,
                          height: 1.25,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Intro text + Smiling Sun Illustration ─────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              "If you treat calm as an afterthought, you're building days on shaky ground. Mindful pauses shape how you think, breathe, and navigate life.",
                              style: AppTheme.body14.copyWith(
                                color: context.secondaryTextColor,
                                height: 1.45,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            width: 86,
                            height: 74,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const ScenicSunIllustration(
                              height: 74,
                              compactSun: true,
                              showHills: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Numbered Structured Practice Cards ────────────────
                      _buildPracticeCard(
                        number: '1',
                        iconLabel: 'Aa',
                        iconColor: const Color(0xFF8B5700),
                        iconBg: const Color(0xFFFFE8B3),
                        title: '1. Box Breathing Sets the Rhythm',
                        description:
                            'A consistent 4-4-4 rhythm creates harmony across mind and body. Build from a steady pace.',
                        exerciseId: 'box',
                        state: state,
                      ),
                      const SizedBox(height: 14),

                      _buildPracticeCard(
                        number: '2',
                        icon: Icons.sync_alt_rounded,
                        iconColor: const Color(0xFF5E3EB5),
                        iconBg: const Color(0xFFEAE4FC),
                        title: '2. 4-7-8 Deep Relaxation',
                        description:
                            'Extended exhalations release muscle tension and activate your rest-and-digest nervous system.',
                        exerciseId: '478',
                        state: state,
                      ),
                      const SizedBox(height: 14),

                      _buildPracticeCard(
                        number: '3',
                        icon: Icons.format_list_bulleted_rounded,
                        iconColor: const Color(0xFFBF4D28),
                        iconBg: const Color(0xFFFFE4DC),
                        title: '3. Equal Breathing Balance',
                        description:
                            'Match the length of inhale and exhale to regain steady composure and mental clarity.',
                        exerciseId: 'equal',
                        state: state,
                      ),
                      const SizedBox(height: 14),

                      _buildPracticeCard(
                        number: '4',
                        icon: Icons.accessibility_new_rounded,
                        iconColor: const Color(0xFF3C7132),
                        iconBg: const Color(0xFFE3EFE0),
                        title: '4. 5-4-3-2-1 Sensory Grounding',
                        description:
                            'Contrast, touch, and physical semantics aren’t extras—they’re the foundation of inner peace.',
                        exerciseId: 'bodyscan',
                        state: state,
                      ),
                      const SizedBox(height: 28),

                      // ── Interactive Rating Card (Scale 1 to 10) ───────────
                      _buildRatingCard(),
                      const SizedBox(height: 20),

                      // ── Playful Reset (Bubble Pop Game) ───────────────────
                      _buildBubblePopTile(),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Practice Card (Clean Numbered Tile matching Design) ───────────────────

  Widget _buildPracticeCard({
    required String number,
    String? iconLabel,
    IconData? icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String description,
    required String exerciseId,
    required dynamic state,
  }) {
    final isFav = state.favourites.contains(exerciseId);
    final minutes = state.durations[exerciseId] ?? 4;

    return Container(
      decoration: BoxDecoration(
        color: context.secondaryWidgetColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.35),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            context.push(
              Routes.wellnessSession,
              extra: {
                'exerciseId': exerciseId,
                'minutes': minutes,
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon square
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: iconLabel != null
                        ? Text(
                            iconLabel,
                            style: TextStyle(
                              color: iconColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : Icon(icon, color: iconColor, size: 24),
                  ),
                ),
                const SizedBox(width: 14),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTheme.body14.copyWith(
                                fontWeight: FontWeight.w800,
                                color: context.primaryTextColor,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              ref
                                  .read(wellnessLibraryViewModelProvider.notifier)
                                  .toggleFavourite(exerciseId);
                            },
                            child: Icon(
                              isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: isFav
                                  ? const Color(0xFFFDBB3B)
                                  : context.secondaryTextColor,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: AppTheme.body12.copyWith(
                          color: context.secondaryTextColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Interactive Rating Card (Scale 1 to 10) ───────────────────────────────

  Widget _buildRatingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFE299),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFDBB3B).withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDBB3B),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    Icons.chat_bubble_rounded,
                    color: Color(0xFF2E1C00),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rate your calm state',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2E1C00),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'On a scale from 1–10, how grounded do you feel right now?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B4800),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Number pills row (1 to 10)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(10, (index) {
                final score = index + 1;
                final isSelected = _selectedCalmRating == score;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedCalmRating = score);
                      context.showSuccessSnackBar(
                        'Calm level logged: $score/10 ✨ Keep breathing gently.',
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFDBB3B)
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFDBB3B)
                              : Colors.transparent,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF2E1C00)
                                : const Color(0xFF4A3510),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),

          // Warm footer
          Row(
            children: const [
              Text('🧡', style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "What's your score? Take a breath and celebrate showing up.",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A5A00),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bubble Pop mini-game tile ─────────────────────────────────────────────

  Widget _buildBubblePopTile() {
    return GestureDetector(
      onTap: () => context.push(Routes.wellnessGame, extra: 'bubble_pop'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE2F0FB),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.bubble_chart_rounded,
                  color: Color(0xFF3F82B8), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bubble Pop Mini-Game',
                    style: AppTheme.body14.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E3A52),
                    ),
                  ),
                  Text(
                    'Tap floating bubbles for an immediate sensory release',
                    style: AppTheme.body12.copyWith(
                      color: const Color(0xFF4A6B85),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF4A6B85),
            ),
          ],
        ),
      ),
    );
  }
}
