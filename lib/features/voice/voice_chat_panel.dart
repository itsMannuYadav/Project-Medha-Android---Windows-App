import 'package:flutter/material.dart';

import '../../core/api/speech_api.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/medha_icon.dart';

enum VoiceConverseKind { teacher, tutor, english }

/// Bottom sheet voice panel: record → STT → converse SSE → play TTS audio.
class VoiceChatPanel extends StatefulWidget {
  const VoiceChatPanel({
    super.key,
    required this.sessionId,
    required this.kind,
    this.language,
  });

  final String sessionId;
  final VoiceConverseKind kind;
  final String? language;

  static Future<void> open(
    BuildContext context, {
    required String sessionId,
    required VoiceConverseKind kind,
    String? language,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MedhaColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => VoiceChatPanel(sessionId: sessionId, kind: kind, language: language),
    );
  }

  @override
  State<VoiceChatPanel> createState() => _VoiceChatPanelState();
}

class _VoiceChatPanelState extends State<VoiceChatPanel> {
  bool _recording = false;
  bool _busy = false;
  String _status = 'माइक दबाकर बोलें';
  String _reply = '';
  final _history = <(String user, String assistant)>[];

  Future<void> _toggle() async {
    if (_busy) return;
    if (_recording) {
      setState(() {
        _recording = false;
        _busy = true;
        _status = 'समझ रहा है…';
      });
      final file = await SpeechApi.stopRecording();
      if (file == null) {
        setState(() {
          _busy = false;
          _status = 'रिकॉर्डिंग नहीं मिली';
        });
        return;
      }
      try {
        final stt = await SpeechApi.transcribe(file, language: widget.language);
        final transcript = stt.transcript.trim();
        if (transcript.isEmpty) {
          setState(() {
            _busy = false;
            _status = 'कुछ सुनाई नहीं दिया — फिर कोशिश करें';
          });
          return;
        }
        setState(() {
          _status = 'जवाब आ रहा है…';
          _reply = '';
        });
        var reply = '';
        void onToken(String t) {
          reply += t;
          if (mounted) setState(() => _reply = reply);
        }

        void onAudio(String b64, {int? seq, String? mime}) {
          if (b64.isNotEmpty) SpeechApi.playBase64Wav(b64);
        }

        void onDone(Map<String, dynamic> _) {
          if (!mounted) return;
          setState(() {
            _history.add((transcript, reply));
            _busy = false;
            _status = 'माइक दबाकर बोलें';
          });
        }

        void onError(String msg) {
          if (!mounted) return;
          setState(() {
            _busy = false;
            _status = msg;
          });
        }

        switch (widget.kind) {
          case VoiceConverseKind.teacher:
            await SpeechApi.teacherConverse(
              sessionId: widget.sessionId,
              transcript: transcript,
              language: widget.language,
              onToken: onToken,
              onAudio: onAudio,
              onDone: onDone,
              onError: onError,
            );
          case VoiceConverseKind.tutor:
            await SpeechApi.tutorConverse(
              sessionId: widget.sessionId,
              transcript: transcript,
              language: widget.language,
              onToken: onToken,
              onAudio: onAudio,
              onDone: onDone,
              onError: onError,
            );
          case VoiceConverseKind.english:
            await SpeechApi.englishConverse(
              sessionId: widget.sessionId,
              transcript: transcript,
              language: widget.language ?? 'en-IN',
              onToken: onToken,
              onAudio: onAudio,
              onDone: onDone,
              onError: onError,
            );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _busy = false;
            _status = 'आवाज़ सेवा उपलब्ध नहीं';
          });
        }
      }
    } else {
      final ok = await SpeechApi.hasMicPermission();
      if (!ok) {
        setState(() => _status = 'माइक की अनुमति दें');
        return;
      }
      await SpeechApi.startRecording();
      setState(() {
        _recording = true;
        _status = 'सुन रहा है… फिर टैप करें';
      });
    }
  }

  @override
  void dispose() {
    SpeechApi.cancelRecording();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.62;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: MedhaColors.borderStrong, borderRadius: BorderRadius.circular(99))),
            const SizedBox(height: 14),
            const Text('आवाज़ से बात करें', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(_status, style: const TextStyle(fontSize: 12.5, color: MedhaColors.muted)),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                children: [
                  for (final h in _history) ...[
                    _bubble(h.$1, true),
                    _bubble(h.$2, false),
                  ],
                  if (_busy && _reply.isNotEmpty) _bubble(_reply, false),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _busy && !_recording ? null : _toggle,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _recording ? MedhaColors.danger : MedhaColors.primary,
                ),
                child: Center(
                  child: _busy && !_recording
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : MedhaIcon(_recording ? 'mic' : 'mic', size: 28, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(String text, bool user) {
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: user ? MedhaColors.primary : MedhaColors.bg,
          borderRadius: BorderRadius.circular(MedhaRadii.lg),
          border: user ? null : Border.all(color: MedhaColors.border),
        ),
        child: Text(text, style: TextStyle(fontSize: 13, height: 1.4, color: user ? Colors.white : MedhaColors.ink)),
      ),
    );
  }
}

/// Hold-to-dictate into a text field via `/speech/transcribe`.
Future<void> dictateInto(
  BuildContext context,
  TextEditingController controller, {
  String? language,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final ok = await SpeechApi.hasMicPermission();
  if (!ok) {
    messenger.showSnackBar(const SnackBar(content: Text('माइक की अनुमति दें')));
    return;
  }
  messenger.showSnackBar(const SnackBar(content: Text('सुन रहा है… फिर टैप करें बंद करने के लिए'), duration: Duration(seconds: 2)));
  await SpeechApi.startRecording();
  final stop = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('बोल रहे हैं…'),
      content: const Text('खत्म होने पर Stop दबाएं।'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('रद्द')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Stop')),
      ],
    ),
  );
  if (stop != true) {
    await SpeechApi.cancelRecording();
    return;
  }
  final file = await SpeechApi.stopRecording();
  if (file == null) return;
  try {
    final result = await SpeechApi.transcribe(file, language: language);
    if (result.transcript.trim().isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('कुछ सुनाई नहीं दिया')));
      return;
    }
    final existing = controller.text.trim();
    controller.text = existing.isEmpty ? result.transcript : '$existing ${result.transcript}';
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
  } catch (_) {
    messenger.showSnackBar(const SnackBar(content: Text('आवाज़ पहचान नहीं हो सकी')));
  }
}
