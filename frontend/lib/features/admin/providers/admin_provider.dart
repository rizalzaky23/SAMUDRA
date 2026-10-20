import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/constants/app_constants.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class ArticleModel {
  final String id;
  final String title;
  final String content;
  final String category;
  final String status;
  final String? coverImageUrl;
  final String authorId;
  final DateTime? publishedAt;
  final DateTime createdAt;

  ArticleModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.status,
    this.coverImageUrl,
    required this.authorId,
    this.publishedAt,
    required this.createdAt,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'edukasi_tsunami',
      status: json['status'] ?? 'draft',
      coverImageUrl: json['coverImageUrl'],
      authorId: json['authorId'] ?? '',
      publishedAt: json['publishedAt'] != null ? DateTime.tryParse(json['publishedAt']) : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class MitigasiModel {
  final String id;
  final int stepNumber;
  final String title;
  final String description;
  final String? iconName;

  MitigasiModel({
    required this.id,
    required this.stepNumber,
    required this.title,
    required this.description,
    this.iconName,
  });

  factory MitigasiModel.fromJson(Map<String, dynamic> json) {
    return MitigasiModel(
      id: json['id'] ?? '',
      stepNumber: json['stepNumber'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      iconName: json['iconName'],
    );
  }
}

class PeralatanModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final int priority;
  final String? iconName;

  PeralatanModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.priority,
    this.iconName,
  });

  factory PeralatanModel.fromJson(Map<String, dynamic> json) {
    return PeralatanModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 0,
      iconName: json['iconName'],
    );
  }
}

// ─── Admin State ──────────────────────────────────────────────────────────────

class AdminState {
  final List<ArticleModel> articles;
  final List<MitigasiModel> mitigasiSteps;
  final List<PeralatanModel> peralatan;
  final List<UserModel> users;
  final bool isLoading;
  final String? error;

  const AdminState({
    this.articles = const [],
    this.mitigasiSteps = const [],
    this.peralatan = const [],
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    List<ArticleModel>? articles,
    List<MitigasiModel>? mitigasiSteps,
    List<PeralatanModel>? peralatan,
    List<UserModel>? users,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AdminState(
      articles: articles ?? this.articles,
      mitigasiSteps: mitigasiSteps ?? this.mitigasiSteps,
      peralatan: peralatan ?? this.peralatan,
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Admin Notifier ───────────────────────────────────────────────────────────

class AdminNotifier extends StateNotifier<AdminState> {
  final FlutterSecureStorage _storage;

  AdminNotifier(this._storage) : super(const AdminState());

  Future<Dio> _authenticatedDio() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    final dio = Dio();
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
    return dio;
  }

  // ─── Articles ──────────────────────────────────────────────────────────────

  Future<void> loadArticles() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = await _authenticatedDio();
      final response = await dio.get('${AppConstants.apiBaseUrl}/articles/admin/all');
      final list = (response.data as List).map((e) => ArticleModel.fromJson(e)).toList();
      state = state.copyWith(articles: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Gagal memuat artikel: $e');
    }
  }

  Future<bool> createArticle({
    required String title,
    required String content,
    required String category,
    required String status,
    String? coverImageUrl,
  }) async {
    try {
      final dio = await _authenticatedDio();
      await dio.post(
        '${AppConstants.apiBaseUrl}/articles',
        data: {
          'title': title,
          'content': content,
          'category': category,
          'status': status,
          if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
        },
      );
      await loadArticles();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Gagal membuat artikel: $e');
      return false;
    }
  }

  Future<bool> updateArticle(String id, Map<String, dynamic> data) async {
    try {
      final dio = await _authenticatedDio();
      await dio.patch('${AppConstants.apiBaseUrl}/articles/$id', data: data);
      await loadArticles();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Gagal mengupdate artikel: $e');
      return false;
    }
  }

  Future<bool> deleteArticle(String id) async {
    try {
      final dio = await _authenticatedDio();
      await dio.delete('${AppConstants.apiBaseUrl}/articles/$id');
      await loadArticles();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Gagal menghapus artikel: $e');
      return false;
    }
  }

  // ─── Mitigasi ──────────────────────────────────────────────────────────────

  Future<void> loadMitigasi() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = Dio();
      final response = await dio.get('${AppConstants.apiBaseUrl}/mitigasi');
      final list = (response.data as List).map((e) => MitigasiModel.fromJson(e)).toList();
      state = state.copyWith(mitigasiSteps: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Gagal memuat mitigasi: $e');
    }
  }

  Future<bool> createMitigasi({
    required int stepNumber,
    required String title,
    required String description,
    String? iconName,
  }) async {
    try {
      final dio = await _authenticatedDio();
      await dio.post(
        '${AppConstants.apiBaseUrl}/mitigasi',
        data: {
          'stepNumber': stepNumber,
          'title': title,
          'description': description,
          if (iconName != null) 'iconName': iconName,
        },
      );
      await loadMitigasi();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Gagal membuat langkah mitigasi: $e');
      return false;
    }
  }

  Future<bool> updateMitigasi(String id, Map<String, dynamic> data) async {
    try {
      final dio = await _authenticatedDio();
      await dio.patch('${AppConstants.apiBaseUrl}/mitigasi/$id', data: data);
      await loadMitigasi();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Gagal mengupdate mitigasi: $e');
      return false;
    }
  }

  Future<bool> deleteMitigasi(String id) async {
    try {
      final dio = await _authenticatedDio();
      await dio.delete('${AppConstants.apiBaseUrl}/mitigasi/$id');
      await loadMitigasi();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Gagal menghapus mitigasi: $e');
      return false;
    }
  }

  // ─── Peralatan ─────────────────────────────────────────────────────────────

  Future<void> loadPeralatan() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = Dio();
      final response = await dio.get('${AppConstants.apiBaseUrl}/peralatan');
      final list = (response.data as List).map((e) => PeralatanModel.fromJson(e)).toList();
      state = state.copyWith(peralatan: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Gagal memuat peralatan: $e');
    }
  }

  Future<bool> createPeralatan({
    required String name,
    required String category,
    required String description,
    int priority = 0,
    String? iconName,
  }) async {
    try {
      final dio = await _authenticatedDio();
      await dio.post(
        '${AppConstants.apiBaseUrl}/peralatan',
        data: {
          'name': name,
          'category': category,
          'description': description,
          'priority': priority,
          if (iconName != null) 'iconName': iconName,
        },
      );
      await loadPeralatan();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Gagal membuat peralatan: $e');
      return false;
    }
  }

  Future<bool> updatePeralatan(String id, Map<String, dynamic> data) async {
    try {
      final dio = await _authenticatedDio();
      await dio.patch('${AppConstants.apiBaseUrl}/peralatan/$id', data: data);
      await loadPeralatan();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Gagal mengupdate peralatan: $e');
      return false;
    }
  }

  Future<bool> deletePeralatan(String id) async {
    try {
      final dio = await _authenticatedDio();
      await dio.delete('${AppConstants.apiBaseUrl}/peralatan/$id');
      await loadPeralatan();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Gagal menghapus peralatan: $e');
      return false;
    }
  }

  // ─── Users (super_admin) ───────────────────────────────────────────────────

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = await _authenticatedDio();
      final response = await dio.get('${AppConstants.apiBaseUrl}/users');
      final data = response.data['data'] as List;
      final list = data.map((e) => UserModel.fromJson(e)).toList();
      state = state.copyWith(users: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Gagal memuat pengguna: $e');
    }
  }

  Future<bool> updateUserRole(String userId, String role) async {
    try {
      final dio = await _authenticatedDio();
      await dio.patch(
        '${AppConstants.apiBaseUrl}/users/$userId/role',
        data: {'role': role},
      );
      await loadUsers();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Gagal mengubah role: $e');
      return false;
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier(const FlutterSecureStorage());
});
