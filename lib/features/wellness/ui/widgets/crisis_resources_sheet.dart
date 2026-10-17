import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';

class CrisisResourcesSheet extends StatelessWidget {
  const CrisisResourcesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const CrisisResourcesSheet(),
    );
  }

  static const _helplines = [
    ('Umang Pakistan', '0311 7786264', 'tel:03117786264'),
    ('Rozan Helpline', '0800 22444', 'tel:080022444'),
    ('Pakistan Association for Mental Health', '021 111 726 111', 'tel:021111726111'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.mono20,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Need support now?', style: AppTheme.title20),
          const SizedBox(height: 8),
          Text(
            'Khayal is not emergency care. If you are in crisis, please contact a local helpline.',
            style: AppTheme.body14.copyWith(color: AppColors.mono60),
          ),
          const SizedBox(height: 16),
          ..._helplines.map(
            (line) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(line.$1, style: AppTheme.subtitle16),
              subtitle: Text(line.$2, style: AppTheme.body14),
              trailing: IconButton(
                icon: const Icon(Icons.phone_outlined),
                onPressed: () => launchUrl(Uri.parse(line.$3)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
