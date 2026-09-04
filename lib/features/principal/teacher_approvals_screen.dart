import 'package:flutter/material.dart';

import '../../core/api/principal_api.dart';
import '../../core/models/principal.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/medha_card.dart';
import '../../core/widgets/medha_icon.dart';

class TeacherApprovalsScreen extends StatefulWidget {
  const TeacherApprovalsScreen({super.key});

  @override
  State<TeacherApprovalsScreen> createState() => _TeacherApprovalsScreenState();
}

class _TeacherApprovalsScreenState extends State<TeacherApprovalsScreen> {
  List<PendingTeacher> _pending = [];
  bool _loading = true;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final pending = await PrincipalApi.pendingTeachers();
      if (!mounted) return;
      setState(() {
        _pending = pending;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(String id) async {
    setState(() => _busyId = id);
    try {
      await PrincipalApi.approveTeacher(id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('शिक्षक स्वीकृत हुए।')));
      await _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('कुछ गड़बड़ हो गई।')));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _reject(String id) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _ReasonDialog(),
    );
    if (reason == null || reason.trim().isEmpty) return;
    setState(() => _busyId = id);
    try {
      await PrincipalApi.rejectTeacher(id, reason.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('आवेदन अस्वीकृत हुआ।')));
      await _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('कुछ गड़बड़ हो गई।')));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(
        leading: IconButton(icon: const MedhaIcon('chevron_left', color: MedhaColors.ink), onPressed: () => Navigator.of(context).pop()),
        title: const Text('शिक्षक आवेदन'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
          : _pending.isEmpty
              ? const Center(child: Text('कोई लंबित आवेदन नहीं है', style: TextStyle(color: MedhaColors.muted)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pending.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final t = _pending[i];
                    final busy = _busyId == t.id;
                    return MedhaCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: MedhaColors.primaryWash),
                                alignment: Alignment.center,
                                child: Text(t.fullName.isEmpty ? '?' : t.fullName.substring(0, 1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: MedhaColors.primary)),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                    Text(
                                      [if (t.employeeCode != null) 'कोड ${t.employeeCode}', if (t.yearsOfExperience != null) '${t.yearsOfExperience} वर्ष अनुभव'].join(' · '),
                                      style: const TextStyle(fontSize: 11.5, color: MedhaColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: busy ? null : () => _approve(t.id),
                                  icon: const MedhaIcon('shield_check', size: 14, color: Colors.white),
                                  label: const Text('स्वीकृत करें'),
                                  style: ElevatedButton.styleFrom(backgroundColor: MedhaColors.success),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: busy ? null : () => _reject(t.id),
                                  style: OutlinedButton.styleFrom(foregroundColor: MedhaColors.danger, side: const BorderSide(color: MedhaColors.danger, width: 1.5)),
                                  child: const Text('अस्वीकृत करें'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: MedhaColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MedhaRadii.lg)),
      title: const Text('अस्वीकृति का कारण'),
      content: TextField(
        controller: _reason,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(hintText: 'संक्षेप में कारण लिखें'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('रद्द करें')),
        TextButton(onPressed: () => Navigator.of(context).pop(_reason.text), child: const Text('अस्वीकृत करें')),
      ],
    );
  }
}
