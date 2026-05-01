import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';
import 's13_prompt_editor.dart';

// ── S14 Prompt Test Run ───────────────────────────────────────────────────────

class PromptTestScreen extends StatefulWidget {
  final AgentPrompt agent;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  const PromptTestScreen({
    super.key,
    required this.agent,
    required this.onBack,
    required this.onEdit,
  });

  @override
  State<PromptTestScreen> createState() => _PromptTestScreenState();
}

class _PromptTestScreenState extends State<PromptTestScreen> {
  final _inputCtrl = TextEditingController(text:
    'Patient: Margaret Thompson, DOB: 03/14/1965\n'
    'Diagnosis: Severe bilateral knee osteoarthritis (M17.11, M17.12)\n'
    'Requested procedure: Total Knee Arthroplasty (CPT 27447)\n'
    'Insurance: Blue Cross Blue Shield, Policy BCB-2027-123456\n'
    'Conservative treatment: 18 months PT, 3x corticosteroid injections — no relief\n'
    'Current meds: Celecoxib 200mg, Acetaminophen 500mg\n'
    'Allergies: Penicillin',
  );

  bool _running = false;
  String? _output;
  int? _tokens;
  double? _latency;

  static const _mockOutput = '''{
  "patient_id": "PT-2027-1847",
  "name": "Margaret Thompson",
  "dob": "1965-03-14",
  "age": 62,
  "diagnoses": [
    {"code": "M17.11", "description": "Primary osteoarthritis, right knee"},
    {"code": "M17.12", "description": "Primary osteoarthritis, left knee"}
  ],
  "requested_procedure": {
    "cpt": "27447",
    "name": "Arthroplasty, knee, condyle and plateau",
    "clinical_necessity": "CONFIRMED",
    "necessity_basis": "Failed conservative treatment > 90 days"
  },
  "insurance": {
    "provider": "Blue Cross Blue Shield",
    "policy_number": "BCB-2027-123456",
    "auth_required": true
  },
  "risk_factors": [],
  "missing_docs": [],
  "authorization_recommendation": "APPROVE"
}''';

  Future<void> _run() async {
    setState(() { _running = true; _output = null; });
    final start = DateTime.now();
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final elapsed = DateTime.now().difference(start).inMilliseconds / 1000.0;
    setState(() {
      _running = false;
      _output  = _mockOutput;
      _tokens  = 432;
      _latency = elapsed;
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        title: Text('Test — ${widget.agent.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sample Input',
              style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _inputCtrl,
              maxLines: 8,
              minLines: 6,
              style: GoogleFonts.robotoMono(fontSize: 12, color: C.navy900),
              decoration: const InputDecoration(
                hintText: 'Enter sample patient input...',
              ),
            ),
            const SizedBox(height: 16),

            PrimaryButton(
              label: 'Run agent',
              onPressed: _running ? null : _run,
              loading: _running,
              icon: Icons.play_arrow_rounded,
            ),

            if (_output != null) ...[
              const SizedBox(height: 20),

              // Metrics row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: C.surf2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: C.surf3, width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Metric(label: 'Tokens', value: '$_tokens', icon: Icons.tag),
                    Container(width: 1, height: 30, color: C.surf3),
                    _Metric(
                      label: 'Latency',
                      value: '${_latency?.toStringAsFixed(1)}s',
                      icon: Icons.timer_outlined),
                    Container(width: 1, height: 30, color: C.surf3),
                    _Metric(
                      label: 'Status',
                      value: 'OK',
                      icon: Icons.check_circle_outline,
                      valueColor: C.green500),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // JSON output
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: C.textPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Output',
                          style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: C.surf300, letterSpacing: 1.0)),
                        Text('JSON',
                          style: GoogleFonts.inter(
                            fontSize: 11, color: C.teal500)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_output!,
                      style: GoogleFonts.robotoMono(
                        fontSize: 11, color: C.teal400, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              PrimaryButton(
                label: 'Looks good — save prompt',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Prompt saved ✓'),
                      backgroundColor: C.teal700,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                icon: Icons.save_outlined,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: widget.onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit prompt'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52)),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, size: 18, color: C.textTertiary),
      const SizedBox(height: 4),
      Text(value,
        style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w700,
          color: valueColor ?? C.textPrimary)),
      Text(label,
        style: GoogleFonts.inter(fontSize: 11, color: C.textTertiary)),
    ],
  );
}
