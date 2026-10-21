import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/admin/providers/admin_provider.dart';

class ImageUploadField extends ConsumerStatefulWidget {
  final String? initialUrl;
  final String folder;
  final String label;
  final String? hint;
  final ValueChanged<String?> onChanged;

  const ImageUploadField({
    super.key,
    this.initialUrl,
    required this.folder,
    required this.label,
    this.hint,
    required this.onChanged,
  });

  @override
  ConsumerState<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends ConsumerState<ImageUploadField> {
  final ImagePicker _picker = ImagePicker();
  String? _currentUrl;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
  }

  @override
  void didUpdateWidget(covariant ImageUploadField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialUrl != widget.initialUrl) {
      _currentUrl = widget.initialUrl;
    }
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (file == null) return;

      setState(() {
        _isUploading = true;
        _errorMessage = null;
      });

      final Uint8List bytes = await file.readAsBytes();
      final url = await ref.read(adminProvider.notifier).uploadFile(
            bytes: bytes,
            filename: file.name,
            folder: widget.folder,
          );

      if (mounted) {
        if (url != null && url.isNotEmpty) {
          setState(() {
            _currentUrl = url;
            _isUploading = false;
          });
          widget.onChanged(url);
        } else {
          final err = ref.read(adminProvider).error ?? 'Gagal mengunggah gambar. Coba lagi.';
          setState(() {
            _isUploading = false;
            _errorMessage = err;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Terjadi kesalahan: $e';
        });
      }
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Pilih Sumber Gambar',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B6FE8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: Color(0xFF3B6FE8)),
                ),
                title: Text(
                  'Galeri Foto',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'Pilih gambar dari penyimpanan perangkat',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUpload(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Color(0xFF059669)),
                ),
                title: Text(
                  'Kamera',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'Ambil foto baru langsung dengan kamera',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUpload(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeImage() {
    setState(() {
      _currentUrl = null;
      _errorMessage = null;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
            if (widget.hint != null) ...[
              const SizedBox(width: 4),
              Text(
                '(${widget.hint})',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        if (_isUploading)
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF3B6FE8),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Mengunggah ke Cloudflare R2...',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mohon tunggu sebentar',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          )
        else if (_currentUrl != null && _currentUrl!.isNotEmpty)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: _currentUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_rounded,
                                  color: Color(0xFF94A3B8), size: 36),
                              SizedBox(height: 6),
                              Text(
                                'Gagal memuat gambar',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.white, size: 20),
                          tooltip: 'Hapus gambar',
                          onPressed: _removeImage,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF10B981), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _currentUrl!.split('/').last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _showPickerOptions,
                        icon: const Icon(Icons.sync_rounded, size: 14),
                        label: Text(
                          'Ganti',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          InkWell(
            onTap: _showPickerOptions,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFCBD5E1),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B6FE8).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      color: Color(0xFF3B6FE8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pilih Gambar',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JPG, PNG, atau WEBP (Maksimal 50MB)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFEF4444), size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
