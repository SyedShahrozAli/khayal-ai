class HeroTable {
  HeroTable._();

  static const String tableName = 'heroes';

  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnDescription = 'description';
  static const String columnImageUrl = 'imageUrl';
  static const String columnIsFavorite = 'isFavorite';
  static const String columnPower = 'power';
  static const String columnLastUpdated = 'lastUpdated';

  static const String createTableQuery = '''
    CREATE TABLE IF NOT EXISTS $tableName (                                                                         
      $columnId TEXT PRIMARY KEY,
      $columnName TEXT NOT NULL,
      $columnDescription TEXT NOT NULL,
      $columnImageUrl TEXT NOT NULL,
      $columnIsFavorite INTEGER NOT NULL DEFAULT 0,
      $columnPower INTEGER NOT NULL DEFAULT 0,
      $columnLastUpdated INTEGER
    )
  ''';
}

class MoodTable {
  MoodTable._();

  static const String tableName = 'moods';
  static const String columnDate = 'date';
  static const String columnMoodIndex = 'moodIndex';
  static const String columnLabel = 'label';

  static const String createTableQuery = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $columnDate TEXT PRIMARY KEY,
      $columnMoodIndex INTEGER NOT NULL,
      $columnLabel TEXT NOT NULL
    )
  ''';
}

class ExerciseSessionTable {
  ExerciseSessionTable._();

  static const String tableName = 'exercise_sessions';
  static const String columnId = 'id';
  static const String columnType = 'type';
  static const String columnTitle = 'title';
  static const String columnDurationSeconds = 'durationSeconds';
  static const String columnCompleted = 'completed';
  static const String columnTimestamp = 'timestamp';

  static const String createTableQuery = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnType TEXT NOT NULL,
      $columnTitle TEXT NOT NULL,
      $columnDurationSeconds INTEGER NOT NULL,
      $columnCompleted INTEGER NOT NULL DEFAULT 1,
      $columnTimestamp INTEGER NOT NULL
    )
  ''';
}

class CommunityPostTable {
  CommunityPostTable._();

  static const String tableName = 'community_posts';
  static const String columnId = 'id';
  static const String columnCategory = 'category';
  static const String columnBody = 'body';
  static const String columnAnonymousName = 'anonymousName';
  static const String columnCreatedAt = 'createdAt';
  static const String columnLikes = 'likes';
  static const String columnFlagged = 'flagged';
  static const String columnLikedByUser = 'likedByUser';

  static const String createTableQuery = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnCategory TEXT NOT NULL,
      $columnBody TEXT NOT NULL,
      $columnAnonymousName TEXT NOT NULL,
      $columnCreatedAt INTEGER NOT NULL,
      $columnLikes INTEGER NOT NULL DEFAULT 0,
      $columnFlagged INTEGER NOT NULL DEFAULT 0,
      $columnLikedByUser INTEGER NOT NULL DEFAULT 0
    )
  ''';
}

class CommunityCommentTable {
  CommunityCommentTable._();

  static const String tableName = 'community_comments';
  static const String columnId = 'id';
  static const String columnPostId = 'postId';
  static const String columnBody = 'body';
  static const String columnAnonymousName = 'anonymousName';
  static const String columnCreatedAt = 'createdAt';

  static const String createTableQuery = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnPostId TEXT NOT NULL,
      $columnBody TEXT NOT NULL,
      $columnAnonymousName TEXT NOT NULL,
      $columnCreatedAt INTEGER NOT NULL
    )
  ''';
}

class JournalTable {
  JournalTable._();

  static const String tableName = 'local_journals';

  static const String columnId = 'id';
  static const String columnUserId = 'user_id';
  static const String columnEntryType = 'entry_type';
  static const String columnContentText = 'content_text';
  static const String columnTitle = 'title';
  static const String columnLanguage = 'language';
  static const String columnTags = 'tags';
  static const String columnSentiment = 'sentiment';
  static const String columnDetectedKeywords = 'detected_keywords';
  static const String columnIsDraft = 'is_draft';
  static const String columnIsDeleted = 'is_deleted';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnSyncedAt = 'synced_at';

  static const String createTableQuery = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnUserId TEXT NOT NULL,
      $columnEntryType TEXT NOT NULL,
      $columnContentText TEXT NOT NULL,
      $columnTitle TEXT,
      $columnLanguage TEXT NOT NULL,
      $columnTags TEXT,
      $columnSentiment TEXT,
      $columnDetectedKeywords TEXT,
      $columnIsDraft INTEGER NOT NULL DEFAULT 0,
      $columnIsDeleted INTEGER NOT NULL DEFAULT 0,
      $columnCreatedAt TEXT NOT NULL,
      $columnUpdatedAt TEXT NOT NULL,
      $columnSyncedAt TEXT
    )
  ''';
}

