import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/assets.dart';
import '../../../constants/constants.dart';
import '../../../extensions/build_context_extension.dart';
import '../../../generated/locale_keys.g.dart';
import '../../../routing/routes.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/global_loading.dart';
import '../../../utils/validator.dart';
import '../../common/ui/widgets/common_text_form_field.dart';
import '../../common/ui/widgets/primary_button.dart';
import 'view_model/authentication_view_model.dart';
import 'widgets/horizontal_divider.dart';
import 'widgets/sign_in_agreement.dart';
import 'widgets/social_sign_in.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _emailController.addListener(_validateInputs);
    _passwordController.addListener(_validateInputs);
    _confirmPasswordController.addListener(_validateInputs);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateInputs);
    _passwordController.removeListener(_validateInputs);
    _confirmPasswordController.removeListener(_validateInputs);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateInputs() {
    setState(() {
      _isEmailValid = isValidEmail(_emailController.text);
      _isPasswordValid = _passwordController.text.length >= 6;
      _isConfirmPasswordValid = _passwordController.text == _confirmPasswordController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authenticationViewModelProvider, (previous, next) {
      if (next.isLoading != previous?.isLoading) {
        if (next.isLoading) {
          Global.showLoading(context);
        } else {
          Global.hideLoading();
        }
      }

      if (next is AsyncError) {
        context.showErrorSnackBar(next.error.toString());
      }

      if (next is AsyncData) {
        if (next.value?.isRegisterSuccessfully == true) {
          context.pushReplacement(Routes.emailVerificationPending);
        } else if (next.value?.isSignInSuccessfully == true) {
          context.pushReplacement(Routes.main);
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SvgPicture.asset(
                  Assets.welcome,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                  semanticsLabel: 'Welcome',
                ),
              ),
              Text(
                'register'.tr(),
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
              const SizedBox(height: 16),
              CommonTextFormField(
                label: 'Confirm Password',
                controller: _confirmPasswordController,
                validator: (val) => confirmPasswordValidator(_passwordController.text, val),
                isPassword: true,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                isEnable: _isEmailValid && _isPasswordValid && _isConfirmPasswordValid,
                text: LocaleKeys.continueText.tr(),
                onPressed: () {
                  ref
                      .read(authenticationViewModelProvider.notifier)
                      .signUpWithEmailPassword(
                        _emailController.text,
                        _passwordController.text,
                      );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    LocaleKeys.alreadyHaveAccount.tr(),
                    style: AppTheme.body14,
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () {
                      context.push(Routes.login);
                    },
                    child: Text(
                      LocaleKeys.signIn.tr(),
                      style: AppTheme.title14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const HorizontalDivider(),
              const SizedBox(height: 16),
              const SocialSignIn(),
              const SizedBox(height: 16),
              const SignInAgreement(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
