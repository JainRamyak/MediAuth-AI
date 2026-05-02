import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../api/api_service.dart';
import 's13_prompt_editor.dart';
import 's14_prompt_test.dart';

// ── Agent definitions for the list ───────────────────────────────────────────

const _agentList = [
  (
    1,
    'Intake & History Agent',
    'System + User template',
    '2,340',
    '3 days ago',
  ),
  (
    2,
    'Medical Analysis Agent',
    'System + User template',
    '1,870',
    '1 day ago',
  ),
  (
    3,
    'Policy Intelligence Agent',
    'System + User template',
    '4,120',
    '5 hours ago',
  ),
  (
    4,
    'Justification Writer',
    'System + User template',
    '6,450',
    '2 hours ago',
  ),
  (
    5,
    'Submission & Monitor',
    'System + User template',
    '1,230',
    '12 hours ago',
  ),
  (
    6,
    'Denial & Appeal Agent',
    'System + User template',
    '8,910',
    '30 mins ago',
  ),
  (
    7,
    'Claims Validation Agent',
    'System + User template',
    '2,670',
    '4 hours ago',
  ),
];

// ── S12 Agent List ─────────────────────────────────────────────────────────────

class AgentListScreen extends StatefulWidget {
  const AgentListScreen({super.key});

  @override
  State<AgentListScreen> createState() => _AgentListScreenState();
}

class _AgentListScreenState extends State<AgentListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        title: const Text('Prompt Inspector'),
      ),
      body: Column(
        children: [
          // Judge-facing banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: C.surf3, width: 0.5)),
            ),
            child: Text(
              'Every agent\'s logic is visible and editable here. No code required.',
              style: GoogleFonts.inter(
                fontSize: 13, color: C.textSecondary),
            ),
          ),
          // Agent cards
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: _agentList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final a = _agentList[i];
                return _AgentCard(
                  number: a.$1,
                  name: a.$2,
                  templateType: a.$3,
                  charCount: a.$4,
                  lastEdited: a.$5,
                  onTap: () => _openEditor(context, a.$1, a.$2),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Maps agent card number → backend agent key used by GET/PUT /api/v1/prompts/{key}
  static const _agentKeys = {
    1: 'intake',
    2: 'medical_analysis',
    3: 'policy',
    4: 'justification',
    5: 'submission',
    6: 'appeal',
    7: 'claims',
  };

  Future<void> _openEditor(BuildContext context, int num, String name) async {
    final agentKey = _agentKeys[num] ?? 'intake';

    // Show loading while fetching prompt from backend
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: C.teal500),
      ),
    );

    Map<String, String> promptData;
    try {
      promptData = await ApiService.fetchPrompt(agentKey);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load prompt: $e'),
          backgroundColor: C.red500,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    Navigator.of(context).pop(); // dismiss loading

    final agent = AgentPrompt(
      name: name,
      agentKey: agentKey,
      systemPrompt: promptData['system'] ?? '',
      userTemplate: promptData['user_template'] ?? '',
    );

    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx2) => PromptEditorScreen(
        agent: agent,
        onBack: () => Navigator.pop(ctx2),
        onTest: (ag) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (ctx3) => PromptTestScreen(
              agent: ag,
              onBack: () => Navigator.pop(ctx3),
              onEdit: () => Navigator.pop(ctx3),
            ),
          ));
        },
      ),
    ));
  }
}

// ── Agent Card ────────────────────────────────────────────────────────────────

class _AgentCard extends StatelessWidget {
  final int number;
  final String name, templateType, charCount, lastEdited;
  final VoidCallback onTap;

  const _AgentCard({
    required this.number, required this.name,
    required this.templateType, required this.charCount,
    required this.lastEdited, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: C.surf0,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.surf3, width: 0.5),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [
              // Agent number circle
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: C.teal50,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$number',
                    style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: C.teal700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                      style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: C.textPrimary)),
                    const SizedBox(height: 2),
                    Text(templateType,
                      style: GoogleFonts.inter(
                        fontSize: 12, color: C.textTertiary)),
                  ],
                ),
              ),
              // Live badge with pulsing dot
              _LiveBadge(),
            ]),
            const SizedBox(height: 10),
            const Divider(height: 0.5),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.text_fields_rounded,
                size: 13, color: C.textTertiary),
              const SizedBox(width: 4),
              Text('$charCount chars',
                style: GoogleFonts.inter(
                  fontSize: 12, color: C.textSecondary,
                  fontWeight: FontWeight.w500)),
              const SizedBox(width: 14),
              const Icon(Icons.access_time_rounded,
                size: 13, color: C.textTertiary),
              const SizedBox(width: 4),
              Text('Edited $lastEdited',
                style: GoogleFonts.inter(
                  fontSize: 12, color: C.textTertiary)),
              const Spacer(),
              Text('Edit →',
                style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: C.teal600)),
            ]),
        ]),
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
    _fade = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
    _ctrl.forward().then((_) => _ctrl.reverse());
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: C.green50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: C.green500, width: 0.5),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(
        animation: _fade,
        builder: (_, __) => Opacity(
          opacity: _fade.value,
          child: Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: C.green500),
          ),
        ),
      ),
      const SizedBox(width: 5),
      Text('Live',
        style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: C.green700)),
    ]),
  );
}
