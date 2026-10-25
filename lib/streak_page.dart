import 'package:flutter/material.dart';
import 'store.dart';
import 'page_header.dart';

const _orange = Color(0xFFFF7043);
const _ice = Color(0xFF81D4FA);
const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class StreakPage extends StatefulWidget {
  const StreakPage({super.key});
  @override
  State<StreakPage> createState() => _StreakState();
}

class _StreakState extends State<StreakPage> {
  late DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final act = store.activeDays().toSet(), frozen = frozenDays();
    final s = currentStreak(), b = bestStreak();
    final todayK = dayKey(now);
    final dates = (store.activeDays().map(parseDay).toList()..sort());
    final blanks = DateTime(month.year, month.month, 1).weekday - 1;
    final dim = DateTime(month.year, month.month + 1, 0).day;
    var monthActive = 0;
    for (var d = 1; d <= dim; d++) {
      if (act.contains(dayKey(DateTime(month.year, month.month, d)))) monthActive++;
    }

    String status;
    if (dates.isEmpty || s == 0) {
      status = 'No active streak. Study or finish a task today to start one!';
    } else {
      final since = parseDay(todayK).difference(dates.last).inDays;
      status = since == 0
          ? 'You are on fire! Today is done.'
          : since == 1
              ? 'Do something today to keep your streak growing.'
              : 'Frozen for ${since - 1} day(s). Come back within ${8 - since} day(s) or your streak resets to zero.';
    }

    Widget cell(int d) {
      final dt = DateTime(month.year, month.month, d);
      final k = dayKey(dt);
      final on = act.contains(k), fz = frozen.contains(k);
      return Container(
        margin: const EdgeInsets.all(3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? _orange : (fz ? _ice : null),
          border: k == todayK ? Border.all(color: _orange, width: 2) : null,
        ),
        child: on
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : fz
                ? const Icon(Icons.ac_unit, color: Colors.white, size: 18)
                : Text('$d', style: TextStyle(color: dt.isAfter(now) ? Colors.grey : null)),
      );
    }

    Widget stat(IconData i, String v, String l) => Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(children: [
                Icon(i, color: _orange),
                Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(l, style: const TextStyle(fontSize: 11)),
              ]),
            ),
          ),
        );

    return Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        PageHeader(
            title: '$s day streak', subtitle: status,
            icon: Icons.local_fire_department, color: _orange),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              stat(Icons.local_fire_department, '$s', 'Current'),
              stat(Icons.emoji_events, '$b', 'Best'),
              stat(Icons.calendar_today, '${dates.length}', 'Active days'),
              stat(Icons.ac_unit, '${frozen.length}', 'Frozen days'),
            ]),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Row(children: [
                    IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setState(() => month = DateTime(month.year, month.month - 1))),
                    Expanded(
                      child: Text('${_months[month.month - 1]} ${month.year}',
                          textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: (month.year == now.year && month.month == now.month)
                            ? null
                            : () => setState(() => month = DateTime(month.year, month.month + 1))),
                  ]),
                  Row(children: [
                    for (final c in 'MTWTFSS'.split(''))
                      Expanded(child: Center(child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)))),
                  ]),
                  GridView.count(
                    crossAxisCount: 7, shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (var i = 0; i < blanks; i++) const SizedBox(),
                      for (var d = 1; d <= dim; d++) cell(d),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 16, children: const [
                    Chip(avatar: CircleAvatar(backgroundColor: _orange, radius: 6), label: Text('Active')),
                    Chip(avatar: CircleAvatar(backgroundColor: _ice, radius: 6), label: Text('Frozen')),
                  ]),
                  Text('You were active $monthActive day(s) in ${_months[month.month - 1]}.'),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Activity log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (dates.isEmpty) const Text('Nothing yet. Your first active day will appear here.'),
                  for (final dt in dates.reversed.take(10))
                    ListTile(
                      dense: true, contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle, color: _orange),
                      title: Text('${_wd[dt.weekday - 1]}, ${dt.day} ${_months[dt.month - 1]} ${dt.year}'),
                      trailing: const Text('Online'),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Builder(builder: (_) {
              const marks = [3, 7, 14, 30, 60, 100];
              final done = s >= marks.last;
              final next = marks.firstWhere((m) => m > s, orElse: () => marks.last);
              final prev = marks.lastWhere((m) => m <= s, orElse: () => 0);
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Streak milestones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(done ? 'Legendary! You passed every milestone.' : '${next - s} more active day(s) to reach $next days'),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                          value: done ? 1.0 : ((s - prev) / (next - prev)).clamp(0.0, 1.0).toDouble(),
                          minHeight: 10, color: _orange),
                    ),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, children: [
                      for (final m in marks)
                        Chip(
                          avatar: Icon(b >= m ? Icons.emoji_events : Icons.lock_outline,
                              size: 18, color: b >= m ? Colors.amber : Colors.grey),
                          label: Text('$m days'),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    const Text('Every new active day also earns +10 XP.'),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 24),
          ]),
        ),
      ]),
    );
  }
}
