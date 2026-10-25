import 'package:flutter/material.dart';
import 'store.dart';
import 'crud_page.dart';
import 'page_header.dart';
import 'calendar_page.dart';
import 'profile_page.dart';
import 'timetable_page.dart';
import 'gpa_page.dart';
import 'ai_page.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          int n(String k) => store.list(k).length;
          final now = DateTime.now();
          final today0 = DateTime(now.year, now.month, now.day);
          final items = <(String, IconData, String, Widget)>[
            ('Timetable', Icons.schedule, '${n('classes')} classes', const TimetablePage()),
            ('Subjects & Grades', Icons.school, '${n('subjects')} subjects',
                CrudPage(
                  title: 'Subjects & Grades', k: 'subjects', tk: 'name',
                  icon: Icons.school, color: const Color(0xFF7B1FA2),
                  empty: 'Add your subjects and track your grades here.',
                  fields: const [F('name', 'Subject'), F('grade', 'Grade / Marks'), F('notes', 'Notes', 'm')],
                  sub: (s) => 'Grade: ${s['grade'] ?? '-'}  ${s['notes'] ?? ''}',
                )),
            ('Exam Countdown', Icons.hourglass_bottom, '${n('exams')} exams',
                CrudPage(
                  title: 'Exam Countdown', k: 'exams', tk: 'name',
                  icon: Icons.hourglass_bottom, color: const Color(0xFFE65100),
                  empty: 'No exams added. Add one and watch the countdown!',
                  fields: const [F('name', 'Exam'), F('date', 'Exam date', 'd')],
                  sub: (e) {
                    if (e['date'] == null) return 'No date';
                    final d = DateTime.parse(e['date']).difference(today0).inDays;
                    return d < 0 ? 'Finished' : (d == 0 ? 'Today!' : '$d days left');
                  },
                )),
            ('Calendar', Icons.calendar_month, 'See your month', const CalendarPage()),
            ('Goals', Icons.flag, '${n('goals')} goals',
                CrudPage(
                  title: 'Goals', k: 'goals', tk: 'title', check: true,
                  icon: Icons.flag, color: const Color(0xFFC2185B),
                  empty: 'Set a goal. Big dreams start with one line!',
                  fields: const [F('title', 'Goal'), F('date', 'Target date', 'd')],
                  sub: (g) => g['date'] == null ? '' : 'Target ${fd(g['date'])}',
                )),
            ('GPA Calculator', Icons.calculate, 'Know your GPA', const GpaPage()),
            ('AI Study Buddy', Icons.auto_awesome, 'Ask or get quizzed', const AiPage()),
            ('Profile & Settings', Icons.person, 'Level up!', const ProfilePage()),
          ];
          return Scaffold(
            body: ListView(padding: EdgeInsets.zero, children: [
              const PageHeader(
                  title: 'More', subtitle: 'Everything else you need', icon: Icons.apps, color: Color(0xFF1E6FBF)),
              GridView.count(
                crossAxisCount: 2, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.05,
                children: [
                  for (var i = 0; i < items.length; i++)
                    InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => items[i].$4)),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                              colors: [palette[i % palette.length], palette[i % palette.length].withOpacity(0.7)]),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Icon(items[i].$2, color: Colors.white, size: 36),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(items[i].$1, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(items[i].$3, style: const TextStyle(color: Colors.white70)),
                          ]),
                        ]),
                      ),
                    ),
                ],
              ),
            ]),
          );
        },
      );
}
