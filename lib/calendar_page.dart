import 'package:flutter/material.dart';
import 'store.dart';
import 'page_header.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarState();
}

class _CalendarState extends State<CalendarPage> {
  DateTime sel = DateTime.now();
  @override
  Widget build(BuildContext context) {
    final items = <(IconData, Color, String)>[];
    void scan(String k, String dk, String tk, String tag, IconData ic, Color col) {
      for (final e in store.list(k)) {
        if (e[dk] == null) continue;
        final d = DateTime.parse(e[dk]);
        if (d.year == sel.year && d.month == sel.month && d.day == sel.day) items.add((ic, col, '$tag: ${e[tk]}'));
      }
    }

    scan('tasks', 'due', 'title', 'Task', Icons.checklist, const Color(0xFF1E6FBF));
    scan('exams', 'date', 'name', 'Exam', Icons.hourglass_bottom, const Color(0xFFE65100));
    scan('goals', 'date', 'title', 'Goal', Icons.flag, const Color(0xFFC2185B));
    return Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        const PageHeader(
            title: 'Calendar', subtitle: 'Tasks, exams and goals by date',
            icon: Icons.calendar_month, color: Color(0xFFC2185B)),
        CalendarDatePicker(
          initialDate: sel, firstDate: DateTime(2020), lastDate: DateTime(2035),
          onDateChanged: (d) => setState(() => sel = d),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text('${sel.day}/${sel.month}/${sel.year}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Column(children: [
              Icon(Icons.event_available, size: 64, color: Colors.grey),
              SizedBox(height: 8),
              Text('Free day! Nothing scheduled.'),
            ]),
          ),
        for (final it in items)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: it.$2, child: Icon(it.$1, color: Colors.white, size: 20)),
              title: Text(it.$3),
            ),
          ),
        const SizedBox(height: 24),
      ]),
    );
  }
}
