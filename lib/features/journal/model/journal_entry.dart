// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'journal_entry.freezed.dart';
part 'journal_entry.g.dart';

@freezed
abstract class JournalEntry with _$JournalEntry {
  const JournalEntry._();

  const factory JournalEntry({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'entry_type') @Default('text') String entryType,
    @JsonKey(name: 'content_text') required String contentText,
    String? title,
    @Default('en') String language,
    Map<String, dynamic>? sentiment,
    @JsonKey(name: 'detected_keywords') @Default([]) List<String> detectedKeywords,
    @Default([]) List<String> tags,
    @JsonKey(name: 'is_draft') @Default(false) bool isDraft,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'synced_at') DateTime? syncedAt,
  }) = _JournalEntry;

  String get content => contentText;

  String? get primaryEmotion =>
      sentiment != null ? sentiment!['primary_emotion'] as String? : null;

  double? get sentimentConfidence =>
      sentiment != null ? (sentiment!['confidence'] as num?)?.toDouble() : null;

  factory JournalEntry.fromJson(Map<String, Object?> json) =>
      _$JournalEntryFromJson(json);
}
