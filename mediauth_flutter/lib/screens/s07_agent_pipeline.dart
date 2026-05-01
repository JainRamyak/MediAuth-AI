import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

// ── Agent definitions ─────────────────────────────────────────────────────────

const _agents = [
  (
    Icons.manage_search_rounded,
    'Intake & History Agent',
    'Extracting and structuring patient profile…',
    'Parsed: 3 diagnoses · 2 medications · 1 allergy. Profile structured.',
  ),
  (
    Icons.biotech_outlined,
    'Medical Analysis Agent',
    'Mapping diagnoses to ICD-10 and CPT codes…',
    'ICD-10: M17.11, M17.12 · CPT: 27447 · Clinical necessity confirmed.',
  ),
  (
    Icons.policy_outlined,
    'Policy Intelligence Agent',
    'Searching insurer policy requirements via RAG…',
    'Blue Cross §4.2.1 — prior auth required for CPT 27447. Verified.',
  ),
  (
    Icons.edit_document,
    'Justification Writer',
    'Generating clinical narrative letter…',
    'Letter: 847 words · AMA guidelines §4.2.1 cited · Probability: HIGH.',
  ),
  (
    Icons.send_rounded,
    'Submission & Monitor',
    'Submitting request to insurer portal…',
    'Submitted 17:52:03 · Ref BCB-2027-482 · Polling every 30s.',
  ),
  (
    Icons.gavel_rounded,
    'Denial & Appeal Agent',
    'Monitoring insurer decision…',
    'No denial detected. Standby mode active.',
  ),
  (
    Icons.receipt_long_outlined,
    'Claims Validation Agent',
    'Validating codes and calculating denial risk…',
    'Risk: LOW ✓  All CPT/ICD-10 codes valid · No missing docs.',
  ),
];

// ── S07 Agent Pipeline ─────────────────────────────────────────────────────────

class AgentPipelineScreen extends StatefulWidget {
  final VoidCallback onApproved;
  final VoidCallback onDenied;

  const AgentPipelineScreen({
    super.key,
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
  Timer? _timer;
  String _claimsStatus = 'running';

  @override
  void initState() {
    super.initState();
    _runPipeline();
  }

  void _runPipeline() {
    _timer = Timer.periodic(
      const Duration(milliseconds: 1700), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_done < _agents.length) {
        final a = _agents[_done];
        setState(() {
          _log.add(_LogEntry(_ts(), '${a.$2}: ${a.$4}'));
          _done++;
          if (_done == 5) _claimsStatus = 'LOW';
        });
      } else {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) widget.onApproved();
        });
      }
    });
  }

  String _ts() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2,'0')}:'
           '${n.minute.toString().padLeft(2,'0')}:'
           '${n.second.toString().padLeft(2,'0')}';
  }

  AgentStepStatus _status(int i) {
    if (i < _done)  return AgentStepStatus.complete;
    if (i == _done) return AgentStepStatus.active;
    return AgentStepStatus.pending;
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final progress = _done / _agents.length;

    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        title: Text('Processing Request',
          style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w600,
            color: C.textPrimary)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Progress header card ──────────────────────────────────────────
            MediCard(
              accentColor: _done == _agents.length ? C.green500 : C.teal500,
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _done == _agents.length
                            ? 'All agents complete!'
                            : 'AI Pipeline Running',
                          style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: C.textPrimary)),
                        Text('$_done of ${_agents.length} agents complete',
                          style: GoogleFonts.inter(
                            fontSize: 12, color: C.textTertiary)),
                      ],
                    ),
                  ),
                  // Circular progress badge
                  SizedBox(
                    width: 48, height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 3.5,
                          backgroundColor: C.surf2,
                          valueColor: AlwaysStoppedAnimation(
                            _done == _agents.length ? C.green500 : C.teal500),
                        ),
                        Text('${(_done / _agents.length * 100).round()}%',
                          style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: C.textPrimary)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: C.surf2,
                    valueColor: AlwaysStoppedAnimation(
                      _done == _agents.length ? C.green500 : C.teal500),
                  ),
                ),
                if (_done < _agents.length) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.info_outline_rounded,
                      size: 13, color: C.textTertiary),
                    const SizedBox(width: 5),
                    Text('Tap any completed step to see output',
                      style: GoogleFonts.inter(
                        fontSize: 12, color: C.textTertiary)),
                  ]),
                ],
              ]),
            ),
            const SizedBox(height: 20),

            // ── Agent Timeline ────────────────────────────────────────────────
            Text('Agent Timeline',
              style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: C.textPrimary)),
            const SizedBox(height: 10),
            MediCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: _agents.asMap().entries.map((entry) {
                  final i  = entry.key;
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
                        // Timeline track
                        Column(children: [
                          _StepDot(st, ag.$1),
                          if (!isLast)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: 2,
                              height: exp && st == AgentStepStatus.complete
                                ? 100 : 48,
                              color: st == AgentStepStatus.complete
                                ? C.teal500.withValues(alpha: 0.4)
                                : C.surf3,
                            ),
                        ]),
                        const SizedBox(width: 12),

                        // Content
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 8 : 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(children: [
                                  Expanded(
                                    child: Text(ag.$2,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: st == AgentStepStatus.pending
                                          ? C.textTertiary : C.textPrimary)),
                                  ),
                                  if (i == 4) _ClaimsBadge(_claimsStatus),
                                ]),
                                const SizedBox(height: 2),
                                Text(_label(st, ag.$3),
                                  style: GoogleFonts.inter(
                                    fontSize: 11, color: _labelColor(st))),

                                // Expanded output
                                if (exp && st == AgentStepStatus.complete) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: C.textPrimary,
                                      borderRadius: BorderRadius.circular(10)),
                                    child: Text(ag.$4,
                                      style: AppTheme.monoStyle(
                                        color: C.teal400, size: 11)),
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text('Hide ↑',
                                      style: GoogleFonts.inter(
                                        fontSize: 12, color: C.teal700,
                                        fontWeight: FontWeight.w500)),
                                  ),
                                ] else if (st == AgentStepStatus.complete) ...[
                                  Text('Show output ↓',
                                    style: GoogleFonts.inter(
                                      fontSize: 12, color: C.teal700,
                                      fontWeight: FontWeight.w500)),
                                ],
                                SizedBox(height: isLast ? 0 : 10),
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

            // ── Live audit trail ──────────────────────────────────────────────
            if (_log.isNotEmpty) ...[
              Text('Live Audit Trail',
                style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w700,
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
                              size: 10, height: 1.5)),
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
    AgentStepStatus.pending  => C.textTertiary,
    AgentStepStatus.active   => C.amber600,
    AgentStepStatus.complete => C.teal700,
    AgentStepStatus.error    => C.red700,
  };
  String _label(AgentStepStatus s, String active) => switch (s) {
    AgentStepStatus.pending  => 'Waiting in queue…',
    AgentStepStatus.active   => active,
    AgentStepStatus.complete => 'Complete',
    AgentStepStatus.error    => 'Failed',
  };
}

// ── Step dot with icon ────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final AgentStepStatus status;
  final IconData icon;
  const _StepDot(this.status, this.icon);

  @override
  Widget build(BuildContext context) => switch (status) {
    AgentStepStatus.pending => Container(
      width: 32, height: 32,
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
          width: 32, height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: const AlwaysStoppedAnimation(C.amber500))),
        Icon(icon, size: 13, color: C.amber600),
      ],
    ),
    AgentStepStatus.complete => Container(
      width: 32, height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle, color: C.teal500),
      child: const Icon(Icons.check_rounded, size: 16, color: C.white),
    ),
    AgentStepStatus.error => Container(
      width: 32, height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle, color: C.red500),
      child: const Icon(Icons.close_rounded, size: 16, color: C.white),
    ),
  };
}

// ── Claims badge ──────────────────────────────────────────────────────────────

class _ClaimsBadge extends StatelessWidget {
  final String status;
  const _ClaimsBadge(this.status);

  @override
  Widget build(BuildContext context) {
    if (status == 'running') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: C.surf2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: C.surf3)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(
            width: 10, height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation(C.textTertiary))),
          const SizedBox(width: 4),
          Text('Claims',
            style: GoogleFonts.inter(
              fontSize: 10, color: C.textTertiary)),
        ]),
      );
    }
    final (bg, fg) = switch (status) {
      'LOW'    => (C.green50,  C.green500),
      'MEDIUM' => (C.amber50,  C.amber500),
      _        => (C.red50,    C.red500),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.3))),
      child: Text('$status risk',
        style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

// ── Log entry ─────────────────────────────────────────────────────────────────

class _LogEntry {
  final String time, msg;
  const _LogEntry(this.time, this.msg);
}
