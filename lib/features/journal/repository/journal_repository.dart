import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/remote/firebase_provider.dart';
import '../model/journal_entry.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository(
    ref.watch(firebaseFirestoreProvider),
    FirebaseAuth.instance,
  );
});

class JournalRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  const JournalRepository(this.firestore, this.auth);

  CollectionReference<Map<String, dynamic>> _entries() {
    final user = auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to use your journal.');
    }
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('journalEntries');
  }

  Future<List<JournalEntry>> getEntries() async {
    final snapshot = await _entries()
        .orderBy('updatedAt', descending: true)
        .get();
    return snapshot.docs.map(JournalEntry.fromDocument).toList();
  }

  Future<JournalEntry> saveEntry({
    String? id,
    required String title,
    required String body,
    String? prompt,
  }) async {
    final entries = _entries();
    final now = DateTime.now();
    final document = id == null ? entries.doc() : entries.doc(id);
    final existing = id == null ? null : await document.get();
    final createdAt = existing != null && existing.exists
        ? JournalEntry.fromDocument(existing).createdAt
        : now;
    final entry = JournalEntry(
      id: document.id,
      title: title.trim(),
      body: body.trim(),
      prompt: prompt,
      createdAt: createdAt,
      updatedAt: now,
    );
    await document.set(entry.toFirestore());
    return entry;
  }

  Future<void> deleteEntry(String id) async {
    await _entries().doc(id).delete();
  }
}
