import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';

// ── Patient Info Form Data ────────────────────────────────────────────────────

class PatientFormData {
  String providerName = '';
  List<String> diagnoses = [];
  List<String> medications = [];
  List<String> allergies = [];
  List<PlatformFile> uploadedFiles = [];
}

// ── S04 Patient Info Screen ───────────────────────────────────────────────────

class PatientInfoScreen extends StatefulWidget {
  final PatientFormData data;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const PatientInfoScreen({
    super.key,
    required this.data,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<PatientInfoScreen> createState() => _PatientInfoScreenState();
}

class _PatientInfoScreenState extends State<PatientInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _pickingFile = false;
  bool get _canProceed => widget.data.providerName.isNotEmpty;

  Future<void> _pickFiles() async {
    setState(() => _pickingFile = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );
      if (result != null && mounted) {
        setState(() {
          for (final f in result.files) {
            if (!widget.data.uploadedFiles.any((e) => e.name == f.name)) {
              widget.data.uploadedFiles.add(f);
            }
          }
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _pickingFile = false);
  }

  void _removeFile(PlatformFile f) =>
    setState(() => widget.data.uploadedFiles.remove(f));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        title: Text('New Authorization',
          style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w600,
            color: C.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
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
              StepHeader(current: 1, total: 3,
                title: 'Provider & Clinical Info'),
              const SizedBox(height: 24),

              // ── Identity card (pre-filled) ────────────────────────────────
              MediCard(
                accentColor: C.teal500,
                child: Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: const BoxDecoration(
                      color: C.teal50, shape: BoxShape.circle),
                    child: const Icon(Icons.verified_user_rounded,
                      size: 20, color: C.teal600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Margaret Thompson',
                          style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: C.textPrimary)),
                        Text('DOB: 05/14/1982 · UnitedHealth · UHG-9844-XYZ',
                          style: GoogleFonts.inter(
                            fontSize: 12, color: C.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded,
                    size: 18, color: C.teal500),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Provider section ──────────────────────────────────────────
              SectionLabel('Ordering Provider',
                Icons.business_center_outlined),
              const SizedBox(height: 10),

              MediCard(
                child: TextFormField(
                  initialValue: widget.data.providerName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Doctor or Clinic Name *',
                    hintText: 'e.g. Dr. Sarah Kim (AIIMS)',
                    prefixIcon: Icon(
                      Icons.person_outline_rounded, size: 20),
                    border: InputBorder.none,
                    filled: false,
                  ),
                  onChanged: (v) =>
                    setState(() => widget.data.providerName = v),
                  validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Provider name is required' : null,
                ),
              ),
              const SizedBox(height: 20),

              // ── Clinical section ──────────────────────────────────────────
              SectionLabel('Clinical History',
                Icons.medical_information_outlined),
              const SizedBox(height: 10),

              MediCard(
                child: Column(
                  children: [
                    ChipInputField(
                      label: 'Diagnoses',
                      chips: widget.data.diagnoses,
                      hint: 'Enter code & press Enter (e.g. M17.11)',
                      onChanged: (v) =>
                        setState(() => widget.data.diagnoses = v),
                    ),
                    const SizedBox(height: 14),
                    ChipInputField(
                      label: 'Current Medications',
                      chips: widget.data.medications,
                      hint: 'e.g. Celecoxib 200mg',
                      onChanged: (v) =>
                        setState(() => widget.data.medications = v),
                    ),
                    const SizedBox(height: 14),
                    ChipInputField(
                      label: 'Known Allergies',
                      chips: widget.data.allergies,
                      hint: 'e.g. Penicillin',
                      onChanged: (v) =>
                        setState(() => widget.data.allergies = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Medical records upload ─────────────────────────────────────
              SectionLabel('Medical Records',
                Icons.upload_file_outlined),
              const SizedBox(height: 6),
              Text('Attach lab reports, imaging, or referral letters',
                style: GoogleFonts.inter(
                  fontSize: 12, color: C.textTertiary)),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: _pickingFile ? null : _pickFiles,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _pickingFile ? C.teal50 : C.surf0,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _pickingFile ? C.teal500 : C.surf3,
                      width: _pickingFile ? 1.5 : 0.5),
                  ),
                  child: Column(children: [
                    Icon(
                      _pickingFile
                        ? Icons.hourglass_top_rounded
                        : Icons.cloud_upload_outlined,
                      size: 36,
                      color: _pickingFile ? C.teal500 : C.textTertiary),
                    const SizedBox(height: 8),
                    Text(
                      _pickingFile
                        ? 'Selecting files…'
                        : 'Tap to upload medical records',
                      style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: _pickingFile ? C.teal600 : C.textSecondary)),
                    const SizedBox(height: 2),
                    Text('PDF, JPG, PNG, DOC · Max 25 MB each',
                      style: GoogleFonts.inter(
                        fontSize: 11, color: C.textTertiary)),
                  ]),
                ),
              ),

              if (widget.data.uploadedFiles.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...widget.data.uploadedFiles.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: C.teal50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: C.teal500.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.description_outlined,
                        size: 18, color: C.teal600),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.name,
                              style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w500,
                                color: C.textPrimary),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (f.size > 0)
                              Text('${(f.size / 1024).toStringAsFixed(1)} KB',
                                style: GoogleFonts.inter(
                                  fontSize: 11, color: C.teal700)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removeFile(f),
                        child: const Icon(Icons.close_rounded,
                          size: 18, color: C.textTertiary),
                      ),
                    ]),
                  ),
                )),
              ],

              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Continue to Treatment →',
                onPressed: _canProceed
                  ? () {
                      if (_formKey.currentState!.validate()) {
                        widget.onNext();
                      }
                    }
                  : null,
                icon: Icons.arrow_forward_rounded,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
