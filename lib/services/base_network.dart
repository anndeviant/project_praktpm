import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class BaseNetwork {
  static const String _baseUrl = 'https://api.myquran.com/v2';
  final Logger _logger = Logger();

  Future<Map<String, dynamic>?> get(String endpoint) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      _logger.i('Making GET request to: $uri');

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      _logger.i('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.i('Response data: $data');
        return data;
      } else {
        _logger.e('HTTP Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Network error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getHijriCalendar() async {
    try {
      final uri = Uri.parse('$_baseUrl/cal/hijr');
      _logger.i('Making GET request to: $uri');

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      _logger.i('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.i('Hijri calendar response data: $data');
        return data;
      } else {
        _logger.e('HTTP Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Network error getting hijri calendar: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getRandomDoa() async {
    try {
      final uri = Uri.parse('$_baseUrl/doa/random');
      _logger.i('Making GET request to: $uri');

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      _logger.i('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.i('Random doa response data: $data');
        return data;
      } else {
        _logger.e('HTTP Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Network error getting random doa: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getRandomAsmaul() async {
    try {
      final uri = Uri.parse('$_baseUrl/husna/acak');
      _logger.i('Making GET request to: $uri');

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      _logger.i('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.i('Random asmaul response data: $data');
        return data;
      } else {
        _logger.e('HTTP Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Network error getting random asmaul: $e');
      return null;
    }
  }
}
