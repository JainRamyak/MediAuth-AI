import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 's04_patient_info.dart';
import 's06_review_submit.dart';
import 's06b_prompt_customization.dart';
import '../api/api_service.dart';

// ── Agent definitions — plain language per userflow Screen 7 ──────────────────
// UF Screen 7 shows 6 visible steps (no appeal step shown during normal processing)
// Agent $5 = done at seconds (simulated frontend timer — API is a single call)

const _agents = [
  (
    Icons.manage_search_rounded,
    'Reading your patient information...',
    'Extracting your details and organising them for review...',
    'Patient profile structured. Name, insurer, diagnoses and history confirmed.',
    3, // done at ~3s
  ),
  (
    Icons.biotech_outlined,
    'Identifying your medical codes...',
    'Matching your diagnoses and treatment to the correct medical codes...',
    'Medical codes identified. Coverage eligibility confirmed for your treatment.',
    7, // done at ~7s
  ),
  (
    Icons.policy_outlined,
    "Checking your insurer's policy rules...",
    "Retrieving your insurer's authorisation requirements...",
    'Policy checked. Prior authorisation required — criteria identified.',
    11, // done at ~11s
  ),
  (
    Icons.draw_outlined,
    'Writing your authorisation letter...',
    'Drafting a formal letter citing clinical evidence and guidelines...',
    'Authorisation letter complete. 847 words. Clinical necessity well supported.',
    20, // done at ~20s (longest — UF: "letter writing takes longest")
  ),
  (
    Icons.send_rounded,
    'Submitting to your insurer...',
    'Sending your request directly to the insurer portal...',
    'Submitted successfully. Reference number issued. Awaiting decision.',
    24, // done at ~24s
  ),
  (
    Icons.receipt_long_outlined,
    'Validating your billing codes...',
    'Cross-checking all codes for accuracy and completeness...',
    'All codes valid. Denial risk: LOW. No missing documents.',
    28, // done at ~28s
  ),
];

// ── S07 Agent Pipeline ────────────────────────────────────────────────────────

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
  final _expandedAgents = <int>{};
  final _log = <_LogEntry>[];
  bool _timedOut = false;
  bool _hardTimeout = false; // UF: up to 60s — after that show error
  int _elapsedSeconds = 0;
  Timer? _clockTimer;

  Map<String, dynamic>? _apiResult;
  bool _apiDone = false;

  @override
  void initState() {
    super.initState();
    _startClock();
    _executeApiCall();
    _runPipeline();
  }

  String _buildPatientText() {
    final f = widget.patient;
    return 'Name: ${f.fullName}\nDOB: ${f.dateOfBirth?.toIso8601String()}\nInsurer: ${f.insurer}\nPolicy: ${f.policyNumber}\nDiagnoses: ${f.diagnoses.join(', ')}\nMedications: ${f.medications.join(', ')}\nHistory: ${f.medicalHistory}';
  }

  Future<void> _executeApiCall() async {
    try {
      if (widget.payload?.editedAgents != null) {
        for (final agent in widget.payload!.editedAgents) {
          await ApiService.updatePrompt(agent);
        }
      }

      final pText = _buildPatientText();
      final ctx = widget.payload?.customContext ?? '';
      final fullText = ctx.isNotEmpty ? '$pText\nContext:\n$ctx' : pText;

      final treatmentStr = widget.treatment.requestedTreatment + 
          (widget.treatment.whyNeeded.isNotEmpty ? '\nReason: ${widget.treatment.whyNeeded}' : '');

      final res = await ApiService.authorizeTreatment(fullText, treatmentStr);
      
      if (!mounted) return;
      setState(() {
         _apiResult = res;
         _apiDone = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
         _hardTimeout = true;
         _clockTimer?.cancel();
      });
    }
  }

  void _checkAndNavigate() async {
    while (!_apiDone && !_hardTimeout) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted || _hardTimeout) return;
    }
    if (_hardTimeout || !mounted) return;

    final result = _apiResult ?? {};
    final status = result['workflow_status']?.toString().toLowerCase() ?? '';

    // Any status containing 'denied', 'appeal', or 'escalat' → denied screen
    if (status.contains('denied') ||
        status.contains('appeal') ||
        status.contains('escalat')) {
      widget.onDenied(result);
    } else {
      widget.onApproved(result);
    }
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);

      // Warn at 45s — real AI pipeline can take 45–90s
      if (_elapsedSeconds == 45 && _done < _agents.length) {
        setState(() => _timedOut = true);
      }

      // Hard timeout at 180s — if API hasn't responded something is wrong
      if (_elapsedSeconds >= 180 && _done < _agents.length) {
        setState(() => _hardTimeout = true);
        _clockTimer?.cancel();
      }
    });
  }

  void _runPipeline() {
    for (int i = 0; i < _agents.length; i++) {
      final agentIndex = i;
      final doneAt = _agents[i].$5;
      Timer(Duration(seconds: doneAt), () {
        if (!mounted) return;
        setState(() {
          _done = agentIndex + 1;
          _log.add(_LogEntry(_ts(),
              '${_agents[agentIndex].$2} ${_agents[agentIndex].$4}'));
          _timedOut = false; 
        });

        if (agentIndex == _agents.length - 1) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (!mounted) return;
            _checkAndNavigate();
          });
        }
      });
    }
  }

  String _ts() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:'
        '${n.minute.toString().padLeft(2, '0')}:'
        '${n.second.toString().padLeft(2, '0')}';
  }

  AgentStepStatus _status(int i) {
    if (i < _done) return AgentStepStatus.complete;
    if (i == _done) return AgentStepStatus.active;
    return AgentStepStatus.pending;
  }

  // UF: Progress is time-based for smooth animation
  double get _progress => (_elapsedSeconds / 28.0).clamp(0.0, 1.0);

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allDone = _done == _agents.length;

    // UF Error state: "Our AI encountered an issue. Please try again." + Retry
    if (_hardTimeout) {
      return Scaffold(
        backgroundColor: C.surf1,
        appBar: AppBar(
          backgroundColor: C.surf0,
          surfaceTintColor: Colors.transparent,
          title: Text('Processing Request',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: C.textPrimary)),
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                    color: C.red50, shape: BoxShape.circle),
                child:
                    const Icon(Icons.error_outline_rounded, size: 36, color: C.red500),
              ),
              const SizedBox(height: 20),
              Text('Our AI encountered an issue.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: C.textPrimary)),
              const SizedBox(height: 8),
              Text('Please try again.',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: C.textSecondary)),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                onPressed: () {
                  setState(() {
                    _done = 0;
                    _expandedAgents.clear();
                    _log.clear();
                    _timedOut = false;
                    _hardTimeout = false;
                    _elapsedSeconds = 0;
                    _apiDone = false;
                    _apiResult = null;
                  });
                  _executeApiCall();
                  _runPipeline();
                  _startClock();
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        backgroundColor: C.surf0,
        surfaceTintColor: Colors.transparent,
        title: Text('Processing Request',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: C.textPrimary)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero heading ───────────────────────────────────────────────
            Text(
              allDone
                  ? 'All Done!'
                  : 'AI Agents Working on Your Authorization...',
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: C.textPrimary,
                  letterSpacing: -0.3,
                  height: 1.2),
            ),
            const SizedBox(height: 6),
            Text(
              allDone
                  ? 'Taking you to your result now...'
                  // UF: "Sit tight — this takes about 20 seconds. You do not need to do anything."
                  : 'Sit tight — this takes about 20 seconds. You do not need to do anything.',
              style: GoogleFonts.inter(
                  fontSize: 14, color: C.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),

            // ── Timeout warning (45s) ──────────────────────────────────────
            // UF: "This is taking longer than expected. Still working..."
            if (_timedOut && !allDone) ...[
              InfoBanner(
                message:
                    'This is taking longer than expected. Still working...',
                icon: Icons.hourglass_top_rounded,
                bgColor: C.amber50,
                borderColor: C.amber500,
                textColor: C.amber700,
              ),
              const SizedBox(height: 12),
            ],

            // ── Progress card ──────────────────────────────────────────────
            MediCard(
              accentColor: allDone ? C.green500 : C.teal500,
              child: Column(
                children: [
                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            allDone
                                ? 'All agents complete!'
                                : 'AI Pipeline Running',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: C.textPrimary),
                          ),
                          Text(
                            '$_done of ${_agents.length} agents complete',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: C.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 3.5,
                            backgroundColor: C.surf2,
                            valueColor: AlwaysStoppedAnimation(
                                allDone ? C.green500 : C.teal500),
                          ),
                          Text(
                            '${(_progress * 100).round()}%',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: C.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 6,
                      backgroundColor: C.surf2,
                      valueColor: AlwaysStoppedAnimation(
                          allDone ? C.green500 : C.teal500),
                    ),
                  ),
                  if (!allDone) ...[
                    const SizedBox(height: 8),
                    // UF: "You will be automatically taken to your result when done."
                    Row(children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 13, color: C.textTertiary),
                      const SizedBox(width: 5),
                      Text(
                        'You will be automatically taken to your result when done.',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: C.textTertiary),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Agent Timeline ────────────────────────────────────────────
            Text('Agent Progress',
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: C.textPrimary)),
            const SizedBox(height: 10),
            MediCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: _agents.asMap().entries.map((entry) {
                  final i = entry.key;
                  final ag = entry.value;
                  final st = _status(i);
                  final exp = _expandedAgents.contains(i);
                  final isLast = i == _agents.length - 1;

                  return GestureDetector(
                    onTap: () => setState(() {
                      exp
                          ? _expandedAgents.remove(i)
                          : _expandedAgents.add(i);
                    }),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(children: [
                          _StepDot(st, ag.$1),
                          if (!isLast)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: 2,
                              height: exp && st == AgentStepStatus.complete
                                  ? 90
                                  : 44,
                              color: st == AgentStepStatus.complete
                                  ? C.teal500.withValues(alpha: 0.4)
                                  : C.surf3,
                            ),
                        ]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 8 : 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                // UF: plain-language label
                                Text(ag.$2,
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: st == AgentStepStatus.pending
                                            ? C.textTertiary
                                            : C.textPrimary)),
                                const SizedBox(height: 2),
                                Text(_statusLabel(st, ag.$3),
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: _labelColor(st))),
                                if (exp &&
                                    st == AgentStepStatus.complete) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                        color: C.textPrimary,
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Text(ag.$4,
                                        style: AppTheme.monoStyle(
                                            color: C.teal400, size: 11)),
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text('Hide ↑',
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: C.teal700,
                                            fontWeight: FontWeight.w500)),
                                  ),
                                ] else if (st == AgentStepStatus.complete) ...[
                                  Text('Show output ↓',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: C.teal700,
                                          fontWeight: FontWeight.w500)),
                                ],
                                SizedBox(height: isLast ? 0 : 8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── Live Audit Trail ───────────────────────────────────────────
            if (_log.isNotEmpty) ...[
              Text('Live Audit Trail',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: C.textPrimary)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: C.textPrimary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _log.reversed.take(6).map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('[${e.time}] ',
                            style: AppTheme.monoStyle(
                                color: C.teal400, size: 10)),
                        Expanded(
                          child: Text(e.msg,
                              style: AppTheme.monoStyle(
                                  color: const Color(0xFFCAD5E5),
                                  size: 10,
                                  height: 1.5)),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _labelColor(AgentStepStatus s) => switch (s) {
        AgentStepStatus.pending => C.textTertiary,
        AgentStepStatus.active => C.amber600,
        AgentStepStatus.complete => C.teal700,
        AgentStepStatus.error => C.red700,
      };

  String _statusLabel(AgentStepStatus s, String activeText) => switch (s) {
        AgentStepStatus.pending => 'Waiting in queue…',
        AgentStepStatus.active => activeText,
        AgentStepStatus.complete => 'Complete ✓',
        AgentStepStatus.error => 'Failed',
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: C.surf2,
                border: Border.all(color: C.surf3, width: 1.5)),
            child: Icon(icon, size: 14, color: C.textTertiary),
          ),
        AgentStepStatus.active => Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          const AlwaysStoppedAnimation(C.amber500))),
              Icon(icon, size: 13, color: C.amber600),
            ],
          ),
        AgentStepStatus.complete => Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: C.teal500),
            child: const Icon(Icons.check_rounded, size: 16, color: C.white),
          ),
        AgentStepStatus.error => Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: C.red500),
            child: const Icon(Icons.close_rounded, size: 16, color: C.white),
          ),
      };
}

class _LogEntry {
  final String time, msg;
  const _LogEntry(this.time, this.msg);
}