import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

const palette = [
  Color(0xFF1E6FBF), Color(0xFF2E8B57), Color(0xFFE65100),
  Color(0xFF7B1FA2), Color(0xFFC2185B), Color(0xFF00838F),
];

/// SQLite storage. Tables: items(kind, data) and settings(k, v).
/// Data is cached in memory (d) so the UI stays fast; save() writes to SQLite.
class Store extends ChangeNotifier {
  Map<String, dynamic> d = {};
  late Database db;
  Future<void> _q = Future.value();

  Future<void> init() async {
    db = await openDatabase('${await getDatabasesPath()}/razormate.db', version: 1,
        onCreate: (db, v) async {
      await db.execute('CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, kind TEXT, data TEXT)');
      await db.execute('CREATE TABLE settings(k TEXT PRIMARY KEY, v TEXT)');
    });
    for (final r in await db.query('settings')) {
      d[r['k'] as String] = jsonDecode(r['v'] as String);
    }
    for (final r in await db.query('items', orderBy: 'id')) {
      (d[r['kind'] as String] ??= <dynamic>[]).add(jsonDecode(r['data'] as String));
    }
  }

  List<Map<String, dynamic>> list(String k) =>
      ((d[k] ??= <dynamic>[]) as List).cast<Map<String, dynamic>>();
  List<String> activeDays() => ((d['days'] ??= <dynamic>[]) as List).cast<String>();
  T get<T>(String k, T def) => (d[k] ?? def) as T;
  void set(String k, dynamic v) {
    d[k] = v;
    save();
  }

  void save() {
    notifyListeners();
    _q = _q.then((_) => _write());
  }

  Future<void> _write() async {
    final b = db.batch();
    b.delete('items');
    b.delete('settings');
    d.forEach((k, v) {
      if (v is List) {
        for (final e in v) {
          b.insert('items', {'kind': k, 'data': jsonEncode(e)});
        }
      } else {
        b.insert('settings', {'k': k, 'v': jsonEncode(v)});
      }
    });
    await b.commit(noResult: true);
  }
}

final store = Store();

ImageProvider avatarImage() {
  final a = store.get<String>('avatar', '');
  if (a.isEmpty) return const AssetImage('assets/icon.png');
  return MemoryImage(base64Decode(a));
}

String fd(String s) {
  final d = DateTime.parse(s);
  return '${d.day}/${d.month}/${d.year}';
}

String todayKey() {
  final n = DateTime.now();
  return '${n.year}-${n.month}-${n.day}';
}

void logStudy(int m) {
  store.d['studyMin'] = store.get<int>('studyMin', 0) + m;
  final t = todayKey();
  store.d['st'] = (store.get<String>('sd', '') == t ? store.get<int>('st', 0) : 0) + m;
  store.d['sd'] = t;
  final ad = store.activeDays();
  if (!ad.contains(t)) {
    ad.add(t);
    store.d['xp'] = store.get<int>('xp', 0) + 10;
  }
  store.d['xp'] = store.get<int>('xp', 0) + 1;
  store.save();
}

int studiedToday() => store.get<String>('sd', '') == todayKey() ? store.get<int>('st', 0) : 0;

String dayKey(DateTime n) => '${n.year}-${n.month}-${n.day}';

/// Call when the student does something useful today (study or finish a task).
void markActive() {
  final l = store.activeDays(), k = todayKey();
  if (!l.contains(k)) {
    l.add(k);
    store.d['xp'] = store.get<int>('xp', 0) + 10;
    store.save();
  }
}

DateTime parseDay(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime.utc(p[0], p[1], p[2]);
}


// ---- XP & levels ----
int levelOf(int xp) => sqrt(xp / 50).floor() + 1;
int xpForLevel(int l) => 50 * (l - 1) * (l - 1);
const rankNames = ['Rookie', 'Learner', 'Scholar', 'Achiever', 'Master', 'Genius', 'Legend'];
String rankOf(int l) => rankNames[min(l - 1, rankNames.length - 1)];

// ---- Streaks (Duolingo style with freezes) ----
// Missed days inside a streak are "frozen": the streak is kept.
// After 7 missed days in a row the streak resets to 0.
List<List<DateTime>> _chains() {
  final l = store.activeDays().map(parseDay).toList()..sort();
  final out = <List<DateTime>>[];
  for (final d in l) {
    if (out.isNotEmpty && d.difference(out.last.last).inDays < 8) {
      out.last.add(d);
    } else {
      out.add([d]);
    }
  }
  return out;
}

int currentStreak() {
  final c = _chains();
  if (c.isEmpty) return 0;
  return parseDay(todayKey()).difference(c.last.last).inDays >= 8 ? 0 : c.last.length;
}

int bestStreak() => _chains().fold<int>(0, (m, c) => c.length > m ? c.length : m);

Set<String> frozenDays() {
  final out = <String>{};
  final c = _chains();
  for (final ch in c) {
    for (var i = 1; i < ch.length; i++) {
      final gap = ch[i].difference(ch[i - 1]).inDays;
      for (var k = 1; k < gap; k++) {
        out.add(dayKey(ch[i - 1].add(Duration(days: k))));
      }
    }
  }
  if (c.isNotEmpty) {
    final last = c.last.last;
    final since = parseDay(todayKey()).difference(last).inDays;
    if (since < 8) {
      for (var k = 1; k < since; k++) {
        out.add(dayKey(last.add(Duration(days: k))));
      }
    }
  }
  return out;
}
