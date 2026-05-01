import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Shield bounce
  late AnimationController _bounceCtl;
  late Animation<double> _bounceAnim;

  // 3 outward pulse rings
  late AnimationController _pulseCtl;

  // Content fade-up
  late AnimationController _fadeCtl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Typewriter
  final String _tagline = 'Automating authorizations. Fighting for your coverage.';
  String _typedText = '';
  Timer? _typeTimer;

  @override
  void initState() {
    super.initState();

    // Shield bounce in
    _bounceCtl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
    _bounceAnim = CurvedAnimation(parent: _bounceCtl, curve: Curves.elasticOut);
    _bounceCtl.forward();

    // Pulse rings — repeat
    _pulseCtl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000))..repeat();

    // Content fade+slide
    _fadeCtl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _fadeCtl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fadeCtl.forward();
    });

    // Typewriter (starts at 500ms)
    Future.delayed(const Duration(milliseconds: 500), _startTypewriter);

    // Navigate at 2.4s
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) widget.onDone();
    });
  }

  void _startTypewriter() {
    int idx = 0;
    _typeTimer = Timer.periodic(const Duration(milliseconds: 38), (t) {
      if (!mounted) { t.cancel(); return; }
      if (idx >= _tagline.length) { t.cancel(); return; }
      setState(() => _typedText = _tagline.substring(0, ++idx));
    });
  }

  @override
  void dispose() {
    _bounceCtl.dispose();
    _pulseCtl.dispose();
    _fadeCtl.dispose();
    _typeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [C.surf0, C.surf1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Pulse rings + shield ──────────────────────────────────
                    SizedBox(
                      width: 220, height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Animated outer rings
                          AnimatedBuilder(
                            animation: _pulseCtl,
                            builder: (_, __) => Stack(
                              alignment: Alignment.center,
                              children: [
                                _PulseRingWidget(_pulseCtl, 0.0, 140),
                                _PulseRingWidget(_pulseCtl, 0.33, 110),
                                _PulseRingWidget(_pulseCtl, 0.66, 80),
                              ],
                            ),
                          ),
                          // Shield with bounce
                          ScaleTransition(
                            scale: _bounceAnim,
                            child: Container(
                              width: 76, height: 76,
                              decoration: const BoxDecoration(
                                color: C.teal500,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.health_and_safety_rounded,
                                size: 38, color: C.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── Brand ────────────────────────────────────────────────
                    Text('MediAuth AI',
                      style: GoogleFonts.inter(
                        fontSize: 34, fontWeight: FontWeight.w700,
                        color: C.textPrimary, letterSpacing: -1)),
                    const SizedBox(height: 10),

                    // Typewriter tagline
                    SizedBox(
                      height: 20,
                      child: Text(
                        _typedText.isEmpty ? '' : _typedText,
                        style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w400,
                          color: C.textTertiary),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: C.teal50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: C.teal500.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt_rounded, size: 14, color: C.teal600),
                          const SizedBox(width: 5),
                          Text('Veersa Hackathon 2027',
                            style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: C.teal700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseRingWidget extends StatelessWidget {
  final AnimationController ctrl;
  final double delay;
  final double size;
  const _PulseRingWidget(this.ctrl, this.delay, this.size);

  @override
  Widget build(BuildContext context) {
    final val = (ctrl.value + delay) % 1.0;
    final scale = 1.0 + val * 0.6;
    final opacity = (1.0 - val) * 0.25;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: C.teal500.withValues(alpha: opacity),
          border: Border.all(
            color: C.teal500.withValues(alpha: opacity * 1.5),
            width: 1.5),
        ),
      ),
    );
  }
}
