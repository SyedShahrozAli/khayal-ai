import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/constants.dart';
import '../features/authentication/ui/otp_screen.dart';
import '../features/authentication/ui/register_screen.dart';
import '../features/authentication/ui/sign_in_screen.dart';
import '../features/authentication/ui/welcome_screen.dart';
import '../features/main/ui/main_screen.dart';
<<<<<<< HEAD
import '../features/authentication/ui/email_verification_pending_screen.dart';
=======
import '../features/journal/model/journal_entry.dart';
import '../features/journal/ui/journal_editor_screen.dart';
import '../features/journal/ui/journal_screen.dart';
>>>>>>> 646c0a0 (new feature added)
import '../features/onboarding/ui/onboarding_screen.dart';
import '../features/onboarding/ui/splash_screen.dart';
import '../features/onboarding/ui/startup_screen.dart';
import '../features/profile/model/profile.dart';
import '../features/profile/ui/account_info_screen.dart';
import '../features/profile/ui/appearances_screen.dart';
import '../features/profile/ui/languages_screen.dart';
import '../features/progress/ui/progress_screen.dart';
import '../features/wellness/ui/breathing_session_screen.dart';
import '../features/wellness/ui/wellness_game_screen.dart';
import '../features/wellness/ui/wellness_library_screen.dart';
import 'routes.dart';

enum SlideDirection { right, left, up, down }

extension GoRouterStateExtension on GoRouterState {
  SlideRouteTransition slidePage(
    Widget child, {
    SlideDirection direction = SlideDirection.left,
  }) {
    return SlideRouteTransition(
      key: pageKey,
      child: child,
      direction: direction,
    );
  }
}

class SlideRouteTransition extends CustomTransitionPage<void> {
  SlideRouteTransition({
    required super.key,
    required super.child,
    SlideDirection direction = SlideDirection.left,
  }) : super(
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curve = CurvedAnimation(
             parent: animation,
             curve: Curves.easeInOut,
           );

           Offset begin;
           switch (direction) {
             case SlideDirection.right:
               begin = const Offset(-1.0, 0.0);
               break;
             case SlideDirection.left:
               begin = const Offset(1.0, 0.0);
               break;
             case SlideDirection.up:
               begin = const Offset(0.0, 1.0);
               break;
             case SlideDirection.down:
               begin = const Offset(0.0, -1.0);
               break;
           }
           final tween = Tween(begin: begin, end: Offset.zero);
           final offsetAnimation = tween.animate(curve);

           return SlideTransition(position: offsetAnimation, child: child);
         },
       );
}

final GoRouter router = GoRouter(
  initialLocation: Routes.splash,
  routes: [
    GoRoute(
      path: Routes.splash,
      pageBuilder: (context, state) => state.slidePage(const SplashScreen()),
    ),
    GoRoute(
      path: Routes.startup,
      pageBuilder: (context, state) => state.slidePage(const StartupScreen()),
    ),
    GoRoute(
      path: Routes.welcome,
      pageBuilder: (context, state) => state.slidePage(const WelcomeScreen()),
    ),
    GoRoute(
      path: Routes.register,
      pageBuilder: (context, state) => state.slidePage(const RegisterScreen()),
    ),
    GoRoute(
      path: Routes.login,
      pageBuilder: (context, state) => state.slidePage(const SignInScreen()),
    ),
    GoRoute(
      path: Routes.otp,
      pageBuilder: (context, state) {
        final map = state.extra as Map?;
        return state.slidePage(
          OtpScreen(email: map?['email'], isRegister: map?['isRegister']),
        );
      },
    ),
<<<<<<< HEAD
    GoRoute(
      path: Routes.emailVerificationPending,
      pageBuilder: (context, state) =>
          state.slidePage(const EmailVerificationPendingScreen()),
    ),
=======
>>>>>>> 646c0a0 (new feature added)
    GoRoute(
      path: Routes.onboarding,
      pageBuilder: (context, state) =>
          state.slidePage(const OnboardingScreen()),
    ),
    GoRoute(
      path: Routes.main,
      pageBuilder: (context, state) => state.slidePage(const MainScreen()),
    ),
    GoRoute(
      path: Routes.journal,
      pageBuilder: (context, state) => state.slidePage(const JournalScreen()),
    ),
    GoRoute(
      path: Routes.journalEdit,
      pageBuilder: (context, state) => state.slidePage(
        JournalEditorScreen(entry: state.extra as JournalEntry?),
      ),
    ),
    GoRoute(
      path: Routes.wellness,
      pageBuilder: (context, state) =>
          state.slidePage(const WellnessLibraryScreen()),
    ),
    GoRoute(
      path: Routes.wellnessSession,
      pageBuilder: (context, state) {
        final map = state.extra as Map?;
        return state.slidePage(
          BreathingSessionScreen(
            exerciseId: map?['exerciseId'] as String? ?? 'box',
            minutes: map?['minutes'] as int? ?? 3,
          ),
        );
      },
    ),
    GoRoute(
      path: Routes.wellnessGame,
      pageBuilder: (context, state) => state.slidePage(
        WellnessGameScreen(gameId: state.extra as String? ?? 'bubble_pop'),
      ),
    ),
    GoRoute(
      path: Routes.progress,
      pageBuilder: (context, state) => state.slidePage(const ProgressScreen()),
    ),
    GoRoute(
      path: Routes.accountInformation,
      pageBuilder: (context, state) {
        final profile = state.extra as Profile;
        return state.slidePage(AccountInfoScreen(originalProfile: profile));
      },
    ),
    GoRoute(
      path: Routes.appearances,
      pageBuilder: (context, state) =>
          state.slidePage(const AppearancesScreen()),
    ),
    GoRoute(
      path: Routes.languages,
      pageBuilder: (context, state) => state.slidePage(const LanguagesScreen()),
    ),
<<<<<<< HEAD
=======
    GoRoute(
      path: Routes.premium,
      pageBuilder: (context, state) {
        final map = state.extra as Map?;
        return state.slidePage(
          PremiumScreen(isGoToMain: map?[Constants.isGoToMain] as bool?),
          direction: SlideDirection.up,
        );
      },
    ),
>>>>>>> 646c0a0 (new feature added)
  ],
);
