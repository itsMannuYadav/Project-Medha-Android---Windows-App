import 'package:flutter/material.dart';

import '../../core/theme/medha_colors.dart';
import '../../core/widgets/medha_card.dart';

/// Web parity for `/tools/pdf-qa` — local preview helper until a dedicated
/// backend endpoint exists. Teachers paste text from a PDF and get study prompts.
class PdfQaScreen extends StatefulWidget {
  const PdfQaScreen({super.key});

  @override
  State<PdfQaScreen> createState() => _PdfQaScreenState();
}

class _PdfQaScreenState extends State<PdfQaScreen> {
  final _text = TextEditingController();
  final _question = TextEditingController();
  String? _answer;

  @override
  void dispose() {
    _text.dispose();
    _question.dispose();
    super.dispose();
  }

  void _run() {
    final doc = _text.text.trim();
    final q = _question.text.trim();
    if (doc.isEmpty || q.isEmpty) {
      setState(() => _answer = 'दस्तावेज़ और प्रश्न दोनों भरें।');
      return;
    }
    // Lightweight local extractive answer: find sentences containing question keywords.
    final keywords = q.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 3).toList();
    final sentences = doc.split(RegExp(r'(?<=[.!?।])\s+'));
    final hits = sentences.where((s) {
      final lower = s.toLowerCase();
      return keywords.any(lower.contains);
    }).take(3).toList();
    setState(() {
      _answer = hits.isEmpty
          ? 'इस पाठ में सीधा उत्तर नहीं मिला। AI जनरेशन (क्विज़/नोट्स) आज़माएं।'
          : hits.join('\n\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: const Text('PDF से सवाल-जवाब')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('PDF का पाठ यहाँ पेस्ट करें', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
          const SizedBox(height: 6),
          TextField(controller: _text, maxLines: 8, decoration: const InputDecoration(hintText: 'पाठ सामग्री…')),
          const SizedBox(height: 14),
          const Text('आपका प्रश्न', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
          const SizedBox(height: 6),
          TextField(controller: _question, decoration: const InputDecoration(hintText: 'जैसे — प्रकाश संश्लेषण क्या है?')),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _run, child: const Text('उत्तर खोजें')),
          if (_answer != null) ...[
            const SizedBox(height: 16),
            MedhaCard(child: Text(_answer!, style: const TextStyle(fontSize: 13.5, height: 1.5))),
          ],
        ],
      ),
    );
  }
}
