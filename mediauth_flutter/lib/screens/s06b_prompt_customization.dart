import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';
import '../api/api_service.dart';
import 's04_patient_info.dart';

// ── Prompt Submit Payload ─────────────────────────────────────────────────────
// Passed from Screen 6B back to Screen 7 on submit.

class PromptSubmitPayload {
  final List<AgentPromptData> editedAgents;
  final String customContext;

  const PromptSubmitPayload({
    required this.editedAgents,
    required this.customContext,
  });
}

class AgentPromptData {
  final String key;
  String systemPrompt;
  String userTemplate;
  String originalSystem;
  String originalTemplate;

  AgentPromptData({
    required this.key,
    required this.systemPrompt,
    required this.userTemplate,
    required this.originalSystem,
    required this.originalTemplate,
  });

  bool get isDirty =>
      systemPrompt != originalSystem || userTemplate != originalTemplate;
}

// ── Prompt Customization Screen ───────────────────────────────────────────────

class PromptCustomizationScreen extends StatefulWidget {
  final PatientFormData patient;
  final TreatmentFormData treatment;
  final void Function(PromptSubmitPayload? payload) onSubmit;
  final VoidCallback onBack;

  const PromptCustomizationScreen({
    super.key,
    required this.patient,
    required this.treatment,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  State<PromptCustomizationScreen> createState() => _PromptCustomizationScreenState();
}

class _PromptCustomizationScreenState extends State<PromptCustomizationScreen>
    with SingleTickerProviderStateMixin {
  final _contextCtrl = TextEditingController();
  bool _advancedOpen = false;
  bool _loading = false;
  bool _saving = false;

  // Agent data
  static const _agentNames = {
    'intake':           'Intake',
    'medical_analysis': 'Medical',
    'policy':           'Policy',
    'justification':    'Justification',
    'submission':       'Submission',
    'appeal':           'Appeal',
    'claims':           'Claims',
  };

  final _agents = <AgentPromptData>[];
  int _selectedTab = 0;
  bool _agentsLoaded = false;

  // Example context hints
  static const _hints = [
    'Insurer denied this before — stress 9-month history',
    'My doctor considers this medically urgent',
    'Include failed Metformin dose escalation attempts',
  ];

  int get _contextLen => _contextCtrl.text.length;

  @override
  void dispose() {
    _contextCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAgents() async {
    if (_agentsLoaded) return;
    setState(() => _loading = true);
    try {
      final keys = await ApiService.fetchPromptsList();
      for (final k in keys) {
        try {
          final p = await ApiService.fetchPrompt(k);
          _agents.add(AgentPromptData(
            key: k,
            systemPrompt: p['system'] ?? '',
            userTemplate: p['user_template'] ?? '',
            originalSystem: p['system'] ?? '',
            originalTemplate: p['user_template'] ?? '',
          ));
        } catch (_) {}
      }
      _agentsLoaded = true;
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _anyDirty => _agents.any((a) => a.isDirty);

  void _resetAll() {
    setState(() {
      for (final a in _agents) {
        a.systemPrompt  = a.originalSystem;
        a.userTemplate  = a.originalTemplate;
      }
    });
  }

  Future<void> _submitWithPrompts() async {
    setState(() => _saving = true);

    final dirtyAgents = _agents.where((a) => a.isDirty).toList();

    // Save dirty agents first
    for (final ag in dirtyAgents) {
      try {
        await ApiService.updatePromptDirect(ag.key, ag.systemPrompt, ag.userTemplate);
        ag.originalSystem   = ag.systemPrompt;
        ag.originalTemplate = ag.userTemplate;
      } catch (_) {
        if (mounted) {
          showMediToast(context, 'Failed to save ${_agentNames[ag.key] ?? ag.key} prompt.',
              kind: ToastKind.error);
        }
      }
    }

    setState(() => _saving = false);

    widget.onSubmit(PromptSubmitPayload(
      editedAgents: [], // already saved above
      customContext: _contextCtrl.text.trim(),
    ));
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
            Text('Customize AI Prompts',
              style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700, color: C.textPrimary)),
            Text('Optional · AI works great without changes',
              style: GoogleFonts.inter(fontSize: 11, color: C.textTertiary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => widget.onSubmit(null),
            child: Text('Skip & Submit →',
              style: GoogleFonts.inter(
                fontSize: 13, color: C.teal600, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section 1: Quick Context ──────────────────────────────────
            MediCard(
              accentColor: C.teal500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        size: 18, color: C.teal500),
                    const SizedBox(width: 8),
                    Text('Add Extra Context for the AI',
                      style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: C.textPrimary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: C.green50,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: C.green500.withValues(alpha: 0.3)),
                      ),
                      child: Text('Recommended',
                        style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: C.green600)),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contextCtrl,
                    maxLines: 6,
                    maxLength: 1000,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText:
                          'Add anything extra the AI should know before writing your authorization letter…',
                      counterText: ''),
                    style: GoogleFonts.inter(fontSize: 13, color: C.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _contextLen / 1000.0,
                          minHeight: 3,
                          backgroundColor: C.surf2,
                          valueColor: AlwaysStoppedAnimation(
                              _contextLen > 800 ? C.amber500 : C.teal500),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$_contextLen / 1000',
                      style: GoogleFonts.inter(
                        fontSize: 11, color: C.textTertiary)),
                  ]),
                  const SizedBox(height: 12),
                  Text('💡 Example context:',
                    style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: C.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _hints.map((h) => GestureDetector(
                      onTap: () {
                        final cur = _contextCtrl.text;
                        _contextCtrl.text = cur.isEmpty ? h : '$cur\n$h';
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: C.teal50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: C.teal500.withValues(alpha: 0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.add_rounded, size: 13, color: C.teal600),
                          const SizedBox(width: 4),
                          Text(h,
                            style: GoogleFonts.inter(
                              fontSize: 11, color: C.teal700)),
                        ]),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Section 2: Advanced prompt editor ────────────────────────
            Container(
              decoration: BoxDecoration(
                color: C.surf0,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: C.surf3, width: 0.5),
              ),
              child: ExpansionTile(
                leading: const Icon(Icons.code_rounded, color: C.teal500, size: 20),
                title: Text('Advanced — Inspect & Edit AI Agent Prompts',
                  style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: C.textPrimary)),
                initiallyExpanded: _advancedOpen,
                shape: const Border(),
                collapsedShape: const Border(),
                onExpansionChanged: (v) {
                  setState(() => _advancedOpen = v);
                  if (v) _loadAgents();
                },
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(color: C.teal500)),
                    )
                  else if (_agents.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: InfoBanner(
                        message: 'Could not load agent prompts. Backend may be offline.',
                        icon: Icons.wifi_off_rounded,
                        bgColor: C.amber50,
                        accentColor: C.amber500,
                        textColor: C.amber700,
                      ),
                    )
                  else ...[
                    // Tab bar
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _agents.length,
                        itemBuilder: (ctx, i) {
                          final ag = _agents[i];
                          final active = i == _selectedTab;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedTab = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: active ? C.teal500 : C.surf2,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: active ? C.teal500 : C.surf3,
                                  width: 0.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_agentNames[ag.key] ?? ag.key,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: active ? Colors.white : C.textSecondary)),
                                  if (ag.isDirty) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      width: 6, height: 6,
                                      decoration: const BoxDecoration(
                                        color: C.amber500, shape: BoxShape.circle)),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_selectedTab < _agents.length)
                      _InlineAgentEditor(
                        agent: _agents[_selectedTab],
                        onChanged: () => setState(() {}),
                      ),
                    if (_anyDirty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: OutlinedButton(
                          onPressed: _resetAll,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: C.red500,
                            side: const BorderSide(color: C.red500, width: 0.8),
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('↺ Reset All Agents to Default',
                            style: GoogleFonts.inter(fontSize: 13)),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
              onPressed: _saving ? null : _submitWithPrompts,
              style: ElevatedButton.styleFrom(
                backgroundColor: C.teal500, foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                  : Text('Submit with These Prompts →',
                      style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => widget.onSubmit(null),
              style: TextButton.styleFrom(foregroundColor: C.textSecondary),
              child: Text('Discard changes · use default prompts',
                style: GoogleFonts.inter(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Inline Agent Editor (inside ExpansionTile) ────────────────────────────────

class _InlineAgentEditor extends StatefulWidget {
  final AgentPromptData agent;
  final VoidCallback onChanged;
  const _InlineAgentEditor({required this.agent, required this.onChanged});

  @override
  State<_InlineAgentEditor> createState() => _InlineAgentEditorState();
}

class _InlineAgentEditorState extends State<_InlineAgentEditor> {
  late final TextEditingController _sysCtrl;
  late final TextEditingController _usrCtrl;

  @override
  void initState() {
    super.initState();
    _sysCtrl = TextEditingController(text: widget.agent.systemPrompt);
    _usrCtrl = TextEditingController(text: widget.agent.userTemplate);
  }

  @override
  void didUpdateWidget(_InlineAgentEditor old) {
    super.didUpdateWidget(old);
    if (old.agent.key != widget.agent.key) {
      _sysCtrl.text = widget.agent.systemPrompt;
      _usrCtrl.text = widget.agent.userTemplate;
    }
  }

  @override
  void dispose() { _sysCtrl.dispose(); _usrCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sysDirty = _sysCtrl.text != widget.agent.originalSystem;
    final usrDirty = _usrCtrl.text != widget.agent.originalTemplate;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sysDirty || usrDirty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InfoBanner(
                message: 'Editing a live agent. Changes affect all future requests.',
                icon: Icons.warning_amber_rounded,
                bgColor: C.amber50, accentColor: C.amber500, textColor: C.amber700,
              ),
            ),
          _field('System Prompt', _sysCtrl, sysDirty, () {
            setState(() {
              _sysCtrl.text = widget.agent.originalSystem;
              widget.agent.systemPrompt = widget.agent.originalSystem;
              widget.onChanged();
            });
          }, (v) {
            widget.agent.systemPrompt = v;
            widget.onChanged();
          }),
          const SizedBox(height: 12),
          _field('User Prompt Template', _usrCtrl, usrDirty, () {
            setState(() {
              _usrCtrl.text = widget.agent.originalTemplate;
              widget.agent.userTemplate = widget.agent.originalTemplate;
              widget.onChanged();
            });
          }, (v) {
            widget.agent.userTemplate = v;
            widget.onChanged();
          }),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, bool dirty,
      VoidCallback onReset, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label, style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600, color: C.textSecondary)),
          const Spacer(),
          TextButton(
            onPressed: onReset,
            style: TextButton.styleFrom(
              foregroundColor: C.red500,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            ),
            child: Text('Reset', style: GoogleFonts.inter(fontSize: 11)),
          ),
        ]),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: dirty ? const Color(0xFFFFFDE7) : C.surf2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: dirty ? const Color(0xFFF39C12) : C.surf3,
              width: dirty ? 1.5 : 0.5),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: 5,
            onChanged: onChanged,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11, color: C.textPrimary, height: 1.5),
            decoration: const InputDecoration(
              border: InputBorder.none, filled: false,
              contentPadding: EdgeInsets.all(10)),
          ),
        ),
      ],
    );
  }
}
