import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  static const String baseUrl =
      "http://localhost:8000/api";

  static Future<String> test() async {

    final response = await http.get(
      Uri.parse('$baseUrl/test/')
    );

    final data = jsonDecode(response.body);

    return data['mensaje'];
  }
}