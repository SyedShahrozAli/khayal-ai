import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

enum MainTab {
  home(HugeIcons.strokeRoundedHome01, 'menuHome'),
  journal(HugeIcons.strokeRoundedBook02, 'menuJournal'),
  chat(HugeIcons.strokeRoundedMessage01, 'menuChat'),
  wellness(Icons.spa_outlined, 'menuWellness'),
  progress(Icons.insights_outlined, 'menuProgress'),
  community(HugeIcons.strokeRoundedUserGroup, 'menuCommunity'),
  settings(HugeIcons.strokeRoundedSettings01, 'menuSettings');

  const MainTab(this.iconData, this.labelKey);

  final Object iconData;
  final String labelKey;
}
