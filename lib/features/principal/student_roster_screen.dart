import 'package:flutter/material.dart';

import '../../core/api/principal_api.dart';
import '../../core/models/principal.dart';
import '../../core/theme/medha_colors.dart';

class StudentRosterScreen extends StatefulWidget {
  const StudentRosterScreen({super.key});

  @override
  State<StudentRosterScreen> createState() => _StudentRosterScreenState();
}

class _StudentRosterScreenState extends State<StudentRosterScreen> {
  List<PrincipalStudentItem> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final students = await PrincipalApi.students();
      if (!mounted) return;
      setState(() {
        _students = students;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: const Text('छात्र सूची')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
          : _students.isEmpty
              ? const Center(child: Text('अभी कोई स्वीकृत छात्र नहीं है', style: TextStyle(color: MedhaColors.muted)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _students.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, i) {
                      final s = _students[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(color: MedhaColors.surface, border: Border.all(color: MedhaColors.border), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: MedhaColors.primaryWash),
                              alignment: Alignment.center,
                              child: Text(s.fullName.isEmpty ? '?' : s.fullName.substring(0, 1), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: MedhaColors.primary)),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.fullName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                                  Text(
                                    '${s.gradeLabel}${s.rollNumber != null ? ' · रोल ${s.rollNumber}' : ''}',
                                    style: const TextStyle(fontSize: 11, color: MedhaColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              s.activated ? 'सक्रिय' : 'सक्रिय नहीं',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: s.activated ? MedhaColors.muted : MedhaColors.accentInk),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
