import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';

// ── Patient Info Form Data ────────────────────────────────────────────────────

class PatientFormData {
  String fullName      = 'Margaret Thompson';
  DateTime? dateOfBirth = DateTime(1982, 5, 14);
  String insurer       = 'UnitedHealth';
  String policyNumber  = 'UHG-9844-XYZ';
  String memberId      = 'M-889012';

  // Medical info (Step 2)
  List<String> diagnoses  = [];
  List<String> medications = [];
  List<String> allergies  = [];
  String medicalHistory   = '';
  String doctorName       = '';

  List<PlatformFile> uploadedFiles = [];
}

// ── Insurer list ──────────────────────────────────────────────────────────────

const _insurers = [
  'UnitedHealth',
  'Blue Cross Blue Shield',
  'Aetna',
  'Cigna',
  'Humana',
  'Kaiser Permanente',
  'Anthem',
  'Centene',
  'Molina Healthcare',
  'Other',
];

// ── S04 Personal & Insurance Info — Step 1 of 3 ──────────────────────────────

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
  late TextEditingController _nameCtrl;
  late TextEditingController _policyCtrl;
  late TextEditingController _memberCtrl;

  bool get _canProceed =>
      widget.data.fullName.trim().isNotEmpty &&
      widget.data.dateOfBirth != null &&
      widget.data.insurer.isNotEmpty &&
      widget.data.policyNumber.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameCtrl   = TextEditingController(text: widget.data.fullName);
    _policyCtrl = TextEditingController(text: widget.data.policyNumber);
    _memberCtrl = TextEditingController(text: widget.data.memberId);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _policyCtrl.dispose();
    _memberCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.data.dateOfBirth ?? DateTime(1980),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: C.teal500,
            onPrimary: C.white,
            onSurface: C.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => widget.data.dateOfBirth = picked);
  }

  String _formatDob(DateTime? d) {
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')} / '
        '${d.month.toString().padLeft(2, '0')} / ${d.year}';
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
              StepHeader(
                current: 1,
                total: 3,
                title: 'Personal & Insurance Info',
              ),
              const SizedBox(height: 24),

              // ── Helper tip ─────────────────────────────────────────────────
              InfoBanner(
                message:
                    'Your Policy Number and Member ID are on the front of your insurance card.',
                icon: Icons.credit_card_rounded,
              ),
              const SizedBox(height: 20),

              // ── Personal Info ──────────────────────────────────────────────
              SectionLabel('Your Information', Icons.person_outline_rounded),
              const SizedBox(height: 10),

              MediCard(
                child: Column(
                  children: [
                    // Full Name
                    _FieldLabel('Full Name', required: true),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'e.g. John Doe',
                        prefixIcon:
                            Icon(Icons.person_outline_rounded, size: 20),
                      ),
                      onChanged: (v) =>
                          setState(() => widget.data.fullName = v),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Full name is required'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth
                    _FieldLabel('Date of Birth', required: true),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: C.surf2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.data.dateOfBirth == null
                                ? C.surf3
                                : C.teal500,
                            width: widget.data.dateOfBirth == null ? 0.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 18, color: C.textTertiary),
                            const SizedBox(width: 10),
                            Text(
                              widget.data.dateOfBirth != null
                                  ? _formatDob(widget.data.dateOfBirth)
                                  : 'DD / MM / YYYY',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: widget.data.dateOfBirth != null
                                    ? C.textPrimary
                                    : C.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Insurance Info ─────────────────────────────────────────────
              SectionLabel(
                  'Insurance Details', Icons.health_and_safety_outlined),
              const SizedBox(height: 10),

              MediCard(
                child: Column(
                  children: [
                    // Insurance Provider dropdown
                    _FieldLabel('Insurance Provider', required: true),
                    DropdownButtonFormField<String>(
                      value: widget.data.insurer.isNotEmpty
                          ? widget.data.insurer
                          : null,
                      decoration: InputDecoration(
                        hintText: 'Select your insurer...',
                        prefixIcon: const Icon(
                            Icons.business_outlined,
                            size: 20),
                        filled: true,
                        fillColor: C.surf2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: C.surf3, width: 0.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: C.surf3, width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: C.teal500, width: 1.5),
                        ),
                      ),
                      items: _insurers
                          .map((ins) => DropdownMenuItem(
                                value: ins,
                                child: Text(ins,
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: C.textPrimary)),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => widget.data.insurer = v ?? ''),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Please select your insurance provider'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Policy Number
                    _FieldLabel('Policy Number', required: true),
                    TextFormField(
                      controller: _policyCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'e.g. BCX-12345',
                        prefixIcon: Icon(Icons.tag_rounded, size: 20),
                      ),
                      onChanged: (v) =>
                          setState(() => widget.data.policyNumber = v),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Policy number is required'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    // Member ID (optional)
                    _FieldLabel('Member ID', required: false),
                    TextFormField(
                      controller: _memberCtrl,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: 'e.g. M-789012  (optional)',
                        prefixIcon:
                            Icon(Icons.badge_outlined, size: 20),
                      ),
                      onChanged: (v) =>
                          setState(() => widget.data.memberId = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              PrimaryButton(
                label: 'Next: Medical Info →',
                icon: Icons.arrow_forward_rounded,
                onPressed: _canProceed
                    ? () {
                        if (_formKey.currentState!.validate()) {
                          widget.onNext();
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Field label helper ────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel(this.label, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: C.textSecondary,
            ),
          ),
          if (required) ...[
            const SizedBox(width: 3),
            Text(
              ' *',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: C.red500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}