import 'package:go_router/go_router.dart';

import '../model/journal_entry.dart';
import 'journal_editor_screen.dart';
import 'journal_screen.dart';

List<RouteBase> journalRoutes() {
  return [
    GoRoute(
      path: '/journal/edit',
      builder: (context, state) =>
          JournalEditorScreen(entry: state.extra as JournalEntry?),
    ),
  ];
}

const journalScreen = JournalScreen();
