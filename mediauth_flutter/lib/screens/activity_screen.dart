import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';
import 's03_dashboard.dart';

// ── Activity Screen ───────────────────────────────────────────────────────────

class ActivityScreen extends StatefulWidget {
  final void Function(AuthRequest) onRequestTap;
  const ActivityScreen({super.key, required this.onRequestTap});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  AuthStatus? _filter;
  bool _searchVisible = false;
  String _query = '';
  final _searchCtl = TextEditingController();

  static final _all = [...mockRequests].reversed.toList();

  List<AuthRequest> get _filtered {
    var items = _filter == null
      ? _all
      : _all.where((r) => r.status == _filter).toList();
    if (_query.isNotEmpty) {
      items = items.where((r) =>
        r.providerName.toLowerCase().contains(_query.toLowerCase()) ||
        r.treatment.toLowerCase().contains(_query.toLowerCase())).toList();
    }
    return items;
  }

  // Group by date bucket
  Map<String, List<AuthRequest>> get _grouped {
    final now = DateTime.now();
    final map = <String, List<AuthRequest>>{};
    for (final r in _filtered) {
      final diff = now.difference(r.timestamp);
      String key;
      if (diff.inHours < 24) { key = 'Today'; }
      else if (diff.inDays < 2) { key = 'Yesterday'; }
      else if (diff.inDays < 7) { key = 'This Week'; }
      else { key = DateFormat.yMMM().format(r.timestamp); }
      map.putIfAbsent(key, () => []).add(r);
    }
    return map;
  }

  @override
  void dispose() { _searchCtl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        title: Text('Activity',
          style: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700,
            color: C.textPrimary)),
        actions: [
          IconButton(
            icon: Icon(
              _searchVisible ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _searchVisible = !_searchVisible;
                if (!_searchVisible) {
                  _query = '';
                  _searchCtl.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar ────────────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            child: _searchVisible
              ? Container(
                  color: C.surf0,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: _searchCtl,
                    autofocus: true,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search by provider or treatment…',
                      prefixIcon: const Icon(
                        Icons.search_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          ),

          // ── Sticky filter pills ───────────────────────────────────────────
          Container(
            color: C.surf0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _FilterPill(null, 'All', _filter,
                    (v) => setState(() => _filter = v)),
                  const SizedBox(width: 6),
                  ...AuthStatus.values.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _FilterPill(s, _statusLabel(s), _filter,
                      (v) => setState(() => _filter = v)),
                  )),
                ],
              ),
            ),
          ),
          Container(height: 0.5, color: C.surf3),

          // ── Timeline list ─────────────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
              ? EmptyStateView(
                  icon: Icons.inbox_outlined,
                  title: 'No matching requests',
                  subtitle: 'Try adjusting your filter or search.',
                  actionLabel: 'Clear Filter',
                  onAction: () => setState(() {
                    _filter = null;
                    _query = '';
                    _searchCtl.clear();
                  }),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    for (final entry in grouped.entries) ...[
                      // Date section header
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          Text(entry.key,
                            style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: C.textTertiary,
                              letterSpacing: 0.5)),
                          const SizedBox(width: 8),
                          Expanded(child: Container(height: 0.5, color: C.surf3)),
                          const SizedBox(width: 8),
                          Text('${entry.value.length}',
                            style: GoogleFonts.inter(
                              fontSize: 11, color: C.textTertiary)),
                        ]),
                      ),
                      // Items in this group
                      ...entry.value.asMap().entries.map((e) {
                        final i = e.key;
                        final req = e.value;
                        final isLast = i == entry.value.length - 1;
                        return Stack(
                          children: [
                            if (!isLast)
                              Positioned(
                                left: 19,
                                top: 48,
                                bottom: -4,
                                child: Container(
                                  width: 1.5, color: C.surf3),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _HistoryTile(
                                request: req,
                                onTap: () => widget.onRequestTap(req),
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(AuthStatus s) => switch (s) {
  AuthStatus.approved  => 'Approved',
  AuthStatus.pending   => 'Pending',
  AuthStatus.denied    => 'Denied',
  AuthStatus.appealing => 'Appealing',
  AuthStatus.submitted => 'Submitted',
};

// ── Inline filter pill ────────────────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  final AuthStatus? value;
  final String label;
  final AuthStatus? current;
  final ValueChanged<AuthStatus?> onTap;

  const _FilterPill(this.value, this.label, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? C.teal500 : C.surf1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? C.teal500 : C.surf3, width: 1),
        ),
        child: Text(label,
          style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: selected ? C.white : C.textSecondary)),
      ),
    );
  }
}

// ── History Tile ──────────────────────────────────────────────────────────────

class _HistoryTile extends StatefulWidget {
  final AuthRequest request;
  final VoidCallback onTap;
  const _HistoryTile({required this.request, required this.onTap});

  @override
  State<_HistoryTile> createState() => _HistoryTileState();
}

class _HistoryTileState extends State<_HistoryTile> {
  bool _expanded = false;

  Color get _nodeColor => switch (widget.request.status) {
    AuthStatus.approved  => C.green500,
    AuthStatus.pending   => C.amber500,
    AuthStatus.denied    => C.red500,
    AuthStatus.appealing => C.violet500,
    AuthStatus.submitted => C.blue500,
  };
  Color get _nodeBg => switch (widget.request.status) {
    AuthStatus.approved  => C.green50,
    AuthStatus.pending   => C.amber50,
    AuthStatus.denied    => C.red50,
    AuthStatus.appealing => C.violet50,
    AuthStatus.submitted => C.blue50,
  };
  IconData get _nodeIcon => switch (widget.request.status) {
    AuthStatus.approved  => Icons.check_circle_outline_rounded,
    AuthStatus.pending   => Icons.hourglass_empty_rounded,
    AuthStatus.denied    => Icons.cancel_outlined,
    AuthStatus.appealing => Icons.gavel_rounded,
    AuthStatus.submitted => Icons.send_outlined,
  };

  String _elapsed(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24)  return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline node
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: _nodeBg, shape: BoxShape.circle,
            border: Border.all(color: _nodeColor.withValues(alpha: 0.4))),
          child: Icon(_nodeIcon, size: 17, color: _nodeColor),
        ),
        const SizedBox(width: 14),

        // Card
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _expanded = !_expanded);
              widget.onTap();
            },
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: C.surf0,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: C.surf3, width: 0.5)),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(widget.request.providerName,
                          style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: C.textPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text(_elapsed(widget.request.timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 11, color: C.textTertiary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(widget.request.treatment,
                    style: GoogleFonts.inter(
                      fontSize: 13, color: C.textSecondary),
                    maxLines: _expanded ? null : 2,
                    overflow: _expanded ? null : TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Row(children: [
                    StatusPill(widget.request.status),
                    const Spacer(),
                    Text(widget.request.id,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10, color: C.textTertiary)),
                  ]),
                  // Expanded detail
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    child: _expanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: C.surf1,
                              borderRadius: BorderRadius.circular(8)),
                            child: Row(children: [
                              const Icon(Icons.business_outlined,
                                size: 13, color: C.textTertiary),
                              const SizedBox(width: 7),
                              Text(widget.request.insurer,
                                style: GoogleFonts.inter(
                                  fontSize: 12, color: C.textSecondary)),
                            ]),
                          ),
                        )
                      : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(
                width: 2.5,
                decoration: BoxDecoration(
                  color: _nodeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ],
);
  }
}
