import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

// ── Approved Result Screen ────────────────────────────────────────────────────

class ApprovedScreen extends StatefulWidget {
  final Map<String, dynamic> result;
  final VoidCallback onNewRequest;
  final VoidCallback onHome;

  const ApprovedScreen({
    super.key,
    required this.result,
    required this.onNewRequest,
    required this.onHome,
  });

  @override
  State<ApprovedScreen> createState() => _ApprovedScreenState();
}

class _ApprovedScreenState extends State<ApprovedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _confetti;
  bool _techExpanded = false;
  bool _letterExpanded = false;

  @override
  void initState() {
    super.initState();
    _confetti = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..forward();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  String get _authId {
    final raw = widget.result['auth_request_id']?.toString() ?? '';
    return raw.length > 8 ? raw.substring(0, 8).toUpperCase() : raw.toUpperCase();
  }

  String get _letter =>
      widget.result['justification_letter']?.toString() ?? '';

  List<dynamic> get _trail =>
      widget.result['audit_trail'] as List<dynamic>? ?? [];

  int get _appealLevel => (widget.result['appeal_level'] as num?)?.toInt() ?? 0;

  String _agentName(String key) {
    const names = {
      'intake':           'Intake Agent',
      'medical_analysis': 'Medical Analysis',
      'policy':           'Policy Intelligence',
      'justification':    'Justification Writer',
      'submission':       'Submission Agent',
      'appeal':           'Appeal Agent',
      'claims':           'Claims Validator',
    };
    return names[key] ?? key.replaceAll('_', ' ').toUpperCase();
  }

  Color _statusColor(String status) {
    if (status.contains('success') || status.contains('approved') || status.contains('complete')) return C.green700;
    if (status.contains('submitted') || status.contains('appealing')) return C.violet700;
    if (status.contains('error')) return C.red700;
    return C.textTertiary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surf1,
      body: CustomScrollView(
        slivers: [
          // ── Hero ───────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Confetti painter
                AnimatedBuilder(
                  animation: _confetti,
                  builder: (_, __) => SizedBox(
                    height: 280,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: ConfettiPainter(
                        progress: _confetti.value,
                        dots: generateConfetti(),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [C.green500, C.green700],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: Column(
                        children: [
                          // Back / close
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white70),
                              onPressed: widget.onHome,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 96, height: 96,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
                            ),
                            child: const Icon(Icons.check_rounded,
                                size: 48, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text('Approved',
                            style: GoogleFonts.outfit(
                              fontSize: 30, fontWeight: FontWeight.w800,
                              color: Colors.white, letterSpacing: -0.8)),
                          const SizedBox(height: 8),
                          if (_authId.isNotEmpty)
                            Text('Auth ID: $_authId',
                              style: AppTheme.monoStyle(
                                color: Colors.white70, size: 12)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _appealLevel == 0
                                  ? 'Approved on first submission'
                                  : 'Approved after $_appealLevel appeal(s)',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── AI Activity Trail ─────────────────────────────────────
                if (_trail.isNotEmpty) ...[
                  Text('AI Activity Trail',
                    style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: C.textPrimary)),
                  const SizedBox(height: 10),
                  MediCard(
                    child: Column(
                      children: _trail.asMap().entries.map((e) {
                        final idx = e.key;
                        final entry = e.value as Map<String, dynamic>? ?? {};
                        final agent  = entry['agent']?.toString() ?? '';
                        final status = entry['status']?.toString() ?? '';
                        final detail = entry['detail']?.toString() ?? '';
                        final ok = status.contains('success') ||
                            status.contains('approved') ||
                            status.contains('complete') ||
                            status.contains('submitted');
                        final isLast = idx == _trail.length - 1;
                        return Column(children: [
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ok ? C.green50 : C.red50),
                              child: Icon(
                                ok ? Icons.check_rounded : Icons.close_rounded,
                                color: ok ? C.green600 : C.red500, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(_agentName(agent),
                                    style: GoogleFonts.inter(
                                      fontSize: 13, fontWeight: FontWeight.w700,
                                      color: C.textPrimary)),
                                  if (detail.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(detail,
                                      style: GoogleFonts.inter(
                                        fontSize: 11, color: C.textSecondary,
                                        height: 1.4)),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: ok ? C.green50 : C.red50,
                                borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                status.length > 12 ? '${status.substring(0,12)}…' : status,
                                style: GoogleFonts.inter(
                                  fontSize: 10, fontWeight: FontWeight.w600,
                                  color: _statusColor(status))),
                            ),
                          ]),
                          if (!isLast) ...[const SizedBox(height: 10), const Divider(height: 1), const SizedBox(height: 6)],
                        ]);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Technical details (collapsed) ─────────────────────────
                MediCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _techExpanded = !_techExpanded),
                        child: Row(children: [
                          const Icon(Icons.code_rounded, size: 18, color: C.textTertiary),
                          const SizedBox(width: 8),
                          Text('Technical Details',
                            style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: C.textSecondary)),
                          const Spacer(),
                          Icon(_techExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                            color: C.textTertiary, size: 20),
                        ]),
                      ),
                      if (_techExpanded) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Text('Authorization ID: ${widget.result['auth_request_id'] ?? '—'}',
                          style: AppTheme.monoStyle(color: C.textSecondary, size: 11)),
                        const SizedBox(height: 4),
                        Text('Status: ${widget.result['workflow_status'] ?? '—'}',
                          style: AppTheme.monoStyle(color: C.textSecondary, size: 11)),
                        Text('Appeal Level: $_appealLevel',
                          style: AppTheme.monoStyle(color: C.textSecondary, size: 11)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Letter preview ─────────────────────────────────────────
                if (_letter.isNotEmpty) ...[
                  MediCard(
                    accentColor: C.teal500,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.description_outlined, size: 18, color: C.teal500),
                          const SizedBox(width: 8),
                          Text('Authorization Letter  ·  ${_letter.split(' ').length} words',
                            style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: C.textPrimary)),
                        ]),
                        const Divider(height: 20),
                        Text(
                          _letter.length > 300
                              ? '${_letter.substring(0, 300)}…'
                              : _letter,
                          style: GoogleFonts.inter(
                            fontSize: 13, color: C.textSecondary, height: 1.6)),
                        const SizedBox(height: 12),
                        // Expand / collapse
                        GestureDetector(
                          onTap: () => setState(() => _letterExpanded = !_letterExpanded),
                          child: Text(
                            _letterExpanded ? 'Show less ↑' : 'View full letter ↓',
                            style: GoogleFonts.inter(
                              fontSize: 13, color: C.teal600,
                              fontWeight: FontWeight.w600)),
                        ),
                        if (_letterExpanded) ...[
                          const SizedBox(height: 12),
                          SelectableText(_letter,
                            style: GoogleFonts.inter(
                              fontSize: 13, color: C.textPrimary, height: 1.7)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Actions ────────────────────────────────────────────────
                if (_letter.isNotEmpty) ...[
                  PrimaryButton(
                    label: 'Copy Letter Text',
                    icon: Icons.copy_rounded,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _letter));
                      showMediToast(context, 'Letter copied to clipboard');
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('File Another Request'),
                  onPressed: widget.onNewRequest,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: C.teal600,
                    side: const BorderSide(color: C.teal500, width: 0.8),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
