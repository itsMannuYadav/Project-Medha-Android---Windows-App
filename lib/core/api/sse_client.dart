import 'dart:convert';

import 'package:dio/dio.dart';

/// Streams a POST-based SSE endpoint (`/chat/*`, `/tutor/*`, `/english/*`) --
/// these are POST requests returning `text/event-stream`, so the browser
/// `EventSource` API (GET-only, no custom headers) doesn't apply; this reads
/// the raw byte stream and parses `event:`/`data:` frames by hand, the same
/// approach the Next.js client uses (`shiksha_sathi/lib/sse.ts`).
///
/// Frames are blank-line-delimited (`\n\n`) and sse-starlette emits CRLF, so
/// both are normalized before splitting.
Future<void> streamSse({
  required Dio dio,
  required String path,
  required Map<String, dynamic> body,
  required void Function(String text) onToken,
  required void Function(Map<String, dynamic> data) onDone,
  required void Function(String message) onError,
}) async {
  Response<ResponseBody> response;
  try {
    response = await dio.post<ResponseBody>(
      path,
      data: body,
      options: Options(responseType: ResponseType.stream, headers: {'Accept': 'text/event-stream'}),
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
