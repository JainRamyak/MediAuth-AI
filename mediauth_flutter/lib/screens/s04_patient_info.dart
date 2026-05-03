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

// ─────────────────────────────────────────────────────────────────────────────
// s04_patient_info.dart  —  Step 1 of 3: Patient & Insurance Info
// ─────────────────────────────────────────────────────────────────────────────

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
    'BlueCross', 'Aetna', 'UHC', 'Cigna',
    'Humana', 'Kaiser', 'Medicaid', 'Medicare', 'Other',
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
    widget.data.fullName    = _name.text.trim();
    widget.data.abhaId      = _abha.text.trim();
    widget.data.policyNumber = _policy.text.trim();
    widget.data.memberId    = _member.text.trim();
  }

  Future<void> _pickDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: widget.data.dateOfBirth ?? DateTime(1985),
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
      backgroundColor: C.surf0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final q = ValueNotifier<String>('');
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: C.surf3, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Select Insurance Provider',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: C.textPrimary)),
            ),
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
            const SizedBox(height: 6),
            Flexible(
              child: ValueListenableBuilder<String>(
                valueListenable: q,
                builder: (_, query, __) {
                  final filtered = _insurers
                      .where((i) => i.toLowerCase().contains(query)).toList();
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => ListTile(
                      leading: const Icon(Icons.business_outlined,
                          size: 18, color: C.textSecondary),
                      title: Text(filtered[i],
                        style: GoogleFonts.inter(fontSize: 14, color: C.textPrimary)),
                      trailing: widget.data.insurer == filtered[i]
                        ? const Icon(Icons.check_circle_rounded, size: 18, color: C.teal500)
                        : null,
                      onTap: () => Navigator.pop(ctx, filtered[i]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ]),
        );
      },
    );
    if (result != null) setState(() => widget.data.insurer = result);
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
      appBar: IntakeAppBar(
        title: 'New Authorization',
        onBack: widget.onBack,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverList(delegate: SliverChildListDelegate([

                  StepHeader(current: 1, total: 3, title: 'Patient & Insurance Info'),
                  const SizedBox(height: 24),

                  // ── Personal ─────────────────────────────────────────
                  _FormSectionCard(
                    icon: Icons.person_outline_rounded,
                    label: 'About the Patient',
                    child: Column(children: [

                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full Patient Name *',
                          hintText: 'e.g. John Doe',
                          prefixIcon: Icon(Icons.person_outline_rounded, size: 20)),
                        validator: (v) => v!.trim().isEmpty ? 'Full name is required' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _abha,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'ABHA ID (Optional)',
                          hintText: '14-digit ABHA Number',
                          prefixIcon: Icon(Icons.credit_card_outlined, size: 20)),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),

                      // DOB picker
                      _PickerRow(
                        icon: Icons.calendar_today_rounded,
                        label: dobStr ?? 'Date of Birth *',
                        filled: dob != null,
                        onTap: _pickDate,
                      ),

                      if (widget.data.dateOfBirth == null)
                        const _RequiredHint('Date of birth is required'),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // ── Insurance ─────────────────────────────────────────
                  _FormSectionCard(
                    icon: Icons.shield_outlined,
                    label: 'Insurance Details',
                    child: Column(children: [

                      _PickerRow(
                        icon: Icons.business_outlined,
                        label: widget.data.insurer.isEmpty
                            ? 'Insurance Provider *'
                            : widget.data.insurer,
                        filled: widget.data.insurer.isNotEmpty,
                        onTap: _pickInsurer,
                        trailing: const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 20, color: C.textTertiary),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _policy,
                        decoration: const InputDecoration(
                          labelText: 'Policy Number *',
                          hintText: 'e.g. BCX-12345',
                          prefixIcon: Icon(Icons.badge_outlined, size: 20)),
                        validator: (v) => v!.trim().isEmpty ? 'Policy number is required' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _member,
                        decoration: const InputDecoration(
                          labelText: 'Member ID (Optional)',
                          hintText: 'e.g. M-789012',
                          prefixIcon: Icon(Icons.numbers_rounded, size: 20)),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),

                      // Hint banner
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
                          Expanded(child: Text(
                            'Policy number and Member ID are printed on the front of your insurance card.',
                            style: GoogleFonts.inter(fontSize: 12, color: C.teal700, height: 1.4))),
                        ]),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 48),
                ])),
              ),

              // Sticky bottom button
              SliverFillRemaining(
                hasScrollBody: false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: PrimaryButton(
                      label: 'Next: Medical Info →',
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

// ─── Shared Intake App Bar ───────────────────────────────────────────────────

class IntakeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;
  const IntakeAppBar({required this.title, required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: C.navy800,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      onPressed: onBack,
    ),
    title: Text(title,
      style: GoogleFonts.outfit(
        fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(0.5),
      child: Container(height: 0.5, color: Colors.white.withValues(alpha: 0.08)),
    ),
  );
}

// ─── Form Section Card ────────────────────────────────────────────────────────

class _FormSectionCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Widget   child;
  const _FormSectionCard({required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: C.surf0,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: C.surf3.withValues(alpha: 0.7), width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Section header
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: C.teal50, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 15, color: C.teal500),
          ),
          const SizedBox(width: 10),
          Text(label,
            style: GoogleFonts.outfit(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: C.textPrimary, letterSpacing: -0.2)),
        ]),
      ),

      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: child,
      ),
    ]),
  );
}

// ─── Picker Row ───────────────────────────────────────────────────────────────

class _PickerRow extends StatelessWidget {
  final IconData  icon;
  final String    label;
  final bool      filled;
  final VoidCallback onTap;
  final Widget?   trailing;
  const _PickerRow({
    required this.icon, required this.label,
    required this.filled, required this.onTap, this.trailing,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: C.surf2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.surf3, width: 0.5),
      ),
      child: Row(children: [
        Icon(icon, size: 20, color: C.textTertiary),
        const SizedBox(width: 10),
        Expanded(child: Text(label,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: filled ? C.textPrimary : C.textTertiary))),
        trailing ?? const Icon(Icons.chevron_right_rounded, size: 18, color: C.textTertiary),
      ]),
    ),
  );
}

// ─── Required hint ────────────────────────────────────────────────────────────

class _RequiredHint extends StatelessWidget {
  final String msg;
  const _RequiredHint(this.msg);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 14, top: 4),
    child: Text(msg,
      style: GoogleFonts.inter(fontSize: 11, color: C.red500)),
  );
}
