import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/constants.dart';
import '../../../features/profile/model/profile.dart';
import '../../../utils/utils.dart';
import '../../premium/model/premium_info.dart';

part 'profile_repository.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepository();
}

class ProfileRepository {
  const ProfileRepository();

  Future<Profile?> get() async {
    // TODO: temporary get profile from local
    final prefs = await SharedPreferences.getInstance();
    final profileStr = prefs.getString(Constants.profileKey);
    if (profileStr == null) return null;

    final fakeProfile = Profile.fromJson(jsonDecode(profileStr));
    return fakeProfile;
  }

  PremiumInfo _extractPremiumInfo(Map<String, EntitlementInfo> entitlements) {
    final isPremium = entitlements.containsKey(Constants.premium);
    if (!isPremium) {
      return const PremiumInfo(isPremium: false);
    }

    final premiumEntitlement = entitlements[Constants.premium];
    final date = premiumEntitlement?.expirationDate;
    if (date != null) {
      return PremiumInfo(
        isPremium: true,
        expiryDate: DateTime.parse(date),
      );
    } else {
      return const PremiumInfo(
        isPremium: true,
        isLifetime: true,
      );
    }
  }

  Future<void> update(Profile profile) async {
    // TODO: temporary save profile to local
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(Constants.profileKey, jsonEncode(profile.toJson()));
    return;
  }

  Future<bool> wasShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Constants.wasShowOnboardingKey) ?? false;
  }

  Future<void> setWasShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.wasShowOnboardingKey, true);
  }

  Future<void> setIsPremiumUser(bool isPremiumUser) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.isPremiumUserKey, isPremiumUser);
  }

  Future<bool> isShowPremium() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremiumUser = prefs.getBool(Constants.isPremiumUserKey) ?? false;
    if (isPremiumUser) return false;

    final day = prefs.getString(Constants.lastDayShowPremiumKey);
    if (day == null) return true;
    return Utils.today().difference(DateTime.parse(day)).inDays >= 3;
  }

  Future<void> setIsShowPremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        Constants.lastDayShowPremiumKey, Utils.today().toIso8601String());
  }
}
