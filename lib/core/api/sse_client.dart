import 'dart:convert';

import 'package:dio/dio.dart';

/// Streams a POST-based SSE endpoint (`/ask/*`, `/tutor/*`, `/english/*`,
/// `/generate/*`, `/speech/converse`) — POST returning `text/event-stream`.
Future<void> streamSse({
  required Dio dio,
  required String path,
  required Map<String, dynamic> body,
  required void Function(String text) onToken,
  void Function(String stage, int done, int total)? onProgress,
  void Function(String b64, {int? seq, String? mime})? onAudio,
  required void Function(Map<String, dynamic> data) onDone,
  required void Function(String message) onError,
}) async {
  Response<ResponseBody> response;
  try {
    response = await dio.post<ResponseBody>(
      path,
      data: body,
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
  } on DioException catch (e) {
    onError(_dioErrorMessage(e));
    return;
  }

  final stream = response.data?.stream;
  if (stream == null) {
    onError('कनेक्शन शुरू नहीं हो सका।');
    return;
  }

  var buffer = '';
  var sawTerminal = false;

  try {
    await for (final chunk in stream) {
      buffer += utf8.decode(chunk, allowMalformed: true).replaceAll('\r\n', '\n');

      while (true) {
        final splitAt = buffer.indexOf('\n\n');
        if (splitAt == -1) break;
        final frame = buffer.substring(0, splitAt);
        buffer = buffer.substring(splitAt + 2);

        final parsed = _parseFrame(frame);
        if (parsed == null) continue;
        final (event, dataStr) = parsed;

        Map<String, dynamic> data;
        try {
          data = jsonDecode(dataStr) as Map<String, dynamic>;
        } catch (_) {
          continue;
        }

        switch (event) {
          case 'token':
            onToken(data['text'] as String? ?? '');
          case 'progress':
            onProgress?.call(
              data['stage'] as String? ?? '',
              (data['done'] as num?)?.toInt() ?? 0,
              (data['total'] as num?)?.toInt() ?? 0,
            );
          case 'audio':
            onAudio?.call(
              data['b64'] as String? ?? '',
              seq: (data['seq'] as num?)?.toInt(),
              mime: data['mime'] as String?,
            );
          case 'done':
            sawTerminal = true;
            onDone(data);
          case 'error':
            sawTerminal = true;
            onError(data['message'] as String? ?? 'कुछ गड़बड़ हो गई।');
        }
      }
    }
  } catch (_) {
    if (!sawTerminal) onError('कनेक्शन बीच में टूट गया।');
    return;
  }

  if (!sawTerminal) onError('कनेक्शन बीच में टूट गया।');
}

(String, String)? _parseFrame(String frame) {
  String? event;
  final dataLines = <String>[];
  for (final line in frame.split('\n')) {
    if (line.startsWith('event:')) {
      event = line.substring(6).trim();
    } else if (line.startsWith('data:')) {
      dataLines.add(line.substring(5).trim());
    }
  }
  if (event == null || dataLines.isEmpty) return null;
  return (event, dataLines.join('\n'));
}

String _dioErrorMessage(DioException e) {
  if (e.response?.statusCode == 429) return 'बहुत सारे सवाल — थोड़ी देर बाद कोशिश करें।';
  return 'सर्वर से जुड़ नहीं पाए। इंटरनेट जांचें।';
}
