import 'package:flutter/material.dart';

import '../../core/api/api_error.dart';
import '../../core/api/reference_api.dart';
import '../../core/api/tutor_api.dart';
import '../../core/models/reference.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/medha_colors.dart';
import '../../core/theme/medha_radii.dart';
import '../../core/widgets/avatar_initials.dart';
import '../../core/widgets/medha_card.dart';
import '../../core/widgets/medha_icon.dart';
import '../../core/widgets/notification_bell.dart';
import '../homework/homework_screen.dart';
import '../library/library_screen.dart';
import '../notes/notes_screen.dart';
import '../practice/practice_screen.dart';

enum _TurnKind { student, assistant }

class _Turn {
  _Turn.student(this.text) : kind = _TurnKind.student, failed = false;
  _Turn.assistant(this.text) : kind = _TurnKind.assistant, failed = false;
  final _TurnKind kind;
  String text;
  bool failed;
}

/// The student's doubt-chat entry (`/tutor/*`) -- separate backend from the
/// teacher's lesson-kit chat. Class is fixed to the student's own; only
/// subject + chapter are picked. The empty state's quick actions are real
/// navigations (Notes/Practice/Homework/Library), not artifact generation --
/// tutor sessions have no quiz/activity concept.
class TutorScreen extends StatefulWidget {
  const TutorScreen({super.key});

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();

  bool _loadingContext = true;
  String? _contextError;
  List<SubjectRef> _subjects = [];
  SubjectRef? _selectedSubject;
  List<ChapterRef> _chapters = [];
  ChapterRef? _selectedChapter;

  String? _sessionId;
  final _turns = <_Turn>[];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    try {
      final subjects = await ReferenceApi.subjects();
      if (!mounted) return;
      setState(() {
        _subjects = subjects;
        _selectedSubject = subjects.isEmpty ? null : subjects.first;
        _loadingContext = false;
      });
      await _loadChapters();
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _contextError = e.message;
        _loadingContext = false;
      });
    }
  }

  Future<void> _loadChapters() async {
    final subject = _selectedSubject;
    final gradeId = AppScope.of(context, listen: false).teacher?.gradeId;
    if (subject == null || gradeId == null) return;
    try {
      final chapters = await ReferenceApi.chapters(gradeId: gradeId, subjectId: subject.id);
      if (!mounted) return;
      setState(() {
        _chapters = chapters;
        _selectedChapter = chapters.isEmpty ? null : chapters.first;
      });
    } on ApiError catch (_) {
      if (!mounted) return;
      setState(() {
        _chapters = [];
        _selectedChapter = null;
      });
    }
  }

  void _resetSession() => setState(() {
        _sessionId = null;
        _turns.clear();
      });

  Future<void> _pickSubject() async {
    final choice = await showModalBottomSheet<SubjectRef>(
      context: context,
      backgroundColor: MedhaColors.surface,
      builder: (context) => _PickerSheet<SubjectRef>(title: 'विषय चुनें', items: _subjects, labelOf: (s) => s.name),
    );
    if (choice == null || choice.id == _selectedSubject?.id) return;
    setState(() => _selectedSubject = choice);
    _resetSession();
    await _loadChapters();
  }

  Future<void> _pickChapter() async {
    if (_chapters.isEmpty) return;
    final choice = await showModalBottomSheet<ChapterRef>(
      context: context,
      backgroundColor: MedhaColors.surface,
      builder: (context) => _PickerSheet<ChapterRef>(
        title: 'अध्याय चुनें',
        items: _chapters,
        labelOf: (c) => '${c.chapterNumber}. ${c.title}',
      ),
    );
    if (choice == null || choice.id == _selectedChapter?.id) return;
    setState(() => _selectedChapter = choice);
    _resetSession();
  }

  Future<String?> _ensureSession() async {
    if (_sessionId != null) return _sessionId;
    final subject = _selectedSubject;
    final chapter = _selectedChapter;
    if (subject == null || chapter == null) return null;
    try {
      final session = await TutorApi.createSession(subjectId: subject.id, chapterId: chapter.id);
      setState(() => _sessionId = session.id);
      return session.id;
    } on ApiError catch (e) {
      _showError(e.message);
      return null;
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _ask(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;
    _composer.clear();

    setState(() {
      _sending = true;
      _turns.add(_Turn.student(trimmed));
    });
    _scrollToEnd();

    final sessionId = await _ensureSession();
    if (sessionId == null) {
      setState(() => _sending = false);
      return;
    }

    final reply = _Turn.assistant('');
    setState(() => _turns.add(reply));
    _scrollToEnd();

    await TutorApi.sendMessage(
      sessionId: sessionId,
      content: trimmed,
      onToken: (t) => setState(() => reply.text += t),
      onDone: (_) => setState(() => _sending = false),
      onError: (msg) => setState(() {
        reply.text = msg;
        reply.failed = true;
        _sending = false;
      }),
    );
    _scrollToEnd();
  }

  void _openNotes() {
    final chapter = _selectedChapter;
    if (chapter == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => NotesScreen(chapterId: chapter.id, chapterTitle: chapter.title)));
  }

  void _openPractice() {
    final chapter = _selectedChapter;
    if (chapter == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PracticeScreen(chapterId: chapter.id, chapterTitle: chapter.title)));
  }

  void _openHomework() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HomeworkScreen()));

  void _openLibrary() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LibraryScreen()));

  @override
  Widget build(BuildContext context) {
    final inChat = _turns.isNotEmpty;

    return Scaffold(
      backgroundColor: MedhaColors.bg,
      body: SafeArea(
        child: _loadingContext
            ? const Center(child: CircularProgressIndicator(color: MedhaColors.primary))
            : Column(
                children: [
                  _TopBar(inChat: inChat, subjectLabel: _selectedSubject == null ? '' : _selectedSubject!.name, onNewTopic: _resetSession),
                  if (!inChat)
                    _ContextSelectors(
                      subjectName: _selectedSubject?.name ?? '—',
                      chapterTitle: _selectedChapter?.title ?? (_chapters.isEmpty ? 'उपलब्ध नहीं' : 'चुनें'),
                      onTapSubject: _subjects.length > 1 ? _pickSubject : null,
                      onTapChapter: _chapters.isNotEmpty ? _pickChapter : null,
                    ),
                  if (_contextError != null)
                    Padding(padding: const EdgeInsets.all(16), child: Text(_contextError!, style: const TextStyle(color: MedhaColors.danger))),
                  Expanded(
                    child: inChat
                        ? _ChatThread(scroll: _scroll, turns: _turns)
                        : _EmptyState(onNotes: _openNotes, onPractice: _openPractice, onHomework: _openHomework, onLibrary: _openLibrary),
                  ),
                  _Composer(controller: _composer, busy: _sending, onSend: _ask),
                ],
              ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.inChat, required this.subjectLabel, required this.onNewTopic});
  final bool inChat;
  final String subjectLabel;
  final VoidCallback onNewTopic;

  @override
  Widget build(BuildContext context) {
    final initials = AppScope.of(context).teacher?.fullName.characters.take(1).toString().toUpperCase() ?? '?';
    return Container(
      padding: EdgeInsets.fromLTRB(20, inChat ? 12 : 16, 20, inChat ? 12 : 12),
      decoration: const BoxDecoration(color: MedhaColors.surface, border: Border(bottom: BorderSide(color: MedhaColors.border))),
      child: Row(
        children: [
          if (inChat)
            Expanded(
              child: InkWell(
                onTap: onNewTopic,
                child: Row(
                  children: [
                    const MedhaIcon('chevron_left', size: 18, color: MedhaColors.ink),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('नया सवाल', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: MedhaColors.ink)),
                          Text(subjectLabel, style: const TextStyle(fontSize: 10.5, color: MedhaColors.muted), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const Expanded(
              child: Row(
                children: [
                  _BrandMark(),
                  SizedBox(width: 9),
                  Text('मेधा', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: MedhaColors.ink)),
                ],
              ),
            ),
          const NotificationBell(),
          const SizedBox(width: 10),
          AvatarInitials(initials: initials),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: MedhaColors.primaryWash, border: Border.fromBorderSide(BorderSide(color: MedhaColors.primary, width: 1.5))),
    );
  }
}

class _ContextSelectors extends StatelessWidget {
  const _ContextSelectors({required this.subjectName, required this.chapterTitle, required this.onTapSubject, required this.onTapChapter});
  final String subjectName;
  final String chapterTitle;
  final VoidCallback? onTapSubject;
  final VoidCallback? onTapChapter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: MedhaColors.surface, border: Border(bottom: BorderSide(color: MedhaColors.border))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ContextPill(label: 'विषय', value: subjectName, onTap: onTapSubject),
            const SizedBox(width: 8),
            _ContextPill(label: 'अध्याय', value: chapterTitle, onTap: onTapChapter),
          ],
        ),
      ),
    );
  }
}

class _ContextPill extends StatelessWidget {
  const _ContextPill({required this.label, required this.value, this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(border: Border.all(color: MedhaColors.borderStrong, width: 1.5), borderRadius: BorderRadius.circular(MedhaRadii.pill), color: MedhaColors.surface),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label ', style: const TextStyle(fontSize: 12.5, color: MedhaColors.muted)),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: MedhaColors.ink), overflow: TextOverflow.ellipsis),
          ),
          if (onTap != null) ...[const SizedBox(width: 6), const MedhaIcon('chevron_down', size: 12, color: MedhaColors.muted)],
        ],
      ),
    );
    return onTap == null ? pill : InkWell(borderRadius: BorderRadius.circular(MedhaRadii.pill), onTap: onTap, child: pill);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNotes, required this.onPractice, required this.onHomework, required this.onLibrary});
  final VoidCallback onNotes;
  final VoidCallback onPractice;
  final VoidCallback onHomework;
  final VoidCallback onLibrary;

  @override
  Widget build(BuildContext context) {
    final name = AppScope.of(context).teacher?.fullName.split(' ').first ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text('नमस्ते, $name', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: MedhaColors.ink)),
          const SizedBox(height: 4),
          const Text('आज क्या समझना है?', style: TextStyle(fontSize: 14, color: MedhaColors.inkSoft)),
          const SizedBox(height: 26),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.6,
            children: [
              _actionCard(icon: 'book', title: 'अध्याय के नोट्स', subtitle: 'सार व मुख्य बिंदु', blue: true, onTap: onNotes),
              _actionCard(icon: 'file_question', title: 'अभ्यास प्रश्न', subtitle: 'खुद जाँचें', blue: false, onTap: onPractice),
              _actionCard(icon: 'clipboard', title: 'होमवर्क देखें', subtitle: 'दिया गया काम', blue: true, onTap: onHomework),
              _actionCard(icon: 'book', title: 'ई-लाइब्रेरी', subtitle: 'संसाधन देखें', blue: false, onTap: onLibrary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionCard({required String icon, required String title, required String subtitle, required bool blue, required VoidCallback onTap}) {
    return MedhaCard(
      padding: const EdgeInsets.all(13),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: blue ? MedhaColors.primaryWash : MedhaColors.accentWash, borderRadius: BorderRadius.circular(10)),
            child: Center(child: MedhaIcon(icon, size: 18, color: blue ? MedhaColors.primary : MedhaColors.accentInk)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MedhaColors.ink)),
                Text(subtitle, style: const TextStyle(fontSize: 10.5, color: MedhaColors.muted), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatThread extends StatelessWidget {
  const _ChatThread({required this.scroll, required this.turns});
  final ScrollController scroll;
  final List<_Turn> turns;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.all(16),
      itemCount: turns.length,
      itemBuilder: (context, i) {
        final turn = turns[i];
        final isStudent = turn.kind == _TurnKind.student;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Align(
            alignment: isStudent ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * (isStudent ? 0.82 : 0.9)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: isStudent
                  ? const BoxDecoration(
                      color: MedhaColors.primary,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14), bottomLeft: Radius.circular(14), bottomRight: Radius.circular(3)),
                    )
                  : BoxDecoration(
                      color: MedhaColors.surface,
                      border: Border.all(color: MedhaColors.border),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14), bottomRight: Radius.circular(14), bottomLeft: Radius.circular(3)),
                    ),
              child: Text(
                isStudent ? turn.text : (turn.text.isEmpty ? '...' : turn.text),
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  color: isStudent ? Colors.white : (turn.failed ? MedhaColors.danger : MedhaColors.ink),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.busy, required this.onSend});
  final TextEditingController controller;
  final bool busy;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(color: MedhaColors.surface, border: Border(top: BorderSide(color: MedhaColors.border))),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
        decoration: BoxDecoration(color: MedhaColors.bg, border: Border.all(color: MedhaColors.borderStrong, width: 1.5), borderRadius: BorderRadius.circular(MedhaRadii.lg)),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !busy,
                minLines: 1,
                maxLines: 4,
                onSubmitted: onSend,
                style: const TextStyle(fontSize: 13.5),
                decoration: const InputDecoration(filled: false, border: InputBorder.none, hintText: 'अपना सवाल यहाँ लिखें…', isDense: true),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(shape: BoxShape.circle, color: busy ? MedhaColors.borderStrong : MedhaColors.primary),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const MedhaIcon('send', size: 16, color: Colors.white),
                onPressed: busy ? null : () => onSend(controller.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerSheet<T> extends StatelessWidget {
  const _PickerSheet({required this.title, required this.items, required this.labelOf});
  final String title;
  final List<T> items;
  final String Function(T) labelOf;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MedhaColors.ink)),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(labelOf(items[i]), style: const TextStyle(fontSize: 14, color: MedhaColors.ink)),
                  onTap: () => Navigator.of(context).pop(items[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
