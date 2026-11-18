import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/router/app_router.dart';

/// Netflix-inspired SAMUDRA Splash Screen.
///
/// Koreografi 4 fase:
///  Fase 1 (0.00–0.45): Ikon ombak muncul — scale-up + rotasi halus + fade-in + glow
///  Fase 2 (0.25–0.50): Wordmark "samudra" slide-up + fade-in di bawah ikon
///  Fase 3 (0.55–0.60): Hold — logo utuh diam sejenak
///  Fase 4 (0.60–0.90): Dramatic zoom-in ala Netflix + fade-out wordmark
///  Navigasi di ~2.4s
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;

  // ── Fase 1: Ikon ombak ──
  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  late final Animation<double> _iconRotation;
  late final Animation<double> _glowOpacity;

  // ── Fase 2: Wordmark ──
  late final Animation<double> _wordmarkFade;
  late final Animation<double> _wordmarkSlide;

  // ── Fase 4: Dramatic zoom ──
  late final Animation<double> _zoomScale;
  late final Animation<double> _zoomFade;

  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    // Sembunyikan status bar selama splash
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // ════════════════════════════════════════════════════════════════════════
    // FASE 1 — Pembentukan Ikon Ombak (0% → 45%)
    // ════════════════════════════════════════════════════════════════════════
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.42, curve: Curves.easeOutBack),
      ),
    );
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
      ),
    );
    _iconRotation = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.42, curve: Curves.easeOutCubic),
      ),
    );
    _glowOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.6), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.25), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.25, end: 0.0), weight: 40),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.05, 0.55, curve: Curves.easeOut),
      ),
    );

    // ════════════════════════════════════════════════════════════════════════
    // FASE 2 — Kemunculan Wordmark (25% → 50%)
    // ════════════════════════════════════════════════════════════════════════
    _wordmarkFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.28, 0.48, curve: Curves.easeOut),
      ),
    );
    _wordmarkSlide = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.28, 0.50, curve: Curves.easeOutCubic),
      ),
    );

    // ════════════════════════════════════════════════════════════════════════
    // FASE 3 — Hold (50% → 60%) — implisit, tidak ada animasi
    // ════════════════════════════════════════════════════════════════════════

    // ════════════════════════════════════════════════════════════════════════
    // FASE 4 — Dramatic Zoom-In ala Netflix (60% → 92%)
    // ════════════════════════════════════════════════════════════════════════
    _zoomScale = Tween<double>(begin: 1.0, end: 18.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.62, 0.92, curve: Curves.easeInExpo),
      ),
    );
    _zoomFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.75, 0.92, curve: Curves.easeIn),
      ),
    );

    _mainController.forward();

    // Navigasi saat animasi hampir selesai
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNextScreen();
      }
    });
  }

  Future<void> _navigateToNextScreen() async {
    if (_navigating || !mounted) return;
    _navigating = true;

    // Kembalikan system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );

    final auth = ref.read(authStateProvider);
    final destination =
        (auth.isAuthenticated || auth.isGuest) ? AppRoutes.home : AppRoutes.login;

    if (!mounted) return;
    context.go(destination);
  }

  @override
  void dispose() {
    _mainController.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _mainController,
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2563EB), // Vibrant Royal Blue
                  Color(0xFF1D4ED8), // Deep Blue
                ],
              ),
            ),
            child: Stack(
              children: [
                // ── Partikel dekoratif halus (depth) ──
                ..._buildParticles(),

                // ── Logo utama (ikon + wordmark) ──
                Center(
                  child: FadeTransition(
                    opacity: _zoomFade,
                    child: Transform.scale(
                      scale: _zoomScale.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Ikon Ombak ──
                          _buildWaveIcon(),

                          const SizedBox(height: 18),

                          // ── Wordmark "samudra" ──
                          _buildWordmark(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWaveIcon() {
    return FadeTransition(
      opacity: _iconFade,
      child: Transform.scale(
        scale: _iconScale.value,
        child: Transform.rotate(
          angle: _iconRotation.value * math.pi,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                // Soft outer glow — cyan tint
                BoxShadow(
                  color: const Color(0xFF22D3EE)
                      .withValues(alpha: _glowOpacity.value),
                  blurRadius: 48,
                  spreadRadius: 8,
                ),
                // Secondary glow — deeper blue
                BoxShadow(
                  color: const Color(0xFF3B82F6)
                      .withValues(alpha: _glowOpacity.value * 0.5),
                  blurRadius: 80,
                  spreadRadius: 16,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/logo_icon.png',
              width: 130,
              height: 130,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordmark() {
    return FadeTransition(
      opacity: _wordmarkFade,
      child: Transform.translate(
        offset: Offset(0, _wordmarkSlide.value),
        child: Image.asset(
          'assets/images/wordmark_white.png',
          width: 180,
          filterQuality: FilterQuality.high,
          color: const Color(0xFFE0F2FE), // Biru es terang agar kontras
        ),
      ),
    );
  }

  List<Widget> _buildParticles() {
    // Lingkaran dekoratif transparan memberikan kedalaman visual
    final progress = _mainController.value;
    final particleOpacity = (progress < 0.3)
        ? progress / 0.3 * 0.06
        : (progress > 0.7)
            ? (1.0 - progress) / 0.3 * 0.06
            : 0.06;

    return [
      Positioned(
        top: -60,
        right: -60,
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: particleOpacity),
          ),
        ),
      ),
      Positioned(
        bottom: -100,
        left: -50,
        child: Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: particleOpacity * 0.7),
          ),
        ),
      ),
      Positioned(
        top: MediaQuery.of(context).size.height * 0.35,
        left: -30,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF22D3EE).withValues(alpha: particleOpacity * 0.5),
          ),
        ),
      ),
    ];
  }
}
