import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';
import 's04_patient_info.dart';
import 's05_treatment_request.dart';

class ReviewSubmitScreen extends StatefulWidget {
  final PatientFormData patient;
  final TreatmentFormData treatment;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final void Function(int step) onEditStep;

  const ReviewSubmitScreen({
    super.key,
    required this.patient,
    required this.treatment,
    required this.onBack,
    required this.onSubmit,
    required this.onEditStep,
  });

  @override
  State<ReviewSubmitScreen> createState() => _ReviewSubmitScreenState();
}

class _ReviewSubmitScreenState extends State<ReviewSubmitScreen> {
  bool _submitting = false;

  Future<void> _doSubmit() async {
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _submitting = false);
    widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    final t = widget.treatment;

    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        title: const Text('Review & Submit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepHeader(current: 3, total: 3, title: 'Review & Submit'),
            const SizedBox(height: 16),

            InfoBanner(
              message: 'Review your details before submission. '
                       'Tap ✏️ to edit any section.',
              icon: Icons.info_outline_rounded,
            ),
            const SizedBox(height: 16),

            // Patient section
            _ReviewCard(
              title: 'Provider & Clinical Info',
              icon: Icons.business_center_outlined,
              onEdit: () => widget.onEditStep(1),
              children: [
                _ReviewRow('Patient',     'Margaret Thompson'),
                _ReviewRow('Insurance',   'UnitedHealth (UHG-9844-XYZ)'),
                _ReviewRow('Provider',    p.providerName),
                if (p.diagnoses.isNotEmpty)
                  _ReviewRow('Diagnoses', p.diagnoses.join(', ')),
                if (p.medications.isNotEmpty)
                  _ReviewRow('Medications', p.medications.join(', ')),
                if (p.allergies.isNotEmpty)
                  _ReviewRow('Allergies', p.allergies.join(', ')),
                if (p.uploadedFiles.isNotEmpty)
                  _ReviewRow('Files',
                    '${p.uploadedFiles.length} document(s) attached'),
              ],
            ),
            const SizedBox(height: 12),

            // Treatment section
            _ReviewCard(
              title: 'Treatment Request',
              icon: Icons.medical_services_outlined,
              onEdit: () => widget.onEditStep(2),
              children: [
                _ReviewRow('Description',
                  t.description, maxLines: 3),
                if (t.uploadedFiles.isNotEmpty)
                  _ReviewRow('Medical Documents', t.uploadedFiles.join(', ')),
                if (t.clinicalNotes.isNotEmpty)
                  _ReviewRow('Clinical Notes',
                    t.clinicalNotes, maxLines: 2),
              ],
            ),
            const SizedBox(height: 12),

            // Agent preview card
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
                    Text('7 AI Agents Ready',
                      style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: C.white)),
                  ]),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: [
                      'Intake', 'Medical Analysis', 'Policy',
                      'Justification', 'Submission',
                      'Appeal', 'Claims Validation',
                    ].map((name) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: C.teal500.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: C.teal500.withValues(alpha: 0.3),
                          width: 0.5),
                      ),
                      child: Text(name,
                        style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: C.teal400)),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submitting ? null : _doSubmit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: C.teal500,
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
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: C.white)),
                    ],
                  ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined,
                    size: 14, color: C.textTertiary),
                  const SizedBox(width: 4),
                  Text('Processing takes 30–120 seconds',
                    style: GoogleFonts.inter(
                      fontSize: 12, color: C.textTertiary)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onEdit;
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
                        fontSize: 12, fontWeight: FontWeight.w600,
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
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
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
