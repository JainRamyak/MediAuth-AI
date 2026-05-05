import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';
import 's04_patient_info.dart';

// ── Screen 6 — Treatment Request + Review ─────────────────────────────────────

class ReviewSubmitScreen extends StatefulWidget {
  final PatientFormData patient;
  final TreatmentFormData treatment;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final VoidCallback onCustomize;

  const ReviewSubmitScreen({
    super.key,
    required this.patient,
    required this.treatment,
    required this.onBack,
    required this.onSubmit,
    required this.onCustomize,
  });

  @override
  State<ReviewSubmitScreen> createState() => _ReviewSubmitScreenState();
}

class _ReviewSubmitScreenState extends State<ReviewSubmitScreen> {
  late final TextEditingController _treatment;
  late final TextEditingController _reason;
  bool _consentGiven = false;

  @override
  void initState() {
    super.initState();
    _treatment = TextEditingController(text: widget.treatment.requestedTreatment);
    _reason    = TextEditingController(text: widget.treatment.whyNeeded);
  }

  @override
  void dispose() { _treatment.dispose(); _reason.dispose(); super.dispose(); }

  void _save() {
    widget.treatment.requestedTreatment = _treatment.text.trim();
    widget.treatment.whyNeeded          = _reason.text.trim();
  }

  bool get _canSubmit => _treatment.text.trim().isNotEmpty && _consentGiven;

  String _dobStr() {
    final d = widget.patient.dateOfBirth;
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surf1,
      appBar: IntakeAppBar(title: 'New Authorization', onBack: widget.onBack),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  StepHeader(current: 3, total: 3, title: 'Treatment Request & Review'),
                  const SizedBox(height: 20),

            // Treatment fields
            SectionLabel('Treatment Request', Icons.medical_services_outlined),
            const SizedBox(height: 10),
            TextFormField(
              controller: _treatment,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Requested Treatment *',
                hintText: 'e.g. Continuous glucose monitoring system and insulin pump therapy',
                alignLabelWithHint: true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reason,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Why is this treatment needed?',
                hintText: 'Brief reason in your own words — helps the AI write a stronger letter',
                alignLabelWithHint: true),
            ),
            const SizedBox(height: 24),

            // Review summary
            SectionLabel('Review Before Submitting', Icons.checklist_rounded),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: C.primary100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: C.primary500.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReviewRow('Patient', '${widget.patient.fullName}  ·  DOB ${_dobStr()}'),
                  if (widget.patient.abhaId.isNotEmpty)
                    _ReviewRow('ABHA ID', widget.patient.abhaId),
                  _ReviewRow('Insurance', '${widget.patient.insurer}  ·  ${widget.patient.policyNumber}'),
                  _ReviewRow('Admission', widget.patient.admissionType),
                  _ReviewRow('Diagnoses', widget.patient.diagnoses.join(', ')),
                  _ReviewRow('Medications', widget.patient.medications.join(', ')),
                  if (widget.patient.doctorName.isNotEmpty)
                    _ReviewRow('Physician', widget.patient.doctorName),
                  _ReviewRow('Treatment', _treatment.text.trim().isNotEmpty
                      ? _treatment.text.trim() : '(not filled yet)'),
                  const Divider(height: 24),
                  Row(children: [
                    const Icon(Icons.edit_outlined, size: 14, color: C.primary600),
                    const SizedBox(width: 8),
                    Text('Tap Back to edit any section',
                      style: GoogleFonts.inter(fontSize: 12, color: C.primary700, fontWeight: FontWeight.w500)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Our AI processes your request in 20–30 seconds.',
              style: GoogleFonts.inter(fontSize: 13, color: C.textTertiary),
              textAlign: TextAlign.center),
            const SizedBox(height: 24),

                ]),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // HIPAA Consent
                      Container(
                        decoration: BoxDecoration(
                          color: C.primary100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: C.primary500.withValues(alpha: 0.3)),
                        ),
                        child: CheckboxListTile(
                          value: _consentGiven,
                          onChanged: (val) => setState(() => _consentGiven = val ?? false),
                          activeColor: C.primary500,
                          checkColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            'I consent to the processing of this medical data by MediAuth AI in accordance with HIPAA guidelines.',
                            style: GoogleFonts.inter(fontSize: 12, color: C.primary800, fontWeight: FontWeight.w500, height: 1.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Actions
                      PrimaryButton(
                        label: 'Submit for Authorization',
                        icon: Icons.send_rounded,
                        onPressed: _canSubmit ? () { _save(); widget.onSubmit(); } : null,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.settings_outlined, size: 18),
                        label: const Text('View & Customize AI Prompts (Optional)'),
                        onPressed: () { _save(); widget.onCustomize(); },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: C.primary600,
                          side: const BorderSide(color: C.primary500, width: 1.0),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          "Not sure? Just tap Submit — the AI handles everything.",
                          style: GoogleFonts.inter(fontSize: 12, color: C.textTertiary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
              style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: C.textTertiary)),
          ),
          Expanded(
            child: Text(value,
              style: GoogleFonts.inter(fontSize: 13, color: C.textPrimary, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
