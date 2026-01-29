// TODO Martin Server deinstallieren?
// TODO Action Buttons mit Funktionen belegen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'controllers/category_controller.dart';
import 'controllers/poi_controller.dart';
import 'controllers/poi_thumbnails_controller.dart';
import 'repositories/category_repository.dart';
import 'screens/auth_gate.dart';
import 'state/app_state.dart';
import 'state/categories_menu_state.dart';
import 'state/poi_panel_state.dart';
import 'state/pois_thumbnails_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ymniruxxduyewqvyjrve.supabase.co',
    anonKey: 'sb_publishable_UoTQd39QJPhglwwJ-QQhHg_83s3h-Lo',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryState()),
        Provider(create: (_) => CategoryRepository()),
        Provider(
          create: (context) => CategoryController(
            context.read<CategoryState>(),
            context.read<CategoryRepository>(),
          ),
        ),

        ChangeNotifierProvider(create: (_) => CategoriesMenuState()),
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => PoiPanelState()),
        ChangeNotifierProvider(create: (_) => PoiController()),
        ChangeNotifierProvider(create: (_) => PoiThumbnailsState()),
        ChangeNotifierProvider(create: (_) => PoiThumbnailsController()),
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
