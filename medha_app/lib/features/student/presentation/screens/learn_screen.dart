import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../data/student_models.dart';
import '../../data/student_repository.dart';
import '../providers/student_providers.dart';

enum _MsgRole { student, assistant }

class _Message {
  final String id;
  final _MsgRole role;
  final String content;
  final bool streaming;
  final bool failed;

  const _Message({
    required this.id,
    required this.role,
    required this.content,
    this.streaming = false,
    this.failed = false,
  });

  _Message copyWith(
          {String? content, bool? streaming, bool? failed}) =>
      _Message(
        id: id,
        role: role,
        content: content ?? this.content,
        streaming: streaming ?? this.streaming,
        failed: failed ?? this.failed,
      );
}

class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<_Message> _messages = [];
  bool _busy = false;
  String? _sessionId;
  String? _selectedSubjectId;
  String? _selectedChapterId;
  List<SubjectItem> _subjects = [];
  List<ChapterItem> _chapters = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    try {
      final subjects = await ref.read(studentRepositoryProvider).getMySubjects();
      if (mounted) setState(() { _subjects = subjects; });
    } catch (_) {}
  }

  Future<void> _loadChapters(String subjectId) async {
    final chapters = await ref.read(studentRepositoryProvider).getChapters(subjectId);
    if (mounted) setState(() { _chapters = chapters; _selectedChapterId = null; });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String?> _ensureSession() async {
    if (_sessionId != null) return _sessionId;
    if (_selectedSubjectId == null || _selectedChapterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a subject and chapter first')),
      );
      return null;
    }
    final session = await ref.read(studentRepositoryProvider).createTutorSession(
      _selectedSubjectId!,
      _selectedChapterId!,
    );
    _sessionId = session['id'] as String;
    return _sessionId;
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _busy) return;
    _msgCtrl.clear();

    final sessionId = await _ensureSession();
    if (sessionId == null) return;

    final userMsg = _Message(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: _MsgRole.student,
      content: text,
    );
    final asstId = '${DateTime.now().microsecondsSinceEpoch}a';
    final asstMsg = _Message(
      id: asstId,
      role: _MsgRole.assistant,
      content: '',
      streaming: true,
    );

    setState(() {
      _messages = [..._messages, userMsg, asstMsg];
      _busy = true;
    });
    _scrollToBottom();

    try {
      final api = ref.read(apiClientProvider);
      var acc = '';
      await for (final token in api.streamPost(
        '/tutor/sessions/$sessionId/messages',
        {'content': text},
        null,
      )) {
        acc += token;
        if (mounted) {
          setState(() {
            _messages = _messages.map((m) {
              if (m.id == asstId) return m.copyWith(content: acc);
              return m;
            }).toList();
          });
          _scrollToBottom();
        }
      }
      if (mounted) {
        setState(() {
          _messages = _messages.map((m) {
            if (m.id == asstId) return m.copyWith(streaming: false);
            return m;
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages = _messages.map((m) {
            if (m.id == asstId) {
              return m.copyWith(streaming: false, failed: true);
            }
            return m;
          }).toList();
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          title: 'Ask Medha',
          subtitle: 'Ask any doubt in Hindi or English',
        ),
        // Subject + chapter pickers
        _SubjectChapterBar(
          subjects: _subjects,
          chapters: _chapters,
          selectedSubjectId: _selectedSubjectId,
          selectedChapterId: _selectedChapterId,
          onSubjectChanged: (id, _) {
            setState(() {
              _selectedSubjectId = id;
              _selectedChapterId = null;
              _sessionId = null;
              _messages = [];
            });
            if (id != null) _loadChapters(id);
          },
          onChapterChanged: (id, _) => setState(() {
            _selectedChapterId = id;
            _sessionId = null;
            _messages = [];
          }),
        ),
        // Messages
        Expanded(
          child: _messages.isEmpty
              ? _EmptyChat(canAsk: _selectedSubjectId != null && _selectedChapterId != null)
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: _messages.length,
                  itemBuilder: (ctx, i) => _MessageBubble(msg: _messages[i]),
                ),
        ),
        // Composer
        _Composer(
          controller: _msgCtrl,
          enabled: !_busy,
          onSend: _sendMessage,
          hint: _selectedSubjectId == null
              ? 'Pick a subject first…'
              : 'Type your question…',
        ),
      ],
    );
  }
}

class _SubjectChapterBar extends StatelessWidget {
  final List<SubjectItem> subjects;
  final List<ChapterItem> chapters;
  final String? selectedSubjectId;
  final String? selectedChapterId;
  final void Function(String?, String?) onSubjectChanged;
  final void Function(String?, String?) onChapterChanged;

  const _SubjectChapterBar({
    required this.subjects,
    required this.chapters,
    required this.selectedSubjectId,
    required this.selectedChapterId,
    required this.onSubjectChanged,
    required this.onChapterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
        color: AppColors.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: _Dropdown(
              hint: 'Subject',
              value: selectedSubjectId,
              items: subjects.map((s) => (s.id, s.name)).toList(),
              onChanged: (id) {
                final name = subjects.firstWhere((s) => s.id == id, orElse: () => SubjectItem(id: '', name: '')).name;
                onSubjectChanged(id, name);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Dropdown(
              hint: 'Chapter',
              value: selectedChapterId,
              items: chapters.map((c) => (c.id, 'Ch.${c.chapterNumber}: ${c.title}')).toList(),
              onChanged: (id) {
                final name = chapters.firstWhere((c) => c.id == id, orElse: () => ChapterItem(id: '', title: '', chapterNumber: 0)).title;
                onChapterChanged(id, name);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<(String, String)> items;
  final void Function(String?) onChanged;

  const _Dropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      // Without this the button sizes to its widest menu item and overflows
      // the Expanded parent — long chapter titles break the bar on small phones.
      isExpanded: true,
      hint: Text(hint, style: GoogleFonts.manrope(fontSize: 13, color: AppColors.mutedForeground)),
      items: items.map((item) => DropdownMenuItem(
        value: item.$1,
        child: Text(item.$2, style: GoogleFonts.manrope(fontSize: 13), overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: onChanged,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final bool canAsk;
  const _EmptyChat({required this.canAsk});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.violetMuted,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 36, color: AppColors.violet),
          ),
          const SizedBox(height: 16),
          Text(
            canAsk ? 'Hi! What would you like to know?' : 'Pick a subject and chapter to start',
            style: GoogleFonts.manrope(fontSize: 15, color: AppColors.ink),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            canAsk ? 'Ask any doubt in Hindi or English' : '',
            style: GoogleFonts.manrope(fontSize: 13, color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _Message msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    if (msg.role == _MsgRole.student) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.terracotta,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            msg.content,
            style: GoogleFonts.manrope(fontSize: 14, color: AppColors.ivory),
          ),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.violetMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    size: 14, color: AppColors.violet),
              ),
              const SizedBox(width: 6),
              Text('Medha',
                  style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.violet)),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 6, bottom: 12, right: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: msg.content.isEmpty && msg.streaming
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.terracotta))
                : MarkdownBody(
                    data: msg.content +
                        (msg.streaming ? '▋' : '') +
                        (msg.failed ? '\n\n*Couldn\'t finish the response.*' : ''),
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: GoogleFonts.manrope(fontSize: 14, color: AppColors.ink),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final void Function(String) onSend;
  final String hint;

  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: enabled ? onSend : null,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.manrope(
                      fontSize: 14, color: AppColors.mutedForeground),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                style: GoogleFonts.manrope(fontSize: 14, color: AppColors.ink),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: enabled ? () => onSend(controller.text) : null,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: enabled ? AppColors.terracotta : AppColors.hairline,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: enabled ? AppColors.ivory : AppColors.mutedForeground,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
