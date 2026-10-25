import 'package:flutter/material.dart';
import 'store.dart';
import 'xp.dart';
import 'page_header.dart';

class F {
  final String k, label, type; // type: t text, m multiline, n number, d date, o options
  final List<String> opts;
  const F(this.k, this.label, [this.type = 't', this.opts = const []]);
}

class CrudPage extends StatelessWidget {
  final String title, k, tk;
  final List<F> fields;
  final String Function(Map<String, dynamic>) sub;
  final bool check;
  final IconData icon;
  final Color color;
  final String empty;
  final String Function(List<Map<String, dynamic>>)? summary;
  const CrudPage(
      {super.key, required this.title, required this.k, required this.tk,
      required this.fields, required this.sub, this.check = false,
      this.icon = Icons.list, this.color = const Color(0xFF1E6FBF), this.empty = 'Nothing here yet.', this.summary});

  Widget _field(BuildContext c, F f, Map v, TextEditingController t, StateSetter ss) {
    final dec = InputDecoration(labelText: f.label, border: const OutlineInputBorder());
    if (f.type == 'd') {
      return OutlinedButton.icon(
        icon: const Icon(Icons.event),
        label: Text(v[f.k] == null ? f.label : '${f.label}: ${fd(v[f.k])}'),
        onPressed: () async {
          final n = DateTime.now();
          final d = await showDatePicker(
              context: c, initialDate: n,
              firstDate: n.subtract(const Duration(days: 365)),
              lastDate: n.add(const Duration(days: 365 * 5)));
          if (d != null) ss(() => v[f.k] = d.toIso8601String());
        },
      );
    }
    if (f.type == 'o') {
      return DropdownButtonFormField<String>(
        value: v[f.k] ?? f.opts.first,
        decoration: dec,
        items: [for (final o in f.opts) DropdownMenuItem(value: o, child: Text(o))],
        onChanged: (x) => v[f.k] = x,
      );
    }
    return TextField(
      controller: t, decoration: dec,
      maxLines: f.type == 'm' ? 5 : 1,
      keyboardType: f.type == 'n' ? TextInputType.number : null,
    );
  }

  void _edit(BuildContext c, [Map<String, dynamic>? it]) {
    final v = Map<String, dynamic>.from(it ?? {});
    final ctl = {for (final f in fields) f.k: TextEditingController(text: '${v[f.k] ?? ''}')};
    showModalBottomSheet(
      context: c,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final f in fields)
                Padding(padding: const EdgeInsets.only(bottom: 12), child: _field(ctx, f, v, ctl[f.k]!, ss)),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    for (final f in fields) {
                      if (['t', 'm', 'n'].contains(f.type)) v[f.k] = ctl[f.k]!.text.trim();
                      if (f.type == 'o') v.putIfAbsent(f.k, () => f.opts.first);
                    }
                    if ('${v[tk] ?? ''}'.isEmpty) return;
                    final l = store.list(k);
                    if (it == null) {
                      l.add(v);
                    } else {
                      l[l.indexOf(it)] = v;
                    }
                    store.save();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext c) => ListenableBuilder(
        listenable: store,
        builder: (c, _) {
          final l = store.list(k);
          final done = l.where((e) => e['done'] == true).length;
          return Scaffold(
            floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _edit(c), icon: const Icon(Icons.add), label: const Text('Add')),
            body: ListView(padding: const EdgeInsets.only(bottom: 90), children: [
              PageHeader(
                title: title, icon: icon, color: color,
                subtitle: summary != null ? summary!(l) : (check ? '$done of ${l.length} completed' : '${l.length} saved'),
                extra: check && l.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                            value: done / l.length, minHeight: 8,
                            backgroundColor: Colors.white24, color: Colors.white))
                    : null,
              ),
              if (l.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(children: [
                    Icon(icon, size: 90, color: color.withOpacity(0.35)),
                    const SizedBox(height: 16),
                    Text(empty, textAlign: TextAlign.center, style: Theme.of(c).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text('Tap Add to get started'),
                  ]),
                ),
              for (var i = 0; i < l.length; i++)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Dismissible(
                    key: ObjectKey(l[i]),
                    background: Container(
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      l.remove(l[i]);
                      store.save();
                    },
                    child: Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: check
                            ? Checkbox(
                                value: l[i]['done'] == true,
                                onChanged: (x) {
                                  l[i]['done'] = x;
                                  store.save();
                                  if (x == true) {
                                    if (l[i]['xpd'] != true) {
                                      l[i]['xpd'] = true;
                                      rewardXp(c, k == 'goals' ? 50 : 20,
                                          k == 'goals' ? 'Goal achieved!' : 'Task completed!');
                                    } else {
                                      markActive();
                                    }
                                  }
                                })
                            : CircleAvatar(
                                backgroundColor: palette[i % palette.length],
                                child: Icon(icon, color: Colors.white, size: 20)),
                        title: Text('${l[i][tk]}',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: l[i]['done'] == true ? TextDecoration.lineThrough : null)),
                        subtitle: Text(sub(l[i]), maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete',
                          onPressed: () async {
                            final item = l[i];
                            final ok = await showDialog<bool>(
                              context: c,
                              builder: (d) => AlertDialog(
                                title: const Text('Delete?'),
                                content: Text('Remove "${item[tk]}"?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                                  FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Delete')),
                                ],
                              ),
                            );
                            if (ok == true) {
                              l.remove(item);
                              store.save();
                            }
                          },
                        ),
                        onTap: () => _edit(c, l[i]),
                      ),
                    ),
                  ),
                ),
            ]),
          );
        },
      );
}
