import 'package:flutter/material.dart';
import 'services/api_service.dart';
// Ajusta esta ruta según tu estructura de carpetas:
import 'features/estado_sueno/screens/estado_sueno_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});
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
      setState(() => mensaje = res);
    } catch (e) {
      setState(() => mensaje = "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text("Inicio",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Estado de conexión
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      mensaje.contains("Error") ? Icons.error : Icons.check_circle,
                      color: mensaje.contains("Error")
                          ? const Color(0xFFE24B4A)
                          : const Color(0xFF5DCAA5),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(mensaje,
                          style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Botón para tu módulo
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.mood),
                  label: const Text('Estado Emocional y Sueño',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Cambia el usuarioId por uno que exista en tu BD
                      builder: (_) => const EstadoSuenoScreen(usuarioId: 1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}