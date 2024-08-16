import 'package:flutter/material.dart';
import 'map_screen.dart';

void main() async {
  // Ensure that Flutter framework is fully initialized before running the app
  // WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}
