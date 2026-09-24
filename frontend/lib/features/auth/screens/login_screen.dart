import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  Future<void> _handleLogin() async {
    await ref.read(authStateProvider.notifier).loginDirectly(
      name: 'Rizal Zaky',
      email: 'rizalzaky@gmail.com',
    );
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  Future<void> _handleKindeLogin() async {
    final googleConnId = dotenv.env['KINDE_GOOGLE_CONNECTION_ID'];
    await ref.read(authStateProvider.notifier).loginWithKinde(
          connectionId: (googleConnId != null && googleConnId.trim().isNotEmpty)
              ? googleConnId.trim()
              : null,
        );
    if (!mounted) return;
    final s = ref.read(authStateProvider);
    if (s.isAuthenticated) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _handleGuest() async {
    await ref.read(authStateProvider.notifier).continueAsGuest();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Blue gradient header with wave ──
          SizedBox(
            width: double.infinity,
            height: size.height * 0.42,
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF3B5BDB),
                        Color(0xFF1E40AF),
                      ],
                    ),
                  ),
                ),
                // Wave decoration at bottom of header
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: CustomPaint(
                    size: Size(size.width, 60),
                    painter: _WavePainter(color: Colors.white),
                  ),
                ),
                // Logo & title
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 40,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      // Tsunami icon in rounded square
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.waves_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tsunami',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Peringatan dini, kapan pun dibutuhkan',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── White card body ──
          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.only(top: size.height * 0.35),
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Masuk ke akun',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pantau gempa dan tsunami secara real-time',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Error banner
                    if (authState.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.danger, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(authState.error!,
                                  style: const TextStyle(
                                      color: AppColors.danger, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Masuk dengan Kinde (SSO) button ──
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                'Masuk',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Divider "atau"
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('atau',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textMuted)),
                        ),
                        const Expanded(child: Divider(color: AppColors.border)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Google Login (via Kinde Google OAuth)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: isLoading ? null : _handleKindeLogin,
                        style: OutlinedButton.styleFrom(
                          side:
                              const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google "G" logo
                            _GoogleIcon(),
                            const SizedBox(width: 10),
                            Text(
                              'Masuk dengan Google',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lanjutkan sebagai tamu
                    Center(
                      child: TextButton(
                        onPressed: isLoading ? null : _handleGuest,
                        child: Text(
                          'Lanjutkan sebagai tamu',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Daftar link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Belum punya akun? ',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary)),
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.register),
                          child: Text(
                            'Daftar',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wave painter ──
class _WavePainter extends CustomPainter {
  final Color color;
  const _WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(
        size.width * 0.25, 0, size.width * 0.5, size.height * 0.4);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.8, size.width, size.height * 0.3);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => false;
}

// ── Google G icon ──
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / 2;
    // Blue arc
    _drawArc(canvas, size, c, const Color(0xFF4285F4), -0.12, 1.0);
    // Red arc
    _drawArc(canvas, size, c, const Color(0xFFEA4335), 0.88, 0.5);
    // Yellow arc
    _drawArc(canvas, size, c, const Color(0xFFFBBC04), 1.38, 0.5);
    // Green arc
    _drawArc(canvas, size, c, const Color(0xFF34A853), 1.88, 0.5);
    // White center (G notch)
    final p = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(c, c - size.height * 0.18,
        size.width * 0.5, size.height * 0.36), p);
    canvas.drawCircle(
        Offset(c, c), size.width * 0.3, Paint()..color = Colors.white);
    // Redraw partial colored ring
    _drawRing(canvas, size, c);
  }

  void _drawArc(Canvas canvas, Size size, double c, Color color,
      double startFrac, double sweepFrac) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(c, c), radius: size.width * 0.41),
      startFrac * 3.14159,
      sweepFrac * 3.14159,
      false,
      p,
    );
  }

  void _drawRing(Canvas canvas, Size size, double c) {
    // No additional drawing needed; the arcs compose into Google G appearance
  }

  @override
  bool shouldRepaint(_GooglePainter old) => false;
}
