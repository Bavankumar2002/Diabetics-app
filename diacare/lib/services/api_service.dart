import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';

class ApiService {
  static const String tokenKey = 'diacare_auth_token';
  static const String serverHostKey = 'diacare_server_host';

  static Future<void> initHost() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(serverHostKey);
    if (saved != null && saved.trim().isNotEmpty) {
      ApiConstants.setServerHost(saved.trim());
    }
  }

  static Future<void> saveServerHost(String host) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(serverHostKey, host.trim());
    ApiConstants.setServerHost(host.trim());
  }

  static Future<bool> testConnection([String? host]) async {
    try {
      final testBase = host != null && host.trim().isNotEmpty
          ? 'http://${host.trim()}/diabetics_app/backend'
          : ApiConstants.baseUrl;
      final response = await http
          .get(Uri.parse('$testBase/food/get_foods.php'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> get(String url) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers).timeout(
        const Duration(seconds: 15),
      );

      final data = json.decode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data is Map<String, dynamic> ? data : {'success': true, 'data': data};
      } else {
        throw Exception(data['message'] ?? 'Request failed with status: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Connection timed out reaching ${ApiConstants.serverHost}. Please verify phone and PC are on the same Wi-Fi network.');
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data is Map<String, dynamic> ? data : {'success': true, 'data': data};
      } else {
        throw Exception(data['message'] ?? 'Request failed with status: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Connection timed out reaching ${ApiConstants.serverHost}. Please verify phone and PC are on the same Wi-Fi network.');
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }
}
