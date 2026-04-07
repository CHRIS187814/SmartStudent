// services/api_service.dart — All HTTP calls to FastAPI backend

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  // ── CHANGE THIS to your deployed backend URL ──────────────────────────────
  static const String baseUrl = 'http://localhost:8000'; // Android emulator
  // static const String baseUrl = 'http://localhost:8000'; // iOS simulator
  // static const String baseUrl = 'https://your-api.railway.app'; // Production

  final AuthService _auth = AuthService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _auth.getSavedToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── AUTH ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      await _auth.saveToken(data['access_token']);
      return data;
    }
    throw Exception(data['detail'] ?? 'Login failed');
  }

  Future<Map<String, dynamic>> signup(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      await _auth.saveToken(data['access_token']);
      return data;
    }
    throw Exception(data['detail'] ?? 'Signup failed');
  }

  // ── TASKS ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> addTask({
    required String name,
    required DateTime deadline,
    required double taskWeight,
    required int effortLevel,
    required String category,
    String? description,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/add-task'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'name':         name,
        'deadline':     deadline.toUtc().toIso8601String(),
        'task_weight':  taskWeight,
        'effort_level': effortLevel,
        'category':     category,
        'description':  description,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) return data;
    throw Exception(data['detail'] ?? 'Failed to add task');
  }

  Future<List<dynamic>> getTasks() async {
    final res = await http.get(
      Uri.parse('$baseUrl/tasks'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as List;
    throw Exception('Failed to fetch tasks');
  }

  Future<void> completeTask(String taskId) async {
    await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId/complete'),
      headers: await _authHeaders(),
    );
  }

  Future<void> deleteTask(String taskId) async {
    await http.delete(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: await _authHeaders(),
    );
  }

  // ── DASHBOARD ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboard() async {
    final res = await http.get(
      Uri.parse('$baseUrl/dashboard'),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load dashboard');
  }
}
