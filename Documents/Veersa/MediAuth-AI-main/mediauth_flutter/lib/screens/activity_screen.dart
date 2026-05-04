import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';
import '../api/api_service.dart';

// ── Activity (History) Screen ─────────────────────────────────────────────────
// Primary data source: GET /api/v1/authorize (real database)
// Fallback: SharedPreferences cache (if backend is offline)

class ActivityScreen extends StatefulWidget {
  final void Function(Map<String, dynamic> result) onRequestTap;
  const ActivityScreen({super.key, required this.onRequestTap});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;
  bool _fromCache = false;
  bool _backendReachable = true;
  String _filter = 'All';
  final _searchCtrl = TextEditingController();

  static const _filters = ['All', 'Approved', 'Denied', 'Appealing', 'Pending'];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _fromCache = false; _backendReachable = true; });

    // ── Try backend first ────────────────────────────────────────────────────
    try {
      final items = await ApiService.fetchHistory(limit: 50);
      // Normalize field names from backend response to match what the result screens expect
      final normalized = items.map((r) => _normalizeBackendItem(r)).toList();
      if (mounted) setState(() { _all = normalized; _loading = false; });
      return;
    } on ApiException catch (e) {
      // 405 = endpoint not deployed yet (older HF Space build)
      // Other statuses = backend reachable but erroring
      _backendReachable = e.statusCode != null; // null = network/timeout
    } catch (_) {
      _backendReachable = false;
    }

    // ── Fallback: SharedPreferences cache ────────────────────────────────────
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('auth_history') ?? [];
      final items = raw.map((s) {
        try { return jsonDecode(s) as Map<String, dynamic>; } catch (_) { return null; }
      }).whereType<Map<String, dynamic>>().toList();
      if (mounted) setState(() { _all = items; _loading = false; _fromCache = true; });
    } catch (_) {
      if (mounted) setState(() { _all = []; _loading = false; _fromCache = true; });
    }
  }

  /// Normalize the backend's snake_case response into the format expected by UI.
  Map<String, dynamic> _normalizeBackendItem(Map<String, dynamic> r) {
    return {
      'auth_request_id':     r['auth_request_id'],
      'workflow_status':     r['workflow_status'],
      'appeal_level':        r['appeal_level'],
      'justification_letter': r['justification_letter'],
      'denial_reason':       r['denial_reason'],
      'created_at':          r['created_at'],
      // Patient fields joined from DB
      'insurer':             r['insurer'],
      'policy_number':       r['policy_number'],
      'patient_name':        r['patient_name'],
      // Treatment field isn't stored in DB yet — use a descriptive fallback
      'requested_treatment': _treatmentLabel(r),
    };
  }

  String _treatmentLabel(Map<String, dynamic> r) {
    final status = (r['workflow_status'] ?? '').toString();
    final patient = (r['patient_name'] ?? '').toString();
    if (patient.isNotEmpty) return 'Authorization — $patient';
    return 'Authorization Request ($status)';
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _all;
    if (_filter != 'All') {
      list = list.where((r) =>
          (r['workflow_status'] ?? '').toString().toLowerCase() ==
          _filter.toLowerCase()).toList();
    }
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((r) {
        final t = (r['requested_treatment'] ?? '').toString().toLowerCase();
        final i = (r['insurer']          ?? '').toString().toLowerCase();
        final n = (r['patient_name']     ?? '').toString().toLowerCase();
        return t.contains(q) || i.contains(q) || n.contains(q);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        backgroundColor: C.navy800,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Activity History',
          style: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: C.navy800,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by patient, insurer or treatment…',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: C.textTertiary),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: C.textTertiary),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
                filled: true, fillColor: Colors.white.withValues(alpha: 0.10),
                isDense: true,
              ),
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: C.teal500,
        child: CustomScrollView(
          slivers: [


            // ── Filter chips ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _filters.map((f) {
                      final active = _filter == f;
                      return GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: active ? C.teal500 : C.surf2,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: active ? C.teal500 : C.surf3, width: 0.5)),
                          child: Text(f,
                            style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: active ? Colors.white : C.textSecondary)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // ── Content ────────────────────────────────────────────────────
            if (_loading)
              SliverList(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  return FadeSlide(
                    delay: Duration(milliseconds: i * 100),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: const SkeletonShimmer(width: double.infinity, height: 110, borderRadius: 14),
                    ),
                  );
                }, childCount: 4),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(child: _EmptyHistory())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  final r = filtered[i];
                  return FadeSlide(
                    delay: Duration(milliseconds: i * 100),
                    child: _HistoryCard(data: r, onTap: () => widget.onRequestTap(r))
                  );
                }, childCount: filtered.length),
              ),

            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
            ),
          ],
        ),
      ),
    );
  }
}

// ── History Card ──────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  const _HistoryCard({required this.data, required this.onTap});

  AuthStatus get _authStatus {
    final s = (data['workflow_status'] ?? '').toString().toLowerCase();
    if (s.contains('approved'))                      return AuthStatus.approved;
    if (s.contains('denied'))                        return AuthStatus.denied;
    if (s.contains('appeal') || s.contains('escalat')) return AuthStatus.appealing;
    if (s.contains('submit'))                        return AuthStatus.submitted;
    return AuthStatus.pending;
  }

  @override
  Widget build(BuildContext context) {
    final treatment = data['requested_treatment']?.toString() ?? 'Authorization Request';
    final insurer   = data['insurer']?.toString() ?? '';
    final policy    = data['policy_number']?.toString() ?? '';
    final rawId     = data['auth_request_id']?.toString() ?? '';
    final shortId   = rawId.length > 8 ? rawId.substring(0, 8).toUpperCase() : rawId.toUpperCase();
    final dateRaw   = data['created_at']?.toString() ?? '';
    final date      = DateTime.tryParse(dateRaw) ?? DateTime.now();
    final dateStr   = '${date.day.toString().padLeft(2,'0')}/'
                      '${date.month.toString().padLeft(2,'0')}/'
                      '${date.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: C.surf0,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: C.surf3, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(treatment,
                  style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600, color: C.textPrimary),
                  maxLines: 2, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              StatusPill(_authStatus),
            ]),
            const SizedBox(height: 6),
            Text(
              [insurer, if (policy.isNotEmpty) 'Policy $policy']
                  .where((e) => e.isNotEmpty).join('  ·  '),
              style: GoogleFonts.inter(fontSize: 12, color: C.textSecondary)),
            const SizedBox(height: 8),
            Row(children: [
              if (shortId.isNotEmpty) ...[
                Text('ID $shortId',
                  style: GoogleFonts.jetBrainsMono(fontSize: 11, color: C.textTertiary)),
                const SizedBox(width: 12),
              ],
              Text(dateStr,
                style: GoogleFonts.inter(fontSize: 11, color: C.textTertiary)),
              const Spacer(),
              Text('View →',
                style: GoogleFonts.inter(
                  fontSize: 12, color: C.teal600, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── Empty ─────────────────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(color: C.surf2, shape: BoxShape.circle),
          child: const Icon(Icons.history_rounded, size: 40, color: C.textTertiary),
        ),
        const SizedBox(height: 20),
        Text('No history yet',
          style: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700, color: C.textPrimary)),
        const SizedBox(height: 8),
        Text('Submitted authorization requests will appear here.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: C.textSecondary)),
      ]),
    ),
  );
}
