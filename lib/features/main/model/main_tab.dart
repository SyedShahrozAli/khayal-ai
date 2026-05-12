import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/generated/locale_keys.g.dart';
import 'package:hugeicons/hugeicons.dart';

enum MainTab {
  home(HugeIcons.strokeRoundedHome01, LocaleKeys.menuHome),
  journal(HugeIcons.strokeRoundedBook02, LocaleKeys.menuJournal),
  chat(HugeIcons.strokeRoundedMessage01, LocaleKeys.menuChat),
  community(HugeIcons.strokeRoundedUserGroup, LocaleKeys.menuCommunity),
  settings(HugeIcons.strokeRoundedSettings01, LocaleKeys.menuSettings);


  const MainTab(this.iconData, this.labelKey);

  final dynamic iconData;
  final String labelKey;
}
