import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/english_api.dart';
import '../../core/api/speech_api.dart';
import '../../core/data/english_content.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/medha_card.dart';
import '../../core/widgets/medha_icon.dart';
import '../../core/widgets/pill_chip.dart';
import '../voice/voice_chat_panel.dart';

enum _TurnKind { student, assistant }

class _Turn {
  _Turn.student(this.text) : kind = _TurnKind.student, failed = false;
  _Turn.assistant(this.text) : kind = _TurnKind.assistant, failed = false;
  final _TurnKind kind;
  String text;
  bool failed;
}

/// Full Learn English surface — chat + lessons + vocab + speak + word of day.
class EnglishScreen extends StatefulWidget {
  const EnglishScreen({super.key});

  @override
  State<EnglishScreen> createState() => _EnglishScreenState();
}

class _EnglishScreenState extends State<EnglishScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  String? _sessionId;
  final _turns = <_Turn>[];
  bool _sending = false;
  int _vocabIndex = 0;
  PronunciationResult? _lastPronunciation;
  bool _checkingPronunciation = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<String?> _ensureSession({String? topic}) async {
    if (_sessionId != null && topic == null) return _sessionId;
    try {
      final s = await EnglishApi.createSession(lessonTopic: topic);
      _sessionId = s.id;
      return s.id;
    } on ApiError catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return null;
    }
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _composer.text).trim();
    if (text.isEmpty || _sending) return;
    _composer.clear();
    _tabs.animateTo(0);
    setState(() {
      _sending = true;
      _turns.add(_Turn.student(text));
      _turns.add(_Turn.assistant(''));
    });
    final id = await _ensureSession();
    if (id == null) {
      setState(() => _sending = false);
      return;
    }
    final assistant = _turns.last;
    await EnglishApi.sendMessage(
      sessionId: id,
      content: text,
      onToken: (t) {
        if (!mounted) return;
        setState(() => assistant.text += t);
      },
      onDone: (_) {
        if (mounted) setState(() => _sending = false);
      },
      onError: (msg) {
        if (!mounted) return;
        setState(() {
          assistant.text = msg;
          assistant.failed = true;
          _sending = false;
        });
      },
    );
  }

  Future<void> _startLesson(EnglishLesson lesson) async {
    await _ensureSession(topic: lesson.id);
    await _send(lesson.starterPrompt);
  }

  Future<void> _openVoice() async {
    final id = await _ensureSession();
    if (id == null || !mounted) return;
    await VoiceChatPanel.open(context, sessionId: id, kind: VoiceConverseKind.english, language: 'en-IN');
  }

  Future<void> _practicePronunciation(String expected) async {
    final ok = await SpeechApi.hasMicPermission();
    if (!ok || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('माइक अनुमति दें')));
      return;
    }
    setState(() => _checkingPronunciation = true);
    await SpeechApi.startRecording();
    final stop = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Say it aloud'),
        content: Text(expected),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Stop')),
        ],
      ),
    );
    if (stop != true) {
      await SpeechApi.cancelRecording();
      setState(() => _checkingPronunciation = false);
      return;
    }
    final file = await SpeechApi.stopRecording();
    if (file == null) {
      setState(() => _checkingPronunciation = false);
      return;
    }
    try {
      final result = await SpeechApi.pronunciationCheck(file: file, expected: expected);
      if (mounted) setState(() => _lastPronunciation = result);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not check pronunciation')));
    } finally {
      if (mounted) setState(() => _checkingPronunciation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = dailyWord();
    return Scaffold(
      backgroundColor: MedhaColors.bg,
      appBar: AppBar(
        title: const Text('Learn English'),
        actions: [
          IconButton(
            tooltip: 'Voice chat',
            onPressed: _sending ? null : _openVoice,
            icon: const MedhaIcon('mic', color: MedhaColors.primary),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: MedhaColors.primary,
          unselectedLabelColor: MedhaColors.muted,
          indicatorColor: MedhaColors.primary,
          tabs: const [
            Tab(text: 'Chat'),
            Tab(text: 'Lessons'),
            Tab(text: 'Vocab'),
            Tab(text: 'Speak'),
            Tab(text: 'Word'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _chatTab(),
          _lessonsTab(),
          _vocabTab(),
          _speakTab(),
          _wordTab(word),
        ],
      ),
    );
  }

  Widget _chatTab() {
    return Column(
      children: [
        Expanded(
          child: _turns.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text('Start chatting in English', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    for (final s in const [
                      'Help me introduce myself in English',
                      'Practice greeting a new friend',
                      'Correct my sentence: I going to school',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OutlinedButton(
                          onPressed: _sending ? null : () => _send(s),
                          child: Align(alignment: Alignment.centerLeft, child: Text(s)),
                        ),
                      ),
                  ],
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: _turns.length,
                  itemBuilder: (context, i) {
                    final t = _turns[i];
                    final isStudent = t.kind == _TurnKind.student;
                    return Align(
                      alignment: isStudent ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                        decoration: BoxDecoration(
                          color: isStudent ? MedhaColors.primary : MedhaColors.surface,
                          borderRadius: BorderRadius.circular(MedhaRadii.lg),
                          border: isStudent ? null : Border.all(color: MedhaColors.border),
                        ),
                        child: Text(
                          t.text.isEmpty ? '…' : t.text,
                          style: TextStyle(fontSize: 13.5, height: 1.45, color: t.failed ? MedhaColors.danger : (isStudent ? Colors.white : MedhaColors.ink)),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: const BoxDecoration(color: MedhaColors.surface, border: Border(top: BorderSide(color: MedhaColors.border))),
          child: Row(
            children: [
              IconButton(
                onPressed: _sending ? null : () => dictateInto(context, _composer, language: 'en-IN'),
                icon: const MedhaIcon('mic', size: 18, color: MedhaColors.inkSoft),
              ),
              Expanded(
                child: TextField(
                  controller: _composer,
                  enabled: !_sending,
                  decoration: const InputDecoration(hintText: 'Type in English…'),
                  onSubmitted: (_) => _send(),
                ),
              ),
              IconButton.filled(
                onPressed: _sending ? null : () => _send(),
                style: IconButton.styleFrom(backgroundColor: MedhaColors.primary),
                icon: const MedhaIcon('send', size: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _lessonsTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: englishLessons.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final lesson = englishLessons[i];
        return MedhaCard(
          onTap: () => _startLesson(lesson),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lesson.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(lesson.subtitle, style: const TextStyle(fontSize: 12, color: MedhaColors.muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: lesson.topics.map((t) => PillChip(label: t, dense: true)).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _vocabTab() {
    final set = vocabSets[_vocabIndex];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < vocabSets.length; i++) ...[
                  PillChip(label: vocabSets[i].label, dense: true, selected: i == _vocabIndex, onTap: () => setState(() => _vocabIndex = i)),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: set.words.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final w = set.words[i];
              return MedhaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(w.word, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                        IconButton(
                          icon: const MedhaIcon('mic', size: 16, color: MedhaColors.primary),
                          onPressed: () => SpeechApi.speak(w.word, language: 'en-IN'),
                        ),
                      ],
                    ),
                    Text('${w.hindi} · ${w.meaning}', style: const TextStyle(fontSize: 12.5, color: MedhaColors.inkSoft)),
                    const SizedBox(height: 4),
                    Text(w.example, style: const TextStyle(fontSize: 12.5)),
                    Text(w.phonetic, style: const TextStyle(fontSize: 11, color: MedhaColors.muted)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _speakTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Pronunciation practice', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (_lastPronunciation != null)
          MedhaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Score: ${_lastPronunciation!.score.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('Heard: ${_lastPronunciation!.heard}'),
                Text(_lastPronunciation!.feedback),
              ],
            ),
          ),
        const SizedBox(height: 12),
        for (final p in speakingPrompts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MedhaCard(
              child: Row(
                children: [
                  Expanded(child: Text(p, style: const TextStyle(fontSize: 13.5))),
                  IconButton(
                    onPressed: _checkingPronunciation ? null : () => _practicePronunciation(p.replaceAll('___', '…')),
                    icon: const MedhaIcon('mic', color: MedhaColors.primary),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _wordTab(DailyWord word) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Word of the day', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        MedhaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(word.word, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700))),
                  IconButton(onPressed: () => SpeechApi.speak(word.word, language: 'en-IN'), icon: const MedhaIcon('mic', color: MedhaColors.primary)),
                ],
              ),
              Text('${word.hindi} — ${word.meaning}', style: const TextStyle(fontSize: 14, color: MedhaColors.inkSoft)),
              const SizedBox(height: 10),
              Text(word.example, style: const TextStyle(fontSize: 13.5, height: 1.4)),
              const SizedBox(height: 6),
              Text(word.tip, style: const TextStyle(fontSize: 12, color: MedhaColors.muted)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => _send('Teach me more about the word "${word.word}"'), child: const Text('Practice this word')),
            ],
          ),
        ),
      ],
    );
  }
}
