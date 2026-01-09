import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/filter_state.dart';
import 'screens/home_screen.dart';
import 'repositories/category_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


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
      home: const MyHomePage(title: 'Stadtschreiber'),
    );
  }
}
