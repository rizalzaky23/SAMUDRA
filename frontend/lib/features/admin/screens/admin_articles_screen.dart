import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/admin_provider.dart';

class AdminArticlesScreen extends ConsumerStatefulWidget {
  const AdminArticlesScreen({super.key});

  @override
  ConsumerState<AdminArticlesScreen> createState() => _AdminArticlesScreenState();
}

class _AdminArticlesScreenState extends ConsumerState<AdminArticlesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).loadArticles());
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Artikel Edukasi',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _showArticleDialog(context, ref),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B6FE8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Tambah',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: adminState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : adminState.articles.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: adminState.articles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _buildArticleCard(context, ref, adminState.articles[i]),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.article_outlined,
              size: 64, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          Text(
            'Belum ada artikel',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan tombol Tambah untuk membuat artikel baru',
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFFCBD5E1)),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(
      BuildContext context, WidgetRef ref, ArticleModel article) {
    final isPublished = article.status == 'published';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPublished
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPublished ? 'Published' : 'Draft',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPublished
                        ? const Color(0xFF059669)
                        : const Color(0xFFD97706),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _categoryLabel(article.category),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF3B6FE8),
                  ),
                ),
              ),
              const Spacer(),
              // Edit button
              IconButton(
                onPressed: () =>
                    _showArticleDialog(context, ref, article: article),
                icon: const Icon(Icons.edit_rounded,
                    size: 18, color: Color(0xFF64748B)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              // Delete button
              IconButton(
                onPressed: () => _confirmDelete(context, ref, article.id),
                icon: const Icon(Icons.delete_rounded,
                    size: 18, color: Color(0xFFEF4444)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            article.title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            article.content.length > 100
                ? '${article.content.substring(0, 100)}...'
                : article.content,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'mitigasi_bencana':
        return 'Mitigasi';
      case 'edukasi_tsunami':
        return 'Edukasi';
      case 'berita':
        return 'Berita';
      case 'tips_keselamatan':
        return 'Tips';
      default:
        return cat;
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Hapus artikel?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Tindakan ini tidak bisa dibatalkan.',
            style: GoogleFonts.inter()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: GoogleFonts.inter())),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(adminProvider.notifier).deleteArticle(id);
            },
            child: Text('Hapus',
                style: GoogleFonts.inter(color: const Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  void _showArticleDialog(BuildContext context, WidgetRef ref,
      {ArticleModel? article}) {
    final titleCtrl = TextEditingController(text: article?.title ?? '');
    final contentCtrl = TextEditingController(text: article?.content ?? '');
    String selectedCategory = article?.category ?? 'edukasi_tsunami';
    String selectedStatus = article?.status ?? 'draft';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    article == null ? 'Artikel Baru' : 'Edit Artikel',
                    style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Judul'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: titleCtrl,
                        decoration: _inputDecoration('Masukkan judul artikel'),
                      ),
                      const SizedBox(height: 14),
                      _fieldLabel('Kategori'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: _inputDecoration(''),
                        items: const [
                          DropdownMenuItem(
                              value: 'edukasi_tsunami',
                              child: Text('Edukasi Tsunami')),
                          DropdownMenuItem(
                              value: 'mitigasi_bencana',
                              child: Text('Mitigasi Bencana')),
                          DropdownMenuItem(
                              value: 'berita', child: Text('Berita')),
                          DropdownMenuItem(
                              value: 'tips_keselamatan',
                              child: Text('Tips Keselamatan')),
                        ],
                        onChanged: (v) =>
                            setState(() => selectedCategory = v!),
                      ),
                      const SizedBox(height: 14),
                      _fieldLabel('Status'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: _inputDecoration(''),
                        items: const [
                          DropdownMenuItem(
                              value: 'draft', child: Text('Draft')),
                          DropdownMenuItem(
                              value: 'published', child: Text('Published')),
                        ],
                        onChanged: (v) =>
                            setState(() => selectedStatus = v!),
                      ),
                      const SizedBox(height: 14),
                      _fieldLabel('Konten'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: contentCtrl,
                        maxLines: 8,
                        decoration: _inputDecoration('Tulis isi artikel...'),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            if (article == null) {
                              await ref.read(adminProvider.notifier).createArticle(
                                    title: titleCtrl.text,
                                    content: contentCtrl.text,
                                    category: selectedCategory,
                                    status: selectedStatus,
                                  );
                            } else {
                              await ref.read(adminProvider.notifier).updateArticle(
                                    article.id,
                                    {
                                      'title': titleCtrl.text,
                                      'content': contentCtrl.text,
                                      'category': selectedCategory,
                                      'status': selectedStatus,
                                    },
                                  );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B6FE8),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            article == null ? 'Buat Artikel' : 'Simpan Perubahan',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) => Text(
        label,
        style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151)),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3B6FE8), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
