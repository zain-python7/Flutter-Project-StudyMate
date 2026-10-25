import 'package:flutter/material.dart';
import 'store.dart';
import 'splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.init();
  runApp(const StudyMateApp());
}

class StudyMateApp extends StatelessWidget {
  const StudyMateApp({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (_, __) => MaterialApp(
          title: 'StudyMate',
          debugShowCheckedModeBanner: false,
          themeMode: store.get('dark', false) ? ThemeMode.dark : ThemeMode.light,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: const Splash(),
        ),
      );
}


ThemeData _theme(Brightness b) => ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      colorSchemeSeed: const Color(0xFF1E6FBF),
      brightness: b,
    );
