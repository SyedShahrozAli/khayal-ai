import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../common/ui/widgets/common_header.dart';
import 'view_model/progress_view_model.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E9),
      body: progress.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not load progress')),
        data: (state) => RefreshIndicator(
          onRefresh: () => ref.refresh(progressViewModelProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            children: [
              const CommonHeader(header: 'Your progress'),
              Text(
                'Small steps become a pattern.',
                style: AppTheme.body14.copyWith(color: AppColors.mono60),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _StatCard(
                    label: 'Current streak',
                    value: '${state.streak.current}',
                    suffix: ' days',
                    color: AppColors.blueberry100,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Best streak',
                    value: '${state.streak.best}',
                    suffix: ' days',
                    color: AppColors.watermelon100,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                sessions: state.weekSessions.length,
                minutes: state.weekSessions.fold<int>(
                  0,
                  (total, session) => total + (session.durationSeconds ~/ 60),
                ),
                moods: state.moods.length,
              ),
              const SizedBox(height: 24),
              Text('Recent sessions', style: AppTheme.title18),
              const SizedBox(height: 8),
              if (state.sessions.isEmpty)
                const _EmptyState()
              else
                ...state.sessions
                    .take(8)
                    .map(
                      (session) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFD7E4EE),
                          child: Icon(Icons.air_rounded),
                        ),
                        title: Text(session.title, style: AppTheme.body16),
                        subtitle: Text(
                          '${session.durationSeconds ~/ 60} minutes',
                          style: AppTheme.body12.copyWith(
                            color: AppColors.mono60,
                          ),
                        ),
                        trailing: const Icon(Icons.check_circle_outline),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.suffix,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTheme.body12.copyWith(color: AppColors.mono60),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                text: value,
                style: AppTheme.title24.copyWith(color: color),
                children: [TextSpan(text: suffix, style: AppTheme.body12)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int sessions;
  final int minutes;
  final int moods;

  const _SummaryCard({
    required this.sessions,
    required this.minutes,
    required this.moods,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.blueberry100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(value: '$sessions', label: 'sessions'),
          _SummaryItem(value: '$minutes', label: 'minutes'),
          _SummaryItem(value: '$moods', label: 'moods logged'),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;

  const _SummaryItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTheme.title24.copyWith(color: Colors.white)),
        Text(label, style: AppTheme.body12.copyWith(color: Colors.white70)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'Complete a breathing exercise to see it here.',
          style: AppTheme.body14.copyWith(color: AppColors.mono60),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
