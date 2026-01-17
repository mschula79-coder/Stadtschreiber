// TODO MapLibre auf Hetzner hosten
// Android Studio deinstallieren?
// Martin Server deinstallieren?
// Action Buttons mit Funktionen belegen
// Test-App für Android veröffentlichen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'controllers/poi_controller.dart';
import 'repositories/category_repository.dart';
import 'screens/auth_gate.dart';
import 'state/app_state.dart';
import 'state/filter_state.dart';
import 'state/poi_state.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ymniruxxduyewqvyjrve.supabase.co',
    anonKey: 'sb_publishable_UoTQd39QJPhglwwJ-QQhHg_83s3h-Lo',
  );

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => FilterState()),
          Provider(create: (_) => CategoryRepository()),
          ChangeNotifierProvider(create: (_) => AppState()),
          ChangeNotifierProvider(create: (_) => PoiState()),
          ChangeNotifierProvider(create: (_) => PoiController()),
        ],
        child: const MyApp(),
      ),
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
      home: const AuthGate(),

    );
  }
}
