import 'package:freezed_annotation/freezed_annotation.dart';

part 'journal_entry.freezed.dart';
part 'journal_entry.g.dart';

@freezed
abstract class JournalEntry with _$JournalEntry {
  const factory JournalEntry({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    String? title,
    required String content,
    @Default([]) List<String> tags,
    @JsonKey(name: 'is_private') @Default(true) bool isPrivate,
    @JsonKey(name: 'sentiment_score') double? sentimentScore,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _JournalEntry;

  factory JournalEntry.fromJson(Map<String, dynamic> json) =>
      _$JournalEntryFromJson(json);
}
