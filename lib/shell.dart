import 'package:flutter/material.dart';
import 'home_page.dart';
import 'tasks_page.dart';
import 'study_page.dart';
import 'notes_page.dart';
import 'more_page.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;
  late final pages = <Widget>[
    HomePage(onNav: (x) => setState(() => i = x)),
    const TasksPage(),
    const StudyPage(),
    const NotesPage(),
    const MorePage(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: i, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: i,
          onDestinationSelected: (x) => setState(() => i = x),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.checklist), label: 'Tasks'),
            NavigationDestination(icon: Icon(Icons.timer), label: 'Study'),
            NavigationDestination(icon: Icon(Icons.note_alt), label: 'Notes'),
            NavigationDestination(icon: Icon(Icons.apps), label: 'More'),
          ],
        ),
      );
}
