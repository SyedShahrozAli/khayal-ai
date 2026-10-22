import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';

class CrisisScanner {
  CrisisScanner._();

  static final List<RegExp> _triggers = [
    // English triggers
    RegExp(
      r'\b(suicide|suicidal|kill myself|end my life|want to die|hang myself|slit my wrist|overdose)\b',
      caseSensitive: false,
    ),
    // Roman Urdu triggers
    RegExp(
      r'\b(khudkushi|khud kushi|marna chahta|marne laga|jaan dena|khatam karna chahta|jeena nahi chahta)\b',
      caseSensitive: false,
    ),
    // Urdu script triggers
    RegExp(
      r'(خودکشی|مرنا چاہتا|مرنے لگا|جان دینا|ختم کرنا چاہتا|جینا نہیں چاہتا|زندگی ختم)',
    ),
  ];

  static bool hasCrisisIntent(String text) {
    if (text.trim().isEmpty) return false;
    for (final reg in _triggers) {
      if (reg.hasMatch(text)) return true;
    }
    return false;
  }
}

class CrisisSafetyBanner extends StatelessWidget {
  const CrisisSafetyBanner({super.key});

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB3B3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedAlertCircle,
                    color: Color(0xFFD32F2F),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You are not alone • ہم آپ کے ساتھ ہیں',
                      style: AppTheme.title16.copyWith(
                        color: const Color(0xFFB71C1C),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'If you feel overwhelmed or unsafe, please reach out to verified professionals.',
                      style: AppTheme.body12.copyWith(
                        color: const Color(0xFF5D1010),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFFFD4D4), height: 1),
          const SizedBox(height: 12),
          Text(
            'Verified Pakistani Mental Health Helplines:',
            style: AppTheme.body12.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8B0000),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _helplineButton(
                name: 'Umang',
                phone: '03117786264',
                displayPhone: '0311-7786264',
              ),
              _helplineButton(
                name: 'Rozan',
                phone: '03041111741',
                displayPhone: '0304-1111741',
              ),
              _helplineButton(
                name: 'Taskeen',
                phone: '03168275336',
                displayPhone: '0316-8275336',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _helplineButton({
    required String name,
    required String phone,
    required String displayPhone,
  }) {
    return Semantics(
      label: 'Call $name helpline at $displayPhone',
      button: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: InkWell(
          onTap: () => _makeCall(phone),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.phone_in_talk_rounded,
                  size: 16,
                  color: Color(0xFFC62828),
                ),
                const SizedBox(width: 6),
                Text(
                  '$name: $displayPhone',
                  style: AppTheme.body12.copyWith(
                    color: const Color(0xFFC62828),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
