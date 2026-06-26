import 'dart:async';

class ApiService {
  // Simulación de conexión para el test inicial sin usar localhost
  static Future<String> test() async {
    // Retraso artificial simulando conexión de red
    await Future.delayed(const Duration(seconds: 1));
    return "Conexión local simulada exitosa (Backend Hardcodeado)";
  }
}