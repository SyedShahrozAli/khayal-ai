import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/features/main/ui/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../extensions/build_context_extension.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../common/ui/widgets/material_ink_well.dart';
import '../../journal/ui/journal_screen.dart';
import '../../profile/ui/profile_screen.dart';
import '../model/main_tab.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentTabIndex = 0;

  void _onTabChange(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onTabChange: _onTabChange),
      const JournalScreen(),
      const Scaffold(body: Center(child: Text('Chat'))),
      const Scaffold(body: Center(child: Text('Community'))),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentTabIndex,
            children: screens,
          ),
          Positioned(
            left: 1,
            right: 1,
            bottom: MediaQuery.paddingOf(context).bottom,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: context.secondaryWidgetColor,
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: MainTab.values
                          .map((tab) => _buildNavItem(tab))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(MainTab tab) {
    final isSelected = _currentTabIndex == tab.index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTabIndex = tab.index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? context.secondaryBackgroundColor : null,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Column(
          children: [
            HugeIcon(
              icon: tab.iconData,
              color: isSelected ? AppColors.blueberry100 : (Theme.of(context).iconTheme.color ?? Colors.black),
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
