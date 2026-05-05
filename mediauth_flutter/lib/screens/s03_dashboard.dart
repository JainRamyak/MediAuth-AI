// ─────────────────────────────────────────────────────────────────────────────
// dashboard_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../api/api_service.dart';
import '../auth/auth_service.dart';

// ─── MODEL ────────────────────────────────────────────────────────────────────

class AuthRequest {
  final String id;
  final String treatment;
  final String insurer;
  final String policyNumber;
  final String status;
  final DateTime date;
  final Map<String, dynamic> raw;

  const AuthRequest({
    required this.id,
    required this.treatment,
    required this.insurer,
    required this.policyNumber,
    required this.status,
    required this.date,
    required this.raw,
  });

  factory AuthRequest.fromMap(Map<String, dynamic> m) => AuthRequest(
    id:           m['auth_request_id'] ?? m['id'] ?? '',
    treatment:    m['requested_treatment'] ?? m['treatment'] ?? 'Treatment',
    insurer:      m['insurer'] ?? 'Insurer',
    policyNumber: m['policy_number'] ?? '',
    status:       (m['workflow_status'] ?? m['status'] ?? 'pending').toString().toLowerCase(),
    date:         DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now(),
    raw:          m,
  );
}

// ─── DASHBOARD ───────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNewRequest;
  final void Function(Map<String, dynamic>) onRequestTap;
  final VoidCallback onProfileTap;

  const DashboardScreen({
    super.key,
    required this.onNewRequest,
    required this.onRequestTap,
    required this.onProfileTap,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<AuthRequest> _all = [];
  String _filter = 'All';
  bool _loading = true;

  static const _filters = ['All', 'Approved', 'Pending', 'Denied'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final items = await ApiService.fetchHistory(limit: 50);
      final reqs = items.map((m) => AuthRequest.fromMap(m)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      if (!mounted) return;
      setState(() { _all = reqs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  int _count(String status) => _all.where((r) => r.status == status.toLowerCase()).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surf1,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildStatsCard(),
                  const SizedBox(height: 32),
                  _buildActivityStream(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final user = AuthService.instance.currentUser;
    final name = user?.fullName?.split(' ').first ?? 'there';
    
    return Container(
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 40),
      decoration: const BoxDecoration(
        color: C.primary500,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, $name!',
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Your MediAuth dashboard is here.',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: widget.onProfileTap,
            child: Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(color: C.surf3, shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded, color: C.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Submissions Stats',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: C.textPrimary)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'In progress', count: _count('pending') + _count('submitted'), color: C.purple),
              _StatItem(label: 'Approved', count: _count('approved'), color: C.green),
              _StatItem(label: 'Pending', count: _count('pending'), color: C.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStream() {
    final filtered = _filter == 'All' ? _all : _all.where((r) => r.status == _filter.toLowerCase()).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Activity Stream',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: C.textPrimary)),
        const SizedBox(height: 16),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = _filters[i];
              final active = _filter == f;
              return GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: active ? C.primary500 : C.primary100.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Center(
                    child: Text(f, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : C.primary500)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
        else if (filtered.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No activities found')))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final r = filtered[i];
              return _ActivityItem(
                request: r,
                onTap: () => widget.onRequestTap(r.raw),
              );
            },
          ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatItem({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(child: Text('$count', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white))),
        ),
        const SizedBox(height: 12),
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: C.textTertiary)),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final AuthRequest request;
  final VoidCallback onTap;

  const _ActivityItem({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (request.status) {
      'approved' => C.green,
      'denied'   => C.red,
      _          => C.orange,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.surf3, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: C.surf2, shape: BoxShape.circle),
              child: const Icon(Icons.person_outline, color: C.textSecondary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.insurer, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: C.textPrimary)),
                  const SizedBox(height: 2),
                  Text(request.treatment, style: GoogleFonts.inter(fontSize: 12, color: C.textTertiary, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(request.status.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: statusColor)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('11:32 AM', style: GoogleFonts.inter(fontSize: 11, color: C.textTertiary, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: C.surf3, size: 20),
          ],
        ),
      ),
    );
  }
}
