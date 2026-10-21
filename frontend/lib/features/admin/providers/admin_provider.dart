import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/constants/app_constants.dart';

export '../../blog/models/article_model.dart';
import '../../blog/models/article_model.dart';
import '../../blog/providers/articles_provider.dart';

class MitigasiModel {
  final String id;
  final int stepNumber;
  final String title;
  final String description;
  final String? iconName;
  final String? imageUrl;

  MitigasiModel({
    required this.id,
    required this.stepNumber,
    required this.title,
    required this.description,
    this.iconName,
    this.imageUrl,
  });

  factory MitigasiModel.fromJson(Map<String, dynamic> json) {
    return MitigasiModel(
      id: json['id'] ?? '',
      stepNumber: json['stepNumber'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      iconName: json['iconName'],
      imageUrl: json['imageUrl'] ?? json['image_url'],
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
  final String? imageUrl;

  PeralatanModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.priority,
    this.iconName,
    this.imageUrl,
  });

  factory PeralatanModel.fromJson(Map<String, dynamic> json) {
    return PeralatanModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 0,
      iconName: json['iconName'],
      imageUrl: json['imageUrl'] ?? json['image_url'],
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
  final Ref? _ref;

  AdminNotifier(this._storage, [this._ref]) : super(const AdminState());

  Future<Dio> _authenticatedDio() async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.accessTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              final token = await _storage.read(key: AppConstants.accessTokenKey);
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              try {
                final retryResponse = await dio.fetch(error.requestOptions);
                return handler.resolve(retryResponse);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final response = await Dio().post(
        '${AppConstants.apiBaseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newToken = response.data['accessToken'];
      final newRefresh = response.data['refreshToken'];
      if (newToken != null) {
        await _storage.write(key: AppConstants.accessTokenKey, value: newToken);
      }
      if (newRefresh != null) {
        await _storage.write(key: AppConstants.refreshTokenKey, value: newRefresh);
      }
      return true;
    } catch (e) {
      debugPrint('[AdminNotifier] Refresh token failed: $e');
      return false;
    }
  }

  // ─── Storage Upload ────────────────────────────────────────────────────────
  Future<String?> uploadFile({
    required List<int> bytes,
    required String filename,
    required String folder,
  }) async {
    try {
      final dio = await _authenticatedDio();

      // Tentukan mimetype yang sesuai dari ekstensi file
      String mimeType = 'image/jpeg';
      String cleanFilename = filename.isNotEmpty ? filename : 'upload.jpg';
      final lower = cleanFilename.toLowerCase();
      if (lower.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (lower.endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (lower.endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (!lower.contains('.')) {
        cleanFilename = '$cleanFilename.jpg';
      }

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: cleanFilename,
          contentType: MediaType.parse(mimeType),
        ),
      });

      final response = await dio.post(
        '${AppConstants.apiBaseUrl}/storage/upload',
        queryParameters: {'folder': folder},
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final url = response.data['url'] as String?;
        return url;
      }
      state = state.copyWith(error: 'Upload gagal (Status ${response.statusCode})');
      return null;
    } catch (e) {
      String msg = 'Gagal mengupload gambar';
      if (e is DioException) {
        if (e.response?.data != null && e.response?.data is Map) {
          msg = e.response?.data['message']?.toString() ?? msg;
        } else if (e.response?.statusCode == 401) {
          msg = 'Sesi telah berakhir. Silakan login ulang.';
        } else if (e.response?.statusCode == 403) {
          msg = 'Akses ditolak: Hanya Admin/Super Admin yang dapat mengunggah gambar.';
        } else if (e.response?.statusCode != null) {
          msg = 'Server error (${e.response?.statusCode})';
        } else {
          msg = e.message ?? msg;
        }
      } else {
        msg = e.toString();
      }
      debugPrint('[AdminNotifier] Upload error: $e');
      state = state.copyWith(error: msg);
      return null;
    }
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
          if (coverImageUrl != null && coverImageUrl.trim().isNotEmpty)
            'coverImageUrl': coverImageUrl.trim(),
        },
      );
      await loadArticles();
      _ref?.invalidate(articlesProvider);
      return true;
    } catch (e) {
      String msg = 'Gagal membuat artikel: $e';
      if (e is DioException && e.response?.data != null) {
        final d = e.response!.data;
        if (d is Map && d['message'] != null) {
          final m = d['message'];
          msg = 'Gagal membuat artikel: ${m is List ? m.join(', ') : m}';
        }
      }
      state = state.copyWith(error: msg);
      return false;
    }
  }

  Future<bool> updateArticle(String id, Map<String, dynamic> data) async {
    try {
      final dio = await _authenticatedDio();
      await dio.patch('${AppConstants.apiBaseUrl}/articles/$id', data: data);
      await loadArticles();
      _ref?.invalidate(articlesProvider);
      return true;
    } catch (e) {
      String msg = 'Gagal mengupdate artikel: $e';
      if (e is DioException && e.response?.data != null) {
        final d = e.response!.data;
        if (d is Map && d['message'] != null) {
          final m = d['message'];
          msg = 'Gagal mengupdate artikel: ${m is List ? m.join(', ') : m}';
        }
      }
      state = state.copyWith(error: msg);
      return false;
    }
  }

  Future<bool> deleteArticle(String id) async {
    try {
      final dio = await _authenticatedDio();
      await dio.delete('${AppConstants.apiBaseUrl}/articles/$id');
      await loadArticles();
      _ref?.invalidate(articlesProvider);
      return true;
    } catch (e) {
      String msg = 'Gagal menghapus artikel: $e';
      if (e is DioException && e.response?.data != null) {
        final d = e.response!.data;
        if (d is Map && d['message'] != null) {
          final m = d['message'];
          msg = 'Gagal menghapus artikel: ${m is List ? m.join(', ') : m}';
        }
      }
      state = state.copyWith(error: msg);
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
    String? imageUrl,
  }) async {
    try {
      final dio = await _authenticatedDio();
      await dio.post(
        '${AppConstants.apiBaseUrl}/mitigasi',
        data: {
          'stepNumber': stepNumber,
          'title': title,
          'description': description,
          if (iconName != null && iconName.trim().isNotEmpty) 'iconName': iconName.trim(),
          if (imageUrl != null && imageUrl.trim().isNotEmpty) 'imageUrl': imageUrl.trim(),
        },
      );
      await loadMitigasi();
      return true;
    } catch (e) {
      String msg = 'Gagal membuat langkah mitigasi: $e';
      if (e is DioException && e.response?.data != null) {
        final d = e.response!.data;
        if (d is Map && d['message'] != null) {
          final m = d['message'];
          msg = 'Gagal membuat langkah mitigasi: ${m is List ? m.join(', ') : m}';
        }
      }
      state = state.copyWith(error: msg);
      return false;
    }
  }

  Future<bool> updateMitigasi(String id, Map<String, dynamic> data) async {
    try {
      final dio = await _authenticatedDio();
      final clean = Map<String, dynamic>.from(data);
      clean.removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));
      await dio.patch('${AppConstants.apiBaseUrl}/mitigasi/$id', data: clean);
      await loadMitigasi();
      return true;
    } catch (e) {
      String msg = 'Gagal mengupdate mitigasi: $e';
      if (e is DioException && e.response?.data != null) {
        final d = e.response!.data;
        if (d is Map && d['message'] != null) {
          final m = d['message'];
          msg = 'Gagal mengupdate mitigasi: ${m is List ? m.join(', ') : m}';
        }
      }
      state = state.copyWith(error: msg);
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
      String msg = 'Gagal menghapus mitigasi: $e';
      if (e is DioException && e.response?.data != null) {
        final d = e.response!.data;
        if (d is Map && d['message'] != null) {
          final m = d['message'];
          msg = 'Gagal menghapus mitigasi: ${m is List ? m.join(', ') : m}';
        }
      }
      state = state.copyWith(error: msg);
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
    String? imageUrl,
  }) async {
    try {
      final dio = await _authenticatedDio();
      await dio.post(
        '${AppConstants.apiBaseUrl}/peralatan',
        data: {
          'name': name,
          'category': category.trim().isEmpty ? 'Umum' : category.trim(),
          'description': description,
          'priority': priority,
          if (iconName != null && iconName.trim().isNotEmpty) 'iconName': iconName.trim(),
          if (imageUrl != null && imageUrl.trim().isNotEmpty) 'imageUrl': imageUrl.trim(),
        },
      );
      await loadPeralatan();
      return true;
    } catch (e) {
      String msg = 'Gagal membuat peralatan: $e';
      if (e is DioException && e.response?.data != null) {
        final d = e.response!.data;
        if (d is Map && d['message'] != null) {
          final m = d['message'];
          msg = 'Gagal membuat peralatan: ${m is List ? m.join(', ') : m}';
        }
      }
      state = state.copyWith(error: msg);
      return false;
    }
  }

  Future<bool> updatePeralatan(String id, Map<String, dynamic> data) async {
    try {
      final dio = await _authenticatedDio();
      final clean = Map<String, dynamic>.from(data);
      clean.removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));
      await dio.patch('${AppConstants.apiBaseUrl}/peralatan/$id', data: clean);
      await loadPeralatan();
      return true;
    } catch (e) {
      String msg = 'Gagal mengupdate peralatan: $e';
      if (e is DioException && e.response?.data != null) {
        final d = e.response!.data;
        if (d is Map && d['message'] != null) {
          final m = d['message'];
          msg = 'Gagal mengupdate peralatan: ${m is List ? m.join(', ') : m}';
        }
      }
      state = state.copyWith(error: msg);
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
      String msg = 'Gagal menghapus peralatan: $e';
      if (e is DioException && e.response?.data != null) {
        final d = e.response!.data;
        if (d is Map && d['message'] != null) {
          final m = d['message'];
          msg = 'Gagal menghapus peralatan: ${m is List ? m.join(', ') : m}';
        }
      }
      state = state.copyWith(error: msg);
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
  return AdminNotifier(const FlutterSecureStorage(), ref);
});
