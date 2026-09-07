import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/profile_api.dart';
import '../../core/api/roster_api.dart';
import '../../core/models/attendance.dart';
import '../../core/models/profile.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/medha_icon.dart';
import '../../core/widgets/pill_chip.dart';

/// Picks a random student from the live class roster.
class NamePickerScreen extends StatefulWidget {
  const NamePickerScreen({super.key});

  @override
  State<NamePickerScreen> createState() => _NamePickerScreenState();
}

class _NamePickerScreenState extends State<NamePickerScreen> {
  List<ProfileSubject> _grades = [];
  String? _gradeId;
  List<AttendanceStudent> _roster = [];
  final _picked = <String>{};
  String? _current;
  bool _includePicked = false;
  Timer? _shuffleTimer;
  bool _shuffling = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _shuffleTimer?.cancel();
    super.dispose();
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
      _picked.clear();
      _current = null;
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

  List<String> get _names => _roster.map((s) => s.fullName).toList();

  List<String> get _pool =>
      _includePicked ? _names : _names.where((n) => !_picked.contains(n)).toList();

  void _pick() {
    final pool = _pool;
    if (pool.isEmpty) return;
    setState(() => _shuffling = true);
    var ticks = 0;
    final rnd = Random();
    _shuffleTimer?.cancel();
    _shuffleTimer = Timer.periodic(const Duration(milliseconds: 70), (t) {
      ticks++;
      setState(() => _current = pool[rnd.nextInt(pool.length)]);
      if (ticks > 10) {
        t.cancel();
        setState(() {
          _shuffling = false;
          if (_current != null) _picked.add(_current!);
        });
      }
    });
  }

  void _resetPicked() => setState(() {
        _picked.clear();
        _current = null;
      });

  @override
  Widget build(BuildContext context) {
    final remaining = _names.length - _picked.length;

    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: const Text('नाम चुनें')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
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
                                  setState(() => _gradeId = g.gradeId);
                                  _loadRoster();
                                },
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    _error ??
                        (_includePicked
                            ? 'कुल ${_names.length} छात्र'
                            : '$remaining / ${_names.length} छात्र बाकी'),
                    style: TextStyle(fontSize: 12.5, color: _error != null ? MedhaColors.danger : MedhaColors.muted),
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 34),
                    decoration: BoxDecoration(
                      color: MedhaColors.surface,
                      border: Border.all(color: MedhaColors.borderStrong, width: 1.5),
                      borderRadius: BorderRadius.circular(MedhaRadii.lg),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _current ?? 'चुनने के लिए नीचे दबाएं',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: _current == null ? 15 : 24,
                        fontWeight: FontWeight.w700,
                        color: _current == null ? MedhaColors.muted : (_shuffling ? MedhaColors.muted : MedhaColors.primary),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const MedhaIcon('dice', size: 16, color: MedhaColors.inkSoft),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('पहले से चुने गए भी शामिल करें', style: TextStyle(fontSize: 13, color: MedhaColors.inkSoft))),
                      Switch(
                        value: _includePicked,
                        activeThumbColor: MedhaColors.primary,
                        onChanged: (v) => setState(() => _includePicked = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(onPressed: _picked.isEmpty ? null : _resetPicked, child: const Text('सूची रीसेट करें')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _pool.isEmpty || _shuffling ? null : _pick,
                          child: Text(_pool.isEmpty ? 'सभी चुने जा चुके' : 'चुनें'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
