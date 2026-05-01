import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';

// ── S10 Appeal In Progress ────────────────────────────────────────────────────

class AppealProgressScreen extends StatelessWidget {
  final int level; // 1, 2, or 3
  final VoidCallback onDone;
  final VoidCallback onEscalate;

  const AppealProgressScreen({
    super.key,
    required this.level,
    required this.onDone,
    required this.onEscalate,
  });

  @override
  Widget build(BuildContext context) {
    final levelLabel = switch (level) {
      1 => 'Level 1 — Internal Review',
      2 => 'Level 2 — Peer-to-peer Review',
      _ => 'Level 3 — External Review Board',
    };

    return Scaffold(
      backgroundColor: C.surf50,
      appBar: AppBar(
        title: Text('Appeal L$level'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: C.violet50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.violet500, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(levelLabel,
                    style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: C.violet500)),
                  const SizedBox(height: 4),
                  Text('AI agent is constructing counter-evidence',
                    style: GoogleFonts.inter(fontSize: 13, color: C.violet700)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Counter-evidence card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Counter-Evidence Found',
                      style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    ...[
                      'Patient completed 18 months of physical therapy (documented)',
                      'Three corticosteroid injections on 2026-08, 09, and 11',
                      'WOMAC score 78/100 — severe functional limitation',
                      'BMI 24.3 — not a contraindication for surgery',
                      'Dr. Ortega recommendation: surgical intervention necessary',
                    ].map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline,
                            size: 16, color: C.teal500),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(item,
                              style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: C.ink600, height: 1.4)),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Appeal letter
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Appeal Letter — L$level',
                      style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Text(
                      'The documentation provided establishes that the patient has '
                      'exhausted all conservative modalities per AAOS guidelines. '
                      'The insurer\'s denial references policy 4.2.1 which requires '
                      '"documented failure of 90-day physical therapy program." '
                      'We attach herein certified physical therapy logs spanning '
                      '548 days, demonstrating sustained engagement and progressive '
                      'treatment escalation without adequate symptom relief. '
                      'Furthermore, the patient\'s WOMAC score of 78/100 places them '
                      'in the severe impairment category per established clinical benchmarks...',
                      style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: C.ink600, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Resubmission status
            InfoBanner(
              message: 'Sent to insurer · Awaiting response',
              icon: Icons.send_outlined,
            ),
            const SizedBox(height: 8),
            InfoBanner(
              message: 'Level ${level + 1} begins automatically if no response in 48h',
              bgColor: C.amber50,
              borderColor: C.amber500,
              textColor: C.amber700,
              icon: Icons.timer_outlined,
            ),
            const SizedBox(height: 24),

            if (level >= 3) ...[
              PrimaryButton(
                label: 'Escalate to Human Review',
                onPressed: onEscalate,
                icon: Icons.person_outlined,
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton(
              onPressed: onDone,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52)),
              child: const Text('Back to Dashboard'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── S11 Human Escalation ──────────────────────────────────────────────────────

class EscalationScreen extends StatelessWidget {
  final VoidCallback onDone;

  const EscalationScreen({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surf50,
      appBar: AppBar(
        backgroundColor: C.navy900,
        title: const Text('Escalation Required',
          style: TextStyle(color: C.white)),
        iconTheme: const IconThemeData(color: C.white),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoBanner(
              message: 'All 3 automated appeal levels have been exhausted. '
                       'Human clinician review is required.',
              bgColor: C.red50,
              borderColor: C.red500,
              textColor: C.red700,
              icon: Icons.warning_amber_outlined,
            ),
            const SizedBox(height: 16),

            Text('Complete Audit Trail',
              style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),

            ...[
              ('05/01 17:52', 'Initial request submitted', C.teal500),
              ('05/01 18:10', 'Authorization denied — Policy §4.2.1', C.red500),
              ('05/01 18:11', 'L1 appeal auto-initiated', C.amber500),
              ('05/03 09:00', 'L1 appeal denied', C.red500),
              ('05/03 09:01', 'L2 peer-to-peer appeal auto-initiated', C.amber500),
              ('05/05 14:30', 'L2 appeal denied', C.red500),
              ('05/05 14:31', 'L3 external review appeal auto-initiated', C.amber500),
              ('05/07 10:00', 'L3 appeal denied — human escalation required', C.red500),
            ].map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8, height: 8,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: entry.$3),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 90,
                    child: Text(entry.$1,
                      style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: C.ink300)),
                  ),
                  Expanded(
                    child: Text(entry.$2,
                      style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: C.ink600)),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),

            // Handoff note
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Handoff Note to Clinician',
                      style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'The Denial & Appeal Agent attempted 3 appeal levels with '
                      'progressively stronger counter-evidence. Each denial cited '
                      'policy 4.2.1 despite documentation that meets stated criteria. '
                      'Agent 6 recommends physician attestation to strengthen '
                      'the medical necessity argument. All 3 appeal letters and '
                      'supporting documentation are attached.',
                      style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: C.ink600, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            PrimaryButton(
              label: 'Assign to Clinician',
              onPressed: () {},
              icon: Icons.person_add_alt_1_outlined,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download Complete Case File'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52)),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onDone,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52)),
              child: const Text('Back to Dashboard'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
