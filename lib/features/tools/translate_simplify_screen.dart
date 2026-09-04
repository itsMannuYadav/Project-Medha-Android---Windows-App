import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/tools_api.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/pill_chip.dart';

const _languageValueFor = {
  AppLanguage.english: 'en',
  AppLanguage.hindi: 'hi-BiharBoli',
  AppLanguage.hinglish: 'hinglish',
};

/// The one Tool that's actually LLM-backed (`POST /tools/translate`) — the
/// rest of the grid is either pure client-side logic or an honest "not
/// connected yet", confirmed against both the backend and the web client.
class TranslateSimplifyScreen extends StatefulWidget {
  const TranslateSimplifyScreen({super.key});

  @override
  State<TranslateSimplifyScreen> createState() => _TranslateSimplifyScreenState();
}

class _TranslateSimplifyScreenState extends State<TranslateSimplifyScreen> {
  final _input = TextEditingController();
  String _mode = 'simplify';
  String _readingLevel = 'class-6';
  bool _busy = false;
  String? _result;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    final targetLanguage = _languageValueFor[AppScope.of(context, listen: false).language]!;
    try {
      final result = await ToolsApi.translate(text: text, mode: _mode, targetLanguage: targetLanguage, readingLevel: _readingLevel);
      if (mounted) setState(() => _result = result);
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(title: const Text('अनुवाद / सरल करें')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PillChip(label: 'सरल करें', selected: _mode == 'simplify', onTap: () => setState(() => _mode = 'simplify')),
                const SizedBox(width: 8),
                PillChip(label: 'अनुवाद करें', selected: _mode == 'translate', onTap: () => setState(() => _mode = 'translate')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final level in const [('class-6', 'कक्षा 6'), ('class-8', 'कक्षा 8'), ('class-10', 'कक्षा 10')]) ...[
                  PillChip(label: level.$2, dense: true, selected: _readingLevel == level.$1, onTap: () => setState(() => _readingLevel = level.$1)),
                  const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _input,
              maxLines: 6,
              enabled: !_busy,
              decoration: const InputDecoration(hintText: 'यहाँ पाठ चिपकाएँ या लिखें...'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _run,
                child: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_mode == 'simplify' ? 'सरल करें' : 'अनुवाद करें'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: MedhaColors.dangerWash, borderRadius: BorderRadius.circular(MedhaRadii.md)),
                child: Text(_error!, style: const TextStyle(color: MedhaColors.danger, fontSize: 13)),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MedhaColors.surface,
                  border: Border.all(color: MedhaColors.border),
                  borderRadius: BorderRadius.circular(MedhaRadii.lg),
                ),
                child: Text(_result!, style: const TextStyle(fontSize: 14, color: MedhaColors.ink, height: 1.7)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
