import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/data/demo_roster.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/medha_icon.dart';

/// Picks a random student to call on — excludes anyone already picked this
/// session by default, so the same few hands don't get called on twice
/// before everyone's had a turn.
class NamePickerScreen extends StatefulWidget {
  const NamePickerScreen({super.key});

  @override
  State<NamePickerScreen> createState() => _NamePickerScreenState();
}

class _NamePickerScreenState extends State<NamePickerScreen> {
  final _picked = <String>{};
  String? _current;
  bool _includePicked = false;
  Timer? _shuffleTimer;
  bool _shuffling = false;

  @override
  void dispose() {
    _shuffleTimer?.cancel();
    super.dispose();
  }

  List<String> get _pool => _includePicked ? demoRoster : demoRoster.where((n) => !_picked.contains(n)).toList();

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
    final remaining = demoRoster.length - _picked.length;

    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: const Text('नाम चुनें')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              _includePicked ? 'कुल ${demoRoster.length} छात्र' : '$remaining / ${demoRoster.length} छात्र बाकी',
              style: const TextStyle(fontSize: 12.5, color: MedhaColors.muted),
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
