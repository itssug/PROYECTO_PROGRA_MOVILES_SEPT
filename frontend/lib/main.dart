import 'package:flutter/material.dart';
import 'screens/alimentacion/alimentacion_nav_shell.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlucosaApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5500),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AlimentacionNavShell(),
    );
  }
}