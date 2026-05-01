import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  
  late TextEditingController _insurerCtrl;
  late TextEditingController _policyCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _pcpCtrl;

  @override
  void initState() {
    super.initState();
    _insurerCtrl = TextEditingController(text: 'UnitedHealth Group');
    _policyCtrl = TextEditingController(text: 'UHG-9844-XYZ');
    _dobCtrl = TextEditingController(text: '05/14/1982');
    _pcpCtrl = TextEditingController(text: 'Dr. Sarah Kim');
  }

  @override
  void dispose() {
    _insurerCtrl.dispose();
    _policyCtrl.dispose();
    _dobCtrl.dispose();
    _pcpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: () {
                setState(() => _isEditing = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Profile updated ✓'),
                    backgroundColor: C.teal700,
                  ),
                );
              },
              child: Text('Save',
                style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w600, color: C.teal600)),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Avatar hero ────────────────────────────────────────────────────
          Center(
            child: Column(children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: C.teal50,
                  border: Border.all(color: C.surf3, width: 0.5),
                ),
                child: Center(
                  child: Text('MT',
                    style: GoogleFonts.inter(
                      fontSize: 28, fontWeight: FontWeight.w700,
                      color: C.teal700)),
                ),
              ),
              const SizedBox(height: 12),
              Text('Margaret Thompson',
                style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: C.teal50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: C.teal500, width: 0.5),
                ),
                child: Text('Patient ID: MT-4820',
                  style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: C.teal700)),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // ── Account info ───────────────────────────────────────────────────
          SectionLabel('Health Coverage', Icons.health_and_safety_outlined),
          const SizedBox(height: 12),
          
          if (_isEditing)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _insurerCtrl,
                      decoration: const InputDecoration(labelText: 'Insurer'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _policyCtrl,
                      decoration: const InputDecoration(labelText: 'Policy Number'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dobCtrl,
                      decoration: const InputDecoration(labelText: 'Date of Birth'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pcpCtrl,
                      decoration: const InputDecoration(labelText: 'Primary Care Physician'),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Column(children: [
                _InfoRow(Icons.business_outlined, 'Insurer', _insurerCtrl.text),
                const Divider(height: 0.5),
                _InfoRow(Icons.credit_card_outlined, 'Policy Number', _policyCtrl.text),
                const Divider(height: 0.5),
                _InfoRow(Icons.calendar_today_outlined, 'Date of Birth', _dobCtrl.text),
                const Divider(height: 0.5),
                _InfoRow(Icons.medical_services_outlined, 'Primary Care', _pcpCtrl.text),
              ]),
            ),
          const SizedBox(height: 20),

          // ── Consumer Settings ──────────────────────────────────────────────
          if (!_isEditing) ...[
            SectionLabel('Preferences', Icons.tune_rounded),
            const SizedBox(height: 12),
            Card(
              child: Column(children: [
                _ActionRow(Icons.notifications_active_outlined, 'Push Notifications'),
                const Divider(height: 0.5),
                _ActionRow(Icons.shield_outlined, 'Privacy & Security'),
                const Divider(height: 0.5),
                _ActionRow(Icons.help_outline_rounded, 'Help Center'),
              ]),
            ),
            const SizedBox(height: 28),

            // Sign out
            OutlinedButton.icon(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout_rounded,
                size: 18, color: C.red500),
              label: Text('Sign out',
                style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w600,
                  color: C.red500)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: C.red500, width: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 14, vertical: 12),
    child: Row(children: [
      Icon(icon, size: 18, color: C.textTertiary),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
              style: GoogleFonts.inter(
                fontSize: 12, color: C.textTertiary)),
            const SizedBox(height: 2),
            Text(value,
              style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: C.textPrimary)),
          ],
        ),
      ),
    ]),
  );
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ActionRow(this.icon, this.label);

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () {},
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14, vertical: 16),
      child: Row(children: [
        Icon(icon, size: 18, color: C.textTertiary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
            style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w500, color: C.textPrimary))),
        const Icon(Icons.chevron_right_rounded, size: 18, color: C.textTertiary),
      ]),
    ),
  );
}
