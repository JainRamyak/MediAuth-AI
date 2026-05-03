import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../api/api_service.dart';
import 's04_patient_info.dart';
import 's06b_prompt_customization.dart';

// ── Agent UI definitions (icons + timing — no fake outputs) ─────────────────
// Order follows README architecture exactly:
// 1. Intake & History → 2. Medical Analysis →
// [Parallel] 3a. Policy Intelligence & 3b. Claims Validation →
// 4. Justification Writer → 5. Submission & Monitor →
// [If Denied] 6. Denial & Appeal Agent

const _agentDefs = [
  (Icons.manage_search_rounded,  'Intake & History',          'Extracting patient profile and organising all details…',         5),
  (Icons.biotech_outlined,       'Medical Analysis',          'Assigning ICD-10 and CPT codes to your diagnoses and treatment…', 10),
  (Icons.policy_outlined,        'Policy Intelligence',       "Checking your insurer's authorisation rules and coverage…",       16),
  (Icons.receipt_long_outlined,  'Claims Validation',         'Pre-scanning billing codes to minimise risk — running in parallel…', 19),
  (Icons.draw_outlined,          'Justification Writer',      'Drafting the formal prior authorisation letter…',                 24),
  (Icons.send_rounded,           'Submission Agent',          'Submitting your request and awaiting insurer decision…',          28),
  (Icons.gavel_rounded,          'Denial & Appeal Agent',     'Reviewing denial and preparing a counter-argument…',              0), // shown only if denied
];

// ── Screen 7 — AI Processing ─────────────────────────────────────────────────

class AgentPipelineScreen extends StatefulWidget {
  final PatientFormData patient;
  final TreatmentFormData treatment;
  final PromptSubmitPayload? payload;
  final void Function(Map<String, dynamic> result) onApproved;
  final void Function(Map<String, dynamic> result) onDenied;

  const AgentPipelineScreen({
    super.key,
    required this.patient,
    required this.treatment,
    required this.payload,
    required this.onApproved,
    required this.onDenied,
  });

  @override
  State<AgentPipelineScreen> createState() => _AgentPipelineScreenState();
}

class _AgentPipelineScreenState extends State<AgentPipelineScreen> {
  int _done = 0;
  bool _timedOut = false;
  bool _hardTimeout = false;
  int  _elapsed = 0;
  Timer? _clock;
  Map<String, dynamic>? _result;
  bool _apiDone = false;
  List<dynamic> _auditTrail = [];

  @override
  void initState() {
    super.initState();
    _startClock();
    _runAnimation();
    _callApi();
  }

  // ── Build the patient text for the API ────────────────────────────────────

  String _buildPatientText() {
    final p = widget.patient;
    final dob = p.dateOfBirth;
    final dobStr = dob != null
        ? '${dob.year}-${dob.month.toString().padLeft(2,'0')}-${dob.day.toString().padLeft(2,'0')}'
        : 'Unknown';
    return '''Patient: ${p.fullName}
DOB: $dobStr
Insurance: ${p.insurer}
Policy: ${p.policyNumber}
Member ID: ${p.memberId}
Diagnoses: ${p.diagnoses.join(', ')}
Medications: ${p.medications.join(', ')}
Allergies: ${p.allergies.isEmpty ? 'None' : p.allergies}
Medical History: ${p.medicalHistory.isEmpty ? 'None provided' : p.medicalHistory}
Treating Physician: ${p.doctorName.isEmpty ? 'Not specified' : p.doctorName}''';
  }

  // ── Real API call ─────────────────────────────────────────────────────────

  Future<void> _callApi() async {
    try {
      // Save any edited prompts first
      if (widget.payload?.editedAgents != null) {
        for (final ag in widget.payload!.editedAgents) {
          await ApiService.updatePrompt(ag);
        }
      }

      var pText = _buildPatientText();
      final ctx = widget.payload?.customContext ?? '';
      if (ctx.isNotEmpty) pText = '$ctx\n\n$pText';

      final treatText = widget.treatment.requestedTreatment +
          (widget.treatment.whyNeeded.isNotEmpty
              ? '\nReason: ${widget.treatment.whyNeeded}' : '');

      final res = await ApiService.authorizeTreatment(pText, treatText);

      // Extract real audit trail from API response
      _auditTrail = res['audit_trail'] as List<dynamic>? ?? [];

      // Persist full result to local history
      try {
        final prefs = await SharedPreferences.getInstance();
        final hist  = prefs.getStringList('auth_history') ?? [];
        final entry = {
          ...res,
          'patient_text':        pText,         // stored for appeal re-submission
          'requested_treatment': treatText,     // stored for appeal re-submission
          'insurer':             widget.patient.insurer,
          'policy_number':       widget.patient.policyNumber,
          'created_at':          DateTime.now().toIso8601String(),
        };
        hist.insert(0, jsonEncode(entry));
        if (hist.length > 50) hist.removeLast();
        await prefs.setStringList('auth_history', hist);
      } catch (_) {}

      if (!mounted) return;
      setState(() { _result = res; _apiDone = true; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _hardTimeout = true; _clock?.cancel(); });
    }
  }

  // ── Timed animation (purely cosmetic, NOT showing fake data) ──────────────

  void _startClock() {
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed++);
      if (_elapsed == 45 && _done < _agentDefs.length) {
        setState(() => _timedOut = true);
      }
      if (_elapsed >= 180) {
        setState(() { _hardTimeout = true; _clock?.cancel(); });
      }
    });
  }

  // Agents 1–6 animate during the pipeline; Agent 7 (Denial & Appeal) is
  // shown by s09_denied.dart and does NOT appear in the normal animation.
  static const _animatedAgentCount = 6;

  void _runAnimation() {
    for (int i = 0; i < _animatedAgentCount; i++) {
      final idx = i;
      Timer(Duration(seconds: _agentDefs[i].$4), () {
        if (!mounted) return;
        setState(() {
          _done = idx + 1;
          _timedOut = false;
        });
        if (idx == _animatedAgentCount - 1) {
          Future.delayed(const Duration(milliseconds: 600), _navigate);
        }
      });
    }
  }

  Future<void> _navigate() async {
    // Wait for the real API result before navigating
    while (!_apiDone && !_hardTimeout) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted || _hardTimeout) return;
    }
    if (!mounted || _hardTimeout) return;
    final res = _result ?? {};
    final status = res['workflow_status']?.toString().toLowerCase() ?? '';
    if (status.contains('denied') || status.contains('appeal') || status.contains('escalat')) {
      widget.onDenied(res);
    } else {
      widget.onApproved(res);
    }
  }

  void _retry() {
    setState(() {
      _done = 0; _timedOut = false; _hardTimeout = false;
      _elapsed = 0; _apiDone = false; _result = null; _auditTrail = [];
    });
    _clock?.cancel();
    _startClock(); _runAnimation(); _callApi();
  }

  @override
  void dispose() { _clock?.cancel(); super.dispose(); }

  bool get _allDone => _done == _animatedAgentCount;

  // Progress is time-based (0–28 seconds maps to 0–100%)
  double get _progress => (_elapsed / 28.0).clamp(0.0, 1.0);

  AgentStepStatus _statusFor(int i) {
    if (i < _done) return AgentStepStatus.complete;
    if (i == _done) return AgentStepStatus.active;
    return AgentStepStatus.pending;
  }

  // ── Look up real agent output from the API audit trail ────────────────────

  String? _realOutputFor(int i) {
    if (_auditTrail.isEmpty) return null;
    // Map animation index → audit_trail agent key (matches LangGraph node names)
    const indexToKey = ['intake', 'medical_analysis', 'policy', 'claims', 'justification', 'submission', 'appeal'];
    if (i >= indexToKey.length) return null;
    final key = indexToKey[i];
    try {
      final entry = _auditTrail.firstWhere(
        (e) => (e as Map<String, dynamic>)['agent'] == key,
        orElse: () => null,
      );
      if (entry == null) return null;
      final m = entry as Map<String, dynamic>;
      final detail = m['detail']?.toString() ?? '';
      final status = m['status']?.toString() ?? '';
      return detail.isNotEmpty ? '$status: $detail' : status;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hardTimeout) return _ErrorScreen(onRetry: _retry);

    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        backgroundColor: C.surf0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text('Processing Request',
          style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700, color: C.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero ──────────────────────────────────────────────────────
            Text(_allDone ? 'Processing Complete' : 'AI Agents Working…',
              style: GoogleFonts.outfit(
                fontSize: 26, fontWeight: FontWeight.w800,
                color: C.textPrimary, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text(_allDone
                ? 'Finalizing your authorization response…'
                : 'Sit tight — this takes about 30 seconds.',
              style: GoogleFonts.inter(fontSize: 14, color: C.textSecondary, height: 1.5)),
            const SizedBox(height: 16),

            // Timeout banner
            if (_timedOut && !_allDone) ...[
              InfoBanner(
                message: 'This is taking longer than expected — still running…',
                icon: Icons.hourglass_top_rounded,
                bgColor: C.amber50, accentColor: C.amber500, textColor: C.amber700,
              ),
              const SizedBox(height: 12),
            ],

            // ── Progress card ─────────────────────────────────────────────
            MediCard(
              accentColor: _allDone ? C.green500 : C.teal500,
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_allDone ? 'Pipeline Complete' : 'AI Pipeline Running',
                          style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: C.textPrimary)),
                        Text('$_done of ${_agentDefs.length} agents complete',
                          style: GoogleFonts.inter(
                            fontSize: 12, color: C.textTertiary)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 52, height: 52,
                    child: Stack(alignment: Alignment.center, children: [
                      CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 3.5,
                        backgroundColor: C.surf2,
                        valueColor: AlwaysStoppedAnimation(
                          _allDone ? C.green500 : C.teal500),
                      ),
                      Text('${(_progress * 100).round()}%',
                        style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: C.textPrimary)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progress, minHeight: 6,
                    backgroundColor: C.surf2,
                    valueColor: AlwaysStoppedAnimation(
                      _allDone ? C.green500 : C.teal500),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Agent timeline ─────────────────────────────────────────────
            Text('Live Agent Progress',
              style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700, color: C.textPrimary)),
            const SizedBox(height: 10),
            MediCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: _agentDefs.asMap().entries.map((e) {
                  final i  = e.key;
                  final ag = e.value;
                  final st = _statusFor(i);
                  final isLast = i == _agentDefs.length - 1;
                  // Use REAL output from backend audit trail (if available)
                  final realOut = _realOutputFor(i);

                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(children: [
                            _StepDot(st, ag.$1),
                            if (!isLast) Container(
                              width: 2,
                              height: realOut != null ? 60 : 44,
                              color: st == AgentStepStatus.complete
                                  ? C.teal500.withValues(alpha: 0.35)
                                  : C.surf3,
                            ),
                          ]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  // Agent name
                                  Text(ag.$2,
                                    style: GoogleFonts.inter(
                                      fontSize: 13, fontWeight: FontWeight.w600,
                                      color: st == AgentStepStatus.pending
                                          ? C.textTertiary : C.textPrimary)),
                                  const SizedBox(height: 2),
                                  // Status label
                                  Text(_statusLabel(st, ag.$3),
                                    style: GoogleFonts.inter(
                                      fontSize: 11, color: _labelColor(st))),
                                  // REAL backend output (only when available from API)
                                  if (realOut != null && realOut.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: C.navy900,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: C.teal500.withValues(alpha: 0.3)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: C.teal500.withValues(alpha: 0.1),
                                            blurRadius: 10, offset: const Offset(0, 4))
                                        ],
                                      ),
                                      child: Text(realOut,
                                        style: AppTheme.monoStyle(
                                          color: C.teal400, size: 11)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!isLast) const SizedBox(height: 4),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Color _labelColor(AgentStepStatus s) => switch (s) {
    AgentStepStatus.pending  => C.textTertiary,
    AgentStepStatus.active   => C.amber600,
    AgentStepStatus.complete => C.teal700,
    AgentStepStatus.error    => C.red700,
  };

  String _statusLabel(AgentStepStatus s, String activeTxt) => switch (s) {
    AgentStepStatus.pending  => 'Queued',
    AgentStepStatus.active   => activeTxt,
    AgentStepStatus.complete => 'Complete ✓',
    AgentStepStatus.error    => 'Error',
  };
}

// ── Step Dot ──────────────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final AgentStepStatus status;
  final IconData icon;
  const _StepDot(this.status, this.icon);

  @override
  Widget build(BuildContext context) => switch (status) {
    AgentStepStatus.pending => Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle, color: C.surf2,
        border: Border.all(color: C.surf3, width: 1.5)),
      child: Icon(icon, size: 14, color: C.textTertiary),
    ),
    AgentStepStatus.active => PulseRings(
      color: C.amber500,
      child: Container(
        width: 32, height: 32,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: C.amber500),
        child: const Icon(Icons.sync_rounded, size: 16, color: C.white),
      ),
    ),
    AgentStepStatus.complete => Container(
      width: 32, height: 32,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: C.teal500),
      child: const Icon(Icons.check_rounded, size: 16, color: C.white),
    ),
    AgentStepStatus.error => Container(
      width: 32, height: 32,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: C.red500),
      child: const Icon(Icons.close_rounded, size: 16, color: C.white),
    ),
  };
}

// ── Error Screen ──────────────────────────────────────────────────────────────

class _ErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        backgroundColor: C.surf0, surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text('Processing Request',
          style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700, color: C.textPrimary)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(color: C.red50, shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded, size: 40, color: C.red500),
            ),
            const SizedBox(height: 24),
            Text('Our AI encountered an issue.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20, fontWeight: FontWeight.w800, color: C.textPrimary)),
            const SizedBox(height: 8),
            Text('Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: C.textSecondary)),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Try Again',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ]),
        ),
      ),
    );
  }
}
