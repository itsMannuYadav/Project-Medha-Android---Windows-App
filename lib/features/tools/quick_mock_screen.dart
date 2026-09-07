import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/medha_colors.dart';
import '../../core/widgets/medha_card.dart';

/// Web parity for `/tools/quick-mock` — client-side mock paper generator.
class QuickMockScreen extends StatefulWidget {
  const QuickMockScreen({super.key});

  @override
  State<QuickMockScreen> createState() => _QuickMockScreenState();
}

class _QuickMockScreenState extends State<QuickMockScreen> {
  final _topic = TextEditingController(text: 'विज्ञान');
  int _count = 5;
  List<String>? _questions;

  static const _templates = [
    '{topic} के मुख्य बिंदु क्या हैं?',
    '{topic} को सरल उदाहरण से समझाइए।',
    '{topic} से जुड़ा एक वास्तविक जीवन का उदाहरण दीजिए।',
    '{topic} में कौन-सी अवधारणा सबसे महत्वपूर्ण है और क्यों?',
    '{topic} पर लघु उत्तर लिखिए (50 शब्द)।',
    '{topic} में सामान्य गलतियाँ क्या हैं?',
    '{topic} की परिभाषा अपने शब्दों में लिखिए।',
    '{topic} से संबंधित एक आरेख बनाइए और लेबल कीजिए।',
  ];

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  void _generate() {
    final topic = _topic.text.trim().isEmpty ? 'विषय' : _topic.text.trim();
    final pool = List<String>.from(_templates)..shuffle(Random());
    setState(() {
      _questions = pool.take(_count).map((t) => t.replaceAll('{topic}', topic)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: const Text('त्वरित मॉक टेस्ट')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: _topic, decoration: const InputDecoration(hintText: 'विषय / अध्याय')),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('प्रश्न संख्या', style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('$_count'),
            ],
          ),
          Slider(
            value: _count.toDouble(),
            min: 3,
            max: 8,
            divisions: 5,
            activeColor: MedhaColors.primary,
            onChanged: (v) => setState(() => _count = v.round()),
          ),
          ElevatedButton(onPressed: _generate, child: const Text('पेपर बनाएं')),
          if (_questions != null) ...[
            const SizedBox(height: 16),
            for (var i = 0; i < _questions!.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MedhaCard(child: Text('${i + 1}. ${_questions![i]}', style: const TextStyle(fontSize: 13.5, height: 1.4))),
              ),
          ],
        ],
      ),
    );
  }
}
