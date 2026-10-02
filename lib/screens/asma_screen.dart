import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../theme/app_theme.dart';

class AsmaScreen extends StatelessWidget {
  const AsmaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = QuranRepository.instance.asma;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Asmaul Husna')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final a = items[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(gradient: Grad.gold, borderRadius: BorderRadius.circular(14)),
                    child: Text('${a.number}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.transliteration, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                        const SizedBox(height: 2),
                        Text(a.en, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.75))),
                        if (a.id.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(a.id, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(a.arabic, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 26, color: AppColors.emerald)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
