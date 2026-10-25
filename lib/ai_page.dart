import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'store.dart';
import 'config.dart';
import 'page_header.dart';

const _defaultModels = ['gemini-3.5-flash', 'gemini-2.5-flash', 'gemini-3.1-flash-lite'];

class AiPage extends StatefulWidget {
  const AiPage({super.key});
  @override
  State<AiPage> createState() => _AiState();
}

class _AiState extends State<AiPage> {
  final msgs = <(bool, String)>[]; // (isUser, text)
  final input = TextEditingController();
  final scroll = ScrollController();
  bool quiz = false, busy = false;

  String get _key {
    final own = store.get<String>('gkey', '');
    if (own.isNotEmpty) return own;
    return builtInGeminiKey == 'PASTE_YOUR_KEY_HERE' ? '' : builtInGeminiKey;
  }

  String get _sys => quiz
      ? 'You are a friendly quiz master for students. The student\'s first message is a topic. '
          'Ask ONE multiple-choice or short-answer question at a time, then wait. When they answer, say if it is '
          'correct, explain briefly, then ask the next question. Keep a running score. Use plain text only.'
      : 'You are a friendly, clear study tutor for students. Explain simply with short examples. '
          'Keep answers concise. Use plain text only, no markdown symbols.';

  String _clean(String t) => t.replaceAll('**', '').replaceAll(RegExp(r'^\* ', multiLine: true), '• ');

  void _down() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients) {
          scroll.animateTo(scroll.position.maxScrollExtent + 80,
              duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        }
      });

  Future<String> _call(String key) async {
    final saved = store.get<String>('gmodel', '');
    final models = [if (saved.isNotEmpty) saved, ..._defaultModels];
    for (final m in models) {
      final res = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$m:generateContent'),
        headers: {'Content-Type': 'application/json', 'x-goog-api-key': key},
        body: jsonEncode({
          'systemInstruction': {'parts': [{'text': _sys}]},
          'contents': [
            for (final x in msgs) {'role': x.$1 ? 'user' : 'model', 'parts': [{'text': x.$2}]}
          ],
        }),
      );
      final j = jsonDecode(res.body);
      if (res.statusCode == 404) continue; // model not available, try the next one
      if (res.statusCode != 200) return 'Error ${res.statusCode}: ${j['error']?['message'] ?? 'unknown'}';
      try {
        return _clean(j['candidates'][0]['content']['parts'][0]['text']);
      } catch (_) {
        return 'The AI sent an empty answer. Try asking again.';
      }
    }
    return 'No Gemini model worked with your key. Tap the key icon and type a model name from Google AI Studio.';
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? input.text).trim();
    if (text.isEmpty || busy) return;
    final key = _key;
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI is not set up yet.')));
      return;
    }
    setState(() {
      msgs.add((true, text));
      busy = true;
      input.clear();
    });
    _down();
    String reply;
    try {
      reply = await _call(key);
    } catch (_) {
      reply = 'Network error. Please check your internet connection.';
    }
    if (!mounted) return;
    setState(() {
      msgs.add((false, reply));
      busy = false;
    });
    _down();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const col = Color(0xFF00838F);
    final tips = quiz
        ? ['Math', 'Biology', 'World history', 'English grammar']
        : ['Explain photosynthesis simply', 'Make me a study plan', 'Tips to beat exam stress'];
    return Scaffold(
      body: Column(children: [
        if (MediaQuery.of(context).viewInsets.bottom == 0)
        PageHeader(
          title: 'AI Study Buddy', icon: Icons.auto_awesome, color: col,
          subtitle: quiz ? 'Quiz mode: test yourself' : 'Ask me anything',
          extra: Row(children: [
            Expanded(
              child: SegmentedButton<bool>(
                style: SegmentedButton.styleFrom(
                    foregroundColor: Colors.white, selectedForegroundColor: col,
                    selectedBackgroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                segments: const [
                  ButtonSegment(value: false, icon: Icon(Icons.question_answer), label: Text('Ask')),
                  ButtonSegment(value: true, icon: Icon(Icons.quiz), label: Text('Quiz me')),
                ],
                selected: {quiz},
                onSelectionChanged: (s) => setState(() {
                  quiz = s.first;
                  msgs.clear();
                }),
              ),
            ),
          ]),
        )
        else SizedBox(height: MediaQuery.of(context).padding.top),
        Expanded(
          child: msgs.isEmpty
              ? Center(
                  child: SingleChildScrollView(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.auto_awesome, size: 80, color: col.withOpacity(0.35)),
                      const SizedBox(height: 12),
                      Text(quiz ? 'Pick a topic and I will quiz you!' : 'Ask a question to get started',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, children: [
                        for (final t in tips)
                          ActionChip(label: Text(t), onPressed: () => _send(quiz ? 'Quiz me on $t' : t)),
                      ]),
                    ]),
                  )),
                )
              : ListView(controller: scroll, padding: const EdgeInsets.all(12), children: [
                  for (final m in msgs)
                    Align(
                      alignment: m.$1 ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: m.$1 ? col : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SelectableText(m.$2, style: TextStyle(color: m.$1 ? Colors.white : null)),
                      ),
                    ),
                  if (busy) const Padding(padding: EdgeInsets.all(8), child: Align(alignment: Alignment.centerLeft, child: Text('Thinking...'))),
                ]),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: input,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                      hintText: quiz && msgs.isNotEmpty ? 'Type your answer' : (quiz ? 'Type a topic' : 'Ask a question'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24))),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: busy ? null : _send, icon: const Icon(Icons.send)),
            ]),
          ),
        ),
      ]),
    );
  }
}
