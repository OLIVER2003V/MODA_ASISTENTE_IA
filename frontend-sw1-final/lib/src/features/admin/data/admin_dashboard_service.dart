import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/services/storage_service.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class AdminStats {
  final int totalUsers, premiumUsers, freeUsers, activeUsers;
  final int totalHairstyles, totalOutfits, totalPosts, totalGarments, totalConversations;

  const AdminStats({
    required this.totalUsers, required this.premiumUsers,
    required this.freeUsers, required this.activeUsers,
    required this.totalHairstyles, required this.totalOutfits,
    required this.totalPosts, required this.totalGarments,
    required this.totalConversations,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
        totalUsers: j['totalUsers'] as int? ?? 0,
        premiumUsers: j['premiumUsers'] as int? ?? 0,
        freeUsers: j['freeUsers'] as int? ?? 0,
        activeUsers: j['activeUsers'] as int? ?? 0,
        totalHairstyles: j['totalHairstyles'] as int? ?? 0,
        totalOutfits: j['totalOutfits'] as int? ?? 0,
        totalPosts: j['totalPosts'] as int? ?? 0,
        totalGarments: j['totalGarments'] as int? ?? 0,
        totalConversations: j['totalConversations'] as int? ?? 0,
      );
}

class AdminUser {
  final String id, email;
  final String? name, profilePhoto;
  final String role, subscriptionStatus;
  final bool isActive;
  final DateTime createdAt;
  final int closets, posts;

  const AdminUser({
    required this.id, required this.email, this.name, this.profilePhoto,
    required this.role, required this.subscriptionStatus,
    required this.isActive, required this.createdAt,
    required this.closets, required this.posts,
  });

  factory AdminUser.fromJson(Map<String, dynamic> j) {
    final count = j['_count'] as Map<String, dynamic>? ?? {};
    return AdminUser(
      id: j['id'] as String,
      email: j['email'] as String,
      name: j['name'] as String?,
      profilePhoto: j['profilePhoto'] as String?,
      role: j['role'] as String? ?? 'CLIENT',
      subscriptionStatus: j['subscriptionStatus'] as String? ?? 'FREE',
      isActive: j['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(j['createdAt'] as String),
      closets: count['closets'] as int? ?? 0,
      posts: count['posts'] as int? ?? 0,
    );
  }

  String get displayName => (name?.isNotEmpty == true) ? name! : email.split('@').first;
  bool get isAdmin => role == 'ADMIN';
  bool get isPremium => subscriptionStatus == 'PREMIUM';
}

class AdminUsersResult {
  final List<AdminUser> users;
  final int total, page, pages;
  const AdminUsersResult({required this.users, required this.total, required this.page, required this.pages});

  factory AdminUsersResult.fromJson(Map<String, dynamic> j) => AdminUsersResult(
        users: (j['users'] as List).map((e) => AdminUser.fromJson(e as Map<String, dynamic>)).toList(),
        total: j['total'] as int? ?? 0,
        page: j['page'] as int? ?? 1,
        pages: j['pages'] as int? ?? 1,
      );
}

class AdminReports {
  final List<String> labels;
  final List<int> userGrowth, outfitGrowth, postGrowth;
  const AdminReports({required this.labels, required this.userGrowth, required this.outfitGrowth, required this.postGrowth});

  factory AdminReports.fromJson(Map<String, dynamic> j) => AdminReports(
        labels: (j['labels'] as List).map((e) => e as String).toList(),
        userGrowth: (j['userGrowth'] as List).map((e) => e as int).toList(),
        outfitGrowth: (j['outfitGrowth'] as List).map((e) => e as int).toList(),
        postGrowth: (j['postGrowth'] as List).map((e) => e as int).toList(),
      );
}

class ActivityEvent {
  final String type, label, detail, icon;
  final String? imageUrl;
  final DateTime createdAt;

  const ActivityEvent({
    required this.type, required this.label, required this.detail,
    required this.icon, this.imageUrl, required this.createdAt,
  });

  factory ActivityEvent.fromJson(Map<String, dynamic> j) => ActivityEvent(
        type: j['type'] as String,
        label: j['label'] as String,
        detail: j['detail'] as String? ?? '',
        icon: j['icon'] as String? ?? 'circle',
        imageUrl: j['imageUrl'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

// ── Service ───────────────────────────────────────────────────────────────────

class AdminDashboardService {
  static String get _base => ApiConfig.baseUrl;

  static Future<Map<String, String>> get _headers async {
    final token = await StorageService.getToken();
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  static Future<AdminStats> getStats() async {
    final res = await http.get(Uri.parse('$_base/admin/stats'), headers: await _headers);
    _check(res);
    return AdminStats.fromJson(json.decode(res.body) as Map<String, dynamic>);
  }

  static Future<AdminUsersResult> getUsers({int page = 1, int limit = 20, String search = '', String role = ''}) async {
    final uri = Uri.parse('$_base/admin/users').replace(queryParameters: {
      'page': '$page', 'limit': '$limit',
      if (search.isNotEmpty) 'search': search,
      if (role.isNotEmpty) 'role': role,
    });
    final res = await http.get(uri, headers: await _headers);
    _check(res);
    return AdminUsersResult.fromJson(json.decode(res.body) as Map<String, dynamic>);
  }

  static Future<AdminUser> updateUser(String id, {String? role, bool? isActive}) async {
    final body = <String, dynamic>{};
    if (role != null) body['role'] = role;
    if (isActive != null) body['isActive'] = isActive;
    final res = await http.patch(
      Uri.parse('$_base/admin/users/$id'),
      headers: await _headers,
      body: json.encode(body),
    );
    _check(res);
    return AdminUser.fromJson(json.decode(res.body) as Map<String, dynamic>);
  }

  static Future<AdminReports> getReports() async {
    final res = await http.get(Uri.parse('$_base/admin/reports'), headers: await _headers);
    _check(res);
    return AdminReports.fromJson(json.decode(res.body) as Map<String, dynamic>);
  }

  static Future<List<ActivityEvent>> getActivity() async {
    final res = await http.get(Uri.parse('$_base/admin/activity'), headers: await _headers);
    _check(res);
    final data = json.decode(res.body) as Map<String, dynamic>;
    return (data['events'] as List).map((e) => ActivityEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Map<String, dynamic>> getMetrics() async {
    final res = await http.get(Uri.parse('$_base/admin/metrics'), headers: await _headers);
    _check(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getRevenue() async {
    final res = await http.get(Uri.parse('$_base/admin/revenue'), headers: await _headers);
    _check(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getEngagement() async {
    final res = await http.get(Uri.parse('$_base/admin/engagement'), headers: await _headers);
    _check(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getSegments() async {
    final res = await http.get(Uri.parse('$_base/admin/segments'), headers: await _headers);
    _check(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  static void _check(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = (json.decode(res.body) as Map<String, dynamic>)['message'] ?? 'Error';
      throw Exception(msg);
    }
  }
}
