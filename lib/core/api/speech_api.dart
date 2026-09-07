import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'api_client.dart';
import 'sse_client.dart';

class TranscribeResult {
  TranscribeResult({required this.transcript, this.languageCode});
  final String transcript;
  final String? languageCode;
}

class VoiceTurn {
  VoiceTurn({
    required this.id,
    required this.userTranscript,
    required this.assistantText,
    required this.createdAt,
  });
  final String id;
  final String userTranscript;
  final String? assistantText;
  final DateTime createdAt;

  factory VoiceTurn.fromJson(Map<String, dynamic> j) => VoiceTurn(
        id: j['id'] as String,
        userTranscript: j['user_transcript'] as String,
        assistantText: j['assistant_text'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

/// Speech + voice converse helpers (`/speech/*`, tutor/english converse).
class SpeechApi {
  SpeechApi._();
  static Dio get _dio => ApiClient.instance.dio;
  static final _player = AudioPlayer();
  static final _recorder = AudioRecorder();

  static Future<bool> hasMicPermission() => _recorder.hasPermission();

  static Future<void> startRecording() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/medha_rec_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
      path: path,
    );
  }

  static Future<File?> stopRecording() async {
    final path = await _recorder.stop();
    if (path == null) return null;
    return File(path);
  }

  static Future<void> cancelRecording() async {
    if (await _recorder.isRecording()) await _recorder.stop();
  }

  static Future<bool> get isRecording => _recorder.isRecording();

  static Future<TranscribeResult> transcribe(File file, {String? language}) => apiCall(() async {
        final form = FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path, filename: 'audio.wav'),
          if (language != null) 'language': language,
        });
        final res = await _dio.post<Map<String, dynamic>>(
          '/speech/transcribe',
          data: form,
          options: Options(contentType: 'multipart/form-data'),
        );
        return TranscribeResult(
          transcript: res.data!['transcript'] as String? ?? '',
          languageCode: res.data!['language_code'] as String?,
        );
      });

  static Future<void> speak(String text, {String language = 'hi-IN', String? accent}) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final res = await apiCall(() async {
      final r = await _dio.post<Map<String, dynamic>>('/speech/synthesize', data: {
        'text': clean.length > 2500 ? clean.substring(0, 2500) : clean,
        'language': language,
        'accent': ?accent,
      });
      return r.data!;
    });
    final b64 = res['audio_base64'] as String? ?? '';
    if (b64.isEmpty) return;
    await playBase64Wav(b64);
  }

  static Future<void> playBase64Wav(String b64) async {
    final bytes = base64Decode(b64);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/medha_tts_${DateTime.now().millisecondsSinceEpoch}.wav');
    await file.writeAsBytes(Uint8List.fromList(bytes), flush: true);
    await _player.stop();
    await _player.play(DeviceFileSource(file.path));
  }

  static Future<void> stopSpeaking() => _player.stop();

  static Future<List<VoiceTurn>> teacherTurns(String sessionId) => apiCall(() async {
        final res = await _dio.get<List<dynamic>>('/speech/sessions/$sessionId/turns');
        return res.data!.map((t) => VoiceTurn.fromJson(t as Map<String, dynamic>)).toList();
      });

  /// Teacher Ask voice turn — SSE with token + audio + done.
  static Future<void> teacherConverse({
    required String sessionId,
    required String transcript,
    String? language,
    String? style,
    required void Function(String text) onToken,
    void Function(String b64, {int? seq, String? mime})? onAudio,
    required void Function(Map<String, dynamic> data) onDone,
    required void Function(String message) onError,
  }) =>
      streamSse(
        dio: _dio,
        path: '/speech/converse',
        body: {
          'session_id': sessionId,
          'transcript': transcript,
          'language': ?language,
          'style': ?style,
        },
        onToken: onToken,
        onAudio: onAudio,
        onDone: onDone,
        onError: onError,
      );

  static Future<void> tutorConverse({
    required String sessionId,
    required String transcript,
    String? language,
    required void Function(String text) onToken,
    void Function(String b64, {int? seq, String? mime})? onAudio,
    required void Function(Map<String, dynamic> data) onDone,
    required void Function(String message) onError,
  }) =>
      streamSse(
        dio: _dio,
        path: '/tutor/sessions/$sessionId/converse',
        body: {'transcript': transcript, 'language': ?language},
        onToken: onToken,
        onAudio: onAudio,
        onDone: onDone,
        onError: onError,
      );

  static Future<void> englishConverse({
    required String sessionId,
    required String transcript,
    String? language,
    required void Function(String text) onToken,
    void Function(String b64, {int? seq, String? mime})? onAudio,
    required void Function(Map<String, dynamic> data) onDone,
    required void Function(String message) onError,
  }) =>
      streamSse(
        dio: _dio,
        path: '/english/sessions/$sessionId/converse',
        body: {'transcript': transcript, 'language': ?language},
        onToken: onToken,
        onAudio: onAudio,
        onDone: onDone,
        onError: onError,
      );

  static Future<PronunciationResult> pronunciationCheck({
    required File file,
    required String expected,
  }) =>
      apiCall(() async {
        final form = FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path, filename: 'audio.wav'),
          'expected': expected,
        });
        final res = await _dio.post<Map<String, dynamic>>(
          '/english/pronunciation-check',
          data: form,
          options: Options(contentType: 'multipart/form-data'),
        );
        return PronunciationResult.fromJson(res.data!);
      });
}

class PronunciationResult {
  PronunciationResult({
    required this.score,
    required this.heard,
    required this.expected,
    required this.feedback,
    required this.tips,
  });
  final double score;
  final String heard;
  final String expected;
  final String feedback;
  final List<String> tips;

  factory PronunciationResult.fromJson(Map<String, dynamic> j) => PronunciationResult(
        score: (j['score'] as num).toDouble(),
        heard: j['heard'] as String? ?? '',
        expected: j['expected'] as String? ?? '',
        feedback: j['feedback'] as String? ?? '',
        tips: (j['tips'] as List? ?? []).map((e) => e as String).toList(),
      );
}
