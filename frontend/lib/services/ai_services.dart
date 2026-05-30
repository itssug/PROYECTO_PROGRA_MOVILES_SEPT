import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {

  static Future<String> enviarMensaje(String mensaje) async {

    final url = Uri.parse("http://127.0.0.1:8000/api/ai/chat/");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "message": mensaje
      }),
    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      return data["respuesta"];

    } else {

      return "Error al conectar con IA";

    }
  }
}