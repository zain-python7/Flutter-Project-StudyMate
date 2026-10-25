import 'package:flutter/material.dart';
import 'store.dart';
import 'xp.dart';
import 'page_header.dart';

const _subjects = ['General', 'Math', 'Science', 'English', 'Computer', 'History', 'Other'];
const _prios = ['Low', 'Medium', 'High'];
const _names = ['Pending', 'Today', 'Overdue', 'Done'];
const _empty = [
  'No pending tasks. Tap New task to add one!',
  'Nothing due today. Enjoy it!',
  'No overdue tasks. Great job staying on track!',
  'Finish a task to see it here.',
];

Color _pc(String p) => p == 'High'
    ? const Color(0xFFC62828)
    : p == 'Low'
        ? const Color(0xFF2E8B57)
        : const Color(0xFFF9A825);

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});
  @override
  State<TasksPage> createState() => _TasksState();
}

class _TasksState extends State<TasksPage> {
  int filter = 0;

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime _dayPlus(int n) => DateTime(_today.year, _today.month, _today.day + n);

  int? _diff(Map t) {
    if (t['due'] == null) return null;
    final d = DateTime.parse(t['due']);
    return DateTime(d.year, d.month, d.day).difference(_today).inDays;
  }

  bool _match(Map t, int f) {
    final done = t['done'] == true;
    final d = _diff(t);
    switch (f) {
      case 0:
        return !done;
      case 1:
        return !done && d == 0;
      case 2:
        return !done && d != null && d < 0;
      default:
        return done;
    }
  }

  (String, Color) _dueInfo(Map t) {
    final d = _diff(t);
    if (d == null) return ('No date', Colors.grey);
    if (t['done'] == true) return (fd(t['due']), Colors.grey);
    if (d < 0) return ('Overdue ${-d}d', const Color(0xFFC62828));
    if (d == 0) return ('Today', const Color(0xFFE65100));
    if (d == 1) return ('Tomorrow', const Color(0xFF1E6FBF));
    return ('In $d days', const Color(0xFF00838F));
  }

  void _toggle(BuildContext c, Map<String, dynamic> t, bool? x) {
    t['done'] = x;
    if (x == true && t['xpd'] != true) {
      t['xpd'] = true;
      rewardXp(c, 20, 'Task completed!');
    } else {
      if (x == true) markActive();
      store.save();
    }
  }

  Future<void> _confirmDelete(BuildContext c, Map<String, dynamic> t) async {
    final ok = await showDialog<bool>(
      context: c,
      builder: (d) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Remove "${t['title']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      store.list('tasks').remove(t);
      store.save();
    }
  }

  void _edit(BuildContext c, [Map<String, dynamic>? it]) {
    final v = Map<String, dynamic>.from(it ?? {'prio': 'Medium', 'subject': 'General'});
    final tc = TextEditingController(text: '${v['title'] ?? ''}');
    showModalBottomSheet(
      context: c,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) {
          final due = v['due'] == null ? null : DateTime.parse(v['due']);
          bool isDay(int n) => due != null && DateTime(due.year, due.month, due.day) == _dayPlus(n);
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(it == null ? 'New task' : 'Edit task', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextField(
                  controller: tc, autofocus: it == null,
                  decoration: const InputDecoration(labelText: 'What do you need to do?', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                const Text('Subject', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(spacing: 8, children: [
                  for (final s in _subjects)
                    ChoiceChip(label: Text(s), selected: v['subject'] == s, onSelected: (_) => ss(() => v['subject'] = s)),
                ]),
                const SizedBox(height: 10),
                const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                SegmentedButton<String>(
                  segments: [for (final p in _prios) ButtonSegment(value: p, label: Text(p))],
                  selected: {v['prio'] ?? 'Medium'},
                  onSelectionChanged: (s) => ss(() => v['prio'] = s.first),
                ),
                const SizedBox(height: 10),
                const Text('Due date', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(spacing: 8, children: [
                  ChoiceChip(label: const Text('Today'), selected: isDay(0), onSelected: (_) => ss(() => v['due'] = _dayPlus(0).toIso8601String())),
                  ChoiceChip(label: const Text('Tomorrow'), selected: isDay(1), onSelected: (_) => ss(() => v['due'] = _dayPlus(1).toIso8601String())),
                  ActionChip(
                    avatar: const Icon(Icons.event, size: 18),
                    label: Text(due != null && !isDay(0) && !isDay(1) ? fd(v['due']) : 'Pick date'),
                    onPressed: () async {
                      final d = await showDatePicker(
                          context: ctx, initialDate: due ?? _today,
                          firstDate: _today.subtract(const Duration(days: 365)), lastDate: _today.add(const Duration(days: 365 * 5)));
                      if (d != null) ss(() => v['due'] = d.toIso8601String());
                    },
                  ),
                  if (due != null) ActionChip(label: const Text('Clear'), onPressed: () => ss(() => v.remove('due'))),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      v['title'] = tc.text.trim();
                      if ('${v['title']}'.isEmpty) return;
                      final l = store.list('tasks');
                      if (it == null) {
                        l.add(v);
                      } else {
                        l[l.indexOf(it)] = v;
                      }
                      store.save();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save task'),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _pill(String t, Color c, [IconData? i]) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (i != null) ...[Icon(i, size: 12, color: c), const SizedBox(width: 3)],
          Text(t, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      );

  @override
  Widget build(BuildContext c) => ListenableBuilder(
        listenable: store,
        builder: (c, _) {
          final all = store.list('tasks');
          final done = all.where((t) => t['done'] == true).length;
          final shown = all.where((t) => _match(t, filter)).toList()
            ..sort((a, b) {
              final da = _diff(a), db = _diff(b);
              if (da != db) {
                if (da == null) return 1;
                if (db == null) return -1;
                return da.compareTo(db);
              }
              return _prios.indexOf(b['prio'] ?? 'Medium').compareTo(_prios.indexOf(a['prio'] ?? 'Medium'));
            });
          return Scaffold(
            floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _edit(c), icon: const Icon(Icons.add), label: const Text('New task')),
            body: ListView(padding: const EdgeInsets.only(bottom: 90), children: [
              PageHeader(
                title: 'Tasks', icon: Icons.checklist, color: const Color(0xFF1E6FBF),
                subtitle: '$done of ${all.length} completed',
                extra: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                        value: all.isEmpty ? 0 : done / all.length, minHeight: 10,
                        backgroundColor: Colors.white24, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text('Finish a task to earn +20 XP', style: TextStyle(color: Colors.white70)),
                ]),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(children: [
                  for (var i = 0; i < 4; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${_names[i]} (${all.where((t) => _match(t, i)).length})'),
                        selected: filter == i,
                        onSelected: (_) => setState(() => filter = i),
                      ),
                    ),
                ]),
              ),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(children: [
                    Icon(filter == 3 ? Icons.emoji_events : Icons.task_alt, size: 90, color: const Color(0xFF1E6FBF).withOpacity(0.35)),
                    const SizedBox(height: 14),
                    Text(_empty[filter], textAlign: TextAlign.center, style: Theme.of(c).textTheme.titleMedium),
                  ]),
                ),
              for (final t in shown)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Dismissible(
                    key: ObjectKey(t),
                    background: Container(
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      store.list('tasks').remove(t);
                      store.save();
                    },
                    child: Card(
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: IntrinsicHeight(
                        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Container(width: 6, color: t['done'] == true ? Colors.grey : _pc(t['prio'] ?? 'Medium')),
                          Expanded(
                            child: InkWell(
                              onTap: () => _edit(c, t),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                                child: Row(children: [
                                  Checkbox(
                                    shape: const CircleBorder(),
                                    value: t['done'] == true,
                                    onChanged: (x) => _toggle(c, t, x),
                                  ),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('${t['title']}',
                                          style: TextStyle(
                                              fontSize: 15, fontWeight: FontWeight.w600,
                                              color: t['done'] == true ? Colors.grey : null,
                                              decoration: t['done'] == true ? TextDecoration.lineThrough : null)),
                                      const SizedBox(height: 6),
                                      Wrap(spacing: 6, runSpacing: 4, children: [
                                        _pill('${t['subject'] ?? 'General'}', palette[_subjects.indexOf('${t['subject'] ?? 'General'}').clamp(0, 5) % palette.length], Icons.book),
                                        _pill(_dueInfo(t).$1, _dueInfo(t).$2, Icons.schedule),
                                        _pill('${t['prio'] ?? 'Medium'}', _pc(t['prio'] ?? 'Medium'), Icons.flag),
                                        if (t['done'] != true && t['xpd'] != true) _pill('+20 XP', const Color(0xFFF9A825), Icons.bolt),
                                      ]),
                                    ]),
                                  ),
                                  IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _confirmDelete(c, t)),
                                ]),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
            ]),
          );
        },
      );
}
