import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../models/article_model.dart';

final fallbackArticles = [
  ArticleModel(
    id: 'default-1',
    title: 'Panduan Evakuasi Mandiri Saat Gempa Bumi',
    content:
        'Saat terjadi gempa bumi berkekuatan besar, jangan panik. Lakukan tindakan "Drop, Cover, and Hold On" (Merunduk, Berlindung di bawah meja kokoh, dan Bertahan). Jauhi kaca, jendela, dan benda gantung. Setelah guncangan mereda, segera keluar menuju ruang terbuka melalui jalur evakuasi yang aman tanpa menggunakan lift.',
    category: 'edukasi_tsunami',
    status: 'published',
    authorId: 'system',
    createdAt: DateTime.now(),
  ),
  ArticleModel(
    id: 'default-2',
    title: 'Tanda Alami Datangnya Gelombang Tsunami',
    content:
        'Tsunami sering diawali oleh gempa bumi dangkal berkekuatan besar di dasar laut. Tanda-tanda alam yang patut diwaspadai meliputi:\n\n1. Air laut yang surut secara tiba-tiba hingga garis pantai menjauh ratusan meter.\n2. Suara gemuruh dahsyat seperti deru pesawat jet dari arah laut.\n3. Perilaku hewan pesisir yang gelisah dan berlari menjauhi pantai.\n\nJika melihat tanda-tanda ini, jangan menunggu sirine atau konfirmasi resmi, segera evakuasi ke tempat tinggi!',
    category: 'mitigasi_bencana',
    status: 'published',
    authorId: 'system',
    createdAt: DateTime.now(),
  ),
  ArticleModel(
    id: 'default-3',
    title: 'Penyusunan Tas Siaga Bencana Keluarga',
    content:
        'Tas Siaga Bencana (TSB) adalah tas tahan air yang disiapkan untuk bertahan hidup minimal 3x24 jam pasca bencana. Isi penting meliputi:\n\n- Dokumen penting (KTP, KK, Ijazah dalam plastik kedap air)\n- Air minum dan makanan instan tahan lama\n- Kotak P3K & obat-obatan pribadi\n- Senter, peluit, dan baterai cadangan\n- Pakaian ganti & selimut darurat\n- Powerbank dan radio portabel.',
    category: 'tips_keselamatan',
    status: 'published',
    authorId: 'system',
    createdAt: DateTime.now(),
  ),
];

final articlesProvider = FutureProvider<List<ArticleModel>>((ref) async {
  try {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    final response = await dio.get('${AppConstants.apiBaseUrl}/articles');
    if (response.statusCode == 200 && response.data is List) {
      final list = (response.data as List)
          .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) {
        return list;
      }
    }
  } catch (_) {
    // If request fails or server is unreachable, fallback to starter articles
  }
  return fallbackArticles;
});
