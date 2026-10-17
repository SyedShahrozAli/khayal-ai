import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../extensions/build_context_extension.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../community/ui/community_screen.dart';
import '../../journal/ui/journal_screen.dart';
import '../../profile/ui/profile_screen.dart';
import '../../progress/ui/progress_screen.dart';
import '../../wellness/ui/wellness_library_screen.dart';
import '../model/main_tab.dart';
import 'home_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentTabIndex = 0;

  List<Widget> get _screens => [
    HomeScreen(
      onTabChange: (index) {
        setState(() => _currentTabIndex = index);
      },
    ),
    const JournalScreen(),
    const Scaffold(body: Center(child: Text('Chat'))),
    const WellnessLibraryScreen(),
    const ProgressScreen(),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentTabIndex, children: _screens),
          Positioned(
            left: 1,
            right: 1,
            bottom: MediaQuery.paddingOf(context).bottom,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: context.secondaryWidgetColor,
                borderRadius: const BorderRadius.all(Radius.circular(15)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: MainTab.values.map(_buildNavItem).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(MainTab tab) {
    final isSelected = _currentTabIndex == tab.index;
    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = tab.index),
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? context.secondaryBackgroundColor : null,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Column(
          children: [
            if (tab.iconData is IconData)
              Icon(
                tab.iconData as IconData,
                color: isSelected
                    ? AppColors.blueberry100
                    : (Theme.of(context).iconTheme.color ?? Colors.black),
              )
            else
              HugeIcon(
                icon: tab.iconData as List<List<dynamic>>,
                color: isSelected
                    ? AppColors.blueberry100
                    : (Theme.of(context).iconTheme.color ?? Colors.black),
              ),
            const SizedBox(height: 4),
            Text(
              context.tr(tab.labelKey),
              style: AppTheme.body12.copyWith(
                color: isSelected ? AppColors.blueberry100 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
