import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';

// ── S08 Authorization Approved ────────────────────────────────────────────────
// Displays the real result from POST /api/v1/authorize:
//   auth_request_id  → reference number
//   justification_letter → letter preview
//   appeal_level     → shown in bento grid
//   workflow_status  → shown in bento grid

class ApprovedScreen extends StatefulWidget {
  final VoidCallback onDone;

  /// Raw response map from POST /api/v1/authorize.
  /// Null-safe: all fields have safe fallbacks.
  final Map<String, dynamic>? apiResult;

  const ApprovedScreen({
    super.key,
    required this.onDone,
    this.apiResult,
  });

  @override
  State<ApprovedScreen> createState() => _ApprovedScreenState();
}

class _ApprovedScreenState extends State<ApprovedScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroCtl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  late AnimationController _confCtl;
  late Animation<double> _confAnim;
  final _dots = generateConfetti();

  // ── Derived data helpers ──────────────────────────────────────────────────
  String get _refNumber {
    final id = widget.apiResult?['auth_request_id']?.toString() ?? '';
    if (id.isNotEmpty) return 'REF #${id.substring(0, 8).toUpperCase()}';
    return 'REF #—';
  }

  String get _workflowStatus =>
      widget.apiResult?['workflow_status']?.toString() ?? 'approved';

  int get _appealLevel =>
      int.tryParse(widget.apiResult?['appeal_level']?.toString() ?? '0') ?? 0;

  String get _justificationLetter =>
      widget.apiResult?['justification_letter']?.toString() ?? '';

  List<dynamic> get _auditTrail =>
      widget.apiResult?['audit_trail'] as List<dynamic>? ?? [];

  /// Returns the first 500 chars of the letter for the preview card.
  String get _letterPreview {
    final letter = _justificationLetter;
    if (letter.isEmpty) return 'No justification letter available.';
    return letter.length > 500 ? '${letter.substring(0, 500)}…' : letter;
  }

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

  // ── Full letter dialog ────────────────────────────────────────────────────

  void _showFullLetter(BuildContext context) {
    final letter = _justificationLetter;
    if (letter.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: C.surf0,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: C.surf3,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(children: [
                  const Icon(Icons.description_outlined,
                      size: 18, color: C.teal600),
                  const SizedBox(width: 8),
                  Text('Authorization Letter',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: C.textPrimary)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: C.green50,
                      borderRadius: BorderRadius.circular(8)),
                    child: Text('AI Generated',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: C.green600)),
                  ),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    letter,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        color: C.textSecondary,
                        height: 1.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                // ── Hero ───────────────────────────────────────────────────
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
                Text(
                  _appealLevel > 0
                      ? 'Approved after $_appealLevel appeal(s)'
                      : 'Approved on first submission',
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
                  child: Text(_refNumber,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: C.textPrimary)),
                ),
                const SizedBox(height: 24),

                // ── Bento summary grid ──────────────────────────────────────
                _BentoGrid(items: [
                  (Icons.calendar_today_rounded, 'Approved On',
                    _formattedDate(), C.green500),
                  (Icons.gavel_rounded, 'Appeal Rounds',
                    _appealLevel == 0 ? 'None' : '$_appealLevel', C.teal500),
                  (Icons.shield_rounded, 'Status',
                    _workflowStatus.toUpperCase(), C.blue500),
                  (Icons.receipt_long_outlined, 'Ref ID',
                    _refNumber.replaceAll('REF #', ''), C.violet500),
                ]),
                const SizedBox(height: 14),

                // ── Audit trail summary ─────────────────────────────────────
                if (_auditTrail.isNotEmpty) ...[
                  MediCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.history_rounded,
                              size: 16, color: C.teal600),
                          const SizedBox(width: 8),
                          Text('Agent Activity',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: C.textPrimary)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: C.teal50,
                              borderRadius: BorderRadius.circular(8)),
                            child: Text('${_auditTrail.length} events',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: C.teal700)),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        ...(_auditTrail.take(4).map((entry) {
                          final e = entry as Map<String, dynamic>? ?? {};
                          final agent = e['agent_name']?.toString() ?? 'Agent';
                          final action = e['action']?.toString() ?? '';
                          final status = e['status']?.toString() ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: status.contains('error')
                                        ? C.red500
                                        : C.green500,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(agent,
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: C.textPrimary)),
                                      if (action.isNotEmpty)
                                        Text(action,
                                          style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: C.textTertiary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        })),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Justification letter card ───────────────────────────────
                MediCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.description_outlined,
                          size: 18, color: C.teal600),
                        const SizedBox(width: 8),
                        Text('Authorization Letter',
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
                          child: Text('AI Generated',
                            style: GoogleFonts.inter(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: C.green600)),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Text(
                        _letterPreview,
                        style: GoogleFonts.inter(
                          fontSize: 12, color: C.textSecondary, height: 1.6),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_justificationLetter.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _showFullLetter(context),
                          child: Text('View full letter →',
                            style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: C.teal600)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Actions ───────────────────────────────────────────────────
                ElevatedButton.icon(
                  onPressed: () {
                    // PDF download: future implementation
                  },
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

  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

// ── Bento grid ────────────────────────────────────────────────────────────────

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
