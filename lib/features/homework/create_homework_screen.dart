import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/homework_api.dart';
import '../../core/api/profile_api.dart';
import '../../core/models/profile.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/pill_chip.dart';

class CreateHomeworkScreen extends StatefulWidget {
  const CreateHomeworkScreen({super.key});

  @override
  State<CreateHomeworkScreen> createState() => _CreateHomeworkScreenState();
}

class _CreateHomeworkScreenState extends State<CreateHomeworkScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  List<ProfileSubject> _subjects = [];
  ProfileSubject? _selected;
  DateTime? _dueDate;
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
      final profile = await ProfileApi.get();
      if (!mounted) return;
      setState(() {
        _subjects = profile.subjects;
        _selected = profile.subjects.isEmpty ? null : profile.subjects.first;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (_selected == null || _title.text.trim().isEmpty) {
      setState(() => _error = 'कक्षा चुनें और शीर्षक लिखें।');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await HomeworkApi.create(
        gradeId: _selected!.gradeId,
        subjectId: _selected!.subjectId,
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        dueDate: _dueDate,
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
      appBar: AppBar(title: const Text('नया होमवर्क')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('कक्षा व विषय', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
                  const SizedBox(height: 8),
                  if (_subjects.isEmpty)
                    const Text('प्रोफ़ाइल में कोई विषय नहीं जुड़ा।', style: TextStyle(color: MedhaColors.muted))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _subjects
                          .map((s) => PillChip(
                                label: '${s.subjectName} · ${s.gradeLabel}',
                                selected: s.subjectId == _selected?.subjectId && s.gradeId == _selected?.gradeId,
                                onTap: () => setState(() => _selected = s),
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 18),
                  const Text('शीर्षक', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
                  const SizedBox(height: 6),
                  TextField(controller: _title, decoration: const InputDecoration(hintText: 'जैसे पाठ 4 के प्रश्न 1-5')),
                  const SizedBox(height: 14),
                  const Text('विवरण (वैकल्पिक)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
                  const SizedBox(height: 6),
                  TextField(controller: _description, maxLines: 3),
                  const SizedBox(height: 14),
                  const Text('अंतिम तिथि (वैकल्पिक)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: MedhaColors.inkSoft)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(MedhaRadii.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(border: Border.all(color: MedhaColors.borderStrong, width: 1.5), borderRadius: BorderRadius.circular(MedhaRadii.md)),
                      child: Text(
                        _dueDate == null ? 'तारीख चुनें' : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                        style: TextStyle(fontSize: 14, color: _dueDate == null ? MedhaColors.muted : MedhaColors.ink),
                      ),
                    ),
                  ),
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
                          : const Text('भेजें'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
