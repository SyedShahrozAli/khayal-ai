import 'package:go_router/go_router.dart';

import '../model/journal_entry.dart';
import 'journal_screen.dart';
import 'journal_write_screen.dart';

List<RouteBase> journalRoutes() {
  return [
    GoRoute(
      path: '/journal/edit',
      builder: (context, state) =>
          JournalWriteScreen(existing: state.extra as JournalEntry?),
    ),
  ];
}

const journalScreen = JournalScreen();
