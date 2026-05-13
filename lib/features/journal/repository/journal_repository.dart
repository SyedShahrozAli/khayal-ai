import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/journal_entry.dart';

import 'dart:io' show Platform;

part 'journal_repository.g.dart';

// Use the gateway port 8000. 10.0.2.2 is for Android Emulator, localhost is for Linux/iOS Simulator
final _kBaseUrl = Platform.isAndroid
    ? 'http://192.168.110.232:8000'
    : 'http://localhost:8000';

@riverpod
JournalRepository journalRepository(Ref ref) => JournalRepository();

class JournalRepository {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _kBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<Options> _authOptions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated. Please sign in.');

    try {
      // Get token with a short timeout to prevent hanging
      final token = await user.getIdToken().timeout(
        const Duration(seconds: 10),
      );
      return Options(headers: {'Authorization': 'Bearer $token'});
    } catch (e) {
      throw Exception('Failed to get authentication token: $e');
    }
  }

  Future<List<JournalEntry>> fetchEntries({int page = 1}) async {
    try {
      final opts = await _authOptions();
      final response = await _dio.get(
        '/journal/entries',
        queryParameters: {'page': page, 'page_size': 20},
        options: opts,
      );
      final List data = response.data as List;
      return data
          .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<JournalEntry> createEntry({
    String? title,
    required String content,
    List<String> tags = const [],
  }) async {
    try {
      final opts = await _authOptions();
      final response = await _dio.post(
        '/journal/entries',
        data: {
          'title': title,
          'content': content,
          'tags': tags,
          'is_private': true,
        },
        options: opts,
      );
      return JournalEntry.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      final opts = await _authOptions();
      await _dio.delete('/journal/entries/$id', options: opts);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception(
        'Connection timed out. Ensure your backend is running on port 8000 and accessible at $_kBaseUrl',
      );
    }
    if (e.type == DioExceptionType.connectionError) {
      return Exception(
        'Network error: Could not reach the server at $_kBaseUrl',
      );
    }
    return Exception('API Error: ${e.message}');
  }
}
