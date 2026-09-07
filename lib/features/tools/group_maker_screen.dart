import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/profile_api.dart';
import '../../core/api/roster_api.dart';
import '../../core/models/attendance.dart';
import '../../core/models/profile.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/medha_card.dart';
import '../../core/widgets/medha_icon.dart';
import '../../core/widgets/pill_chip.dart';

/// Splits the live class roster into random groups.
class GroupMakerScreen extends StatefulWidget {
  const GroupMakerScreen({super.key});

  @override
  State<GroupMakerScreen> createState() => _GroupMakerScreenState();
}

class _GroupMakerScreenState extends State<GroupMakerScreen> {
  List<ProfileSubject> _grades = [];
  String? _gradeId;
  String? _gradeLabel;
  List<AttendanceStudent> _roster = [];
  int _groupSize = 4;
  List<List<String>>? _groups;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final profile = await ProfileApi.get();
      if (!mounted) return;
      final seen = <String>{};
      final grades = [for (final s in profile.subjects) if (seen.add(s.gradeId)) s];
      if (grades.isEmpty) {
        setState(() {
          _error = 'प्रोफ़ाइल में कोई कक्षा नहीं जुड़ी है।';
          _loading = false;
        });
        return;
      }
      setState(() {
        _grades = grades;
        _gradeId = grades.first.gradeId;
        _gradeLabel = grades.first.gradeLabel;
      });
      await _loadRoster();
    } on ApiError catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _loadRoster() async {
    if (_gradeId == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _groups = null;
    });
    try {
      final roster = await RosterApi.forGrade(_gradeId!);
      if (!mounted) return;
      setState(() {
        _roster = roster;
        _loading = false;
      });
    } on ApiError catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _shuffle() {
    final names = _roster.map((s) => s.fullName).toList()..shuffle(Random());
    if (names.isEmpty) return;
    final groups = <List<String>>[];
    for (var i = 0; i < names.length; i += _groupSize) {
      groups.add(names.sublist(i, (i + _groupSize).clamp(0, names.length)));
    }
    setState(() => _groups = groups);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: const Text('ग्रुप बनाएं')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_grades.length > 1) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _grades
                          .map((g) => PillChip(
                                label: g.gradeLabel,
                                selected: g.gradeId == _gradeId,
                                onTap: () {
                                  setState(() {
                                    _gradeId = g.gradeId;
                                    _gradeLabel = g.gradeLabel;
                                  });
                                  _loadRoster();
                                },
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    '${_gradeLabel ?? 'कक्षा'} — कुल ${_roster.length} छात्र',
                    style: const TextStyle(fontSize: 12.5, color: MedhaColors.muted),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: MedhaColors.danger)),
                  ],
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _roster.isEmpty ? null : _shuffle,
                      child: Text(_groups == null ? 'ग्रुप बनाएं' : 'फिर से बनाएं'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _roster.isEmpty
                        ? const Center(child: Text('इस कक्षा में कोई छात्र नहीं', style: TextStyle(color: MedhaColors.muted)))
                        : _groups == null
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
