import 'package:flutter/material.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  String mensaje = "Cargando...";

  @override
  void initState() {
    super.initState();
    obtenerDatos();
  }

  Future<void> obtenerDatos() async {

    try {

      final res = await ApiService.test();

      setState(() {
        mensaje = res;
      });

    } catch (e) {

      setState(() {
        mensaje = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Prueba API"),
      ),
      body: Center(
        child: Text(mensaje),
      ),
    );
  }
}