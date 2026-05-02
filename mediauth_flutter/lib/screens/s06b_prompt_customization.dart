import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';

// ── Agent prompt data ─────────────────────────────────────────────────────────

class AgentPromptData {
  final String key;
  final String label;
  String systemPrompt;
  String userTemplate;
  bool isDirty;

  AgentPromptData({
    required this.key,
    required this.label,
    required this.systemPrompt,
    required this.userTemplate,
    this.isDirty = false,
  });

  AgentPromptData copyWith({
    String? systemPrompt,
    String? userTemplate,
    bool? isDirty,
  }) =>
      AgentPromptData(
        key: key,
        label: label,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        userTemplate: userTemplate ?? this.userTemplate,
        isDirty: isDirty ?? this.isDirty,
      );
}

// ── Submission payload carries both custom context AND edited prompts ──────────
// UF API flow: PUT /api/v1/prompts/{agent} for each dirty agent BEFORE POST /authorize
class PromptSubmitPayload {
  final String customContext;
  final List<AgentPromptData> editedAgents; // only dirty agents

  const PromptSubmitPayload({
    required this.customContext,
    required this.editedAgents,
  });
}

final _defaultAgentPrompts = [
  AgentPromptData(
    key: 'intake',
    label: 'Intake',
    systemPrompt:
        'You are a clinical authorization specialist AI working within the MediAuth AI agentic pipeline.\n\nYour role is to process the patient intake data, extract key medical information, and structure it for downstream agents.\n\nAlways validate that {patient_name}, {dob}, {policy_number}, and {insurer} are present before proceeding.\n\nOutput: Structured JSON with keys: patient_profile, clinical_history, insurance_details.',
    userTemplate:
        'Patient intake data:\n{patient_input}\n\nExtract and return structured profile JSON.',
  ),
  AgentPromptData(
    key: 'medical',
    label: 'Medical',
    systemPrompt:
        'You are a medical coding expert AI. Map the patient\'s diagnoses and requested procedure to accurate ICD-10 and CPT codes.\n\nRules:\n- Use ICD-10-CM codes for diagnoses\n- Use CPT codes for procedures\n- Confirm clinical necessity based on diagnosis-procedure match\n\nOutput: JSON with keys: icd10_codes, cpt_codes, clinical_necessity, necessity_basis.',
    userTemplate:
        'Patient profile:\n{patient_profile}\n\nRequested treatment:\n{requested_treatment}\n\nIdentify and return medical codes JSON.',
  ),
  AgentPromptData(
    key: 'policy',
    label: 'Policy',
    systemPrompt:
        'You are an insurance policy intelligence AI. Search and retrieve the insurer\'s prior authorization requirements for the specified procedure.\n\nCheck:\n- Whether prior auth is required for the CPT code\n- Step therapy requirements\n- Documentation needed\n- Applicable policy sections\n\nOutput: JSON with keys: auth_required, policy_section, step_therapy, documentation_needed.',
    userTemplate:
        'Insurer: {insurer}\nCPT code: {cpt_code}\nPatient profile: {patient_profile}\n\nRetrieve and return policy requirements JSON.',
  ),
  AgentPromptData(
    key: 'justification',
    label: 'Justification',
    systemPrompt:
        'You are a clinical justification writer AI. Generate a formal prior authorization letter based on the patient\'s medical history, the requested procedure, and the insurer\'s policy requirements.\n\nThe letter must:\n- Be written in formal medical language\n- Cite AMA guidelines and relevant clinical evidence\n- Address all policy requirements\n- Be 700–900 words\n- Conclude with a strong medical necessity argument\n\nTone: Professional, assertive, evidence-based.',
    userTemplate:
        'Patient profile: {patient_profile}\nMedical codes: {medical_codes}\nPolicy requirements: {policy_requirements}\n{custom_context}\n\nGenerate the prior authorization letter.',
  ),
  AgentPromptData(
    key: 'submission',
    label: 'Submission',
    systemPrompt:
        'You are a submission and monitoring AI. Submit the prior authorization request to the insurer portal and monitor the response.\n\nActions:\n- Format the request per insurer specifications\n- Submit via the appropriate channel\n- Poll for response every 30 seconds\n- Return the decision and reference number\n\nOutput: JSON with keys: submitted_at, reference_number, decision, decision_reason.',
    userTemplate:
        'Justification letter: {letter}\nInsurer: {insurer}\nPatient: {patient_name}\nPolicy: {policy_number}\n\nSubmit and return decision JSON.',
  ),
  AgentPromptData(
    key: 'appeal',
    label: 'Appeal',
    systemPrompt:
        'You are a denial and appeal specialist AI. If the authorization was denied, analyze the denial reason, gather counter-evidence, and generate a formal appeal letter.\n\nAppeal levels:\n- Level 1: Internal review — cite clinical guidelines\n- Level 2: Peer-to-peer — request physician attestation\n- Level 3: External review board — cite state mandates\n\nOutput: Appeal letter text and evidence summary.',
    userTemplate:
        'Denial reason: {denial_reason}\nPatient history: {patient_profile}\nClinical evidence: {clinical_evidence}\nAppeal level: {level}\n\nGenerate appeal letter and evidence.',
  ),
  AgentPromptData(
    key: 'claims',
    label: 'Claims',
    systemPrompt:
        'You are a claims validation AI. Validate all CPT and ICD-10 codes for accuracy and calculate the denial risk score.\n\nChecks:\n- Code validity against current code sets\n- Diagnosis-procedure alignment\n- Missing documentation flags\n- Payer-specific code restrictions\n\nOutput: JSON with keys: codes_valid, risk_score (LOW/MEDIUM/HIGH), flags, missing_docs.',
    userTemplate:
        'Medical codes: {medical_codes}\nInsurer: {insurer}\nPatient profile: {patient_profile}\n\nValidate and return risk assessment JSON.',
  ),
];

// ── S06B Prompt Customization ──────────────────────────────────────────────────

class PromptCustomizationScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSkip;
  // UF: onSubmit carries BOTH custom context AND edited agent prompts
  // Caller must PUT each dirty agent before POSTing /authorize
  final void Function(PromptSubmitPayload payload) onSubmit;

  const PromptCustomizationScreen({
    super.key,
    required this.onBack,
    required this.onSkip,
    required this.onSubmit,
  });

  @override
  State<PromptCustomizationScreen> createState() =>
      _PromptCustomizationScreenState();
}

class _PromptCustomizationScreenState
    extends State<PromptCustomizationScreen> {
  final _contextCtrl = TextEditingController();
  bool _agentsExpanded = false;
  int _selectedAgent = 0;
  bool _showWarning = false;

  late List<AgentPromptData> _agents;
  late List<AgentPromptData> _defaults;

  late List<TextEditingController> _sysControllers;
  late List<TextEditingController> _userControllers;

  @override
  void initState() {
    super.initState();
    _defaults = _defaultAgentPrompts
        .map((a) => AgentPromptData(
              key: a.key,
              label: a.label,
              systemPrompt: a.systemPrompt,
              userTemplate: a.userTemplate,
            ))
        .toList();
    _agents = _defaultAgentPrompts
        .map((a) => AgentPromptData(
              key: a.key,
              label: a.label,
              systemPrompt: a.systemPrompt,
              userTemplate: a.userTemplate,
            ))
        .toList();
    _sysControllers =
        _agents.map((a) => TextEditingController(text: a.systemPrompt)).toList();
    _userControllers =
        _agents.map((a) => TextEditingController(text: a.userTemplate)).toList();
  }

  @override
  void dispose() {
    _contextCtrl.dispose();
    for (final c in _sysControllers) c.dispose();
    for (final c in _userControllers) c.dispose();
    super.dispose();
  }

  void _markDirty(int index) {
    setState(() {
      _agents[index] = _agents[index].copyWith(isDirty: true);
      _showWarning = true;
    });
  }

  void _resetAgent(int index) {
    setState(() {
      _sysControllers[index].text = _defaults[index].systemPrompt;
      _userControllers[index].text = _defaults[index].userTemplate;
      _agents[index] = _agents[index].copyWith(
        systemPrompt: _defaults[index].systemPrompt,
        userTemplate: _defaults[index].userTemplate,
        isDirty: false,
      );
      _showWarning = _agents.any((a) => a.isDirty);
    });
  }

  void _resetAll() {
    setState(() {
      for (int i = 0; i < _agents.length; i++) {
        _sysControllers[i].text = _defaults[i].systemPrompt;
        _userControllers[i].text = _defaults[i].userTemplate;
        _agents[i] = _agents[i].copyWith(
          systemPrompt: _defaults[i].systemPrompt,
          userTemplate: _defaults[i].userTemplate,
          isDirty: false,
        );
      }
      _showWarning = false;
    });
  }

  bool get _anyDirty => _agents.any((a) => a.isDirty);
  int get _contextLength => _contextCtrl.text.length;

  // UF: "User tries to submit with an empty system prompt → show warning:
  // 'This prompt is empty — reset to default first.'"
  bool _validateBeforeSubmit() {
    if (!_agentsExpanded) return true; // Agent editor never opened — nothing to validate
    for (int i = 0; i < _agents.length; i++) {
      if (_sysControllers[i].text.trim().isEmpty) {
        // Show error toast and select that agent tab
        setState(() {
          _selectedAgent = i;
        });
        showMediToast(
          context,
          'This prompt is empty — reset to default first.',
          kind: ToastKind.error,
        );
        return false;
      }
    }
    return true;
  }

  void _handleSubmit() {
    if (!_validateBeforeSubmit()) return;

    // Sync controller text back to agent data for dirty agents
    for (int i = 0; i < _agents.length; i++) {
      if (_agents[i].isDirty) {
        _agents[i] = _agents[i].copyWith(
          systemPrompt: _sysControllers[i].text,
          userTemplate: _userControllers[i].text,
        );
      }
    }

    final dirtyAgents = _agents.where((a) => a.isDirty).toList();

    widget.onSubmit(PromptSubmitPayload(
      customContext: _contextCtrl.text.trim(),
      editedAgents: dirtyAgents,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        backgroundColor: C.surf0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onBack, // UF: Back → returns to Screen 6
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customize AI Prompts',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: C.textPrimary),
            ),
            // UF subtitle: "Optional — The AI works great without changes"
            Text(
              'Optional — The AI works great without changes',
              style: GoogleFonts.inter(
                  fontSize: 11, color: C.textTertiary),
            ),
          ],
        ),
        // UF: Skip button always visible top-right
        actions: [
          TextButton(
            onPressed: widget.onSkip, // UF: Skip → goes to Screen 7
            child: Text(
              'Skip →',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: C.teal600),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Warning banner (shown when any prompt edited) ──────────
                  if (_showWarning) ...[
                    InfoBanner(
                      message:
                          'Editing agent prompts may affect AI quality. Reset to defaults if unsure.',
                      bgColor: const Color(0xFFFFF8E1),
                      borderColor: C.amber500,
                      textColor: C.amber700,
                      icon: Icons.warning_amber_rounded,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Section 1: Quick Context ─────────────────────────────
                  // UF: Always visible and prominent — main use case
                  _SectionHeader(
                    icon: Icons.edit_note_rounded,
                    label: 'Add Extra Context for the AI',
                    badge: 'Recommended',
                    badgeColor: C.teal500,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: C.surf0,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: C.surf3, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _contextCtrl,
                          maxLines: 5,
                          minLines: 5,
                          maxLength: 1000,
                          buildCounter: (_,
                                  {required currentLength,
                                  required isFocused,
                                  maxLength}) =>
                              null,
                          decoration: InputDecoration(
                            hintText:
                                'Add anything extra the AI should know before it writes your authorization letter.',
                            hintStyle: GoogleFonts.inter(
                                fontSize: 14, color: C.textTertiary),
                            border: InputBorder.none,
                            filled: false,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: C.textPrimary,
                              height: 1.5),
                          onChanged: (_) => setState(() {}),
                        ),
                        Container(height: 0.5, color: C.surf3),
                        // UF: Live counter "0 / 1000"
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$_contextLength / 1000',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: _contextLength > 900
                                        ? C.red500
                                        : C.textTertiary,
                                    fontWeight: FontWeight.w500),
                              ),
                              if (_contextLength > 0)
                                GestureDetector(
                                  onTap: () {
                                    _contextCtrl.clear();
                                    setState(() {});
                                  },
                                  child: Text('Clear',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: C.textTertiary,
                                          decoration:
                                              TextDecoration.underline)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // UF example hints
                  _ExampleHint(
                      "The insurer previously denied this — stress my 9-month treatment history"),
                  _ExampleHint('My doctor considers this medically urgent'),
                  _ExampleHint(
                      'Include my failed attempts with Metformin at higher doses'),
                  const SizedBox(height: 24),

                  // ── Section 2: Agent Prompt Editor ────────────────────────
                  // UF: COLLAPSED by default — only for advanced users
                  _SectionHeader(
                    icon: Icons.smart_toy_outlined,
                    label: 'Advanced — Edit Individual Agent Prompts',
                    badge: 'Advanced',
                    badgeColor: C.violet500,
                  ),
                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: () =>
                        setState(() => _agentsExpanded = !_agentsExpanded),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: C.surf0,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: C.surf3, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _agentsExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_right_rounded,
                            color: C.violet500,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _agentsExpanded
                                ? 'Hide Agent Prompts'
                                : '▶  Show Agent Prompts',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: C.violet500),
                          ),
                          const Spacer(),
                          if (_anyDirty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: C.amber50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: C.amber500.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                '${_agents.where((a) => a.isDirty).length} edited',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: C.amber700),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  if (_agentsExpanded) ...[
                    const SizedBox(height: 12),
                    // UF: Horizontally scrollable tab bar for 7 agents (mobile)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _agents.asMap().entries.map((entry) {
                          final i = entry.key;
                          final agent = entry.value;
                          final isSelected = i == _selectedAgent;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedAgent = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? C.violet500 : C.surf0,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: isSelected ? C.violet500 : C.surf3,
                                    width: 0.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(agent.label,
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? C.white
                                              : C.textSecondary)),
                                  // UF: dot/asterisk on tabs with unsaved edits
                                  if (agent.isDirty) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? C.white
                                            : C.amber500,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _AgentEditorPane(
                      agent: _agents[_selectedAgent],
                      sysController: _sysControllers[_selectedAgent],
                      userController: _userControllers[_selectedAgent],
                      onSysChanged: (_) => _markDirty(_selectedAgent),
                      onUserChanged: (_) => _markDirty(_selectedAgent),
                      onReset: () => _resetAgent(_selectedAgent),
                    ),
                    const SizedBox(height: 10),

                    if (_anyDirty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _resetAll,
                          icon: const Icon(Icons.refresh_rounded,
                              size: 15, color: C.textTertiary),
                          label: Text('Reset all to defaults',
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: C.textTertiary)),
                        ),
                      ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // ── Sticky bottom action bar ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            decoration: const BoxDecoration(
              color: C.surf0,
              border: Border(top: BorderSide(color: C.surf3, width: 0.5)),
            ),
            child: Column(
              children: [
                // UF: PRIMARY "Submit with These Prompts →"
                PrimaryButton(
                  label: 'Submit with These Prompts →',
                  icon: Icons.send_rounded,
                  onPressed: _handleSubmit,
                ),
                const SizedBox(height: 10),
                // UF: SECONDARY "Discard changes and use default prompts"
                GestureDetector(
                  onTap: widget.onSkip,
                  child: Text(
                    'Discard changes and use default prompts',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: C.textTertiary,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Agent editor pane ──────────────────────────────────────────────────────────

class _AgentEditorPane extends StatelessWidget {
  final AgentPromptData agent;
  final TextEditingController sysController;
  final TextEditingController userController;
  final ValueChanged<String> onSysChanged;
  final ValueChanged<String> onUserChanged;
  final VoidCallback onReset;

  const _AgentEditorPane({
    required this.agent,
    required this.sysController,
    required this.userController,
    required this.onSysChanged,
    required this.onUserChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: C.textPrimary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Text('SYSTEM PROMPT',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: C.surf300,
                        letterSpacing: 1.0)),
                const Spacer(),
                GestureDetector(
                  onTap: onReset,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded,
                          size: 13, color: C.teal400),
                      const SizedBox(width: 3),
                      Text('Reset ↺',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: C.teal400)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // UF: Edited prompt fields use light yellow background (#FFFDE7)
          Container(
            color: agent.isDirty
                ? const Color(0xFF1A1A00)
                : Colors.transparent,
            child: TextField(
              controller: sysController,
              maxLines: null,
              minLines: 5,
              style: GoogleFonts.robotoMono(
                  fontSize: 12, color: C.teal400, height: 1.5),
              decoration: InputDecoration(
                border: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.all(16),
                hintText: 'Enter system prompt...',
                hintStyle:
                    GoogleFonts.robotoMono(fontSize: 12, color: C.ink400),
              ),
              onChanged: onSysChanged,
            ),
          ),
          Container(
              height: 0.5, color: C.surf3.withValues(alpha: 0.3)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('USER TEMPLATE',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: C.surf300,
                      letterSpacing: 1.0)),
            ),
          ),
          Container(
            color: agent.isDirty
                ? const Color(0xFF1A1A00)
                : Colors.transparent,
            child: TextField(
              controller: userController,
              maxLines: null,
              minLines: 3,
              style: GoogleFonts.robotoMono(
                  fontSize: 12, color: C.surf200, height: 1.5),
              decoration: InputDecoration(
                border: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.all(16),
                hintText: 'Enter user template with {variables}...',
                hintStyle:
                    GoogleFonts.robotoMono(fontSize: 12, color: C.ink400),
              ),
              onChanged: onUserChanged,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final String badge;
  final Color badgeColor;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.badge,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: badgeColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: C.textPrimary)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: badgeColor.withValues(alpha: 0.3), width: 0.5),
          ),
          child: Text(badge,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: badgeColor)),
        ),
      ],
    );
  }
}

// ── Example hint ──────────────────────────────────────────────────────────────

class _ExampleHint extends StatelessWidget {
  final String text;
  const _ExampleHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: C.textTertiary,
                  fontStyle: FontStyle.italic)),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: C.textTertiary,
                    fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }
}