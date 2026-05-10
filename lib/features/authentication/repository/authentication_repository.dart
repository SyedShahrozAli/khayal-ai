import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/constants/constants.dart';
import '/environment/env.dart';
import '/generated/locale_keys.g.dart';
import '../model/auth_response.dart';

part 'authentication_repository.g.dart';

@riverpod
AuthenticationRepository authenticationRepository(Ref ref) {
  return AuthenticationRepository();
}

class AuthenticationRepository {
  const AuthenticationRepository();

  Future<void> signInWithMagicLink(String email) async {
    // TODO: fake data
    return;
  }

  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    required bool isRegister,
  }) async {
    // TODO: fake data
    return AuthResponse(
      user: User(
        id: '',
        email: email,
        userMetadata: {},
      ),
    );
  }

  Future<AuthResponse> signInWithGoogle() async {
    // TODO: fake data
    return AuthResponse(
      user: User(
        id: '',
        email: 'henry@google.com',
        userMetadata: {},
      ),
    );
  }

  Future<AuthResponse> signInWithApple() async {
    // TODO: fake data
    return AuthResponse(
      user: User(
        id: '',
        email: 'henry@apple.com',
        userMetadata: {},
      ),
    );
  }

  Future<void> signOut() async {
    // TODO: fake data
    setIsLogin(false);
    return;
  }

  Future<bool> isLogin() async {
    // TODO: fake data, remove this when integrating real auth
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Constants.isLoginKey) ?? false;
  }

  // TODO: remove this when integrating real auth
  Future<void> setIsLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.isLoginKey, value);
  }

  Future<bool> isExistAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Constants.isExistAccountKey) ?? false;
  }

  Future<void> setIsExistAccount(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.isExistAccountKey, value);
  }
  // END TODO

  Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Constants.isGuestModeKey) ?? false;
  }

  Future<void> setIsGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.isGuestModeKey, true);
  }
}
