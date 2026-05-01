import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';


// ── Treatment Form Data ────────────────────────────────────────────────────────

class TreatmentFormData {
  String description = '';
  List<String> uploadedFiles = [];
  String clinicalNotes = '';
}

// ── S05 Treatment Request ─────────────────────────────────────────────────────

class TreatmentRequestScreen extends StatefulWidget {
  final TreatmentFormData data;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const TreatmentRequestScreen({
    super.key,
    required this.data,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<TreatmentRequestScreen> createState() =>
    _TreatmentRequestScreenState();
}

// Removed obsolete CPT codes

const _agentNames = [
  (Icons.input_rounded,             'Intake & History Agent'),
  (Icons.biotech_outlined,           'Medical Analysis Agent'),
  (Icons.policy_outlined,            'Policy Intelligence Agent'),
  (Icons.draw_outlined,              'Justification Writer'),
  (Icons.send_outlined,              'Submission & Monitor'),
  (Icons.gavel_outlined,             'Denial & Appeal Agent'),
  (Icons.receipt_long_outlined,      'Claims Validation Agent'),
];

class _TreatmentRequestScreenState extends State<TreatmentRequestScreen> {
  bool _whatNextExpanded = false;

  bool get _canProceed => widget.data.description.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        title: const Text('New Authorization'),
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
            StepHeader(current: 2, total: 3,
              title: 'Treatment Request'),
            const SizedBox(height: 20),

            // ── Treatment description ─────────────────────────────────
            SectionLabel('Procedure Details',
              Icons.medical_services_outlined),
            const SizedBox(height: 10),

            TextFormField(
              initialValue: widget.data.description,
              maxLines: 5,
              minLines: 4,
              decoration: const InputDecoration(
                hintText:
                  'Describe the procedure, why it\'s needed, '
                  'and any prior treatments attempted...',
              ),
              onChanged: (v) =>
                setState(() => widget.data.description = v),
            ),
            const SizedBox(height: 20),

            // ── Document Upload ────────────────────────────────────────
            SectionLabel('Medical Bills & Prescriptions', Icons.upload_file_rounded),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (!widget.data.uploadedFiles.contains('MRI_Brain_Scan_Report.pdf')) {
                    widget.data.uploadedFiles.add('MRI_Brain_Scan_Report.pdf');
                  } else if (!widget.data.uploadedFiles.contains('Physician_Notes.pdf')) {
                    widget.data.uploadedFiles.add('Physician_Notes.pdf');
                  }
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: C.surf0,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: C.teal500.withValues(alpha: 0.3), width: 1.5, strokeAlign: BorderSide.strokeAlignInside),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: C.teal50, shape: BoxShape.circle),
                      child: const Icon(Icons.cloud_upload_rounded, color: C.teal600, size: 28),
                    ),
                    const SizedBox(height: 16),
                    Text('Tap to upload documents',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: C.textPrimary)),
                    const SizedBox(height: 4),
                    Text('PDF, JPG, or PNG (Max 10MB)',
                      style: GoogleFonts.inter(fontSize: 12, color: C.textTertiary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...widget.data.uploadedFiles.map((file) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: C.surf0,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: C.surf3, width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, color: C.red500, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(file,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: C.textPrimary)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: C.textTertiary),
                      onPressed: () => setState(() => widget.data.uploadedFiles.remove(file)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 24),

            // ── Clinical notes ──────────────────────────────────────
            SectionLabel('Clinical Notes',
              Icons.note_alt_outlined),
            const SizedBox(height: 10),

            TextFormField(
              initialValue: widget.data.clinicalNotes,
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(
                hintText:
                  'Lab values, imaging findings, physician notes '
                  '(optional but strengthens the case)...',
                suffixText: 'Optional',
              ),
              onChanged: (v) =>
                setState(() => widget.data.clinicalNotes = v),
            ),
            const SizedBox(height: 16),



            // ── "What happens next?" expandable ──────────────────────
            GestureDetector(
              onTap: () =>
                setState(() => _whatNextExpanded = !_whatNextExpanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [C.teal50, Color(0xFFE5FAF5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: C.teal500.withValues(alpha: 0.3),
                    width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: C.teal500,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.smart_toy_outlined,
                          size: 18, color: C.white),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '7 AI agents will process this request',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: C.teal700)),
                      ),
                      Icon(
                        _whatNextExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                        color: C.teal600),
                    ]),

                    if (_whatNextExpanded) ...[
                      const SizedBox(height: 14),
                      const Divider(color: Color(0x1A00C9A7)),
                      const SizedBox(height: 10),
                      ..._agentNames.asMap().entries.map((e) {
                        final i = e.key;
                        final (icon, name) = e.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: C.surf0,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: C.teal500.withValues(alpha: 0.3),
                                  width: 0.5),
                              ),
                              child: Center(
                                child: Text('${i + 1}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: C.teal600))),
                            ),
                            const SizedBox(width: 10),
                            Icon(icon, size: 15, color: C.teal600),
                            const SizedBox(width: 6),
                            Text(name,
                              style: GoogleFonts.inter(
                                fontSize: 13, color: C.teal700)),
                          ]),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            PrimaryButton(
              label: 'Review & Submit',
              onPressed: _canProceed ? widget.onNext : null,
              icon: Icons.arrow_forward_rounded,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
