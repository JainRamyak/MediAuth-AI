import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';

// ── S09 Denied — real API data ────────────────────────────────────────────────
// Displays data from POST /api/v1/authorize when workflow_status indicates denial.
// Fields used:
//   appeal_level        → shows current appeal level in banner + lifecycle stepper
//   audit_trail         → extracts denial reason from last agent entry
//   justification_letter → shown as appeal letter preview

class DeniedScreen extends StatefulWidget {
  final VoidCallback onAppeal;
  final VoidCallback onDashboard;

  /// Raw response map from POST /api/v1/authorize. Null-safe throughout.
  final Map<String, dynamic>? apiResult;

  const DeniedScreen({
    super.key,
    required this.onAppeal,
    required this.onDashboard,
    this.apiResult,
  });

  @override
  State<DeniedScreen> createState() => _DeniedScreenState();
}

class _DeniedScreenState extends State<DeniedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctl;
  late Animation<double> _fade;
  bool _reasonExpanded = false;
  bool _notifyEnabled = false;

  // ── Derived data ──────────────────────────────────────────────────────────

  int get _appealLevel =>
      int.tryParse(widget.apiResult?['appeal_level']?.toString() ?? '0') ?? 0;

  String get _workflowStatus =>
      widget.apiResult?['workflow_status']?.toString() ?? 'denied';

  List<dynamic> get _auditTrail =>
      widget.apiResult?['audit_trail'] as List<dynamic>? ?? [];

  String get _denialReason {
    // Try to extract denial reason from audit trail
    if (_auditTrail.isNotEmpty) {
      for (final entry in _auditTrail.reversed) {
        final e = entry as Map<String, dynamic>? ?? {};
        final action = e['action']?.toString() ?? '';
        final output = e['output_data'];
        if (action.toLowerCase().contains('deni') ||
            action.toLowerCase().contains('appeal')) {
          if (output is Map) {
            final reason = output['denial_reason']?.toString() ??
                output['reason']?.toString() ??
                output['decision_reason']?.toString() ?? '';
            if (reason.isNotEmpty) return reason;
          }
          if (action.isNotEmpty) return action;
        }
      }
      // Fallback: last audit trail entry action
      final last = _auditTrail.last as Map<String, dynamic>? ?? {};
      final lastAction = last['action']?.toString() ?? '';
      if (lastAction.isNotEmpty) return lastAction;
    }
    // Generic fallback
    return _workflowStatus.contains('escalat')
        ? 'All 3 appeal levels exhausted. Human review required.'
        : 'The insurer denied this authorization request. An appeal has been automatically filed.';
  }



  static const _steps = ['Submitted', 'Denied', 'L1 Appeal', 'L2 Review', 'Final'];

  /// Which step index is currently active based on appeal level + status.
  int get _activeStep {
    if (_workflowStatus.contains('escalat')) return 4;
    if (_appealLevel >= 2) return 3;
    if (_appealLevel >= 1) return 2;
    return 1; // Just denied, no appeal yet
  }

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctl, curve: Curves.easeOut);
    _ctl.forward();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        title: Text('Request Denied',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: C.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onDashboard,
        ),
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero banner ───────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: C.amber500.withValues(alpha: 0.5), width: 1),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: C.amber600, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('DENIED — APPEAL AUTOMATICALLY FILED',
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: C.amber700,
                                  letterSpacing: -0.2)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your request was denied. Our AI has already written and filed an appeal for you.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: C.amber700, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: C.amber500.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _appealLevel > 0
                            ? 'Appeal Level: $_appealLevel of 3'
                            : 'Appeal Level: 1 of 3',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: C.amber700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Denial reason — expandable ────────────────────────────────
              GestureDetector(
                onTap: () =>
                    setState(() => _reasonExpanded = !_reasonExpanded),
                child: MediCard(
                  accentColor: C.red500,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 16, color: C.red500),
                        const SizedBox(width: 8),
                        Text('Why it was denied',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: C.textPrimary)),
                        const Spacer(),
                        Icon(
                          _reasonExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: C.textTertiary),
                      ]),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        child: _reasonExpanded
                            ? Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(_denialReason,
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: C.textSecondary,
                                        height: 1.6)),
                              )
                            : const SizedBox.shrink(),
                      ),
                      if (!_reasonExpanded) ...[
                        const SizedBox(height: 6),
                        Text(
                          _denialReason,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: C.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── AI Appeal in Progress ─────────────────────────────────────
              MediCard(
                accentColor: C.teal500,
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                        color: C.teal50, shape: BoxShape.circle),
                    child: const Icon(Icons.smart_toy_rounded,
                        size: 22, color: C.teal600),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text('AI Appeal in Progress',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: C.textPrimary)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: C.violet50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: C.violet500.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'Level ${_appealLevel > 0 ? _appealLevel : 1} / 3',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: C.violet700)),
                          ),
                        ]),
                        const SizedBox(height: 3),
                        Text(
                          "We're fighting this denial. No action needed from you.",
                          style: GoogleFonts.inter(
                              fontSize: 12, color: C.textSecondary)),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Lifecycle stepper ─────────────────────────────────────────
              Text('Request Lifecycle',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: C.textPrimary)),
              const SizedBox(height: 12),
              MediCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _steps.asMap().entries.map((entry) {
                    final i = entry.key;
                    final label = entry.value;
                    final isPast = i < _activeStep;
                    final isActive = i == _activeStep;

                    return Expanded(
                      child: Column(children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? C.teal500
                                : isPast
                                    ? C.green50
                                    : C.surf2,
                            border: Border.all(
                                color: isActive
                                    ? C.teal500
                                    : isPast
                                        ? C.green500
                                        : C.surf3,
                                width: 1.5),
                          ),
                          child: Center(
                              child: isActive
                                  ? const Icon(Icons.circle,
                                      size: 10, color: C.white)
                                  : isPast
                                      ? const Icon(Icons.check,
                                          size: 14, color: C.green500)
                                      : null),
                        ),
                        const SizedBox(height: 5),
                        Text(label,
                            style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? C.teal600
                                    : isPast
                                        ? C.green600
                                        : C.textTertiary),
                            textAlign: TextAlign.center),
                      ]),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // ── What our AI is doing ───────────────────────────────────────
              MediCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What our AI advocate is doing',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: C.textPrimary)),
                    const SizedBox(height: 12),
                    ...[
                      'Analyzing the denial reason and clinical evidence',
                      'Drafting a medical necessity appeal letter',
                      'Pulling supporting studies and AMA guidelines',
                      'Resubmitting directly to your insurer',
                    ].map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                    color: C.teal50, shape: BoxShape.circle),
                                child: const Icon(Icons.check_rounded,
                                    size: 12, color: C.teal600),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(item,
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: C.textSecondary,
                                          height: 1.4))),
                            ],
                          ),
                        )),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: C.amber50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: C.amber500.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.schedule_rounded,
                            size: 14, color: C.amber600),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                          'L${(_appealLevel + 1).clamp(2, 3)} escalation begins automatically in 48 hours if no response.',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: C.amber700),
                        )),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Action Buttons ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onAppeal,
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: Text('View Appeal Letter',
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          backgroundColor: C.teal500,
                          foregroundColor: C.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () {
                      showMediToast(context, 'Downloading appeal letter...',
                          kind: ToastKind.success);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(52, 52),
                      foregroundColor: C.teal600,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: C.teal500, width: 1),
                    ),
                    child: const Icon(Icons.download_rounded, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Notify toggle
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _notifyEnabled = !_notifyEnabled);
                  showMediToast(
                    context,
                    _notifyEnabled
                        ? 'Notifications enabled for this appeal.'
                        : 'Notifications turned off.',
                    kind: _notifyEnabled ? ToastKind.success : ToastKind.warning,
                  );
                },
                icon: Icon(
                  _notifyEnabled
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_outlined,
                  size: 18,
                  color: _notifyEnabled ? C.teal600 : C.textSecondary,
                ),
                label: Text(
                  _notifyEnabled
                      ? 'Notifications On'
                      : 'Notify Me of Appeal Outcome',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _notifyEnabled ? C.teal600 : C.textSecondary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  foregroundColor:
                      _notifyEnabled ? C.teal600 : C.textSecondary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(
                      color: _notifyEnabled ? C.teal500 : C.surf3,
                      width: _notifyEnabled ? 1.5 : 0.5),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: widget.onDashboard,
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    foregroundColor: C.textPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: C.surf3)),
                child: Text('Back to Dashboard',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}