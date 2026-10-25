import 'package:flutter/material.dart';
import 'store.dart';
import 'page_header.dart';

const gp = {
  'A+': 4.0, 'A': 4.0, 'A-': 3.7, 'B+': 3.3, 'B': 3.0, 'B-': 2.7,
  'C+': 2.3, 'C': 2.0, 'C-': 1.7, 'D': 1.0, 'F': 0.0,
};

Color gradeColor(String g) => g.startsWith('A')
    ? const Color(0xFF2E8B57)
    : g.startsWith('B')
        ? const Color(0xFF1E6FBF)
        : g.startsWith('C')
            ? const Color(0xFFE65100)
            : const Color(0xFFC62828);

String remarkFor(double g) => g >= 3.7
    ? 'Outstanding work!'
    : g >= 3.3
        ? 'Excellent!'
        : g >= 3.0
            ? 'Very good, keep it up!'
            : g >= 2.0
                ? 'Good. A little more effort will lift it.'
                : 'Needs improvement. You can do it!';

String _f(double v) => v.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

class _Row {
  final name = TextEditingController();
  int credits = 3;
  String? grade;
}

class GpaPage extends StatefulWidget {
  const GpaPage({super.key});
  @override
  State<GpaPage> createState() => _GpaState();
}

class _GpaState extends State<GpaPage> {
  final rows = List.generate(6, (_) => _Row());
  final scroll = ScrollController();
  List<(String, int, String, double)>? snap; // subject, credits, grade, points

  (double, int, int) _live() {
    double qp = 0;
    int cr = 0, n = 0;
    for (final r in rows) {
      if (r.grade == null) continue;
      qp += r.credits * gp[r.grade!]!;
      cr += r.credits;
      n++;
    }
    return (cr == 0 ? 0.0 : qp / cr, cr, n);
  }

  void _calc() {
    FocusScope.of(context).unfocus();
    final r = <(String, int, String, double)>[];
    for (var i = 0; i < rows.length; i++) {
      final x = rows[i];
      if (x.grade == null) continue;
      final n = x.name.text.trim().isEmpty ? 'Subject ${i + 1}' : x.name.text.trim();
      r.add((n, x.credits, x.grade!, gp[x.grade!]!));
    }
    if (r.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick a grade for at least one subject')));
      return;
    }
    setState(() => snap = r);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
      }
    });
  }

  void _clear() => setState(() {
        for (final x in rows) {
          x.name.clear();
          x.credits = 3;
          x.grade = null;
        }
        snap = null;
      });

  Widget _subject(int i) {
    final r = rows[i];
    return Card(
      key: ObjectKey(r),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
                radius: 14, backgroundColor: palette[i % palette.length],
                child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 13))),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: r.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                decoration: const InputDecoration(hintText: 'Subject name', border: InputBorder.none),
              ),
            ),
            if (rows.length > 1)
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setState(() => rows.removeAt(i))),
          ]),
          Row(children: [
            const Text('Credit hours'),
            const Spacer(),
            IconButton.filledTonal(
                onPressed: r.credits > 1 ? () => setState(() => r.credits--) : null, icon: const Icon(Icons.remove)),
            SizedBox(width: 34, child: Center(child: Text('${r.credits}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
            IconButton.filledTonal(
                onPressed: r.credits < 10 ? () => setState(() => r.credits++) : null, icon: const Icon(Icons.add)),
            const SizedBox(width: 6),
          ]),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final g in gp.keys)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(g),
                    showCheckmark: false,
                    selected: r.grade == g,
                    selectedColor: gradeColor(g),
                    labelStyle: TextStyle(color: r.grade == g ? Colors.white : null, fontWeight: FontWeight.w600),
                    onSelected: (_) => setState(() => r.grade = r.grade == g ? null : g),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _report(BuildContext context) {
    final r = snap!;
    final totalCr = r.fold<int>(0, (a, e) => a + e.$2);
    final totalQp = r.fold<double>(0, (a, e) => a + e.$2 * e.$4);
    final gpa = totalQp / totalCr;
    final best = r.reduce((a, b) => a.$4 >= b.$4 ? a : b);
    final worst = r.reduce((a, b) => a.$4 <= b.$4 ? a : b);
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.assignment_turned_in, color: primary),
            const SizedBox(width: 8),
            const Text('Your GPA Report', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 14),
          for (final e in r)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(
                      radius: 17, backgroundColor: gradeColor(e.$3),
                      child: Text(e.$3, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${e.$2} credits × ${_f(e.$4)} points', style: const TextStyle(fontSize: 12)),
                    ]),
                  ),
                  Text(_f(e.$2 * e.$4), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: e.$4 / 4, minHeight: 6, color: gradeColor(e.$3)),
                ),
              ]),
            ),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total credits'), Text('$totalCr', style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total quality points'), Text(_f(totalQp), style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: primary.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              const Text('GPA = quality points ÷ credits', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text('${_f(totalQp)} ÷ $totalCr = ${gpa.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary)),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.trending_up, color: Color(0xFF2E8B57)),
            const SizedBox(width: 8),
            Expanded(child: Text('Strongest: ${best.$1} (${best.$3})')),
          ]),
          if (r.length > 1 && worst.$4 < best.$4) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.flag, color: Color(0xFFE65100)),
              const SizedBox(width: 8),
              Expanded(child: Text('Focus on: ${worst.$1} (${worst.$3})')),
            ]),
          ],
          const SizedBox(height: 10),
          Text(remarkFor(gpa), style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (gpa, cr, n) = _live();
    return Scaffold(
      body: ListView(controller: scroll, padding: EdgeInsets.zero, children: [
        PageHeader(
          title: 'GPA Calculator', subtitle: 'Pick grades and watch your GPA grow',
          icon: Icons.calculate, color: const Color(0xFF00838F),
          extra: Row(children: [
            SizedBox(
              width: 92, height: 92,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: gpa / 4),
                    duration: const Duration(milliseconds: 400),
                    builder: (_, v, __) => CircularProgressIndicator(
                        value: v, strokeWidth: 9, backgroundColor: Colors.white24, color: Colors.white),
                  ),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(gpa.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const Text('/ 4.0', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ]),
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n == 0 ? 'Pick grades to see your GPA' : remarkFor(gpa),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$n subject(s) • $cr credits', style: const TextStyle(color: Colors.white70)),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            for (var i = 0; i < rows.length; i++) _subject(i),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => rows.add(_Row())),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add subject'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _calc,
                icon: const Icon(Icons.calculate),
                label: const Text('Calculate GPA', style: TextStyle(fontSize: 16)),
              ),
            ),
            TextButton(onPressed: _clear, child: const Text('Clear all')),
            if (snap != null) _report(context),
            const SizedBox(height: 24),
          ]),
        ),
      ]),
    );
  }
}
