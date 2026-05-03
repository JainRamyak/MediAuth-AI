import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';

// ── Form Data Models ──────────────────────────────────────────────────────────

class PatientFormData {
  String fullName = '';
  String abhaId = '';
  DateTime? dateOfBirth;
  String insurer = '';
  String policyNumber = '';
  String memberId = '';
  List<String> diagnoses = [];
  List<String> medications = [];
  String allergies = '';
  String medicalHistory = '';
  String doctorName = '';
  String admissionType = 'Planned';
}

class TreatmentFormData {
  String requestedTreatment = '';
  String whyNeeded = '';
}

// ── Screen 4 — Patient & Insurance Info ───────────────────────────────────────

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
  late final TextEditingController _name;
  late final TextEditingController _abha;
  late final TextEditingController _policy;
  late final TextEditingController _member;

  static const _insurers = [
    'BlueCross', 'Aetna', 'UHC', 'Cigna', 'Humana', 'Kaiser', 'Medicaid', 'Medicare', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _name   = TextEditingController(text: widget.data.fullName);
    _abha   = TextEditingController(text: widget.data.abhaId);
    _policy = TextEditingController(text: widget.data.policyNumber);
    _member = TextEditingController(text: widget.data.memberId);
  }

  @override
  void dispose() {
    _name.dispose(); _abha.dispose(); _policy.dispose(); _member.dispose();
    super.dispose();
  }

  void _save() {
    widget.data.fullName = _name.text.trim();
    widget.data.abhaId = _abha.text.trim();
    widget.data.policyNumber = _policy.text.trim();
    widget.data.memberId = _member.text.trim();
  }

  Future<void> _pickDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: widget.data.dateOfBirth ?? DateTime(1985, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: C.teal500)),
        child: child!,
      ),
    );
    if (dt != null) setState(() => widget.data.dateOfBirth = dt);
  }

  Future<void> _pickInsurer() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final q = ValueNotifier<String>('');
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4,
                decoration: BoxDecoration(color: C.surf3, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search insurer…',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true, fillColor: C.surf2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: C.surf3, width: 0.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (v) => q.value = v.toLowerCase(),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ValueListenableBuilder<String>(
                  valueListenable: q,
                  builder: (_, query, __) {
                    final filtered = _insurers
                        .where((i) => i.toLowerCase().contains(query))
                        .toList();
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => ListTile(
                        title: Text(filtered[i]),
                        onTap: () => Navigator.pop(ctx, filtered[i]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (result != null) setState(() => widget.data.insurer = result);
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Full name is required';
    return null;
  }

  String? _validatePolicy(String? v) {
    if (v == null || v.trim().isEmpty) return 'Policy number is required';
    return null;
  }

  bool get _canContinue =>
      _name.text.trim().isNotEmpty &&
      widget.data.dateOfBirth != null &&
      widget.data.insurer.isNotEmpty &&
      _policy.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final dob = widget.data.dateOfBirth;
    final dobStr = dob != null
        ? '${dob.day.toString().padLeft(2, '0')} / ${dob.month.toString().padLeft(2, '0')} / ${dob.year}'
        : null;

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
      body: SafeArea(
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
              StepHeader(current: 1, total: 3, title: 'Personal & Insurance Info'),
              const SizedBox(height: 20),

              // ── Personal ─────────────────────────────────────────────────
              SectionLabel('About the Patient', Icons.person_outline_rounded),
              const SizedBox(height: 12),

              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'e.g. John Doe',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 18)),
                validator: _validateName,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _abha,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'ABHA ID / Ayushman Bharat No.',
                  hintText: 'e.g. 14-digit ABHA Number',
                  prefixIcon: Icon(Icons.credit_card_outlined, size: 18)),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: C.surf2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: C.surf3, width: 0.5),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: C.textTertiary),
                    const SizedBox(width: 10),
                    Text(dobStr ?? 'Date of Birth *',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: dob != null ? C.textPrimary : C.textTertiary)),
                  ]),
                ),
              ),
              if (widget.data.dateOfBirth == null)
                Padding(
                  padding: const EdgeInsets.only(left: 14, top: 4),
                  child: Text('Date of birth is required',
                    style: GoogleFonts.inter(fontSize: 11, color: C.red500)),
                ),
              const SizedBox(height: 20),

              // ── Insurance ─────────────────────────────────────────────────
              SectionLabel('Insurance Details', Icons.shield_outlined),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickInsurer,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: C.surf2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: C.surf3, width: 0.5),
                  ),
                  child: Row(children: [
                    const Icon(Icons.business_outlined, size: 18, color: C.textTertiary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(widget.data.insurer.isEmpty
                          ? 'Insurance Provider *'
                          : widget.data.insurer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: widget.data.insurer.isEmpty ? C.textTertiary : C.textPrimary)),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: C.textTertiary),
                  ]),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _policy,
                decoration: const InputDecoration(
                  labelText: 'Policy Number *',
                  hintText: 'e.g. BCX-12345',
                  prefixIcon: Icon(Icons.badge_outlined, size: 18)),
                validator: _validatePolicy,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _member,
                decoration: const InputDecoration(
                  labelText: 'Member ID (Optional)',
                  hintText: 'e.g. M-789012',
                  prefixIcon: Icon(Icons.numbers_rounded, size: 18)),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Info card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: C.teal50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: C.teal500.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.credit_card_outlined, size: 16, color: C.teal600),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your Policy Number and Member ID are printed on the front of your insurance card.',
                      style: GoogleFonts.inter(fontSize: 12, color: C.teal700, height: 1.4)),
                  ),
                ]),
              ),
                  ]),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: PrimaryButton(
                      label: 'Next: Medical Information →',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _canContinue ? () {
                        if (_formKey.currentState!.validate()) {
                          _save();
                          widget.onNext();
                        }
                      } : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
