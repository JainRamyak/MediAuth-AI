import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';
import 's04_patient_info.dart';

// ── S05 Medical Information — Step 2 of 3 ─────────────────────────────────────
// Per userflow Screen 5: diagnoses, medications, allergies, medical history,
// treating doctor's name. All in plain everyday language — no medical codes.
// NOTE: Renamed from TreatmentRequestScreen → MedicalInfoScreen to correctly
// reflect UF Step 2 = "Medical Information" (not Treatment Request).

class MedicalInfoScreen extends StatefulWidget {
  final PatientFormData data;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const MedicalInfoScreen({
    super.key,
    required this.data,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<MedicalInfoScreen> createState() => _MedicalInfoScreenState();
}

class _MedicalInfoScreenState extends State<MedicalInfoScreen> {
  late TextEditingController _historyCtrl;
  late TextEditingController _doctorCtrl;

  bool get _canProceed =>
      widget.data.diagnoses.isNotEmpty && widget.data.medications.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _historyCtrl = TextEditingController(text: widget.data.medicalHistory);
    _doctorCtrl = TextEditingController(text: widget.data.doctorName);
  }

  @override
  void dispose() {
    _historyCtrl.dispose();
    _doctorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepHeader(
              current: 2,
              total: 3,
              title: 'Medical Information',
            ),
            const SizedBox(height: 16),

            // UF reassurance text: "Write in your own words — our AI understands plain language."
            InfoBanner(
              message:
                  'Write in your own words — our AI understands plain language. You do not need to know medical codes.',
              icon: Icons.auto_awesome_outlined,
            ),
            const SizedBox(height: 20),

            // ── Clinical Info ───────────────────────────────────────────────
            SectionLabel(
                'Your Medical Situation', Icons.medical_information_outlined),
            const SizedBox(height: 10),

            MediCard(
              child: Column(
                children: [
                  // UF: "Diagnoses / Conditions *" — required
                  ChipInputField(
                    label: 'Diagnoses / Conditions *',
                    chips: widget.data.diagnoses,
                    hint: 'e.g. Type 2 Diabetes',
                    onChanged: (v) =>
                        setState(() => widget.data.diagnoses = v),
                  ),
                  const SizedBox(height: 16),
                  // UF: "Current Medications *" — required, include dosage and how long
                  ChipInputField(
                    label: 'Current Medications *',
                    chips: widget.data.medications,
                    hint: 'e.g. Metformin 1000mg',
                    onChanged: (v) =>
                        setState(() => widget.data.medications = v),
                  ),
                  const SizedBox(height: 16),
                  // UF: "Known Allergies" — optional, type 'None' if no allergies
                  ChipInputField(
                    label: 'Known Allergies',
                    chips: widget.data.allergies,
                    hint: "e.g. Penicillin  or  None",
                    onChanged: (v) =>
                        setState(() => widget.data.allergies = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── History & Doctor ────────────────────────────────────────────
            SectionLabel('Additional Details', Icons.note_alt_outlined),
            const SizedBox(height: 10),

            MediCard(
              child: Column(
                children: [
                  // UF: "Medical History / Notes" — optional, previous treatments, test results
                  _FieldLabel('Medical History / Notes'),
                  TextFormField(
                    controller: _historyCtrl,
                    maxLines: 4,
                    minLines: 3,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText:
                          'Previous treatments tried, relevant test results, doctor comments...',
                    ),
                    onChanged: (v) =>
                        setState(() => widget.data.medicalHistory = v),
                  ),
                  const SizedBox(height: 16),

                  // UF: "Treating Doctor's Name" — optional
                  _FieldLabel("Treating Doctor's Name"),
                  TextFormField(
                    controller: _doctorCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Dr. Sharma',
                      prefixIcon:
                          Icon(Icons.person_outline_rounded, size: 20),
                    ),
                    onChanged: (v) =>
                        setState(() => widget.data.doctorName = v),
                  ),
                ],
              ),
            ),

            // UF: "Please add at least one diagnosis and one medication to continue."
            if (!_canProceed) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: C.amber50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: C.amber500.withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: C.amber600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please add at least one diagnosis and one medication to continue.',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: C.amber700),
                    ),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 28),
            // UF button label: "Next: Treatment Details →"
            PrimaryButton(
              label: 'Next: Treatment Details →',
              icon: Icons.arrow_forward_rounded,
              onPressed: _canProceed ? widget.onNext : null,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Field label helper ────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: C.textSecondary,
        ),
      ),
    );
  }
}