import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '/constants/constants.dart';
import '../model/auth_response.dart';

part 'authentication_repository.g.dart';

@riverpod
AuthenticationRepository authenticationRepository(Ref ref) {
  return AuthenticationRepository();
}

class AuthenticationRepository {
  const AuthenticationRepository();

  User _mapFirebaseUser(firebase_auth.User? firebaseUser) {
    if (firebaseUser == null) {
      throw Exception('User is null');
    }
    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email,
      userMetadata: {
        'full_name': firebaseUser.displayName,
        'avatar_url': firebaseUser.photoURL,
      },
    );
  }

  Future<void> handleDynamicLink(String pendingLink) async {
    if (firebase_auth.FirebaseAuth.instance.isSignInWithEmailLink(pendingLink)) {
      final prefs = await SharedPreferences.getInstance();
      // Retrieve the email you saved in SharedPreferences earlier
      final email = prefs.getString('magic_link_email') ?? ''; 
      if (email.isNotEmpty) {
        await firebase_auth.FirebaseAuth.instance.signInWithEmailLink(email: email, emailLink: pendingLink);
      } else {
        throw Exception("Email not found for magic link sign in. Please try again.");
      }
    }
  }

  Future<void> signInWithMagicLink(String email) async {
    final acs = firebase_auth.ActionCodeSettings(
      // 1. The 'url' is the web fallback.
      // It must be whitelisted in "Authorized Domains" in Firebase Auth settings.
      url: 'https://khayal-ai0.firebaseapp.com/login',
      handleCodeInApp: true,
      androidPackageName: 'com.henry.khayal_ai',
      androidInstallApp: true,
      androidMinimumVersion: '1',
      iOSBundleId: 'com.henry.flutterMvvmRiverpod',
    );

    await firebase_auth.FirebaseAuth.instance.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: acs,
    );
  }

  Future<AuthResponse> signUpWithEmailPassword(String email, String password) async {
    final userCredential = await firebase_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await userCredential.user?.sendEmailVerification();
    return AuthResponse(user: _mapFirebaseUser(userCredential.user));
  }

  Future<AuthResponse> signInWithEmailPassword(String email, String password) async {
    final userCredential = await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (userCredential.user != null && !userCredential.user!.emailVerified) {
      throw Exception('Please verify your email before signing in.');
    }
    return AuthResponse(user: _mapFirebaseUser(userCredential.user));
  }

  Future<void> sendEmailVerification() async {
    await firebase_auth.FirebaseAuth.instance.currentUser?.sendEmailVerification();
  }

  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    required bool isRegister,
  }) async {
    final userCredential = await firebase_auth.FirebaseAuth.instance.signInWithEmailLink(
      email: email,
      emailLink: token,
    );
    return AuthResponse(user: _mapFirebaseUser(userCredential.user));
  }

  Future<AuthResponse> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize(
      serverClientId: '324748181774-9vdtipu33cdm77hikn6i2c0ekbjaaokt.apps.googleusercontent.com',

    );
    try {
      await googleSignIn.initialize();
    } catch (_) {}
    
    final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
    
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final clientAuth = await googleUser.authorizationClient.authorizationForScopes([
      'email',
      'profile',
    ]);
    
    final firebase_auth.OAuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
      accessToken: clientAuth?.accessToken,
      idToken: googleAuth.idToken,
    );
    
    final userCredential = await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
    return AuthResponse(user: _mapFirebaseUser(userCredential.user));
  }

  Future<AuthResponse> signInWithApple() async {
    final AuthorizationCredentialAppleID appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    
    final firebase_auth.OAuthProvider oAuthProvider = firebase_auth.OAuthProvider('apple.com');
    final firebase_auth.OAuthCredential credential = oAuthProvider.credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    
    final userCredential = await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
    return AuthResponse(user: _mapFirebaseUser(userCredential.user));
  }

  Future<void> signOut() async {
    await firebase_auth.FirebaseAuth.instance.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
   }

  Future<bool> isLogin() async {
    return firebase_auth.FirebaseAuth.instance.currentUser != null;
  }


  Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Constants.isGuestModeKey) ?? false;
  }

  Future<void> setIsGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.isGuestModeKey, true);
  }
}

