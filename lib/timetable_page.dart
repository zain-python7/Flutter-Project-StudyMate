import 'package:flutter/material.dart';
import 'crud_page.dart';

const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class TimetablePage extends StatelessWidget {
  const TimetablePage({super.key});
  @override
  Widget build(BuildContext context) => CrudPage(
        title: 'Timetable', k: 'classes', tk: 'subject',
        icon: Icons.schedule, color: const Color(0xFF2E8B57),
        empty: 'Your week is a blank page. Add your classes!',
        fields: const [F('subject', 'Subject'), F('day', 'Day', 'o', days), F('time', 'Time (9:00-10:00)'), F('room', 'Room')],
        sub: (t) => '${t['day'] ?? days.first} • ${t['time'] ?? ''} • ${t['room'] ?? ''}',
      );
}
