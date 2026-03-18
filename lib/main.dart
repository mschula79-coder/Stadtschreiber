import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/provider/riverpod_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/app_root.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ymniruxxduyewqvyjrve.supabase.co',
    anonKey: 'sb_publishable_UoTQd39QJPhglwwJ-QQhHg_83s3h-Lo',
  );
  runApp(
    ProviderScope(
      observers: [RiverpodLogger()], 
      child: MyApp())
    );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stadtschreiber',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const AppRoot(),
    );
  }
}
