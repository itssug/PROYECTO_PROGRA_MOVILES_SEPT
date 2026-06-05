import 'package:flutter/material.dart';
import 'screens/actividad_fisica/actividad_fisica_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Glucosa App - Diabetes Tipo II',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFF6B00),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const ActividadFisicaScreen(),
    );
  }
}
