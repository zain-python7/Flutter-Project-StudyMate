import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final Widget? extra;
  const PageHeader(
      {super.key, required this.title, required this.subtitle, required this.icon,
      required this.color, this.extra});
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.7)]),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: Column(children: [
          Row(children: [
            if (Navigator.canPop(context))
              IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context)),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ]),
            ),
            Icon(icon, size: 56, color: Colors.white54),
          ]),
          if (extra != null) Padding(padding: const EdgeInsets.only(top: 12), child: extra),
        ]),
      );
}
