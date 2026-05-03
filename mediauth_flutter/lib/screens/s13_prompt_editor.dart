import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../api/api_service.dart';

// ── Agent descriptions ────────────────────────────────────────────────────────

const _descriptions = {
  'intake': 'Reads your submitted form and structures it into a clean patient profile. '
      'Extracts your name, insurance, diagnoses, and medications.',
  'medical_analysis': 'Converts your plain-English diagnoses into official ICD-10 diagnosis '
      'codes and CPT procedure codes that insurers require.',
  'policy': "Checks your insurer's specific coverage rules and documentation requirements "
      'for the requested treatment.',
  'justification': 'Writes the formal prior authorization letter — in medical terminology, '
      'properly formatted, citing your clinical data.',
  'submission': 'Submits the authorization request to your insurer and monitors for their decision.',
  'appeal': 'When a request is denied, this agent analyzes the denial reason, '
      'finds supporting evidence, and writes a formal appeal letter.',
  'claims': 'Validates all billing codes for accuracy and flags any issues that could '
      'cause a claim rejection.',
};

// ── Screen 13 — Agent Detail & Prompt Editor ──────────────────────────────────

class PromptEditorScreen extends StatefulWidget {
  final String agentKey;
  final String displayName;
  final VoidCallback onBack;

  const PromptEditorScreen({
    super.key,
    required this.agentKey,
    required this.displayName,
    required this.onBack,
  });

  @override
  State<PromptEditorScreen> createState() => _PromptEditorScreenState();
}

class _PromptEditorScreenState extends State<PromptEditorScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  late TextEditingController _system;
  late TextEditingController _userTemplate;
  String _origSystem = '';
  String _origUser = '';

  bool get _systemDirty => _system.text != _origSystem;
  bool get _userDirty => _userTemplate.text != _origUser;
  bool get _isDirty => _systemDirty || _userDirty;

  @override
  void initState() {
    super.initState();
    _system = TextEditingController();
    _userTemplate = TextEditingController();
    _system.addListener(() => setState(() {}));
    _userTemplate.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _system.dispose(); _userTemplate.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final p = await ApiService.fetchPrompt(widget.agentKey);
      _origSystem  = p['system'] ?? '';
      _origUser    = p['user_template'] ?? '';
      _system.text = _origSystem;
      _userTemplate.text = _origUser;
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Could not load prompt. Is the backend running?';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService.updatePromptDirect(
        widget.agentKey, _system.text, _userTemplate.text);
      _origSystem = _system.text;
      _origUser   = _userTemplate.text;
      if (mounted) {
        setState(() => _saving = false);
        showMediToast(context, 'Prompt saved successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showMediToast(context, 'Failed to save prompt. Try again.',
            kind: ToastKind.error);
      }
    }
  }

  void _resetToOriginal() {
    setState(() {
      _system.text = _origSystem;
      _userTemplate.text = _origUser;
    });
  }

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.displayName,
              style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700, color: C.textPrimary)),
            Text('Agent • Prompt Editor',
              style: GoogleFonts.inter(fontSize: 11, color: C.textTertiary)),
          ],
        ),
        actions: [
          // ● Live pill
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: C.teal500, width: 0.8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 7, height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF00C853), shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('Live',
                style: GoogleFonts.inter(
                  fontSize: 11, color: C.teal600,
                  fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.teal500))
          : _error != null
              ? _ErrorBody(message: _error!, onRetry: _load)
              : _Body(
                  agentKey: widget.agentKey,
                  systemCtrl: _system,
                  userCtrl: _userTemplate,
                  systemDirty: _systemDirty,
                  userDirty: _userDirty,
                  isDirty: _isDirty,
                  onResetSystem: () => setState(() => _system.text = _origSystem),
                  onResetUser: () => setState(() => _userTemplate.text = _origUser),
                  onCopySystem: () => Clipboard.setData(ClipboardData(text: _system.text)),
                  onCopyUser: () => Clipboard.setData(ClipboardData(text: _userTemplate.text)),
                ),
      bottomNavigationBar: _loading || _error != null
          ? null
          : _BottomBar(
              isDirty: _isDirty,
              saving: _saving,
              onSave: _isDirty && !_saving ? _save : null,
              onReset: _isDirty ? _resetToOriginal : null,
            ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final String agentKey;
  final TextEditingController systemCtrl;
  final TextEditingController userCtrl;
  final bool systemDirty;
  final bool userDirty;
  final bool isDirty;
  final VoidCallback onResetSystem;
  final VoidCallback onResetUser;
  final VoidCallback onCopySystem;
  final VoidCallback onCopyUser;

  const _Body({
    required this.agentKey,
    required this.systemCtrl,
    required this.userCtrl,
    required this.systemDirty,
    required this.userDirty,
    required this.isDirty,
    required this.onResetSystem,
    required this.onResetUser,
    required this.onCopySystem,
    required this.onCopyUser,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // What this agent does
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: C.teal50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: C.teal500.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.smart_toy_outlined, size: 16, color: C.teal600),
                  const SizedBox(width: 8),
                  Text('What This Agent Does',
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600, color: C.teal700)),
                ]),
                const SizedBox(height: 8),
                Text(_descriptions[agentKey] ?? agentKey,
                  style: GoogleFonts.inter(
                    fontSize: 13, color: C.teal700, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dirty warning
          if (isDirty) ...[
            InfoBanner(
              message: "You're editing a live AI agent. Changes affect all future requests.",
              icon: Icons.warning_amber_rounded,
              bgColor: C.amber50,
              accentColor: C.amber500,
              textColor: C.amber700,
            ),
            const SizedBox(height: 16),
          ],

          // System Prompt editor
          _PromptEditor(
            label: 'System Prompt',
            ctrl: systemCtrl,
            isDirty: systemDirty,
            onReset: onResetSystem,
            onCopy: onCopySystem,
          ),
          const SizedBox(height: 16),

          // User Template editor
          _PromptEditor(
            label: 'User Prompt Template',
            ctrl: userCtrl,
            isDirty: userDirty,
            onReset: onResetUser,
            onCopy: onCopyUser,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ── Prompt Editor ─────────────────────────────────────────────────────────────

class _PromptEditor extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final bool isDirty;
  final VoidCallback onReset;
  final VoidCallback onCopy;

  const _PromptEditor({
    required this.label,
    required this.ctrl,
    required this.isDirty,
    required this.onReset,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label,
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600, color: C.textPrimary)),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text('Reset'),
            onPressed: onReset,
            style: TextButton.styleFrom(
              foregroundColor: C.red500,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 14),
            label: const Text('Copy'),
            onPressed: onCopy,
            style: TextButton.styleFrom(
              foregroundColor: C.teal600,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isDirty ? const Color(0xFFFFFDE7) : C.surf0,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDirty ? const Color(0xFFF39C12) : C.surf3,
              width: isDirty ? 1.5 : 0.5,
            ),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: null,
            minLines: 6,
            keyboardType: TextInputType.multiline,
            style: AppTheme.monoStyle(color: C.textPrimary, size: 12),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
              filled: false,
            ),
          ),
        ),
        const SizedBox(height: 4),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: ctrl,
          builder: (_, v, __) => Text(
            '${v.text.length} characters',
            style: GoogleFonts.inter(fontSize: 11, color: C.textTertiary)),
        ),
      ],
    );
  }
}

// ── Bottom Bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool isDirty;
  final bool saving;
  final VoidCallback? onSave;
  final VoidCallback? onReset;

  const _BottomBar({
    required this.isDirty,
    required this.saving,
    this.onSave,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: C.surf0,
        border: Border(top: BorderSide(color: C.surf3, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDirty ? C.teal500 : C.surf3,
              foregroundColor: isDirty ? Colors.white : C.textTertiary,
              elevation: 0,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            ),
            child: saving
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
                : Text('Save Changes',
                    style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          if (isDirty) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: onReset,
              style: TextButton.styleFrom(foregroundColor: C.red500),
              child: const Text('↺  Reset to Original'),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Error Body ────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: C.textTertiary),
            const SizedBox(height: 16),
            Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: C.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: C.teal500, foregroundColor: Colors.white, elevation: 0),
            ),
          ],
        ),
      ),
    );
  }
}
