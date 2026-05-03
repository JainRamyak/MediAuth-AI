import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../api/api_service.dart';
import '../widgets/shared_widgets.dart';

// ── Agent metadata ────────────────────────────────────────────────────────────

const _agentMeta = {
  'intake':           (1, 'Intake & History Agent',       'Reads and structures patient input'),
  'medical_analysis': (2, 'Medical Analysis Agent',       'Assigns ICD-10 & CPT codes'),
  'policy':           (3, 'Policy Intelligence Agent',    'Checks insurer coverage rules'),
  'justification':    (4, 'Justification Writer',         'Writes the authorization letter'),
  'submission':       (5, 'Submission Agent',             'Submits claim and monitors response'),
  'appeal':           (6, 'Denial & Appeal Agent',        'Writes and files appeals automatically'),
  'claims':           (7, 'Claims Validation Agent',      'Validates billing codes for accuracy'),
};

const _agentOrder = [
  'intake', 'medical_analysis', 'policy',
  'justification', 'submission', 'appeal', 'claims',
];

// ── Screen 12 — AI Agents Dashboard ─────────────────────────────────────────

class AgentListScreen extends StatefulWidget {
  final void Function(String agentKey) onAgentTap;

  const AgentListScreen({super.key, required this.onAgentTap});

  @override
  State<AgentListScreen> createState() => _AgentListScreenState();
}

class _AgentListScreenState extends State<AgentListScreen> {
  bool _loading = true;
  String? _error;
  // agentKey → {system, user_template}
  final _prompts = <String, Map<String, String>>{};
  bool _backendUp = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Check backend health first
      await ApiService.healthCheck();
      _backendUp = true;

      // Load all prompts
      final agents = await ApiService.fetchPromptsList();
      for (final a in agents) {
        try {
          _prompts[a] = await ApiService.fetchPrompt(a);
        } catch (_) {}
      }
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Could not connect to backend. Is the server running?';
        _loading = false;
        _backendUp = false;
      });
    }
  }

  int _charCount(String key) {
    final p = _prompts[key];
    if (p == null) return 0;
    return (p['system']?.length ?? 0) + (p['user_template']?.length ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        backgroundColor: C.surf0,
        surfaceTintColor: Colors.transparent,
        title: Text('🤖  AI Agents',
          style: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700, color: C.textPrimary)),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: C.teal500,
        child: CustomScrollView(
          slivers: [
            // ── System health strip ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: _backendUp ? C.teal50 : C.amber50,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: _backendUp ? C.green500 : C.amber500,
                      shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _backendUp
                        ? '${_agentOrder.length}/${_agentOrder.length} Agents Live  ·  System: Operational'
                        : 'Backend offline — showing cached data',
                    style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w500,
                      color: _backendUp ? C.teal700 : C.amber700)),
                ]),
              ),
            ),

            // ── Subtitle ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Text(
                  'Every agent working on your behalf — visible, inspectable, and customizable.',
                  style: GoogleFonts.inter(fontSize: 13, color: C.textSecondary)),
              ),
            ),

            // ── Error ─────────────────────────────────────────────────────
            if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: InfoBanner(
                    message: _error!,
                    icon: Icons.wifi_off_rounded,
                    bgColor: C.amber50,
                    accentColor: C.amber500,
                    textColor: C.amber700,
                  ),
                ),
              ),

            // ── Agent cards ───────────────────────────────────────────────
            if (_loading)
              SliverList(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  return FadeSlide(
                    delay: Duration(milliseconds: i * 100),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: const SkeletonShimmer(width: double.infinity, height: 130, borderRadius: 14),
                    ),
                  );
                }, childCount: 5),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  final key = _agentOrder[i];
                  final meta = _agentMeta[key];
                  if (meta == null) return const SizedBox.shrink();
                  return FadeSlide(
                    delay: Duration(milliseconds: i * 100),
                    child: _AgentCard(
                      index: meta.$1,
                      displayName: meta.$2,
                      subtitle: meta.$3,
                      agentKey: key,
                      charCount: _charCount(key),
                      hasPrompt: _prompts.containsKey(key),
                      onTap: () => widget.onAgentTap(key),
                    ),
                  );
                }, childCount: _agentOrder.length),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ── Agent Card ────────────────────────────────────────────────────────────────

class _AgentCard extends StatelessWidget {
  final int index;
  final String displayName;
  final String subtitle;
  final String agentKey;
  final int charCount;
  final bool hasPrompt;
  final VoidCallback onTap;

  const _AgentCard({
    required this.index,
    required this.displayName,
    required this.subtitle,
    required this.agentKey,
    required this.charCount,
    required this.hasPrompt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: C.surf0,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: C.surf3, width: 0.5),
            ),
            child: Column(
              children: [
                // Top row
                Row(children: [
                  // Numbered circle
                  Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(
                      color: C.teal50, shape: BoxShape.circle),
                    child: Center(
                      child: Text('$index',
                        style: GoogleFonts.inter(
                          fontSize: 18, fontWeight: FontWeight.w800,
                          color: C.teal600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName,
                          style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: C.textPrimary)),
                        Text('System + User template',
                          style: GoogleFonts.inter(
                            fontSize: 12, color: C.textTertiary)),
                      ],
                    ),
                  ),
                  // ● Live pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: C.teal500, width: 0.8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C853), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text('Live',
                        style: GoogleFonts.inter(
                          fontSize: 11, color: C.teal600,
                          fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                // Bottom row
                Row(children: [
                  Text('Ʈr',
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700, color: C.teal500)),
                  const SizedBox(width: 4),
                  Text(charCount > 0 ? '$charCount chars' : 'No data',
                    style: GoogleFonts.inter(fontSize: 12, color: C.teal600)),
                  const SizedBox(width: 16),
                  Icon(Icons.check_circle_outline_rounded,
                    size: 13, color: hasPrompt ? C.green500 : C.textTertiary),
                  const SizedBox(width: 4),
                  Text(subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11, color: C.textTertiary),
                    overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Text('Edit →',
                    style: GoogleFonts.inter(
                      fontSize: 13, color: C.teal500,
                      fontWeight: FontWeight.w700)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
