import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';



import '../../../constants/assets.dart';
import '../../../constants/constants.dart';
import '../../../extensions/build_context_extension.dart';
import '../../../generated/locale_keys.g.dart';
import '../../../routing/routes.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/global_loading.dart';
import '../../profile/ui/view_model/profile_view_model.dart';
import '../../../features/common/ui/widgets/primary_button.dart';
import 'view_model/authentication_view_model.dart';
import 'widgets/continue_as_guest.dart';
import 'widgets/sign_in_agreement.dart';
import 'widgets/social_sign_in.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _logInAsGuest() async {
    await ref.read(authenticationViewModelProvider.notifier).setIsGuestMode();
    await ref.read(authenticationViewModelProvider.notifier).signInAnonymously();
  }

  void _goToNextScreen() async {
    Global.hideLoading();

    final wasShowOnboarding =
        await ref.read(profileViewModelProvider.notifier).wasShowOnboarding();
    if (!wasShowOnboarding) {
      if (mounted) context.go(Routes.onboarding);
      return;
    }



    if (mounted) context.go(Routes.main);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authenticationViewModelProvider, (previous, next) {
      if (next is AsyncLoading) {
        Global.showLoading(context);
      } else {
        Global.hideLoading();
      }

      if (next is AsyncError) {
        context.showErrorSnackBar(next.error.toString());
      }

      // TODO: Remove this because we only observe social login
      if (next is AsyncData) {
        if (next.value?.isSignInSuccessfully == true) {
          _goToNextScreen();
        }
      }
      // END TODO
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Welcome to Khayal AI",
                  style: AppTheme.title32,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Get started on improvement journey with Khayal AI",
                  style: AppTheme.body16,
                ),
              ),
              Expanded(
                child: Lottie.asset(
                  'assets/animations/welcome.json',
                  fit: BoxFit.contain,
                  repeat: false,
               //   animate: true,
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Continue with Email',
                icon: const Icon(Icons.email_outlined, color: Colors.white, size: 20),
                onPressed: () {
                  if (mounted) context.push(Routes.login);
                },
              ),
              const SizedBox(height: 16),
              const SocialSignIn(),
              const SizedBox(height: 8),
              ContinueAsGuest(onClick: _logInAsGuest),
              const SizedBox(height: 8),
              const SignInAgreement(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
