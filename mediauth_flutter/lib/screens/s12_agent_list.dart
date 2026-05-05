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
      if (mounted) {
        setState(() {
        _error = 'Could not connect to backend. Is the server running?';
        _loading = false;
        _backendUp = false;
      });
      }
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('AI Agents Dashboard',
          style: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w800, color: C.primary600)),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: C.primary500,
        child: CustomScrollView(
          slivers: [
            // ── System health strip ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: _backendUp ? C.primary100 : C.amber50,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: _backendUp ? C.primary500 : C.amber500,
                      shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _backendUp
                        ? '${_agentOrder.length}/${_agentOrder.length} Agents Live  ·  System Operational'
                        : 'Backend offline — showing cached data',
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: _backendUp ? C.primary700 : C.amber700)),
                ]),
              ),
            ),

            // ── Subtitle ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Text(
                  'Every agent working on your behalf — visible, inspectable, and customizable.',
                  style: GoogleFonts.inter(fontSize: 14, color: C.textSecondary, height: 1.5)),
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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: const SkeletonShimmer(width: double.infinity, height: 130, borderRadius: 24),
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

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: C.surf3.withValues(alpha: 0.5), width: 1.0),
              ),
              child: Column(
                children: [
                  // Top row
                  Row(children: [
                    // Numbered circle
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: C.primary100, shape: BoxShape.circle),
                      child: Center(
                        child: Text('$index',
                          style: GoogleFonts.inter(
                            fontSize: 20, fontWeight: FontWeight.w800,
                            color: C.primary600)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName,
                            style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w800,
                              color: C.textPrimary)),
                          const SizedBox(height: 2),
                          Text('System + User template',
                            style: GoogleFonts.inter(
                              fontSize: 13, color: C.textTertiary, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    // ● Live pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: C.primary100.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00C853), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text('Live',
                          style: GoogleFonts.inter(
                            fontSize: 11, color: C.primary700,
                            fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  // Bottom row
                  Row(children: [
                    const Icon(Icons.description_outlined, size: 14, color: C.primary500),
                    const SizedBox(width: 6),
                    Text(charCount > 0 ? '$charCount chars' : 'No data',
                      style: GoogleFonts.inter(fontSize: 12, color: C.primary700, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 16),
                    Icon(Icons.check_circle_outline_rounded,
                      size: 14, color: hasPrompt ? C.primary500 : C.textTertiary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12, color: C.textTertiary, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text('Edit →',
                      style: GoogleFonts.inter(
                        fontSize: 13, color: C.primary600,
                        fontWeight: FontWeight.w800)),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

