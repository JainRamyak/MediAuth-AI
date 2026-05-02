import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';

// ──────────────────────────────────────────────────────────────────────────────
// STATUS PILLS — dot + label, 30px tall, border 0.5px
// ──────────────────────────────────────────────────────────────────────────────

enum AuthStatus { approved, pending, denied, appealing, submitted }

class StatusPill extends StatelessWidget {
  final AuthStatus status;
  const StatusPill(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (label, bg, border, fg) = switch (status) {
      AuthStatus.approved  => ('Approved',  C.green50,  C.green500, C.green700),
      AuthStatus.pending   => ('Pending',   C.amber50,  C.amber500, C.amber700),
      AuthStatus.denied    => ('Denied',    C.red50,    C.red500,   C.red700),
      AuthStatus.appealing => ('Appealing', C.violet50, C.violet500,C.violet700),
      AuthStatus.submitted => ('Submitted', C.blue50,   C.blue500,  C.blue700),
    };
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
            style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: fg, letterSpacing: 0.2)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// STEP PROGRESS BAR — segmented, replaces dot indicators
// ──────────────────────────────────────────────────────────────────────────────

class StepHeader extends StatelessWidget {
  final int current; // 1-indexed
  final int total;
  final String title;

  const StepHeader({
    super.key,
    required this.current,
    required this.total,
    required this.title,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Segmented progress bar
      Row(
        children: List.generate(total, (i) {
          final isDone   = i <= current - 1;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isDone ? C.teal500 : C.surf3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: 16),
      Text('Step $current of $total',
        style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: C.teal600, letterSpacing: 0.3)),
      const SizedBox(height: 4),
      Text(title,
        style: Theme.of(context).textTheme.headlineMedium),
    ],
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// SECTION LABEL
// ──────────────────────────────────────────────────────────────────────────────

class SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const SectionLabel(this.label, this.icon, {super.key});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: C.teal600),
    const SizedBox(width: 6),
    Text(label.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w600,
        color: C.teal600, letterSpacing: 0.8)),
    const SizedBox(width: 10),
    Expanded(child: Container(height: 0.5, color: C.surf3)),
  ]);
}

// ──────────────────────────────────────────────────────────────────────────────
// MEDI CARD — reusable card with optional left-accent
// ──────────────────────────────────────────────────────────────────────────────

class MediCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? accentColor;
  final VoidCallback? onTap;

  const MediCard({
    super.key,
    required this.child,
    this.padding,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: C.surf0,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.surf3, width: 0.5),
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
        if (accentColor != null)
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
          ),
      ],
    );
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: inner,
      );
    }
    return inner;
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// CHIP INPUT FIELD
// ──────────────────────────────────────────────────────────────────────────────

class ChipInputField extends StatefulWidget {
  final String label;
  final List<String> chips;
  final ValueChanged<List<String>> onChanged;
  final String hint;

  const ChipInputField({
    super.key,
    required this.label,
    required this.chips,
    required this.onChanged,
    this.hint = 'Add item…',
  });

  @override
  State<ChipInputField> createState() => _ChipInputFieldState();
}

class _ChipInputFieldState extends State<ChipInputField> {
  final _ctrl = TextEditingController();

  void _add(String val) {
    final t = val.trim();
    if (t.isEmpty || widget.chips.contains(t)) {
      _ctrl.clear(); return;
    }
    widget.onChanged([...widget.chips, t]);
    _ctrl.clear();
  }

  void _remove(String val) =>
    widget.onChanged(widget.chips.where((c) => c != val).toList());

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.label,
        style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w500,
          color: C.textSecondary)),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: C.surf2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: C.surf3, width: 0.5),
        ),
        child: Wrap(
          spacing: 6, runSpacing: 6,
          children: [
            ...widget.chips.map((chip) => Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: C.teal50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: C.teal500.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(chip,
                  style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: C.teal700)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _remove(chip),
                  child: Icon(Icons.close, size: 13, color: C.teal600),
                ),
              ]),
            )),
            SizedBox(
              height: 32,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: 120,
                  child: TextField(
                    key: _textKey,
                    controller: _ctrl,
                    style: GoogleFonts.inter(
                      fontSize: 13, color: C.textPrimary),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13, color: C.textTertiary),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 4),
                      filled: false,
                    ),
                    onSubmitted: _add,
                    textInputAction: TextInputAction.done,
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    ],
  );

  final _textKey = GlobalKey();
}

// ──────────────────────────────────────────────────────────────────────────────
// AGENT STEP STATUS
// ──────────────────────────────────────────────────────────────────────────────

enum AgentStepStatus { pending, active, complete, error }

// ──────────────────────────────────────────────────────────────────────────────
// PRIMARY BUTTON
// ──────────────────────────────────────────────────────────────────────────────

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: loading ? null : onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: C.teal500,
      disabledBackgroundColor: C.teal500.withValues(alpha: 0.6),
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14)),
    ),
    child: loading
      ? const SizedBox(
          width: 22, height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5, color: C.white))
      : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: C.white),
              const SizedBox(width: 8),
            ],
            Text(label,
              style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: C.white)),
          ],
        ),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// INFO BANNER
// ──────────────────────────────────────────────────────────────────────────────

class InfoBanner extends StatelessWidget {
  final String message;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final IconData? icon;

  const InfoBanner({
    super.key,
    required this.message,
    this.bgColor    = C.teal50,
    this.borderColor = C.teal500,
    this.textColor  = C.teal700,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      border: Border(left: BorderSide(color: borderColor, width: 3)),
    ),
    child: Row(children: [
      if (icon != null) ...[
        Icon(icon, size: 16, color: borderColor),
        const SizedBox(width: 10),
      ],
      Expanded(
        child: Text(message,
          style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: textColor, height: 1.4)),
      ),
    ]),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// TOP TOAST
// ──────────────────────────────────────────────────────────────────────────────

void showMediToast(
  BuildContext context,
  String message, {
  ToastKind kind = ToastKind.success,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(builder: (_) => _ToastOverlay(
    message: message,
    kind: kind,
    onDismiss: () => entry.remove(),
    duration: duration,
  ));
  overlay.insert(entry);
}

enum ToastKind { success, warning, error }

class _ToastOverlay extends StatefulWidget {
  final String message;
  final ToastKind kind;
  final VoidCallback onDismiss;
  final Duration duration;
  const _ToastOverlay({
    required this.message,
    required this.kind,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 280));
    _slide = Tween<Offset>(
      begin: const Offset(0, -1), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    // All toast kinds auto-dismiss; cap at 5 seconds for safety.
    final dismissAfter = widget.duration > const Duration(seconds: 5)
        ? const Duration(seconds: 5)
        : widget.duration;
    Future.delayed(dismissAfter, _dismiss);
  }

  void _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (widget.kind) {
      ToastKind.success => (C.green50,  C.green500,  C.green700),
      ToastKind.warning => (C.amber50,  C.amber500,  C.amber700),
      ToastKind.error   => (C.red50,    C.red500,    C.red700),
    };
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16, right: 16,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: border, width: 3)),
              ),
              child: Row(children: [
                Icon(
                  widget.kind == ToastKind.success
                    ? Icons.check_circle_rounded
                    : widget.kind == ToastKind.warning
                      ? Icons.warning_rounded
                      : Icons.error_rounded,
                  size: 16, color: fg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.message,
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: fg)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SECTION CARD
// ──────────────────────────────────────────────────────────────────────────────

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const SectionCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: C.surf0,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: C.surf3, width: 0.5),
    ),
    child: child,
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// AGENT STEP ROW — with animated connecting line
// ──────────────────────────────────────────────────────────────────────────────

class AgentStepRow extends StatelessWidget {
  final String agentName;
  final AgentStepStatus status;
  final String? statusLabel;
  final String? outputSnippet;
  final bool isExpanded;
  final VoidCallback? onTap;
  final IconData? agentIcon;

  const AgentStepRow({
    super.key,
    required this.agentName,
    required this.status,
    this.statusLabel,
    this.outputSnippet,
    this.isExpanded = false,
    this.onTap,
    this.agentIcon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(children: [
            _AgentDot(status, icon: agentIcon),
            Container(width: 1.5, height: 44,
              color: status == AgentStepStatus.complete
                ? C.teal500.withValues(alpha: 0.3) : C.surf3),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(agentName,
                    style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: status == AgentStepStatus.pending
                        ? C.textTertiary : C.textPrimary)),
                  if (statusLabel != null) ...[
                    const SizedBox(height: 3),
                    Text(statusLabel!,
                      style: GoogleFonts.inter(
                        fontSize: 12, color: _labelColor)),
                  ],
                  if (isExpanded && outputSnippet != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: C.surf2,
                        borderRadius: BorderRadius.circular(10)),
                      child: Text(outputSnippet!,
                        style: AppTheme.monoStyle(
                          color: C.textSecondary, size: 11)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _labelColor => switch (status) {
    AgentStepStatus.pending  => C.textTertiary,
    AgentStepStatus.active   => C.amber600,
    AgentStepStatus.complete => C.teal700,
    AgentStepStatus.error    => C.red700,
  };
}

class _AgentDot extends StatelessWidget {
  final AgentStepStatus status;
  final IconData? icon;
  const _AgentDot(this.status, {this.icon});

  @override
  Widget build(BuildContext context) => switch (status) {
    AgentStepStatus.pending => Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: C.surf2,
        border: Border.all(color: C.surf3, width: 1.5)),
      child: Icon(icon ?? Icons.circle_outlined,
        size: 16, color: C.textTertiary),
    ),
    AgentStepStatus.active => Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 36, height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: const AlwaysStoppedAnimation(C.amber500))),
        Icon(icon ?? Icons.circle,
          size: 14, color: C.amber600),
      ],
    ),
    AgentStepStatus.complete => Container(
      width: 36, height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle, color: C.teal500),
      child: Icon(icon ?? Icons.check,
        size: 18, color: C.white),
    ),
    AgentStepStatus.error => Container(
      width: 36, height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle, color: C.red500),
      child: const Icon(Icons.close, size: 18, color: C.white),
    ),
  };
}

// ──────────────────────────────────────────────────────────────────────────────
// PULSE RINGS ANIMATION
// ──────────────────────────────────────────────────────────────────────────────

class PulseRings extends StatefulWidget {
  final Widget child;
  final Color color;
  const PulseRings({super.key, required this.child, required this.color});

  @override
  State<PulseRings> createState() => _PulseRingsState();
}

class _PulseRingsState extends State<PulseRings> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
  }
  
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            _buildRing(0.0),
            _buildRing(0.33),
            _buildRing(0.66),
            widget.child,
          ],
        );
      },
    );
  }

  Widget _buildRing(double delay) {
    final val = (_ctrl.value + delay) % 1.0;
    final scale = 1.0 + (val * 0.9);
    final opacity = (1.0 - val) * 0.5;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 120, height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.color.withValues(alpha: opacity),
            width: 2,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// CONFETTI PAINTER — celebration dots (for Approved screen)
// ──────────────────────────────────────────────────────────────────────────────

class ConfettiPainter extends CustomPainter {
  final double progress; // 0→1
  final List<ConfettiDot> dots;

  ConfettiPainter({required this.progress, required this.dots})
    : super(repaint: null);

  @override
  void paint(Canvas canvas, Size size) {
    for (final dot in dots) {
      final y = dot.startY + (dot.speed * progress * size.height * 0.8);
      final x = dot.startX * size.width +
        sin(progress * dot.wobble * pi * 2) * 20;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = dot.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      if (dot.isCircle) {
        canvas.drawCircle(Offset(x, y), dot.size, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y),
            width: dot.size, height: dot.size * 0.5),
          paint);
      }
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter old) => old.progress != progress;
}

class ConfettiDot {
  final double startX, startY, speed, wobble, size;
  final Color color;
  final bool isCircle;
  const ConfettiDot({
    required this.startX, required this.startY, required this.speed,
    required this.wobble, required this.size, required this.color,
    required this.isCircle,
  });
}

List<ConfettiDot> generateConfetti() {
  final rng = Random(42);
  const colors = [C.teal400, C.green500, C.amber500, C.blue500, C.violet500];
  return List.generate(30, (i) => ConfettiDot(
    startX: rng.nextDouble(),
    startY: -rng.nextDouble() * 100,
    speed: 0.4 + rng.nextDouble() * 0.6,
    wobble: 1 + rng.nextDouble() * 3,
    size: 4 + rng.nextDouble() * 6,
    color: colors[i % colors.length],
    isCircle: rng.nextBool(),
  ));
}

// ──────────────────────────────────────────────────────────────────────────────
// FORM FIELD LABEL — consistent field label style
// ──────────────────────────────────────────────────────────────────────────────

class FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const FieldLabel(this.label, {super.key, this.required = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Text(label,
          style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: C.textSecondary)),
        if (required) ...[
          const SizedBox(width: 3),
          Text('*',
            style: GoogleFonts.inter(
              fontSize: 13, color: C.red500,
              fontWeight: FontWeight.w600)),
        ],
      ],
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// EMPTY STATE — consistent empty placeholder
// ──────────────────────────────────────────────────────────────────────────────

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(
              color: C.surf2, shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: C.textTertiary),
          ),
          const SizedBox(height: 16),
          Text(title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 17, fontWeight: FontWeight.w700,
              color: C.textPrimary)),
          const SizedBox(height: 6),
          Text(subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14, color: C.textSecondary, height: 1.5)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded, size: 18, color: C.teal600),
              label: Text(actionLabel!,
                style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: C.teal600)),
            ),
          ],
        ],
      ),
    ),
  );
}
