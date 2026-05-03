import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';
import 's04_patient_info.dart';

// ── Screen 5 — Medical Info ────────────────────────────────────────────────────

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
  late final TextEditingController _allergies;
  late final TextEditingController _history;
  late final TextEditingController _doctor;
  final List<TextEditingController> _medCtrls = [];
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _allergies = TextEditingController(text: widget.data.allergies);
    _history   = TextEditingController(text: widget.data.medicalHistory);
    _doctor    = TextEditingController(text: widget.data.doctorName);

    // Pre-populate medication controllers
    for (final m in widget.data.medications) {
      _medCtrls.add(TextEditingController(text: m));
    }
    if (_medCtrls.isEmpty) _medCtrls.add(TextEditingController());
  }

  @override
  void dispose() {
    for (final c in _medCtrls) c.dispose();
    _allergies.dispose(); _history.dispose(); _doctor.dispose();
    super.dispose();
  }

  void _addMed() {
    setState(() => _medCtrls.add(TextEditingController()));
  }

  void _removeMed(int i) {
    _medCtrls[i].dispose();
    setState(() => _medCtrls.removeAt(i));
  }

  void _save() {
    widget.data.allergies      = _allergies.text.trim();
    widget.data.medicalHistory = _history.text.trim();
    widget.data.doctorName     = _doctor.text.trim();
    widget.data.medications    = _medCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  bool get _canContinue =>
      widget.data.diagnoses.isNotEmpty &&
      _medCtrls.any((c) => c.text.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        backgroundColor: C.surf0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: C.textPrimary),
          onPressed: widget.onBack,
        ),
        title: Text('New Authorization',
          style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700, color: C.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepHeader(current: 2, total: 3, title: 'Medical Information'),
            const SizedBox(height: 16),

            // Reassurance banner
            if (!_bannerDismissed)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: C.teal50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: C.teal500.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.medical_services_outlined, size: 18, color: C.teal600),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Write in plain English — our AI converts everything to medical terminology.',
                      style: GoogleFonts.inter(fontSize: 12, color: C.teal700, height: 1.4)),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _bannerDismissed = true),
                    child: const Icon(Icons.close, size: 16, color: C.teal600),
                  ),
                ]),
              ),

            // Diagnoses chip field
            SectionLabel('Diagnoses / Conditions', Icons.monitor_heart_outlined),
            const SizedBox(height: 10),
            ChipInputField(
              label: '',
              chips: widget.data.diagnoses,
              hint: 'e.g. Type 2 Diabetes — press Enter',
              onChanged: (v) => setState(() => widget.data.diagnoses = v),
            ),
            if (widget.data.diagnoses.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Text('At least one diagnosis is required',
                  style: GoogleFonts.inter(fontSize: 11, color: C.red500)),
              ),
            const SizedBox(height: 20),

            // Medications
            SectionLabel('Current Medications', Icons.medication_outlined),
            const SizedBox(height: 10),
            ..._medCtrls.asMap().entries.map((e) {
              final i = e.key;
              final ctrl = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: ctrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'e.g. Metformin 1000mg daily for 6 months',
                        prefixIcon: const Icon(Icons.medication_liquid_outlined, size: 18)),
                      style: GoogleFonts.inter(fontSize: 14, color: C.textPrimary),
                    ),
                  ),
                  if (_medCtrls.length > 1) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _removeMed(i),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: C.red50, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.remove_rounded, size: 18, color: C.red500),
                      ),
                    ),
                  ],
                ]),
              );
            }),
            GestureDetector(
              onTap: _addMed,
              child: Container(
                height: 40,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: C.teal50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: C.teal500.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.add_rounded, size: 16, color: C.teal600),
                  const SizedBox(width: 6),
                  Text('+ Add Medication',
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600, color: C.teal600)),
                ]),
              ),
            ),

            // Allergies
            SectionLabel('Known Allergies', Icons.warning_amber_outlined),
            const SizedBox(height: 10),
            TextFormField(
              controller: _allergies,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: "e.g. Penicillin — type 'None' if no known allergies"),
            ),
            const SizedBox(height: 20),

            // Medical history
            SectionLabel('Medical History & Previous Treatments', Icons.history_edu_outlined),
            const SizedBox(height: 10),
            TextFormField(
              controller: _history,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Previous treatments tried, test results, doctor notes…'),
            ),
            const SizedBox(height: 20),

            // Treating physician
            SectionLabel('Treating Physician', Icons.person_search_outlined),
            const SizedBox(height: 10),
            TextFormField(
              controller: _doctor,
              decoration: const InputDecoration(
                hintText: 'e.g. Dr. Sharma',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 18)),
            ),
            const SizedBox(height: 32),

            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: C.textPrimary,
                    side: const BorderSide(color: C.surf3),
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('← Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _canContinue ? () { _save(); widget.onNext(); } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.teal500,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Next: Review →',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
