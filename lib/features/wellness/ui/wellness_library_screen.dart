import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../common/ui/widgets/common_header.dart';
import '../model/breathing_exercise.dart';
import '../model/wellness_catalog.dart';
import 'view_model/wellness_library_view_model.dart';
import 'widgets/crisis_resources_sheet.dart';

class WellnessLibraryScreen extends ConsumerWidget {
  const WellnessLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(wellnessLibraryViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFDFEBF5),
      body: library.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load exercises')),
        data: (state) {
          final favourites = WellnessCatalog.exercises
              .where((exercise) => state.favourites.contains(exercise.id))
              .toList();
          return Column(
            children: [
              CommonHeader(
                header: 'Breathe',
                action: IconButton(
                  onPressed: () => CrisisResourcesSheet.show(context),
                  icon: const Icon(Icons.health_and_safety_outlined),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  children: [
                    Text(
                      'Guided exercises and short games you can do offline.',
                      style: AppTheme.body14.copyWith(color: AppColors.mono60),
                    ),
                    if (favourites.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text('Favourites', style: AppTheme.title18),
                      const SizedBox(height: 8),
                      ...favourites.map(
                        (exercise) => _ExerciseCard(
                          exercise: exercise,
                          isFavourite: true,
                          minutes: state.durations[exercise.id] ??
                              exercise.defaultMinutes,
                          onFavourite: () => ref
                              .read(wellnessLibraryViewModelProvider.notifier)
                              .toggleFavourite(exercise.id),
                          onDuration: (value) => ref
                              .read(wellnessLibraryViewModelProvider.notifier)
                              .setDuration(exercise.id, value),
                          onStart: () => context.push(
                            Routes.wellnessSession,
                            extra: {
                              'exerciseId': exercise.id,
                              'minutes': state.durations[exercise.id] ??
                                  exercise.defaultMinutes,
                            },
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text('Exercises', style: AppTheme.title18),
                    const SizedBox(height: 8),
                    ...WellnessCatalog.exercises.map(
                      (exercise) => _ExerciseCard(
                        exercise: exercise,
                        isFavourite: state.favourites.contains(exercise.id),
                        minutes: state.durations[exercise.id] ??
                            exercise.defaultMinutes,
                        onFavourite: () => ref
                            .read(wellnessLibraryViewModelProvider.notifier)
                            .toggleFavourite(exercise.id),
                        onDuration: (value) => ref
                            .read(wellnessLibraryViewModelProvider.notifier)
                            .setDuration(exercise.id, value),
                        onStart: () => context.push(
                          Routes.wellnessSession,
                          extra: {
                            'exerciseId': exercise.id,
                            'minutes': state.durations[exercise.id] ??
                                exercise.defaultMinutes,
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Mini-games', style: AppTheme.title18),
                    const SizedBox(height: 8),
                    ...WellnessGames.all.map(
                      (game) => _GameCard(
                        title: game.title,
                        subtitle: game.subtitle,
                        color: game.color,
                        icon: game.icon,
                        onTap: () => context.push(
                          Routes.wellnessGame,
                          extra: game.id,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final BreathingExercise exercise;
  final bool isFavourite;
  final int minutes;
  final VoidCallback onFavourite;
  final ValueChanged<int> onDuration;
  final VoidCallback onStart;

  const _ExerciseCard({
    required this.exercise,
    required this.isFavourite,
    required this.minutes,
    required this.onFavourite,
    required this.onDuration,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: exercise.color.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  color: exercise.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.air_rounded, color: exercise.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.title, style: AppTheme.title16),
                    Text(
                      exercise.subtitle,
                      style: AppTheme.body12.copyWith(color: AppColors.mono60),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onFavourite,
                icon: Icon(
                  isFavourite ? Icons.favorite : Icons.favorite_border,
                  color: const Color(0xFF8B4F53),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Duration', style: AppTheme.label12),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: minutes.clamp(1, 30),
                underline: const SizedBox.shrink(),
                items: List.generate(
                  30,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1} min'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) onDuration(value);
                },
              ),
              const Spacer(),
              FilledButton(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: exercise.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Start'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.title16.copyWith(color: Colors.white),
                  ),
                  Text(
                    subtitle,
                    style: AppTheme.body12.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
