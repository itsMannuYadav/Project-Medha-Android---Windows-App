import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/screen_header.dart';

class _Msg {
  final String id;
  final bool isUser;
  final String content;
  final bool streaming;
  const _Msg({required this.id, required this.isUser, required this.content, this.streaming = false});
  _Msg copyWith({String? content, bool? streaming}) =>
      _Msg(id: id, isUser: isUser, content: content ?? this.content, streaming: streaming ?? this.streaming);
}

class TeacherAskScreen extends ConsumerStatefulWidget {
  const TeacherAskScreen({super.key});

  @override
  ConsumerState<TeacherAskScreen> createState() => _TeacherAskScreenState();
}

class _TeacherAskScreenState extends ConsumerState<TeacherAskScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<_Msg> _messages = [];
  bool _busy = false;
  String? _sessionId;

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _busy) return;
    _ctrl.clear();
    final uid = DateTime.now().microsecondsSinceEpoch.toString();
    final asstId = '${uid}a';
    setState(() {
      _messages = [
        ..._messages,
        _Msg(id: uid, isUser: true, content: text),
        _Msg(id: asstId, isUser: false, content: '', streaming: true),
      ];
      _busy = true;
    });
    _scrollToBottom();

    try {
      // Create session on first message
      if (_sessionId == null) {
        final res = await ref.read(apiClientProvider).post('/chat/sessions');
        _sessionId = (res.data as Map)['id'] as String;
      }
      final api = ref.read(apiClientProvider);
      var acc = '';
      await for (final token in api.streamPost('/chat/sessions/$_sessionId/messages', {'content': text}, null)) {
        acc += token;
        if (mounted) {
          setState(() {
            _messages = _messages.map((m) => m.id == asstId ? m.copyWith(content: acc) : m).toList();
          });
          _scrollToBottom();
        }
      }
      if (mounted) {
        setState(() {
          _messages = _messages.map((m) => m.id == asstId ? m.copyWith(streaming: false) : m).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages = _messages.map((m) => m.id == asstId ? m.copyWith(content: 'Error: ${e.toString()}', streaming: false) : m).toList();
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
        const ScreenHeader(title: 'Ask Medha AI', subtitle: 'Your teaching assistant'),
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: AppColors.violetMuted, borderRadius: BorderRadius.circular(50)),
                        child: const Icon(Icons.auto_awesome_rounded, size: 36, color: AppColors.violet),
                      ),
                      const SizedBox(height: 16),
                      Text('Ask Medha AI anything', style: GoogleFonts.manrope(fontSize: 16, color: AppColors.ink)),
                      const SizedBox(height: 6),
                      Text('Get lesson plans, quiz ideas, and teaching strategies',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(fontSize: 13, color: AppColors.mutedForeground)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (ctx, i) {
                    final m = _messages[i];
                    if (m.isUser) {
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12, left: 48),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.terracotta,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16), topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(16), bottomRight: Radius.circular(4),
                            ),
                          ),
                          child: Text(m.content, style: GoogleFonts.manrope(fontSize: 14, color: AppColors.ivory)),
                        ),
                      );
                    }
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12, right: 48),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4), topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16),
                          ),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: m.content.isEmpty && m.streaming
                            ? const SizedBox(height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.terracotta))
                            : MarkdownBody(
                                data: m.content + (m.streaming ? '▋' : ''),
                                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                  p: GoogleFonts.manrope(fontSize: 14, color: AppColors.ink),
                                ),
                              ),
                      ),
                    );
                  },
                ),
        ),
        Container(
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
                    controller: _ctrl,
                    enabled: !_busy,
                    minLines: 1, maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: !_busy ? _send : null,
                    decoration: InputDecoration(
                      hintText: 'How do I teach photosynthesis so students stay engaged?',
                      hintStyle: GoogleFonts.manrope(fontSize: 13, color: AppColors.mutedForeground),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    style: GoogleFonts.manrope(fontSize: 14, color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: !_busy ? () => _send(_ctrl.text) : null,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: !_busy ? AppColors.terracotta : AppColors.hairline,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.send_rounded,
                        color: !_busy ? AppColors.ivory : AppColors.mutedForeground, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
