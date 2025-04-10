import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class ApiService {
  // Server IP address - make sure this is accessible from your phone
  // If you're on the same WiFi network, use the VM's IP address
  // If testing on an emulator, use 10.0.2.2 instead of localhost
  final String baseUrl = 'http://10.100.102.50:3000/api';

  // Hash password
  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Register user
  Future<Map<String, dynamic>> registerUser(String username, String password) async {
    final passwordHash = hashPassword(password);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password_hash': passwordHash,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to register user: ${response.body}');
      }
    } catch (e) {
      print('Error registering user: $e');
      throw Exception('Failed to register user: $e');
    }
  }

  // Login user
  Future<Map<String, dynamic>> loginUser(String username, String password) async {
    final passwordHash = hashPassword(password);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password_hash': passwordHash,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      print('Error logging in: $e');
      throw Exception('Failed to login: $e');
    }
  }

  // Save exposed terrain
  Future<void> saveExposedTerrain(int userId, double latitude, double longitude) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/terrain'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
    } catch (e) {
      print('Error saving terrain: $e');
      // Don't throw here to avoid interrupting the user experience
    }
  }

  // Get exposed terrain for a user
  Future<List<Map<String, dynamic>>> getExposedTerrain(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/terrain/$userId'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get exposed terrain: ${response.body}');
      }
    } catch (e) {
      print('Error getting exposed terrain: $e');
      return []; // Return empty list on error
    }
  }

  // Check if terrain is exposed
  Future<bool> isTerrainExposed(int userId, double latitude, double longitude) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/terrain/$userId/$latitude/$longitude'),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        return data['exposed'] as bool;
      } else {
        return false; // Default to not exposed on error
      }
    } catch (e) {
      print('Error checking terrain: $e');
      return false; // Default to not exposed on error
    }
  }

  // Check server status
  Future<bool> checkServerStatus() async {
    try {
      print('Checking server status at: $baseUrl/status');

      // Try to resolve the hostname first to catch DNS issues
      final uri = Uri.parse('$baseUrl/status');
      print('Connecting to host: ${uri.host} on port ${uri.port}');

      final response = await http.get(
        uri,
        headers: {'Connection': 'close'}, // Prevent connection pooling issues
      ).timeout(const Duration(seconds: 5));

      print('Server response: ${response.statusCode} ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      if (e is SocketException) {
        print('Socket exception: ${e.message}');
        print('Cannot connect to server. Check if:');
        print('1. The server is running');
        print('2. Your phone and server are on the same network');
        print('3. The IP address is correct: ${Uri.parse(baseUrl).host}');
      } else if (e is TimeoutException) {
        print('Connection timed out. Server might be slow or unreachable.');
      } else {
        print('Error checking server status: $e');
      }
      return false;
    }
  }
}
