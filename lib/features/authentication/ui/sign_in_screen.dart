import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/assets.dart';
import '../../../features/authentication/ui/view_model/authentication_view_model.dart';
import '../../../features/authentication/ui/widgets/horizontal_divider.dart';
import '../../../features/authentication/ui/widgets/social_sign_in.dart';
import '../../../features/common/ui/widgets/common_back_button.dart';
import '../../../features/common/ui/widgets/common_text_form_field.dart';
import '../../../features/common/ui/widgets/primary_button.dart';
import '../../../generated/locale_keys.g.dart';
import '../../../routing/routes.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/validator.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _emailController.addListener(_validateInputs);
    _passwordController.addListener(_validateInputs);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateInputs);
    _passwordController.removeListener(_validateInputs);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateInputs() {
    setState(() {
      _isEmailValid = isValidEmail(_emailController.text);
      _isPasswordValid = _passwordController.text.length >= 6;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authenticationViewModelProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
      if (next is AsyncData && next.value?.isSignInSuccessfully == true) {
        context.pushReplacement(Routes.main);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SvgPicture.asset(
                      Assets.login,
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.bottomCenter,
                      semanticsLabel: 'Sign in',
                    ),
                  ),
                  Text(
                    LocaleKeys.signIn.tr(),
                    style: AppTheme.title32,
                  ),
                  const SizedBox(height: 24),
                  CommonTextFormField(
                    label: 'Email',
                    controller: _emailController,
                    validator: notEmptyEmailValidator,
                  ),
                  const SizedBox(height: 16),
                  CommonTextFormField(
                    label: 'Password',
                    controller: _passwordController,
                    validator: notEmptyPasswordValidator,
                    isPassword: true,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        if (!_isEmailValid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid email address first.')),
                          );
                          return;
                        }
                        await ref.read(authenticationViewModelProvider.notifier).sendPasswordResetEmail(_emailController.text);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password reset email sent! Check your inbox.')),
                          );
                        }
                      },
                      child: Text(
                        'Forgot Password?',
                        style: AppTheme.body14.copyWith(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    isEnable: _isEmailValid && _isPasswordValid,
                    text: LocaleKeys.continueText.tr(),
                    onPressed: () {
                      ref
                          .read(authenticationViewModelProvider.notifier)
                          .signInWithEmailPassword(
                            _emailController.text,
                            _passwordController.text,
                          );
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: AppTheme.body14,
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () {
                          context.push(Routes.register);
                        },
                        child: Text(
                          LocaleKeys.register.tr(),
                          style: AppTheme.title14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const HorizontalDivider(),
                  const SizedBox(height: 16),
                  const SocialSignIn(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: CommonBackButton(),
            ),
          ],
        ),
      ),
    );
  }
}
