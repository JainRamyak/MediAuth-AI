import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/shared_widgets.dart';

// ── Public mock data ──────────────────────────────────────────────────────────

class AuthRequest {
  final String id;
  final String treatment;   // PRIMARY label per UF: "Treatment name" shown first
  final String insurer;     // SECONDARY label per UF: "Insurer name"
  final String providerName;
  final AuthStatus status;
  final DateTime timestamp;

  const AuthRequest({
    required this.id,
    required this.treatment,
    required this.insurer,
    required this.providerName,
    required this.status,
    required this.timestamp,
  });
}

final mockRequests = <AuthRequest>[
  AuthRequest(
    id: 'AUTH-2027-001',
    treatment: 'Total Knee Arthroplasty',
    insurer: 'UnitedHealth',
    providerName: 'Dr. Sarah Kim (AIIMS)',
    status: AuthStatus.approved,
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  AuthRequest(
    id: 'AUTH-2027-002',
    treatment: 'MRI Brain with contrast',
    insurer: 'UnitedHealth',
    providerName: 'Dr. Alan Grant',
    status: AuthStatus.pending,
    timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
  ),
  AuthRequest(
    id: 'AUTH-2027-003',
    treatment: 'Spinal fusion L4–L5',
    insurer: 'UnitedHealth',
    providerName: 'Dr. Emily Chen',
    status: AuthStatus.denied,
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
  ),
  AuthRequest(
    id: 'AUTH-2027-004',
    treatment: 'Cardiac catheterization',
    insurer: 'UnitedHealth',
    providerName: 'HeartCenter Cardiology',
    status: AuthStatus.appealing,
    timestamp: DateTime.now().subtract(const Duration(hours: 18)),
  ),
  AuthRequest(
    id: 'AUTH-2027-005',
    treatment: 'Hip replacement',
    insurer: 'UnitedHealth',
    providerName: 'City Orthopedics',
    status: AuthStatus.submitted,
    timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
  ),
];

// ── S03 Dashboard ─────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNewRequest;
  final void Function(AuthRequest) onRequestTap;
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

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _countCtl;
  late Animation<double> _countAnim;

  @override
  void initState() {
    super.initState();
    _countCtl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _countAnim = CurvedAnimation(parent: _countCtl, curve: Curves.easeOut);
    _countCtl.forward();
  }

  @override
  void dispose() {
    _countCtl.dispose();
    super.dispose();
  }

  void _showNotificationPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: const BoxDecoration(
          color: C.surf0,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: C.surf3,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                      color: C.green50, shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded,
                      color: C.green500, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Approval Update!',
                          style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: C.textPrimary,
                              letterSpacing: -0.3)),
                      Text('AUTH-2027-001 · 2 hours ago',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: C.textTertiary)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: C.surf1,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: C.surf3, width: 0.5),
                ),
                child: Text(
                  'Good news, Margaret. Your request for Total Knee Arthroplasty submitted by Dr. Sarah Kim has been fully approved by UnitedHealth.',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: C.textSecondary, height: 1.6)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.teal500,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('View Details',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: C.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = mockRequests
        .where((r) =>
            r.status == AuthStatus.pending ||
            r.status == AuthStatus.submitted)
        .length;
    final approved =
        mockRequests.where((r) => r.status == AuthStatus.approved).length;
    final denied = mockRequests
        .where((r) =>
            r.status == AuthStatus.denied ||
            r.status == AuthStatus.appealing)
        .length;

    return Scaffold(
      backgroundColor: C.surf1,
      body: RefreshIndicator(
        color: C.teal500,
        onRefresh: () async =>
            await Future.delayed(const Duration(seconds: 1)),
        child: CustomScrollView(
          slivers: [
            // ── Hero SliverAppBar ──────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: C.surf1,
              surfaceTintColor: Colors.transparent,
              title: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                        color: C.teal500, shape: BoxShape.circle),
                    child: const Icon(Icons.shield_rounded,
                        size: 16, color: C.white),
                  ),
                  const SizedBox(width: 8),
                  Text('MediAuth AI',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: C.textPrimary,
                          letterSpacing: -0.5)),
                ],
              ),
              actions: [
                Stack(clipBehavior: Clip.none, children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: C.textSecondary),
                    onPressed: _showNotificationPopup,
                  ),
                  Positioned(
                    top: 8,
                    right: 6,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                          color: C.red500, shape: BoxShape.circle),
                    ),
                  ),
                ]),
                GestureDetector(
                  onTap: widget.onProfileTap,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: C.teal600,
                      child: Text('MT',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: C.white)),
                    ),
                  ),
                ),
              ],
            ),

            // ── Editorial Hero ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good evening, Margaret 👋',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: C.textTertiary,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text('Your Health\nActivity',
                        style: GoogleFonts.inter(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            color: C.textPrimary,
                            letterSpacing: -1.0)),
                  ],
                ),
              ),
            ),

            // ── Content ───────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Hero Metrics Panel ────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: C.surf0,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: C.surf3, width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: C.teal50,
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 20,
                                  color: C.teal600),
                            ),
                            const SizedBox(width: 12),
                            Text('Claimed Successfully',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: C.textTertiary)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AnimatedBuilder(
                          animation: _countAnim,
                          builder: (_, __) {
                            final val = (14200 * _countAnim.value).round();
                            return Text(
                                '\$${val ~/ 1000},${(val % 1000).toString().padLeft(3, '0')}',
                                style: GoogleFonts.inter(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w800,
                                    color: C.textPrimary,
                                    letterSpacing: -1.5,
                                    height: 1.0));
                          },
                        ),
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: 12,
                            child: Row(
                              children: [
                                Expanded(
                                    flex: approved == 0 ? 1 : approved,
                                    child: Container(color: C.teal500)),
                                const SizedBox(width: 2),
                                Expanded(
                                    flex: pending == 0 ? 1 : pending,
                                    child: Container(color: C.amber500)),
                                if (denied > 0) ...[
                                  const SizedBox(width: 2),
                                  Expanded(
                                      flex: denied,
                                      child: Container(color: C.red500)),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _LegendItem(
                                color: C.teal500, label: '$approved Approved'),
                            _LegendItem(
                                color: C.amber500, label: '$pending Pending'),
                            if (denied > 0)
                              _LegendItem(
                                  color: C.red500, label: '$denied Denied'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Filter Pills ──────────────────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterPill(
                            label: 'All Requests',
                            count: mockRequests.length,
                            isActive: true),
                        _FilterPill(
                            label: 'Approved',
                            count: approved,
                            isActive: false),
                        _FilterPill(
                            label: 'Pending',
                            count: pending,
                            isActive: false),
                        if (denied > 0)
                          _FilterPill(
                              label: 'Action Required',
                              count: denied,
                              isActive: false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (mockRequests.isEmpty)
                    EmptyStateView(
                      icon: Icons.inbox_outlined,
                      title: 'No requests yet',
                      subtitle:
                          'Tap the + button to submit your first treatment authorization.',
                      actionLabel: 'New Request',
                      onAction: widget.onNewRequest,
                    )
                  else
                    // UF: each card shows Treatment name, Insurer name, Status badge, Date submitted
                    ...mockRequests.map((req) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RequestCard(
                              request: req,
                              onTap: () => widget.onRequestTap(req)),
                        )),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onNewRequest,
        backgroundColor: C.teal500,
        elevation: 0,
        label: Text('New Request',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: C.white)),
        icon: const Icon(Icons.add_rounded, color: C.white),
      ),
    );
  }
}

// ── Hero Panel Components ─────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label,
          style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: C.textSecondary)),
    ]);
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  const _FilterPill(
      {required this.label, required this.count, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? C.textPrimary : C.surf0,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isActive ? C.textPrimary : C.surf3, width: 1.0),
      ),
      child: Row(children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? C.white : C.textSecondary)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color:
                isActive ? C.surf2.withValues(alpha: 0.2) : C.surf2,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? C.white : C.textTertiary)),
        ),
      ]),
    );
  }
}

// ── Request Card ──────────────────────────────────────────────────────────────
// UF: Each card shows: Treatment name (PRIMARY), Insurer name, Status badge, Date submitted

class _RequestCard extends StatelessWidget {
  final AuthRequest request;
  final VoidCallback onTap;
  const _RequestCard({required this.request, required this.onTap});

  Color get _accentColor => switch (request.status) {
        AuthStatus.approved => C.green500,
        AuthStatus.pending => C.amber500,
        AuthStatus.denied => C.red500,
        AuthStatus.appealing => C.violet500,
        AuthStatus.submitted => C.blue500,
      };

  @override
  Widget build(BuildContext context) {
    final elapsed = _elapsed(request.timestamp);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: C.surf0,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: C.surf3, width: 0.5),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  // Avatar uses first letter of treatment (UF primary field)
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(request.treatment[0],
                          style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _accentColor)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // UF PRIMARY: Treatment name
                      Text(request.treatment,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: C.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 1),
                      // UF SECONDARY: Insurer name
                      Text(request.insurer,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: C.textSecondary)),
                    ],
                  )),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // UF: Status badge (color + icon + text — never color alone)
                      StatusPill(request.status),
                      const SizedBox(height: 4),
                      // UF: Date submitted
                      Text(elapsed,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: C.textTertiary)),
                    ],
                  ),
                ]),
                const SizedBox(height: 10),
                // Provider shown as secondary detail row
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: C.surf1,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 13, color: C.textTertiary),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(request.providerName,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: C.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.tag_rounded,
                      size: 12, color: C.textTertiary),
                  const SizedBox(width: 3),
                  Text(request.id,
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 11, color: C.textTertiary)),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: C.textTertiary),
                ]),
              ],
            ),
          ),
          // Left accent bar
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _elapsed(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}