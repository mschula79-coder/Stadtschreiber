import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/filter_state.dart';
import 'screens/home_screen.dart';
import 'repositories/category_repository.dart';


void main() {
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
