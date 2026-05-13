import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../../theme/app_theme.dart';
import '../../common/ui/widgets/primary_button.dart';
import 'view_model/authentication_view_model.dart';

class EmailVerificationPendingScreen extends ConsumerWidget {
  const EmailVerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.mark_email_unread_outlined, size: 64),
            const SizedBox(height: 24),
            Text(
              'Please check your email inbox to verify your account.',
              style: AppTheme.title20,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Once verified, you can sign in.',
              style: AppTheme.body14,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            PrimaryButton(
              text: 'Go to Sign In',
              onPressed: () {
                context.pushReplacement(Routes.login);
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                ref.read(authenticationViewModelProvider.notifier).sendEmailVerification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verification email resent!')),
                );
              },
              child: const Text('Resend Verification Email'),
            ),
          ],
        ),
      ),
    );
  }
}
