import 'package:flutter/material.dart';

import '../../core/api/admin_api.dart';
import '../../core/models/admin.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/avatar_initials.dart';
import '../../core/widgets/medha_card.dart';
import '../../core/widgets/medha_icon.dart';
import '../../core/widgets/notification_bell.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminStats? _stats;
  List<PendingPrincipal> _pending = [];
  bool _loading = true;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([AdminApi.stats(), AdminApi.pendingPrincipals()]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as AdminStats;
        _pending = results[1] as List<PendingPrincipal>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(String id) async {
    setState(() => _busyId = id);
    try {
      await AdminApi.approvePrincipal(id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('प्रधानाचार्य स्वीकृत।')));
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
      builder: (_) => _ReasonDialog(),
    );
    if (reason == null || reason.trim().isEmpty) return;
    setState(() => _busyId = id);
    try {
      await AdminApi.rejectPrincipal(id, reason.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('अस्वीकृत।')));
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
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: const BoxDecoration(color: MedhaColors.surface, border: Border(bottom: BorderSide(color: MedhaColors.border))),
              child: const Row(
                children: [
                  Expanded(child: Text('मेधा एडमिन', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700))),
                  NotificationBell(),
                  SizedBox(width: 10),
                  AvatarInitials(initials: 'A'),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (_stats != null)
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.7,
                              children: [
                                _stat('${_stats!.schools}', 'स्कूल'),
                                _stat('${_stats!.principals}', 'प्रधानाचार्य'),
                                _stat('${_stats!.teachers}', 'शिक्षक'),
                                _stat('${_stats!.pendingPrincipals}', 'लंबित'),
                              ],
                            ),
                          const SizedBox(height: 20),
                          const Text('लंबित प्रधानाचार्य', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          if (_pending.isEmpty)
                            const Text('कोई लंबित आवेदन नहीं', style: TextStyle(color: MedhaColors.muted))
                          else
                            ..._pending.map((p) {
                              final busy = _busyId == p.id;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: MedhaCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                      Text('${p.schoolName} · ${p.districtName}', style: const TextStyle(fontSize: 11.5, color: MedhaColors.muted)),
                                      Text(p.email, style: const TextStyle(fontSize: 11.5, color: MedhaColors.muted)),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: busy ? null : () => _approve(p.id),
                                              style: ElevatedButton.styleFrom(backgroundColor: MedhaColors.success),
                                              child: const Text('स्वीकृत'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: busy ? null : () => _reject(p.id),
                                              style: OutlinedButton.styleFrom(foregroundColor: MedhaColors.danger, side: const BorderSide(color: MedhaColors.danger)),
                                              child: const Text('अस्वीकृत'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: MedhaColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: MedhaColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(fontSize: 11, color: MedhaColors.muted)),
        ],
      ),
    );
  }
}

class AdminSchoolsScreen extends StatefulWidget {
  const AdminSchoolsScreen({super.key});

  @override
  State<AdminSchoolsScreen> createState() => _AdminSchoolsScreenState();
}

class _AdminSchoolsScreenState extends State<AdminSchoolsScreen> {
  List<SchoolPrincipalStatus> _schools = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final schools = await AdminApi.schools();
      if (!mounted) return;
      setState(() {
        _schools = schools;
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
      appBar: AppBar(title: const Text('स्कूल')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _schools.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final s = _schools[i];
                  return MedhaCard(
                    child: Row(
                      children: [
                        const MedhaIcon('book', size: 18, color: MedhaColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.schoolName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                              Text(
                                [
                                  s.districtName,
                                  if (s.principalName != null) s.principalName!,
                                  if (s.principalStatus != null) s.principalStatus!,
                                ].join(' · '),
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
      content: TextField(controller: _reason, autofocus: true, maxLines: 3),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('रद्द')),
        TextButton(onPressed: () => Navigator.pop(context, _reason.text), child: const Text('अस्वीकृत')),
      ],
    );
  }
}
