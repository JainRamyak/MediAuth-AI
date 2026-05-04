import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';
import '../api/api_service.dart';

// ── Denied & Escalated Result Screen ─────────────────────────────────────────
// Handles both 'denied' (with appeal info) and 'escalated' (max appeals reached)

class DeniedScreen extends StatefulWidget {
  final Map<String, dynamic> result;
  final VoidCallback onNewRequest;
  final VoidCallback onHome;
  final void Function(Map<String, dynamic> result)? onApproved;

  const DeniedScreen({
    super.key,
    required this.result,
    required this.onNewRequest,
    required this.onHome,
    this.onApproved,
  });

  @override
  State<DeniedScreen> createState() => _DeniedScreenState();
}

class _DeniedScreenState extends State<DeniedScreen> {
  bool _letterExpanded = false;
  bool _appealing = false;
  late Map<String, dynamic> _result;

  @override
  void initState() {
    super.initState();
    _result = Map.from(widget.result);
  }

  String get _status =>
      _result['workflow_status']?.toString().toLowerCase() ?? '';

  bool get _isEscalated => _status.contains('escalat') || _appealLevel >= 3;

  int get _appealLevel => (_result['appeal_level'] as num?)?.toInt() ?? 0;

  String get _letter =>
      _result['justification_letter']?.toString() ?? '';

  List<dynamic> get _trail =>
      _result['audit_trail'] as List<dynamic>? ?? [];

  /// Re-run the full pipeline (Agent 6 handles the appeal internally).
  Future<void> _runAppeal() async {
    final patientText = _result['patient_text']?.toString() ?? '';
    final treatText   = _result['requested_treatment']?.toString() ?? '';
    if (patientText.isEmpty || treatText.isEmpty) {
      showMediToast(context, 'Cannot re-submit: original data missing.', kind: ToastKind.error);
      return;
    }
    setState(() => _appealing = true);
    try {
      final res = await ApiService.authorizeTreatment(patientText, treatText);
      if (!mounted) return;
      final newStatus = res['workflow_status']?.toString().toLowerCase() ?? '';
      setState(() {
        _result = {
          ...res,
          'patient_text':        patientText,
          'requested_treatment': treatText,
        };
        _appealing = false;
      });
      if (newStatus.contains('approved')) {
        widget.onApproved?.call(_result);
      }
      // If still denied the screen updates in place with new level / letter.
    } catch (e) {
      if (!mounted) return;
      setState(() => _appealing = false);
      showMediToast(context, 'Appeal failed: ${e.toString().replaceFirst('ApiException: ', '')}', kind: ToastKind.error);
    }
  }

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
    return names[key] ?? key.replaceAll('_', ' ');
  }

  Color _statusColor(String s) {
    if (s.contains('success') || s.contains('approved')) return C.green700;
    if (s.contains('denied'))                            return C.red700;
    if (s.contains('submitted') || s.contains('appeal')) return C.violet700;
    return C.textTertiary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surf1,
      body: CustomScrollView(
        slivers: [
          // ── Hero ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isEscalated
                      ? [C.amber600, C.amber700]
                      : [C.red500, C.red700],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(children: [
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
                      child: Icon(
                        _isEscalated
                            ? Icons.report_problem_rounded
                            : Icons.gavel_rounded,
                        size: 44, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isEscalated ? 'Escalated' : 'Denied — Appeal Filed',
                      style: GoogleFonts.outfit(
                        fontSize: 30, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: -0.8)),
                    const SizedBox(height: 8),
                    Text(
                      _isEscalated
                          ? 'Maximum appeals reached. Please contact your doctor.'
                          : 'Our AI has already written and submitted your appeal.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14, color: Colors.white70, height: 1.5)),
                    if (_appealLevel > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('Appeal Level: $_appealLevel of 3',
                          style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.white,
                            fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ]),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Denial reason ─────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: C.red50,
                        border: Border.all(color: C.red500.withValues(alpha: 0.25), width: 0.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.cancel_outlined, color: C.red500, size: 18),
                        const SizedBox(width: 8),
                        Text('Denial Reason',
                          style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: C.red700)),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                        widget.result['denial_reason']?.toString().isNotEmpty == true
                            ? widget.result['denial_reason'].toString()
                            : 'The request did not meet the insurer\'s current authorization criteria.',
                        style: GoogleFonts.inter(
                          fontSize: 13, color: C.red700, height: 1.5)),
                    ],
                  ),
                ),
                Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 4, color: C.red500)),
              ]),
            ),
            const SizedBox(height: 16),

                // ── AI response card ──────────────────────────────────────
                if (!_isEscalated) ...[
                  MediCard(
                    accentColor: C.violet500,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.smart_toy_outlined, color: C.violet500, size: 18),
                          const SizedBox(width: 8),
                          Text('What Our AI Did Next',
                            style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: C.textPrimary)),
                        ]),
                        const SizedBox(height: 10),
                        Text(
                          'We reviewed the denial, cross-referenced your treatment history, '
                          'and immediately filed a Level $_appealLevel appeal with a stronger '
                          'justification letter citing clinical evidence.',
                          style: GoogleFonts.inter(
                            fontSize: 13, color: C.textSecondary, height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Escalated timeline ────────────────────────────────────
                if (_isEscalated) ...[
                  MediCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Appeal History',
                          style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: C.textPrimary)),
                        const SizedBox(height: 12),
                        ...List.generate(3, (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(children: [
                            Container(
                              width: 28, height: 28,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: C.red50),
                              child: const Icon(Icons.close_rounded,
                                  size: 16, color: C.red500),
                            ),
                            const SizedBox(width: 12),
                            Text('Level ${i + 1} Appeal — Denied',
                              style: GoogleFonts.inter(
                                fontSize: 13, color: C.textSecondary)),
                          ]),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  MediCard(
                    accentColor: C.amber500,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.tips_and_updates_outlined,
                              color: C.amber600, size: 18),
                          const SizedBox(width: 8),
                          Text('Next Steps',
                            style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: C.textPrimary)),
                        ]),
                        const SizedBox(height: 10),
                        Text(
                          'Please contact your treating physician to discuss alternative treatments '
                          'or to request a formal external review with your insurer.',
                          style: GoogleFonts.inter(
                            fontSize: 13, color: C.textSecondary, height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── AI Trail ─────────────────────────────────────────────
                if (_trail.isNotEmpty) ...[
                  Text('AI Activity Trail',
                    style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: C.textPrimary)),
                  const SizedBox(height: 10),
                  MediCard(
                    child: Column(
                      children: _trail.asMap().entries.map((e) {
                        final entry  = e.value as Map<String, dynamic>? ?? {};
                        final agent  = entry['agent']?.toString() ?? '';
                        final status = entry['status']?.toString() ?? '';
                        final detail = entry['detail']?.toString() ?? '';
                        final ok = status.contains('success') || status.contains('approved') || status.contains('submitted');
                        final isLast = e.key == _trail.length - 1;
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
                                        fontSize: 11, color: C.textSecondary, height: 1.4)),
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

                // ── Letter preview ────────────────────────────────────────
                if (_letter.isNotEmpty) ...[
                  MediCard(
                    accentColor: C.violet500,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.description_outlined,
                              size: 18, color: C.violet500),
                          const SizedBox(width: 8),
                          Text('Appeal Letter  ·  ${_letter.split(' ').length} words',
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
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => setState(() => _letterExpanded = !_letterExpanded),
                          child: Text(
                            _letterExpanded ? 'Show less ↑' : 'View full letter ↓',
                            style: GoogleFonts.inter(
                              fontSize: 13, color: C.violet500,
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

                // ── Appeal / Escalation CTA ───────────────────────────────
                if (!_isEscalated) ...[
                  if (_letter.isNotEmpty) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy Appeal Letter'),
                      onPressed: _appealing ? null : () {
                        Clipboard.setData(ClipboardData(text: _letter));
                        showMediToast(context, 'Letter copied to clipboard');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: C.violet500,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  PrimaryButton(
                    label: 'Appeal Decision (Level ${_appealLevel + 1} of 3)',
                    icon: Icons.gavel_rounded,
                    loading: _appealing,
                    onPressed: _appealing ? null : _runAppeal,
                  ),
                  const SizedBox(height: 10),
                ],
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('File Another Request'),
                  onPressed: _appealing ? null : widget.onNewRequest,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: C.textPrimary,
                    side: const BorderSide(color: C.surf3),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
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
