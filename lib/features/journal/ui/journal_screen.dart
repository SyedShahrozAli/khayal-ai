import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/routes.dart';
import '../../../../theme/app_theme.dart';
import 'view_model/journal_view_model.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(journalViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Write your first reflection.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = items[index];
              return Card(
                child: ListTile(
                  title: Text(
                    entry.title.isEmpty ? 'Untitled reflection' : entry.title,
                    style: AppTheme.title16,
                  ),
                  subtitle: Text(
                    entry.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => context.push(Routes.journalEdit, extra: entry),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.journalEdit),
        child: const Icon(Icons.add),
      ),
    );
  }
}
