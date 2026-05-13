import 'journal_entry.dart';

class JournalState {
  final List<JournalEntry> entries;
  final bool isSaving;
  final bool hasMore;
  final int page;

  const JournalState({
    this.entries = const [],
    this.isSaving = false,
    this.hasMore = false,
    this.page = 1,
  });

  JournalState copyWith({
    List<JournalEntry>? entries,
    bool? isSaving,
    bool? hasMore,
    int? page,
  }) {
    return JournalState(
      entries: entries ?? this.entries,
      isSaving: isSaving ?? this.isSaving,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}
