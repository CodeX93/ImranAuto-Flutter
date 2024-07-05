import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  Future<bool> login(String username, String password) async {
    final url = Uri.parse('${dotenv.env['BACKEND_URL']!}/users/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final token = response.headers['authorization'];
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token!);
      print(response.body);
      final Map<String, dynamic> responseBody = json.decode(response.body);
      final role = responseBody['role'];

      await prefs.setString('role', role);
      return true;
    } else {
      // Handle login failure
      return false;
    }
  }

  static Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

}
