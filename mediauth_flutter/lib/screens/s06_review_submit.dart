import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';
import 's04_patient_info.dart';

// ── Treatment Form Data ───────────────────────────────────────────────────────

class TreatmentFormData {
  String requestedTreatment = '';
  String whyNeeded          = '';
}

// ── S06 Treatment Request + Review — Step 3 of 3 ─────────────────────────────

class ReviewSubmitScreen extends StatefulWidget {
  final PatientFormData patient;
  final TreatmentFormData treatment;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final void Function(int step) onEditStep;
  final VoidCallback onCustomizePrompts;

  const ReviewSubmitScreen({
    super.key,
    required this.patient,
    required this.treatment,
    required this.onBack,
    required this.onSubmit,
    required this.onEditStep,
    required this.onCustomizePrompts,
  });

  @override
  State<ReviewSubmitScreen> createState() => _ReviewSubmitScreenState();
}

class _ReviewSubmitScreenState extends State<ReviewSubmitScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _treatmentCtrl;
  late TextEditingController _whyCtrl;
  bool _submitting = false;

  bool get _canProceed =>
      widget.treatment.requestedTreatment.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _treatmentCtrl =
        TextEditingController(text: widget.treatment.requestedTreatment);
    _whyCtrl = TextEditingController(text: widget.treatment.whyNeeded);
  }

  @override
  void dispose() {
    _treatmentCtrl.dispose();
    _whyCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _submitting = false);
    widget.onSubmit();
  }

  String _formatDob(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    final t = widget.treatment;

    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        backgroundColor: C.surf0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'New Authorization',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: C.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StepHeader(current: 3, total: 3, title: 'Treatment Request'),
              const SizedBox(height: 20),

              // ── Treatment fields ───────────────────────────────────────────
              SectionLabel(
                  'What Do You Need Covered?', Icons.medical_services_outlined),
              const SizedBox(height: 10),

              MediCard(
                child: Column(
                  children: [
                    _FieldLabel('Requested Treatment', required: true),
                    TextFormField(
                      controller: _treatmentCtrl,
                      maxLines: 4,
                      minLines: 3,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText:
                            'e.g. Continuous glucose monitoring system and insulin pump therapy',
                      ),
                      onChanged: (v) => setState(
                          () => widget.treatment.requestedTreatment = v),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Please describe the treatment needed'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel('Why Is This Needed?'),
                    TextFormField(
                      controller: _whyCtrl,
                      maxLines: 3,
                      minLines: 2,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText:
                            'e.g. My current medication is not controlling my sugar levels',
                        suffixText: 'Optional',
                      ),
                      onChanged: (v) =>
                          setState(() => widget.treatment.whyNeeded = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Review Summary ─────────────────────────────────────────────
              SectionLabel('Review Summary', Icons.checklist_rounded),
              const SizedBox(height: 4),
              Text(
                'Read-only summary. Tap Edit to change any field.',
                style: GoogleFonts.inter(
                    fontSize: 12, color: C.textTertiary),
              ),
              const SizedBox(height: 10),

              _ReviewCard(
                title: 'Personal & Insurance',
                icon: Icons.person_outline_rounded,
                onEdit: () => widget.onEditStep(1),
                children: [
                  _ReviewRow('Patient',
                      p.fullName.isNotEmpty ? p.fullName : '—'),
                  _ReviewRow('DOB', _formatDob(p.dateOfBirth)),
                  _ReviewRow('Insurance',
                      p.insurer.isNotEmpty ? p.insurer : '—'),
                  _ReviewRow('Policy',
                      p.policyNumber.isNotEmpty ? p.policyNumber : '—'),
                ],
              ),
              const SizedBox(height: 8),

              _ReviewCard(
                title: 'Medical Information',
                icon: Icons.medical_information_outlined,
                onEdit: () => widget.onEditStep(2),
                children: [
                  if (p.diagnoses.isNotEmpty)
                    _ReviewRow('Diagnoses', p.diagnoses.join(', ')),
                  if (p.medications.isNotEmpty)
                    _ReviewRow('Medications', p.medications.join(', ')),
                  if (p.allergies.isNotEmpty)
                    _ReviewRow('Allergies', p.allergies.join(', ')),
                  if (p.doctorName.isNotEmpty)
                    _ReviewRow('Doctor', p.doctorName),
                ],
              ),

              if (t.requestedTreatment.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ReviewCard(
                  title: 'Treatment',
                  icon: Icons.healing_outlined,
                  onEdit: null,
                  children: [
                    _ReviewRow('Treatment', t.requestedTreatment,
                        maxLines: 3),
                    if (t.whyNeeded.isNotEmpty)
                      _ReviewRow('Reason', t.whyNeeded, maxLines: 2),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // AI agents preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [C.navy900, Color(0xFF162D5C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.smart_toy_outlined,
                          color: C.teal400, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '7 AI Agents Ready to Process',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: C.white,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: [
                        'Intake', 'Medical Analysis', 'Policy',
                        'Justification', 'Submission', 'Appeal', 'Claims',
                      ]
                          .map((n) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: C.teal500.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: C.teal500.withValues(alpha: 0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(n,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: C.teal400,
                                    )),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── PRIMARY: Submit for Authorization ──────────────────────────
              ElevatedButton(
                onPressed: (_canProceed && !_submitting) ? _doSubmit : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: C.teal500,
                  disabledBackgroundColor:
                      C.teal500.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: C.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded,
                              color: C.white, size: 20),
                          const SizedBox(width: 10),
                          Text('Submit for Authorization',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: C.white,
                            )),
                        ],
                      ),
              ),
              const SizedBox(height: 10),

              // ── SECONDARY: Customize AI Prompts ───────────────────────────
              OutlinedButton(
                onPressed: widget.onCustomizePrompts,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  foregroundColor: C.teal600,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  side: const BorderSide(color: C.teal500, width: 1.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.settings_outlined,
                        size: 18, color: C.teal600),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '⚙  Customize AI Prompts Before Submitting (Optional)',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: C.teal600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Center(
                child: Text(
                  'Not sure what prompts are? Just tap Submit — the AI handles everything.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: C.textTertiary),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 14, color: C.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      'Our AI will process your request in approximately 20 seconds',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: C.textTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onEdit;
  final List<Widget> children;

  const _ReviewCard({
    required this.title,
    required this.icon,
    required this.onEdit,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 17, color: C.teal600),
            const SizedBox(width: 7),
            Expanded(
              child: Text(title,
                style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: C.navy900)),
            ),
            if (onEdit != null)
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: C.teal50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_outlined,
                          size: 13, color: C.teal600),
                      const SizedBox(width: 3),
                      Text('Edit',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: C.teal600)),
                    ],
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    ),
  );
}

class _ReviewRow extends StatelessWidget {
  final String label, value;
  final int maxLines;
  const _ReviewRow(this.label, this.value, {this.maxLines = 1});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
            style: GoogleFonts.inter(
              fontSize: 12, color: C.ink300,
              fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value,
            style: GoogleFonts.inter(
              fontSize: 13, color: C.navy900,
              fontWeight: FontWeight.w500),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel(this.label, {this.required = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Text(label,
        style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: C.textSecondary)),
      if (required)
        Text(' *',
          style: GoogleFonts.inter(
            fontSize: 13, color: C.red500,
            fontWeight: FontWeight.w600)),
    ]),
  );
}