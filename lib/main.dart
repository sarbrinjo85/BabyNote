import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Env.isConfigured) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      debug: kDebugMode,
    );
  } else if (kDebugMode) {
    debugPrint(
      'Env not configured — pass --dart-define=SUPABASE_URL=... '
      '--dart-define=SUPABASE_ANON_KEY=... to enable backend features.',
    );
  }

  runApp(const ProviderScope(child: BabyNoteApp()));
}
