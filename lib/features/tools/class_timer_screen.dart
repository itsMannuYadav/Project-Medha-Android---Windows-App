import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/medha_icon.dart';

/// A genuinely working countdown timer — one of the few Tools that's
/// purely client-side (no LLM call), so it's built for real rather than
/// stubbed with a "coming soon" snackbar like the generation-backed tools.
class ClassTimerScreen extends StatefulWidget {
  const ClassTimerScreen({super.key});

  @override
  State<ClassTimerScreen> createState() => _ClassTimerScreenState();
}

class _ClassTimerScreenState extends State<ClassTimerScreen> {
  static const _presets = [3, 5, 10, 15];
  int _totalSeconds = 5 * 60;
  int _remaining = 5 * 60;
  Timer? _timer;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setPreset(int minutes) {
    _timer?.cancel();
    setState(() {
      _running = false;
      _totalSeconds = minutes * 60;
      _remaining = _totalSeconds;
    });
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    if (_remaining <= 0) return;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (_remaining <= 1) {
          _remaining = 0;
          _running = false;
          t.cancel();
        } else {
          _remaining -= 1;
        }
      });
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = _totalSeconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds == 0 ? 0.0 : _remaining / _totalSeconds;
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    final done = _remaining == 0;

    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: const Text('क्लास टाइमर')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: _presets.map((p) {
                  final selected = _totalSeconds == p * 60;
                  return ChoiceChip(
                    label: Text('$p मिनट'),
                    selected: selected,
                    onSelected: (_) => _setPreset(p),
                    labelStyle: TextStyle(color: selected ? Colors.white : MedhaColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 13),
                    selectedColor: MedhaColors.primary,
                    backgroundColor: MedhaColors.surface,
                    side: BorderSide(color: selected ? MedhaColors.primary : MedhaColors.borderStrong, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MedhaRadii.pill)),
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: MedhaColors.surface2,
                        valueColor: AlwaysStoppedAnimation(done ? MedhaColors.success : MedhaColors.primary),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$m:$s', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w700, color: MedhaColors.ink, fontFeatures: [FontFeature.tabularFigures()])),
                        Text(done ? 'समय समाप्त!' : (_running ? 'चल रहा है...' : 'रुका हुआ'),
                            style: TextStyle(fontSize: 13, color: done ? MedhaColors.success : MedhaColors.muted)),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const MedhaIcon('refresh', size: 16, color: MedhaColors.inkSoft),
                      label: const Text('रीसेट'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: done ? null : _toggle,
                      child: Text(_running ? 'रोकें' : 'शुरू करें'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
