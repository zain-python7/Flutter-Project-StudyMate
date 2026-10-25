import 'package:flutter/material.dart';
import 'store.dart';
import 'streak_page.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({super.key});
  @override
  Widget build(BuildContext context) {
    final s = currentStreak(), b = bestStreak();
    final act = store.activeDays().toSet(), frozen = frozenDays();
    final now = DateTime.now();
    final doneToday = act.contains(dayKey(now));
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StreakPage())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF7043), Color(0xFFFFA726)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.local_fire_department, color: Colors.white, size: 44),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$s day streak', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(
                  s == 0
                      ? 'Study or finish a task today to start your streak!'
                      : (doneToday ? 'Done for today! Best: $b days' : 'Do something today to keep it. Best: $b'),
                  style: const TextStyle(color: Colors.white),
                ),
              ]),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            for (var i = 6; i >= 0; i--)
              Builder(builder: (_) {
                final day = now.subtract(Duration(days: i));
                final k = dayKey(day);
                final on = act.contains(k), fz = frozen.contains(k);
                return Column(children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: on ? Colors.white : (fz ? const Color(0xFF81D4FA) : Colors.white24),
                    child: on
                        ? const Icon(Icons.check, size: 16, color: Color(0xFFFF7043))
                        : (fz ? const Icon(Icons.ac_unit, size: 16, color: Colors.white) : null),
                  ),
                  const SizedBox(height: 4),
                  Text('MTWTFSS'[day.weekday - 1], style: const TextStyle(color: Colors.white, fontSize: 12)),
                ]);
              }),
          ]),
        ]),
      ),
    );
  }
}
