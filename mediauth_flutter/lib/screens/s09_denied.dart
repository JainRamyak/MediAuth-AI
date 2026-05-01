import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';

class DeniedScreen extends StatefulWidget {
  final VoidCallback onAppeal;
  final VoidCallback onDashboard;

  const DeniedScreen({
    super.key,
    required this.onAppeal,
    required this.onDashboard,
  });

  @override
  State<DeniedScreen> createState() => _DeniedScreenState();
}

class _DeniedScreenState extends State<DeniedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctl;
  late Animation<double> _fade;
  bool _reasonExpanded = false;

  static const _denialReason =
    'Step therapy not completed — insurer requires a 6-month trial '
    'of conservative treatment (Physical Therapy, NSAID) '
    'before surgical authorization can be granted.';

  static const _steps = ['Submitted', 'Denied', 'L1 Appeal', 'L2 Review', 'Final'];

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctl, curve: Curves.easeOut);
    _ctl.forward();
  }

  @override
  void dispose() { _ctl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        title: Text('Request Denied',
          style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w600, color: C.textPrimary)),
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
              // ── Hero ────────────────────────────────────────────────────────
              Center(
                child: Column(children: [
                  Container(
                    width: 80, height: 80,
                    decoration: const BoxDecoration(
                      color: C.red50, shape: BoxShape.circle),
                    child: const Icon(Icons.cancel_rounded,
                      size: 44, color: C.red500),
                  ),
                  const SizedBox(height: 14),
                  Text('Treatment Request Denied',
                    style: GoogleFonts.inter(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color: C.textPrimary, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text('Spinal fusion L4–L5 · AUTH-2027-003',
                    style: GoogleFonts.inter(
                      fontSize: 13, color: C.textTertiary)),
                ]),
              ),
              const SizedBox(height: 24),

              // ── Denial reason — expandable ──────────────────────────────────
              GestureDetector(
                onTap: () => setState(() => _reasonExpanded = !_reasonExpanded),
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
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: C.textPrimary)),
                        const Spacer(),
                        Icon(
                          _reasonExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                          size: 20, color: C.textTertiary),
                      ]),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        child: _reasonExpanded
                          ? Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(_denialReason,
                                style: GoogleFonts.inter(
                                  fontSize: 14, color: C.textSecondary,
                                  height: 1.6)),
                            )
                          : const SizedBox.shrink(),
                      ),
                      if (!_reasonExpanded) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Step therapy not completed…',
                          style: GoogleFonts.inter(
                            fontSize: 13, color: C.textSecondary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Appeal running ───────────────────────────────────────────────
              MediCard(
                accentColor: C.teal500,
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
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
                              fontSize: 14, fontWeight: FontWeight.w700,
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
                            child: Text('Level 1 / 3',
                              style: GoogleFonts.inter(
                                fontSize: 10, fontWeight: FontWeight.w600,
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

              // ── Lifecycle stepper ────────────────────────────────────────────
              Text('Request Lifecycle',
                style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: C.textPrimary)),
              const SizedBox(height: 12),
              MediCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _steps.asMap().entries.map((entry) {
                    final i = entry.key;
                    final label = entry.value;
                    final isPast   = i < 2;
                    final isActive = i == 2;

                    return Expanded(
                      child: Column(children: [
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? C.teal500
                              : isPast ? C.green50 : C.surf2,
                            border: Border.all(
                              color: isActive ? C.teal500
                                : isPast ? C.green500 : C.surf3,
                              width: 1.5),
                          ),
                          child: Center(child:
                            isActive
                              ? const Icon(Icons.circle, size: 10, color: C.white)
                              : isPast
                                ? const Icon(Icons.check, size: 14, color: C.green500)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(label,
                          style: GoogleFonts.inter(
                            fontSize: 9, fontWeight: FontWeight.w600,
                            color: isActive ? C.teal600
                              : isPast ? C.green600 : C.textTertiary),
                          textAlign: TextAlign.center),
                      ]),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // ── What we're doing ─────────────────────────────────────────────
              MediCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What our AI advocate is doing',
                      style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700,
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
                            width: 20, height: 20,
                            decoration: const BoxDecoration(
                              color: C.teal50, shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded,
                              size: 12, color: C.teal600),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(item,
                              style: GoogleFonts.inter(
                                fontSize: 13, color: C.textSecondary,
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
                            'L2 escalation begins automatically in 48 hours if no response.',
                            style: GoogleFonts.inter(
                              fontSize: 12, color: C.amber700))),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Buttons ──────────────────────────────────────────────────────
              ElevatedButton.icon(
                onPressed: widget.onAppeal,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: Text('View Appeal Progress',
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
