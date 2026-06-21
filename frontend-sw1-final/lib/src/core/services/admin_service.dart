import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

class BackupRun {
  final int id;
  final int runNumber;
  final String status;
  final String? conclusion;
  final DateTime createdAt;
  final String runUrl;
  final String triggeredBy;

  const BackupRun({
    required this.id,
    required this.runNumber,
    required this.status,
    this.conclusion,
    required this.createdAt,
    required this.runUrl,
    required this.triggeredBy,
  });

  factory BackupRun.fromJson(Map<String, dynamic> json) => BackupRun(
        id: json['id'] as int,
        runNumber: json['runNumber'] as int,
        status: json['status'] as String,
        conclusion: json['conclusion'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        runUrl: json['runUrl'] as String,
        triggeredBy: json['triggeredBy'] as String? ?? 'desconocido',
      );

  bool get isSuccess => conclusion == 'success';
  bool get isRunning => status == 'in_progress' || status == 'queued';
  bool get isFailed => conclusion == 'failure' || conclusion == 'cancelled';
}

class AdminService {
  static String get _base => ApiConfig.baseUrl;

  static Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<bool> triggerBackup({String reason = 'Manual backup via app'}) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$_base/admin/backup/trigger'),
      headers: headers,
      body: json.encode({'reason': reason}),
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      return data['triggered'] == true;
    }
    throw Exception('Error al disparar el respaldo');
  }

  static Future<List<BackupRun>> listBackups() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$_base/admin/backup/list'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final list = json.decode(res.body) as List<dynamic>;
      return list.map((e) => BackupRun.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
