import 'package:flutter/material.dart';

import '../../core/api/principal_api.dart';
import '../../core/models/principal.dart';
import '../../core/theme/medha_colors.dart';

class TeacherRosterScreen extends StatefulWidget {
  const TeacherRosterScreen({super.key});

  @override
  State<TeacherRosterScreen> createState() => _TeacherRosterScreenState();
}

class _TeacherRosterScreenState extends State<TeacherRosterScreen> {
  List<TeacherRosterItem> _teachers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final teachers = await PrincipalApi.teachers();
      if (!mounted) return;
      setState(() {
        _teachers = teachers;
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
      appBar: AppBar(title: const Text('आपके शिक्षक')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
          : _teachers.isEmpty
              ? const Center(child: Text('अभी कोई स्वीकृत शिक्षक नहीं है', style: TextStyle(color: MedhaColors.muted)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _teachers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, i) {
                      final t = _teachers[i];
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
                              child: Text(t.fullName.isEmpty ? '?' : t.fullName.substring(0, 1), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: MedhaColors.primary)),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.fullName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                                  Text(
                                    [if (t.employeeCode != null) 'कोड ${t.employeeCode}', if (t.yearsOfExperience != null) '${t.yearsOfExperience} वर्ष अनुभव'].join(' · '),
                                    style: const TextStyle(fontSize: 11, color: MedhaColors.muted),
                                  ),
                                ],
                              ),
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
