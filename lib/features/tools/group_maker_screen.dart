import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/data/demo_roster.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/medha_card.dart';
import '../../core/widgets/medha_icon.dart';

/// Splits the class roster into random groups — genuinely functional,
/// no LLM call needed, matching the equivalent client-side tool in the
/// Next.js app.
class GroupMakerScreen extends StatefulWidget {
  const GroupMakerScreen({super.key});

  @override
  State<GroupMakerScreen> createState() => _GroupMakerScreenState();
}

class _GroupMakerScreenState extends State<GroupMakerScreen> {
  int _groupSize = 4;
  List<List<String>>? _groups;

  void _shuffle() {
    final students = List<String>.from(demoRoster)..shuffle(Random());
    final groups = <List<String>>[];
    for (var i = 0; i < students.length; i += _groupSize) {
      groups.add(students.sublist(i, (i + _groupSize).clamp(0, students.length)));
    }
    setState(() => _groups = groups);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: const Text('ग्रुप बनाएं')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('कक्षा 8 · अनुभाग A — कुल ${demoRoster.length} छात्र', style: const TextStyle(fontSize: 12.5, color: MedhaColors.muted)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('प्रति समूह छात्र', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(border: Border.all(color: MedhaColors.borderStrong, width: 1.5), borderRadius: BorderRadius.circular(MedhaRadii.md)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const MedhaIcon('minus', size: 14, color: MedhaColors.inkSoft), onPressed: () => setState(() => _groupSize = (_groupSize - 1).clamp(2, 8))),
                      SizedBox(width: 24, child: Text('$_groupSize', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700))),
                      IconButton(icon: const MedhaIcon('plus', size: 14, color: MedhaColors.inkSoft), onPressed: () => setState(() => _groupSize = (_groupSize + 1).clamp(2, 8))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _shuffle, child: Text(_groups == null ? 'ग्रुप बनाएं' : 'फिर से बनाएं'))),
            const SizedBox(height: 20),
            Expanded(
              child: _groups == null
                  ? const Center(child: Text('ऊपर बटन दबाकर समूह बनाएं', style: TextStyle(color: MedhaColors.muted)))
                  : ListView.separated(
                      itemCount: _groups!.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final g = _groups![i];
                        return MedhaCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('समूह ${i + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: MedhaColors.primary)),
                              const SizedBox(height: 6),
                              Text(g.join(', '), style: const TextStyle(fontSize: 13.5, color: MedhaColors.ink, height: 1.5)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
