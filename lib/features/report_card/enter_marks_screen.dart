import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/reference_api.dart';
import '../../core/api/report_card_api.dart';
import '../../core/models/reference.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/widgets/pill_chip.dart';

class EnterMarksScreen extends StatefulWidget {
  const EnterMarksScreen({super.key, required this.studentId, required this.studentName});
  final String studentId;
  final String studentName;

  @override
  State<EnterMarksScreen> createState() => _EnterMarksScreenState();
}

class _EnterMarksScreenState extends State<EnterMarksScreen> {
  List<SubjectRef> _subjects = [];
  SubjectRef? _subject;
  final _term = TextEditingController(text: 'सत्र 1');
  final _marks = TextEditingController();
  final _maxMarks = TextEditingController(text: '100');
  final _remarks = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final subjects = await ReferenceApi.subjects();
      if (!mounted) return;
      setState(() {
        _subjects = subjects;
        _subject = subjects.isEmpty ? null : subjects.first;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _term.dispose();
    _marks.dispose();
    _maxMarks.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final marks = double.tryParse(_marks.text.trim());
    final maxMarks = double.tryParse(_maxMarks.text.trim()) ?? 100;
    if (_subject == null || _term.text.trim().isEmpty || marks == null) {
      setState(() => _error = 'विषय, सत्र और अंक भरें।');
      return;
    }
    if (marks > maxMarks) {
      setState(() => _error = 'प्राप्त अंक अधिकतम अंक से अधिक नहीं हो सकते।');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ReportCardApi.upsertMark(
        studentId: widget.studentId,
        subjectId: _subject!.id,
        term: _term.text.trim(),
        marksObtained: marks,
        maxMarks: maxMarks,
        remarks: _remarks.text.trim().isEmpty ? null : _remarks.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiError catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: Text('अंक जोड़ें — ${widget.studentName}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('विषय', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _subjects.map((s) => PillChip(label: s.name, selected: s.id == _subject?.id, onTap: () => setState(() => _subject = s))).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('सत्र', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
                  const SizedBox(height: 6),
                  TextField(controller: _term, decoration: const InputDecoration(hintText: 'जैसे सत्र 1, वार्षिक')),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('प्राप्त अंक', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
                            const SizedBox(height: 6),
                            TextField(controller: _marks, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('अधिकतम अंक', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
                            const SizedBox(height: 6),
                            TextField(controller: _maxMarks, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('टिप्पणी (वैकल्पिक)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
                  const SizedBox(height: 6),
                  TextField(controller: _remarks),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, style: const TextStyle(fontSize: 12.5, color: MedhaColors.danger)),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('सहेजें'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
