import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../extensions/build_context_extension.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../model/journal_entry.dart';
import 'view_model/journal_view_model.dart';

class JournalWriteScreen extends ConsumerStatefulWidget {
  final JournalEntry? existing;

  const JournalWriteScreen({super.key, this.existing});

  @override
  ConsumerState<JournalWriteScreen> createState() => _JournalWriteScreenState();
}

class _JournalWriteScreenState extends ConsumerState<JournalWriteScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _tagsCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title);
    _contentCtrl = TextEditingController(text: widget.existing?.content);
    _tagsCtrl = TextEditingController(
      text: widget.existing?.tags.join(', ') ?? '',
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  List<String> get _parsedTags => _tagsCtrl.text
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  Future<void> _save() async {
    if (_contentCtrl.text.trim().isEmpty) {
      context.showWarningSnackBar('Please write something before saving.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref
          .read(journalViewModelProvider.notifier)
          .createEntry(
            title: _titleCtrl.text.trim().isEmpty
                ? null
                : _titleCtrl.text.trim(),
            content: _contentCtrl.text.trim(),
            tags: _parsedTags,
          );
      if (mounted) {
        Navigator.of(context).pop();
        context.showSuccessSnackBar('Entry saved ✓');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to save: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.secondaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.secondaryBackgroundColor,
        elevation: 0,
        title: Text('New Entry', style: AppTheme.title20),
        centerTitle: false,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blueberry100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Save',
                    style: AppTheme.title14.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title field
            TextField(
              controller: _titleCtrl,
              style: AppTheme.title18,
              decoration: InputDecoration(
                hintText: 'Title (optional)',
                hintStyle: AppTheme.title18.copyWith(
                  color: context.secondaryTextColor,
                ),
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            Divider(color: context.dividerColor, height: 1),
            const SizedBox(height: 12),

            // Content field
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height * 0.4,
              ),
              child: TextField(
                controller: _contentCtrl,
                style: AppTheme.body16,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'What\'s on your mind?',
                  hintStyle: AppTheme.body16.copyWith(
                    color: context.secondaryTextColor,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: context.dividerColor, height: 1),
            const SizedBox(height: 12),

            // Tags field
            Row(
              children: [
                Icon(
                  Icons.tag_rounded,
                  size: 18,
                  color: context.secondaryTextColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _tagsCtrl,
                    style: AppTheme.body14,
                    decoration: InputDecoration(
                      hintText: 'Tags, comma-separated (e.g. gratitude, work)',
                      hintStyle: AppTheme.body14.copyWith(
                        color: context.secondaryTextColor,
                      ),
                      border: InputBorder.none,
                      isDense: true,
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
}
