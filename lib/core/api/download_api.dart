import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'api_client.dart';

/// Authenticated binary downloads (PPTX etc.) shared via the system sheet.
class DownloadApi {
  DownloadApi._();
  static Dio get _dio => ApiClient.instance.dio;

  static Future<void> sharePath(String path, {required String filename, String? mime}) async {
    final res = await _dio.get<List<int>>(
      path,
      options: Options(responseType: ResponseType.bytes),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(res.data!, flush: true);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: mime, name: filename)]));
  }

  static Future<void> libraryPresentationPptx(String id) => sharePath(
        '/library/presentations/$id/pptx',
        filename: 'presentation_$id.pptx',
        mime: 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      );

  static Future<void> moduleArtifactPptx(String moduleId, String artifactId) => sharePath(
        '/modules/$moduleId/artifacts/$artifactId/pptx',
        filename: 'module_$artifactId.pptx',
        mime: 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      );
}
