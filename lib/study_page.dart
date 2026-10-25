import 'dart:async';
import 'package:flutter/material.dart';
import 'store.dart';
import 'xp.dart';

class StudyPage extends StatefulWidget {
  const StudyPage({super.key});
  @override
  State<StudyPage> createState() => _StudyState();
}

class _StudyState extends State<StudyPage> {
  bool onBreak = false;
  int focus = 25, brk = 5, studyLeft = 25 * 60, breakLeft = 5 * 60, tick = 0;
  Timer? t;

  int get left => onBreak ? breakLeft : studyLeft;
  int get total => (onBreak ? brk : focus) * 60;
  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  void _msg(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  void _stop() {
    t?.cancel();
    t = null;
  }

  void _start() {
    _stop();
    t = Timer.periodic(const Duration(seconds: 1), (_) {
      var minute = false;
      setState(() {
        if (onBreak) {
          breakLeft--;
        } else {
          studyLeft--;
          minute = ++tick % 60 == 0;
        }
      });
      if (minute) logStudy(1);
      if (left <= 0) _done();
    });
    setState(() {});
  }

  // Study ends -> break starts automatically. Break ends -> study resumes automatically.
  void _done() {
    _stop();
    if (onBreak) {
      setState(() {
        onBreak = false;
        breakLeft = brk * 60;
      });
      _msg('Break over! Back to studying.');
    } else {
      setState(() {
        onBreak = true;
        studyLeft = focus * 60;
        breakLeft = brk * 60;
      });
      rewardXp(context, 10, 'Focus session complete!');
    }
    _start();
  }

  void _switch(bool b) {
    _stop();
    setState(() => onBreak = b);
  }

  void _reset() {
    _stop();
    setState(() {
      studyLeft = focus * 60;
      breakLeft = brk * 60;
      tick = 0;
    });
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = onBreak ? const Color(0xFF2E8B57) : const Color(0xFF1E6FBF);
    final running = t != null;
    Widget mini(IconData i, String v, String l) => Expanded(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Icon(i, color: c),
                Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(l),
              ]),
            ),
          ),
        );
    return Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c, c.withOpacity(0.7)]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Column(children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, icon: Icon(Icons.menu_book), label: Text('Study')),
                ButtonSegment(value: true, icon: Icon(Icons.free_breakfast), label: Text('Break')),
              ],
              selected: {onBreak},
              onSelectionChanged: (s) => _switch(s.first),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 220, height: 220,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(
                    child: CircularProgressIndicator(
                        value: left / total, strokeWidth: 12, backgroundColor: Colors.white24, color: Colors.white)),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_fmt(left), style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.bold)),
                  Text(onBreak ? 'Relax and recharge' : 'Stay focused', style: const TextStyle(color: Colors.white70)),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: c),
                onPressed: running ? () { _stop(); setState(() {}); } : _start,
                icon: Icon(running ? Icons.pause : Icons.play_arrow),
                label: Text(running ? 'Pause' : 'Start'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                onPressed: _reset,
                child: const Text('Reset'),
              ),
            ]),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (onBreak && studyLeft < focus * 60)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: Text('Study paused at ${_fmt(studyLeft)}'),
                  subtitle: const Text('It will resume automatically when your break ends.'),
                ),
              ),
            const SizedBox(height: 8),
            Text(onBreak ? 'Break length' : 'Study length', style: const TextStyle(fontWeight: FontWeight.bold)),
            Wrap(spacing: 8, children: [
              for (final m in (onBreak ? [5, 10, 15] : [15, 25, 45, 60]))
                ChoiceChip(
                  label: Text('$m min'),
                  selected: (onBreak ? brk : focus) == m,
                  onSelected: (_) {
                    _stop();
                    setState(() {
                      if (onBreak) {
                        brk = m;
                        breakLeft = m * 60;
                      } else {
                        focus = m;
                        studyLeft = m * 60;
                        tick = 0;
                      }
                    });
                  },
                ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              mini(Icons.today, '${studiedToday()}', 'min today'),
              mini(Icons.emoji_events, '${store.get<int>('studyMin', 0)}', 'min total'),
            ]),
          ]),
        ),
      ]),
    );
  }
}
