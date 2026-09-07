import 'package:flutter/material.dart';

import '../../core/api/principal_api.dart';
import '../../core/models/principal.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/widgets/avatar_initials.dart';
import '../../core/widgets/medha_card.dart';
import '../../core/widgets/medha_icon.dart';
import '../../core/widgets/notification_bell.dart';
import '../notifications/notifications_screen.dart';
import 'teacher_approvals_screen.dart';

/// The principal/office landing screen: a school-wide snapshot plus quick
/// links to the two things a principal reaches for most -- pending teacher
/// applications and sending a school-wide announcement.
class PrincipalDashboardScreen extends StatefulWidget {
  const PrincipalDashboardScreen({super.key});

  @override
  State<PrincipalDashboardScreen> createState() => _PrincipalDashboardScreenState();
}

class _PrincipalDashboardScreenState extends State<PrincipalDashboardScreen> {
  PrincipalStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stats = await PrincipalApi.stats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'लोड नहीं हो सका।';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = AppScope.of(context).teacher?.fullName.characters.take(1).toString().toUpperCase() ?? '?';
    final schoolName = AppScope.of(context).teacher?.fullName ?? '';

    return Scaffold(
      backgroundColor: MedhaColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: const BoxDecoration(color: MedhaColors.surface, border: Border(bottom: BorderSide(color: MedhaColors.border))),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: MedhaColors.primaryWash, border: Border.fromBorderSide(BorderSide(color: MedhaColors.primary, width: 1.5))),
                  ),
                  const SizedBox(width: 9),
                  const Expanded(child: Text('मेधा', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: MedhaColors.ink))),
                  const NotificationBell(),
                  const SizedBox(width: 10),
                  AvatarInitials(initials: initials),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        children: [
                          Text('नमस्ते, $schoolName', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: MedhaColors.ink)),
                          const SizedBox(height: 20),
                          if (_error != null)
                            Text(_error!, style: const TextStyle(color: MedhaColors.danger))
                          else if (_stats != null)
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.7,
                              children: [
                                _stat('${_stats!.teachers}', 'स्वीकृत शिक्षक', MedhaColors.surface, MedhaColors.ink),
                                _stat('${_stats!.pendingTeachers}', 'लंबित शिक्षक', MedhaColors.accentWash, MedhaColors.accentInk),
                                _stat('${_stats!.students}', 'स्वीकृत छात्र', MedhaColors.surface, MedhaColors.ink),
                                _stat('${_stats!.pendingStudents}', 'लंबित छात्र', MedhaColors.accentWash, MedhaColors.accentInk),
                              ],
                            ),
                          const SizedBox(height: 20),
                          MedhaCard(
                            padding: const EdgeInsets.all(13),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TeacherApprovalsScreen())),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(color: MedhaColors.primaryWash, borderRadius: BorderRadius.circular(10)),
                                  child: const Center(child: MedhaIcon('users_group', size: 18, color: MedhaColors.primary)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('शिक्षक आवेदन', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      Text(_stats == null ? '' : '${_stats!.pendingTeachers} स्वीकृति की प्रतीक्षा में', style: const TextStyle(fontSize: 10.5, color: MedhaColors.muted)),
                                    ],
                                  ),
                                ),
                                const MedhaIcon('chevron_right', size: 15, color: MedhaColors.muted),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          MedhaCard(
                            padding: const EdgeInsets.all(13),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(color: MedhaColors.accentWash, borderRadius: BorderRadius.circular(10)),
                                  child: const Center(child: MedhaIcon('user', size: 18, color: MedhaColors.accentInk)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('लंबित छात्र', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      Text(
                                        _stats == null
                                            ? ''
                                            : _stats!.pendingStudents == 0
                                                ? 'कोई लंबित आवेदन नहीं'
                                                : '${_stats!.pendingStudents} — शिक्षक स्वीकृत करेंगे',
                                        style: const TextStyle(fontSize: 10.5, color: MedhaColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          MedhaCard(
                            padding: const EdgeInsets.all(13),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(color: MedhaColors.primaryWash, borderRadius: BorderRadius.circular(10)),
                                  child: const Center(child: MedhaIcon('megaphone', size: 18, color: MedhaColors.primary)),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('घोषणा भेजें', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      Text('शिक्षकों या छात्रों को', style: TextStyle(fontSize: 10.5, color: MedhaColors.muted)),
                                    ],
                                  ),
                                ),
                                const MedhaIcon('chevron_right', size: 15, color: MedhaColors.muted),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: bg == MedhaColors.surface ? Border.all(color: MedhaColors.border) : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: fg)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: fg == MedhaColors.ink ? MedhaColors.muted : fg)),
        ],
      ),
    );
  }
}
