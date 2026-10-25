import 'package:flutter/material.dart';
import 'store.dart';

/// Gives XP, marks today as active and shows a reward popup (with level-up).
Future<void> rewardXp(BuildContext c, int amount, String why) async {
  final old = store.get<int>('xp', 0);
  store.d['xp'] = old + amount;
  markActive();
  store.save();
  final now = store.get<int>('xp', 0);
  if (!c.mounted) return;
  await showDialog(context: c, builder: (_) => _Reward(old: old, now: now, amount: amount, why: why));
}

class _Reward extends StatelessWidget {
  final int old, now, amount;
  final String why;
  const _Reward({required this.old, required this.now, required this.amount, required this.why});

  double _frac(int xp, int l) => (xp - xpForLevel(l)) / (xpForLevel(l + 1) - xpForLevel(l));

  @override
  Widget build(BuildContext context) {
    final l0 = levelOf(old), l1 = levelOf(now), up = l1 > l0;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Icon(up ? Icons.emoji_events : Icons.stars, size: 90, color: Colors.amber),
          ),
          Text(up ? 'LEVEL UP!' : why, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (up) Text('You reached Level $l1 • ${rankOf(l1)}'),
          const SizedBox(height: 8),
          Text('+$amount XP',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          if (now - old - amount == 10) const Text('+10 XP first activity of the day'),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: up ? 0.0 : _frac(old, l0), end: _frac(now, l1)),
            duration: const Duration(milliseconds: 900),
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: v.clamp(0.0, 1.0).toDouble(), minHeight: 12),
            ),
          ),
          const SizedBox(height: 6),
          Text('$now XP • ${xpForLevel(l1 + 1) - now} XP to Level ${l1 + 1}'),
          const SizedBox(height: 14),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Awesome!')),
        ]),
      ),
    );
  }
}
