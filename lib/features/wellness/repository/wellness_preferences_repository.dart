import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/constants.dart';

final wellnessPreferencesRepositoryProvider =
    Provider<WellnessPreferencesRepository>((ref) {
  return const WellnessPreferencesRepository();
});

class WellnessPreferencesRepository {
  const WellnessPreferencesRepository();

  Future<Set<String>> getFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(Constants.wellnessFavouritesKey)?.toSet() ??
        <String>{};
  }

  Future<void> toggleFavourite(String exerciseId) async {
    final prefs = await SharedPreferences.getInstance();
    final current =
        prefs.getStringList(Constants.wellnessFavouritesKey)?.toSet() ??
            <String>{};
    if (current.contains(exerciseId)) {
      current.remove(exerciseId);
    } else {
      current.add(exerciseId);
    }
    await prefs.setStringList(
      Constants.wellnessFavouritesKey,
      current.toList(),
    );
  }

  Future<Map<String, int>> getDurations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(Constants.wellnessDurationsKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value as int));
  }

  Future<void> setDuration(String exerciseId, int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getDurations();
    current[exerciseId] = minutes;
    await prefs.setString(Constants.wellnessDurationsKey, jsonEncode(current));
  }
}
