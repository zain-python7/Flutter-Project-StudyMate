import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'store.dart';
import 'page_header.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 400, imageQuality: 70);
    if (x != null) store.set('avatar', base64Encode(await x.readAsBytes()));
  }

  void _edit(BuildContext c) {
    final name = TextEditingController(text: store.get<String>('name', ''));
    final cls = TextEditingController(text: store.get<String>('class', ''));
    showModalBottomSheet(
      context: c,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Edit profile', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Your name', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: cls, decoration: const InputDecoration(labelText: 'Class / School', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                store.d['name'] = name.text.trim();
                store.set('class', cls.text.trim());
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _h(String t) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Align(alignment: Alignment.centerLeft, child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final mins = store.get<int>('studyMin', 0);
          final xp = store.get<int>('xp', 0);
          final level = levelOf(xp);
          final doneTasks = store.list('tasks').where((t) => t['done'] == true).length;
          final doneGoals = store.list('goals').where((t) => t['done'] == true).length;
          final notes = store.list('notes').length;
          final streak = currentStreak(), best = bestStreak();
          final dark = store.get<bool>('dark', false);
          final nm = store.get<String>('name', ''), cl = store.get<String>('class', '');
          final primary = Theme.of(context).colorScheme.primary;

          Widget tile(IconData i, String v, String l, Color c) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [c, c.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(children: [
                  Icon(i, color: Colors.white, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(v, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(l, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ),
                ]),
              );

          final badges = <(String, IconData, bool)>[
            ('First task', Icons.task_alt, doneTasks >= 1),
            ('Note taker', Icons.note_alt, notes >= 1),
            ('1 hour', Icons.timer, mins >= 60),
            ('Goal getter', Icons.flag, doneGoals >= 1),
            ('10 tasks', Icons.checklist, doneTasks >= 10),
            ('3-day streak', Icons.local_fire_department, best >= 3),
            ('7-day streak', Icons.whatshot, best >= 7),
            ('Level 5', Icons.military_tech, level >= 5),
          ];

          return Scaffold(
            body: ListView(padding: EdgeInsets.zero, children: [
              PageHeader(
                title: 'Profile', icon: Icons.person, color: const Color(0xFF7B1FA2),
                subtitle: 'Level $level • ${rankOf(level)} • $xp XP',
                extra: Column(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                        value: (xp - xpForLevel(level)) / (xpForLevel(level + 1) - xpForLevel(level)),
                        minHeight: 10, backgroundColor: Colors.white24, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text('${xpForLevel(level + 1) - xp} XP to Level ${level + 1}', style: const TextStyle(color: Colors.white)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Stack(children: [
                          CircleAvatar(radius: 40, backgroundImage: avatarImage()),
                          Positioned(
                            bottom: 0, right: 0,
                            child: InkWell(
                              onTap: _pick,
                              child: CircleAvatar(
                                  radius: 14, backgroundColor: primary,
                                  child: const Icon(Icons.camera_alt, size: 14, color: Colors.white)),
                            ),
                          ),
                        ]),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(nm.isEmpty ? 'Student' : nm, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            Text(cl.isEmpty ? 'Add your class or school' : cl),
                            const SizedBox(height: 6),
                            OutlinedButton.icon(
                                onPressed: () => _edit(context),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit profile')),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2, shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.3,
                    children: [
                      tile(Icons.task_alt, '$doneTasks', 'Tasks done', const Color(0xFF2E8B57)),
                      tile(Icons.flag, '$doneGoals', 'Goals achieved', const Color(0xFFC2185B)),
                      tile(Icons.note_alt, '$notes', 'Notes written', const Color(0xFFE65100)),
                      tile(Icons.timer, '$mins', 'Minutes studied', const Color(0xFF1E6FBF)),
                      tile(Icons.local_fire_department, '$streak', 'Day streak', const Color(0xFFFF7043)),
                      tile(Icons.emoji_events, '$best', 'Best streak', const Color(0xFF00838F)),
                    ],
                  ),
                  _h('Achievements'),
                  GridView.count(
                    crossAxisCount: 4, shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 0.85,
                    children: [
                      for (final b in badges)
                        Column(children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: b.$3 ? Colors.amber : Colors.grey.withOpacity(0.25),
                            child: Icon(b.$3 ? b.$2 : Icons.lock, color: b.$3 ? Colors.white : Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(b.$1, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 11)),
                        ]),
                    ],
                  ),
                  _h('Settings'),
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: SwitchListTile(
                      secondary: Icon(dark ? Icons.dark_mode : Icons.light_mode),
                      title: Text(dark ? 'Dark mode' : 'Light mode'),
                      subtitle: Text(dark ? 'Easy on the eyes at night' : 'Bright and clear'),
                      value: dark,
                      onChanged: (v) => store.set('dark', v),
                    ),
                  ),
                  _h('How to earn XP'),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(spacing: 8, runSpacing: 4, children: [
                      for (final e in const ['Task +20', 'Goal +50', 'Study +1 / min', 'Focus session +10', 'New day +10'])
                        Chip(avatar: const Icon(Icons.bolt, color: Colors.amber, size: 18), label: Text(e)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ]),
          );
        },
      );
}
