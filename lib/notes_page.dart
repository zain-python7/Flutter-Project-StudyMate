import 'package:flutter/material.dart';
import 'crud_page.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});
  @override
  Widget build(BuildContext context) => CrudPage(
        title: 'Notes', k: 'notes', tk: 'title',
        icon: Icons.note_alt, color: const Color(0xFFE65100),
        empty: 'Your notes live here. Jot down your first idea!',
        fields: const [F('title', 'Title'), F('body', 'Write your note', 'm')],
        sub: (t) => '${t['body'] ?? ''}',
      );
}
