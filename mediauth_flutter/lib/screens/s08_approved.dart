import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';

class ApprovedScreen extends StatefulWidget {
  final VoidCallback onDone;
  const ApprovedScreen({super.key, required this.onDone});

  @override
  State<ApprovedScreen> createState() => _ApprovedScreenState();
}

class _ApprovedScreenState extends State<ApprovedScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroCtl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  // Confetti
  late AnimationController _confCtl;
  late Animation<double> _confAnim;
  final _dots = generateConfetti();

  @override
  void initState() {
    super.initState();

    _heroCtl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
    _scale   = CurvedAnimation(parent: _heroCtl, curve: Curves.elasticOut);
    _opacity = CurvedAnimation(parent: _heroCtl, curve: Curves.easeOut);
    _heroCtl.forward();

    _confCtl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000));
    _confAnim = CurvedAnimation(parent: _confCtl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _confCtl.forward();
    });
  }

  @override
  void dispose() {
    _heroCtl.dispose();
    _confCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surf0,
      appBar: AppBar(
        title: Text('Authorization Approved',
          style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w600,
            color: C.textPrimary)),
        automaticallyImplyLeading: false,
        backgroundColor: C.surf0,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Confetti layer
          AnimatedBuilder(
            animation: _confAnim,
            builder: (_, __) => CustomPaint(
              painter: ConfettiPainter(
                progress: _confAnim.value,
                dots: _dots),
              size: Size.infinite,
            ),
          ),

          // Content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Column(
              children: [
                // ── Hero ─────────────────────────────────────────────────────
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _heroCtl,
                  builder: (_, __) => Opacity(
                    opacity: _opacity.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: _scale.value.clamp(0.0, 1.3),
                      child: PulseRings(
                        color: C.green500,
                        child: Container(
                          width: 114, height: 114,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: C.green50,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            size: 62, color: C.green500),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text('Your Treatment is Approved!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: C.textPrimary, letterSpacing: -0.4)),
                const SizedBox(height: 6),
                Text('Margaret Thompson · Blue Cross Blue Shield',
                  style: GoogleFonts.inter(
                    fontSize: 13, color: C.textSecondary)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: C.surf1,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: C.surf3),
                  ),
                  child: Text('Ref #AUTH-2027-001',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: C.textPrimary)),
                ),
                const SizedBox(height: 24),

                // ── Bento summary grid ────────────────────────────────────────
                _BentoGrid(items: const [
                  (Icons.calendar_today_rounded, 'Approved On',
                    'May 1, 2027', C.green500),
                  (Icons.schedule_rounded, 'Valid Until',
                    'May 1, 2028', C.blue500),
                  (Icons.business_outlined, 'Approved By',
                    'Blue Cross', C.teal500),
                  (Icons.receipt_long_outlined, 'Ref Number',
                    'BCB-2027-482', C.violet500),
                ]),
                const SizedBox(height: 14),

                // ── Codes card ────────────────────────────────────────────────
                MediCard(
                  accentColor: C.green500,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Authorized Codes',
                        style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: C.textPrimary)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          _CodeChip('ICD-10', 'M17.11', C.teal50, C.teal700),
                          _CodeChip('ICD-10', 'M17.12', C.teal50, C.teal700),
                          _CodeChip('CPT', '27447', C.navy50, C.navy500),
                          _CodeChip('CPT', '99213', C.navy50, C.navy500),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        height: 0.5, color: C.surf3),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Out-of-Pocket Estimate',
                            style: GoogleFonts.inter(
                              fontSize: 13, color: C.textSecondary)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: C.green50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: C.green500.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7, height: 7,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: C.green500)),
                                const SizedBox(width: 7),
                                Text('\$0.00 COPAY',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: C.green600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Approval letter card ────────────────────────────────────
                MediCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.description_outlined,
                          size: 18, color: C.teal600),
                        const SizedBox(width: 8),
                        Text('Approval Letter',
                          style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: C.textPrimary)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: C.green50,
                            borderRadius: BorderRadius.circular(8)),
                          child: Text('Ready',
                            style: GoogleFonts.inter(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: C.green600)),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Text(
                        'Dear Margaret Thompson,\n\n'
                        'We are writing to inform you that your treatment request '
                        'for Total Knee Arthroplasty (CPT 27447) with Dr. Sarah Kim '
                        'has been formally approved by Blue Cross Blue Shield. '
                        'Your provider has been notified and will contact you to schedule…',
                        style: GoogleFonts.inter(
                          fontSize: 12, color: C.textSecondary, height: 1.6),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        child: Text('View full letter →',
                          style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: C.teal600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Actions ───────────────────────────────────────────────────
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text('Download PDF Letter',
                    style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: C.teal500,
                    foregroundColor: C.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Share with Provider'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    foregroundColor: C.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: C.surf3)),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: widget.onDone,
                  child: Text('Back to Dashboard',
                    style: GoogleFonts.inter(
                      fontSize: 14, color: C.textSecondary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BentoGrid extends StatelessWidget {
  final List<(IconData, String, String, Color)> items;
  const _BentoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: items.map((item) {
        final (icon, label, value, color) = item;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                    style: GoogleFonts.inter(
                      fontSize: 10, color: C.textTertiary,
                      fontWeight: FontWeight.w500)),
                  Text(value,
                    style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: C.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }
}

class _CodeChip extends StatelessWidget {
  final String type, code;
  final Color bg, fg;
  const _CodeChip(this.type, this.code, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(type,
          style: GoogleFonts.inter(
            fontSize: 9, fontWeight: FontWeight.w600,
            color: fg.withValues(alpha: 0.6), letterSpacing: 0.5)),
        Text(code,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: fg)),
      ],
    ),
  );
}
