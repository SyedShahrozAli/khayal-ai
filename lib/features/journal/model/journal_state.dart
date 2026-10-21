import 'journal_entry.dart';

class JournalState {
  final List<JournalEntry> entries;
  final bool isSaving;
  final bool isSyncing;
  final bool hasMore;
  final int page;
  final int pendingDraftsCount;
  final String selectedFilter; // 'all', 'text', 'voice', 'drafts'
  final String searchQuery;

  const JournalState({
    this.entries = const [],
    this.isSaving = false,
    this.isSyncing = false,
    this.hasMore = false,
    this.page = 1,
    this.pendingDraftsCount = 0,
    this.selectedFilter = 'all',
    this.searchQuery = '',
  });

  List<JournalEntry> get filteredEntries {
    return entries.where((entry) {
      if (selectedFilter == 'text' && entry.entryType != 'text') return false;
      if (selectedFilter == 'voice' && entry.entryType != 'voice') return false;
      if (selectedFilter == 'drafts' && !entry.isDraft) return false;

      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final title = (entry.title ?? '').toLowerCase();
        final content = entry.contentText.toLowerCase();
        final tags = entry.tags.map((t) => t.toLowerCase()).join(' ');
        if (!title.contains(query) &&
            !content.contains(query) &&
            !tags.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  JournalState copyWith({
    List<JournalEntry>? entries,
    bool? isSaving,
    bool? isSyncing,
    bool? hasMore,
    int? page,
    int? pendingDraftsCount,
    String? selectedFilter,
    String? searchQuery,
  }) {
    return JournalState(
      entries: entries ?? this.entries,
      isSaving: isSaving ?? this.isSaving,
      isSyncing: isSyncing ?? this.isSyncing,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      pendingDraftsCount: pendingDraftsCount ?? this.pendingDraftsCount,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
