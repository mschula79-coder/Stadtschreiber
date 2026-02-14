import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'controllers/category_controller.dart';
import 'controllers/poi_thumbnails_controller.dart';
import 'controllers/poi_controller.dart';
import 'repositories/category_repository.dart';
import 'repositories/poi_repository.dart';
import 'screens/auth_gate.dart';
import 'state/app_state.dart';
import 'state/categories_menu_state.dart';
import 'state/poi_panel_and_selection_state.dart';
import 'state/pois_thumbnails_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ymniruxxduyewqvyjrve.supabase.co',
    anonKey: 'sb_publishable_UoTQd39QJPhglwwJ-QQhHg_83s3h-Lo',
  );
  runApp(
    ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider(create: (_) => CategoryState()),
          provider.Provider(create: (_) => CategoryRepository()),
          provider.Provider(
            create: (context) => CategoryController(
              context.read<CategoryState>(),
              context.read<CategoryRepository>(),
            ),
          ),
          provider.Provider(create: (_) => PoiRepository()),

          provider.ChangeNotifierProvider(
            create: (context) => PoiController(context.read<PoiRepository>()),
          ),

          provider.ChangeNotifierProvider(create: (_) => CategoriesMenuState()),
          provider.ChangeNotifierProvider(create: (_) => AppState()),
          provider.ChangeNotifierProvider(create: (_) => PoiPanelAndSelectionState()),
          provider.ChangeNotifierProvider(create: (_) => PoiThumbnailsState()),
          provider.ChangeNotifierProvider(
            create: (_) => PoiThumbnailsController(),
          ),
        ],
        child: const MyApp(),
      ),
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
