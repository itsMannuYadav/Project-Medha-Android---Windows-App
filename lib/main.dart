import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'core/push/push_service.dart';

export 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.instance.init();
  await PushService.init();
  runApp(const MedhaApp());
}
