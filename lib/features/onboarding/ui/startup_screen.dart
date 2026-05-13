import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/assets.dart';
import '../../../routing/routes.dart';
import '../../../theme/app_colors.dart';

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Graphic
          ClipPath(
            clipper: _WaveClipper(),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.65,
              child: Image.asset(Assets.topographicPattern, fit: BoxFit.cover),
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3B3836),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your mental health improvement journey\nstarts here → →',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFBA775D),
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),

                  // Bottom Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          // Goes to WelcomeScreen (which is the actual Auth login screen)
                          context.pushReplacement(Routes.welcome);
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFFB87C5E),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Start at top-left
    path.lineTo(0, size.height - 60);

    // Curve down and up (first wave)
    path.quadraticBezierTo(
      size.width * 0.35,
      size.height - 180,
      size.width * 0.65,
      size.height - 60,
    );

    // Curve down to right edge
    path.quadraticBezierTo(
      size.width * 0.85,
      size.height + 20,
      size.width,
      size.height - 40,
    );

    // Line to top-right
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
