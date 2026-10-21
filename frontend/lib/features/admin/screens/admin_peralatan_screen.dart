import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/image_upload_field.dart';
import '../providers/admin_provider.dart';

class AdminPeralatanScreen extends ConsumerStatefulWidget {
  const AdminPeralatanScreen({super.key});

  @override
  ConsumerState<AdminPeralatanScreen> createState() => _AdminPeralatanScreenState();
}

class _AdminPeralatanScreenState extends ConsumerState<AdminPeralatanScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).loadPeralatan());
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
          'Peralatan Siaga Bencana',
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
              onTap: () => _showPeralatanDialog(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 16),
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
          : adminState.peralatan.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => ref.read(adminProvider.notifier).loadPeralatan(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: adminState.peralatan.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = adminState.peralatan[index];
                      return _buildPeralatanCard(item);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 36, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Peralatan Siaga',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap tombol Tambah untuk memasukkan perlengkapan baru',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildPeralatanCard(PeralatanModel item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medical_services_rounded, color: Color(0xFFF59E0B), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8), size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showPeralatanDialog(context, ref, existing: item);
                  } else if (val == 'delete') {
                    _confirmDelete(context, ref, item.id);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: Color(0xFF3B6FE8)),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: const Color(0xFFF1F5F9),
                    child: const Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            item.description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF475569),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  void _showPeralatanDialog(BuildContext context, WidgetRef ref, {PeralatanModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final catCtrl = TextEditingController(text: existing?.category ?? 'Dokumen & Medis');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final priorityCtrl = TextEditingController(text: existing != null ? '${existing.priority}' : '1');
    String? imageUrl = existing?.imageUrl;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(
              existing == null ? 'Tambah Peralatan Siaga' : 'Edit Peralatan Siaga',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Peralatan',
                      labelStyle: GoogleFonts.inter(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: catCtrl,
                    decoration: InputDecoration(
                      labelText: 'Kategori (contoh: Medis, Logistik, Alat Komunikasi)',
                      labelStyle: GoogleFonts.inter(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: priorityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Prioritas (1 = Sangat Penting, dst)',
                      labelStyle: GoogleFonts.inter(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ImageUploadField(
                    initialUrl: imageUrl,
                    folder: 'peralatan',
                    label: 'Foto Peralatan Siaga',
                    hint: 'Opsional',
                    onChanged: (url) {
                      imageUrl = url;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi / Alasan Kesiapsiagaan',
                      labelStyle: GoogleFonts.inter(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Batal', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final cat = catCtrl.text.trim();
                  final desc = descCtrl.text.trim();
                  final priority = int.tryParse(priorityCtrl.text.trim()) ?? 0;

                  if (name.isEmpty || desc.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nama dan deskripsi tidak boleh kosong')),
                    );
                    return;
                  }

                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  bool success = false;
                  if (existing == null) {
                    success = await ref.read(adminProvider.notifier).createPeralatan(
                          name: name,
                          category: cat,
                          description: desc,
                          priority: priority,
                          imageUrl: imageUrl,
                        );
                  } else {
                    success = await ref.read(adminProvider.notifier).updatePeralatan(
                      existing.id,
                      {
                        'name': name,
                        'category': cat,
                        'description': desc,
                        'priority': priority,
                        'imageUrl': imageUrl,
                      },
                    );
                  }

                  if (mounted && !success) {
                    final err = ref.read(adminProvider).error;
                    if (err != null) {
                      messenger.showSnackBar(SnackBar(content: Text(err)));
                    }
                  }
                },
                child: Text('Simpan', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Hapus Peralatan?',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Peralatan ini akan dihapus dari daftar kesiapsiagaan.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(adminProvider.notifier).deletePeralatan(id);
            },
            child: Text('Hapus', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
