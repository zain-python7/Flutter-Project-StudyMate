import 'package:flutter/material.dart';
import 'store.dart';
import 'timetable_page.dart';
import 'streak_card.dart';
import 'ai_page.dart';

const _quotes = [
  'Small steps every day add up to big results.',
  'Focus on progress, not perfection.',
  'Future you will thank you for studying today.',
  'Discipline beats motivation. Start now.',
  'One more chapter. You have got this.',
  'Dream big, study smart.',
  'Hard work beats talent when talent does not work hard.',
  'Every expert was once a beginner.',
  'Do it tired. Do it scared. Just do it.',
  'Your only limit is the effort you skip today.',
  'Consistency turns average into excellent.',
  'Study now, celebrate later.',
  'A little progress each day is still progress.',
  'Mistakes are proof that you are trying.',
  "Today's effort is tomorrow's result.",
  'You do not need to be perfect, just persistent.',
  'Stay patient. Great grades grow slowly.',
  'The best time to start was yesterday. The next best is now.',
  'Be proud of how far you have come.',
  'Success is the sum of small efforts repeated daily.',
];

class HomePage extends StatelessWidget {
  final void Function(int) onNav;
  const HomePage({super.key, required this.onNav});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final now = DateTime.now();
          final today0 = DateTime(now.year, now.month, now.day);
          DateTime dt(Map e, String k) => DateTime.parse(e[k]);

          final tasks = store.list('tasks');
          final pending = tasks.where((t) => t['done'] != true).toList()
            ..sort((a, b) => a['due'] == null
                ? 1
                : b['due'] == null
                    ? -1
                    : dt(a, 'due').compareTo(dt(b, 'due')));
          final overdue = pending.where((t) => t['due'] != null && dt(t, 'due').isBefore(today0)).length;
          final goals = store.list('goals');
          final goalsDone = goals.where((g) => g['done'] == true).length;
          final studied = studiedToday();
          const goalMin = 60;
          final exams = store.list('exams').where((e) => e['date'] != null && !dt(e, 'date').isBefore(today0)).toList()
            ..sort((a, b) => dt(a, 'date').compareTo(dt(b, 'date')));
          final todayName = days[now.weekday - 1];
          final classes = store.list('classes').where((c) => (c['day'] ?? days.first) == todayName).toList();
          final h = now.hour;
          final greet = h < 12 ? 'Good morning' : (h < 17 ? 'Good afternoon' : 'Good evening');
          final name = store.get<String>('name', '');
          final qi = store.get<int>('qi', now.difference(DateTime(now.year)).inDays);
          final quote = _quotes[qi % _quotes.length];

          return Scaffold(
            body: ListView(padding: EdgeInsets.zero, children: [
              Container(
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF1E6FBF), Color(0xFF2E8B57)]),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('$greet,', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      Text(name.isEmpty ? 'Student' : name,
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => store.set('qi', qi + 1),
                        child: Row(children: [
                          Expanded(child: Text(quote, style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic))),
                          const SizedBox(width: 6),
                          const Icon(Icons.refresh, size: 16, color: Colors.white70),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(radius: 32, backgroundColor: Colors.white, backgroundImage: avatarImage()),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: _Stat(Icons.pending_actions, '${pending.length}', 'Pending tasks',
                        const [Color(0xFF1E6FBF), Color(0xFF4A90D9)], () => onNav(1))),
                    const SizedBox(width: 12),
                    Expanded(child: _Stat(Icons.warning_amber_rounded, '$overdue', 'Overdue',
                        const [Color(0xFFE65100), Color(0xFFFF8A50)], () => onNav(1))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _Stat(Icons.task_alt, '${tasks.length - pending.length}', 'Tasks done',
                        const [Color(0xFF2E8B57), Color(0xFF5CBF8A)], () => onNav(1))),
                    const SizedBox(width: 12),
                    Expanded(child: _Stat(Icons.flag, '$goalsDone/${goals.length}', 'Goals achieved',
                        const [Color(0xFF7B1FA2), Color(0xFFB45FD0)], () => onNav(4))),
                  ]),
                  const SizedBox(height: 16),
                  const StreakCard(),
                  const SizedBox(height: 12),
                  _aiCard(context),
                  const SizedBox(height: 12),
                  _card(Icons.timer, 'Study today', [
                    Text('$studied / $goalMin min', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(value: (studied / goalMin).clamp(0, 1).toDouble(), minHeight: 10),
                    ),
                    const SizedBox(height: 8),
                    Text(studied >= goalMin ? 'Daily goal reached. Great job!' : '${goalMin - studied} min to reach today\'s goal'),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonal(onPressed: () => onNav(2), child: const Text('Start studying')),
                    ),
                  ]),
                  _card(Icons.hourglass_bottom, 'Next exam', [
                    if (exams.isEmpty)
                      const Text('No upcoming exams. Add one in More > Exam Countdown.')
                    else ...[
                      Text('${exams.first['name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      Text(
                        dt(exams.first, 'date').difference(today0).inDays == 0
                            ? 'Today. Good luck!'
                            : '${dt(exams.first, 'date').difference(today0).inDays} days left',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ]),
                  _card(Icons.schedule, 'Today\'s classes ($todayName)', [
                    if (classes.isEmpty) const Text('No classes today. Enjoy your free time!'),
                    for (final c in classes)
                      ListTile(dense: true, contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.class_), title: Text('${c['subject']}'),
                          subtitle: Text('${c['time'] ?? ''} ${c['room'] ?? ''}')),
                  ]),
                  _card(Icons.checklist, 'Up next', [
                    if (pending.isEmpty) const Text('All caught up. Nothing pending!'),
                    for (final t in pending.take(3))
                      ListTile(dense: true, contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.radio_button_unchecked), title: Text('${t['title']}'),
                          subtitle: Text('${t['subject'] ?? ''}${t['due'] != null ? ' • Due ${fd(t['due'])}' : ''}')),
                    Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => onNav(1), child: const Text('See all'))),
                  ]),
                ]),
              ),
            ]),
          );
        },
      );

  Widget _aiCard(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiPage())),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00838F), Color(0xFF26C6DA)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(children: [
            Icon(Icons.auto_awesome, color: Colors.white, size: 36),
            SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AI Study Buddy', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Ask questions or quiz yourself', style: TextStyle(color: Colors.white70)),
              ]),
            ),
            Icon(Icons.chevron_right, color: Colors.white),
          ]),
        ),
      );

  Widget _card(IconData icon, String title, List<Widget> kids) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(icon), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 10),
            ...kids,
          ]),
        ),
      );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final List<Color> colors;
  final VoidCallback onTap;
  const _Stat(this.icon, this.value, this.label, this.colors, this.onTap);
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white70)),
          ]),
        ),
      );
}
