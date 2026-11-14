import 'package:flutter/material.dart';

import 'app/lectio_app.dart';
import 'features/profile/data/local_profile_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalProfileStore.instance.initialize();
  runApp(const LectioApp());
}
