// ─────────────────────────────────────────────────────────
// widgets.dart  –  Medi UI Component Library (recoded)
// ─────────────────────────────────────────────────────────

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../theme/app_theme.dart';

// ─── TYPOGRAPHY HELPERS ───────────────────────────────────

TextStyle _inter(double size, FontWeight w, Color color, {double spacing = 0}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: w, color: color, letterSpacing: spacing);

TextStyle _outfit(double size, FontWeight w, Color color, {double spacing = 0}) =>
    GoogleFonts.outfit(fontSize: size, fontWeight: w, color: color, letterSpacing: spacing);

// ─── STATUS PILL ──────────────────────────────────────────

enum AuthStatus { approved, pending, denied, appealing, submitted }

class StatusPill extends StatelessWidget {
  final AuthStatus status;
  const StatusPill(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (label, bg, dotColor, textColor) = switch (status) {
      AuthStatus.approved  => ('Approved',  C.green50,  C.green500,  C.green800),
      AuthStatus.pending   => ('Pending',   C.amber50,  C.amber500,  C.amber800),
      AuthStatus.denied    => ('Denied',    C.red50,    C.red500,    C.red800),
      AuthStatus.appealing => ('Appealing', C.violet50, C.violet500, C.violet800),
      AuthStatus.submitted => ('Submitted', C.blue50,   C.blue500,   C.blue800),
    };

    final borderColor = dotColor.withValues(alpha: 0.35);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
            style: _inter(11, FontWeight.w600, textColor, spacing: 0.1)),
        ],
      ),
    );
  }
}

// ─── STEP HEADER ─────────────────────────────────────────

class StepHeader extends StatelessWidget {
  final int current;   // 1-indexed
  final int total;
  final String title;
  const StepHeader({super.key, required this.current, required this.total, required this.title});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: List.generate(total, (i) {
          final filled = i < current;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: filled ? C.primary500 : C.surf3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: 14),
      Text(
        'Step $current of $total',
        style: _inter(11, FontWeight.w700, C.primary600, spacing: 0.5),
      ),
      const SizedBox(height: 3),
      Text(title, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: C.textPrimary)),
    ],
  );
}

// ─── SECTION LABEL ───────────────────────────────────────

class SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const SectionLabel(this.label, this.icon, {super.key});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 16, color: C.primary500),
    const SizedBox(width: 8),
    Text(label, style: _inter(14, FontWeight.w700, C.textPrimary, spacing: -0.2)),
    const SizedBox(width: 12),
    Expanded(
      child: Container(height: 1.0, color: C.surf3.withValues(alpha: 0.5)),
    ),
  ]);
}

// ─── MEDI CARD ───────────────────────────────────────────

class MediCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? accentColor;
  final VoidCallback? onTap;

  const MediCard({super.key, required this.child, this.padding, this.accentColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: C.surf3.withValues(alpha: 0.6), width: 1.0),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8)),
              ],
            ),
            child: child,
          ),
          if (accentColor != null)
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(width: 4, color: accentColor),
            ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: C.primary100.withValues(alpha: 0.4),
          highlightColor: Colors.transparent,
          child: card,
        ),
      );
    }
    return card;
  }
}

// ─── CHIP INPUT FIELD ────────────────────────────────────

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
  final _focus = FocusNode();

  void _add(String val) {
    final t = val.trim();
    if (t.isEmpty || widget.chips.contains(t)) { _ctrl.clear(); return; }
    widget.onChanged([...widget.chips, t]);
    _ctrl.clear();
  }

  void _remove(String val) =>
      widget.onChanged(widget.chips.where((c) => c != val).toList());

  @override
  void dispose() { _ctrl.dispose(); _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.label, style: _inter(13, FontWeight.w500, C.textSecondary)),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: () => _focus.requestFocus(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: C.surf2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focus.hasFocus ? C.teal500 : C.surf3,
              width: _focus.hasFocus ? 1 : 0.5,
            ),
          ),
          child: Wrap(
            spacing: 6, runSpacing: 6,
            children: [
              ...widget.chips.map((chip) => _Chip(chip, onRemove: () => _remove(chip))),
              SizedBox(
                height: 30,
                child: IntrinsicWidth(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    style: _inter(13, FontWeight.w400, C.textPrimary),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: _inter(13, FontWeight.w400, C.textTertiary),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    ),
                    onSubmitted: _add,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
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

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _Chip(this.label, {required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
    height: 30,
    padding: const EdgeInsets.only(left: 10, right: 6),
    decoration: BoxDecoration(
      color: C.teal50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: C.teal500.withValues(alpha: 0.25), width: 0.5),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: _inter(12.5, FontWeight.w500, C.teal700)),
      const SizedBox(width: 5),
      GestureDetector(
        onTap: onRemove,
        child: Container(
          width: 16, height: 16,
          decoration: BoxDecoration(
            color: C.teal500.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.close, size: 9, color: C.teal600),
        ),
      ),
    ]),
  );
}

// ─── PRIMARY BUTTON ──────────────────────────────────────

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const PrimaryButton({
    super.key, required this.label,
    this.onPressed, this.loading = false, this.icon,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _down(_) { if (widget.onPressed != null && !widget.loading) _ctrl.forward(); }
  void _up(_)   { if (widget.onPressed != null && !widget.loading) _ctrl.reverse(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: _down,
    onTapUp: _up,
    onTapCancel: () => _up(null),
    child: ScaleTransition(
      scale: _scale,
      child: SizedBox(
        height: 56, width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.loading ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: C.primary500,
            disabledBackgroundColor: C.primary500.withValues(alpha: 0.55),
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: widget.loading
                ? const SizedBox(
                    key: ValueKey('loader'),
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    key: const ValueKey('label'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 20, color: Colors.white),
                        const SizedBox(width: 10),
                      ],
                      Text(widget.label, style: _inter(16, FontWeight.w800, Colors.white)),
                    ],
                  ),
          ),
        ),
      ),
    ),
  );
}

// ─── INFO BANNER ─────────────────────────────────────────

class InfoBanner extends StatelessWidget {
  final String message;
  final Color bgColor;
  final Color accentColor;
  final Color textColor;
  final IconData? icon;

  const InfoBanner({
    super.key,
    required this.message,
    this.bgColor    = C.teal50,
    this.accentColor = C.teal500,
    this.textColor  = C.teal700,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 0.5),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (icon != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, size: 15, color: accentColor),
              ),
              const SizedBox(width: 9),
            ],
            Expanded(
              child: Text(message,
                style: _inter(13, FontWeight.w500, textColor).copyWith(height: 1.45)),
            ),
          ]),
        ),
        Positioned(
          left: 0, top: 0, bottom: 0,
          child: Container(width: 3, color: accentColor),
        ),
      ],
    ),
  );
}

// ─── TOAST ───────────────────────────────────────────────

enum ToastKind { success, warning, error }

void showMediToast(
  BuildContext context,
  String message, {
  ToastKind kind = ToastKind.success,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _MediToast(
      message: message,
      kind: kind,
      duration: duration,
      onDismiss: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _MediToast extends StatefulWidget {
  final String message;
  final ToastKind kind;
  final Duration duration;
  final VoidCallback onDismiss;
  const _MediToast({required this.message, required this.kind, required this.duration, required this.onDismiss});

  @override
  State<_MediToast> createState() => _MediToastState();
}

class _MediToastState extends State<_MediToast> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _slide = Tween(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    int ms = widget.duration.inMilliseconds.clamp(0, 5000);
    Future.delayed(Duration(milliseconds: ms), _dismiss);
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final (bg, accent, fg, icon) = switch (widget.kind) {
      ToastKind.success => (C.green50,  C.green500,  C.green800,  Icons.check_circle_rounded),
      ToastKind.warning => (C.amber50,  C.amber500,  C.amber800,  Icons.warning_rounded),
      ToastKind.error   => (C.red50,    C.red500,    C.red800,    Icons.error_rounded),
    };

    return Positioned(
      top: MediaQuery.of(context).padding.top + 14,
      left: 16, right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: GestureDetector(
            onTap: _dismiss,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.25), width: 0.5),
                  ),
                  child: Row(children: [
                    Icon(icon, size: 16, color: accent),
                    const SizedBox(width: 10),
                    Expanded(child: Text(widget.message, style: _inter(13, FontWeight.w600, fg))),
                    Icon(Icons.close, size: 14, color: fg.withValues(alpha: 0.5)),
                  ]),
                ),
                Positioned(left: 0, top: 0, bottom: 0,
                  child: Container(width: 3, color: accent)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SECTION CARD ────────────────────────────────────────

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const SectionCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: C.surf0,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: C.surf3.withValues(alpha: 0.6), width: 0.5),
    ),
    child: child,
  );
}

// ─── AGENT STEP ROW ──────────────────────────────────────

enum AgentStepStatus { pending, active, complete, error }

class AgentStepRow extends StatelessWidget {
  final String agentName;
  final AgentStepStatus status;
  final String? statusLabel;
  final String? outputSnippet;
  final bool isExpanded;
  final bool isLast;
  final VoidCallback? onTap;
  final IconData? agentIcon;

  const AgentStepRow({
    super.key,
    required this.agentName,
    required this.status,
    this.statusLabel,
    this.outputSnippet,
    this.isExpanded = false,
    this.isLast = false,
    this.onTap,
    this.agentIcon,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column: dot + connector
        SizedBox(
          width: 36,
          child: Column(children: [
            _AgentDot(status, icon: agentIcon),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Container(
                  width: 1.5, height: 36,
                  color: status == AgentStepStatus.complete
                      ? C.teal500.withValues(alpha: 0.25) : C.surf3,
                ),
              ),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agentName,
                  style: _inter(14, FontWeight.w600,
                    status == AgentStepStatus.pending ? C.textTertiary : C.textPrimary),
                ),
                if (statusLabel != null) ...[
                  const SizedBox(height: 3),
                  Text(statusLabel!, style: _inter(12, FontWeight.w400, _labelColor)),
                ],
                if (isExpanded && outputSnippet != null) ...[
                  const SizedBox(height: 8),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: C.surf2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: C.surf3, width: 0.5),
                      ),
                      child: Text(outputSnippet!,
                        style: AppTheme.monoStyle(color: C.textSecondary, size: 11)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );

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
      width: 34, height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: C.surf2,
        border: Border.all(color: C.surf3, width: 1.5)),
      child: Icon(icon ?? Icons.radio_button_unchecked_rounded, size: 15, color: C.textTertiary),
    ),

    AgentStepStatus.active => _PulseRing(
      color: C.amber500,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: C.amber50,
          border: Border.all(color: C.amber500, width: 1.5),
        ),
        child: Icon(icon ?? Icons.more_horiz_rounded, size: 16, color: C.amber600),
      ),
    ),

    AgentStepStatus.complete => Container(
      width: 34, height: 34,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: C.teal500),
      child: Icon(icon ?? Icons.check_rounded, size: 17, color: Colors.white),
    ),

    AgentStepStatus.error => Container(
      width: 34, height: 34,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: C.red500),
      child: const Icon(Icons.close_rounded, size: 17, color: Colors.white),
    ),
  };
}

// Lightweight inline pulse ring (no separate widget file needed)
class _PulseRing extends StatefulWidget {
  final Widget child;
  final Color color;
  const _PulseRing({required this.child, required this.color});

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, child) => Stack(alignment: Alignment.center, children: [
      Opacity(
        opacity: (1 - _anim.value).clamp(0, 0.4),
        child: Transform.scale(
          scale: 1 + _anim.value * 0.55,
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.color, width: 1.5),
            ),
          ),
        ),
      ),
      child!,
    ]),
    child: widget.child,
  );
}

// ─── PULSE RINGS ─────────────────────────────────────────

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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, child) => Stack(
      alignment: Alignment.center,
      children: [
        _ring(0.00), _ring(0.33), _ring(0.66),
        child!,
      ],
    ),
    child: widget.child,
  );

  Widget _ring(double offset) {
    final t = (_ctrl.value + offset) % 1.0;
    return Transform.scale(
      scale: 1.0 + t * 0.85,
      child: Opacity(
        opacity: (1 - t) * 0.45,
        child: Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: widget.color, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ─── GLOBAL ANIMATIONS ──────────────────────────────────────

class PulseOpacity extends StatefulWidget {
  final Widget child;
  const PulseOpacity({super.key, required this.child});
  @override
  State<PulseOpacity> createState() => _PulseOpacityState();
}
class _PulseOpacityState extends State<PulseOpacity> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim, builder: (_, child) => Opacity(opacity: _anim.value, child: child), child: widget.child,
  );
}

class SkeletonShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  const SkeletonShimmer({super.key, required this.width, required this.height, this.borderRadius = 8});

  @override
  Widget build(BuildContext context) => PulseOpacity(
    child: Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: C.surf3.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ),
  );
}

class FloatingAnimation extends StatefulWidget {
  final Widget child;
  const FloatingAnimation({super.key, required this.child});
  @override
  State<FloatingAnimation> createState() => _FloatingAnimationState();
}
class _FloatingAnimationState extends State<FloatingAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat(reverse: true);
    _anim = Tween<Offset>(begin: const Offset(0, -0.04), end: const Offset(0, 0.04)).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => SlideTransition(position: _anim, child: widget.child);
}

// ─── CONFETTI ────────────────────────────────────────────

class ConfettiPainter extends CustomPainter {
  final double progress;
  final List<ConfettiDot> dots;
  const ConfettiPainter({required this.progress, required this.dots});

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in dots) {
      final y = d.startY + d.speed * progress * size.height * 0.8;
      final x = d.startX * size.width + sin(progress * d.wobble * pi * 2) * 18;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = d.color.withValues(alpha: opacity * 0.85)
        ..style = PaintingStyle.fill;
      if (d.isCircle) {
        canvas.drawCircle(Offset(x, y), d.size, paint);
      } else {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(progress * d.wobble);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: d.size * 2, height: d.size),
            const Radius.circular(1)),
          paint);
        canvas.restore();
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
    required this.wobble, required this.size, required this.color, required this.isCircle,
  });
}

List<ConfettiDot> generateConfetti() {
  final rng = Random(42);
  const colors = [C.teal400, C.green500, C.amber500, C.blue500, C.violet500];
  return List.generate(36, (i) => ConfettiDot(
    startX: rng.nextDouble(),
    startY: -rng.nextDouble() * 120,
    speed: 0.35 + rng.nextDouble() * 0.65,
    wobble: 1 + rng.nextDouble() * 3,
    size: 3 + rng.nextDouble() * 5,
    color: colors[i % colors.length],
    isCircle: rng.nextBool(),
  ));
}

// ─── FIELD LABEL ─────────────────────────────────────────

class FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const FieldLabel(this.label, {super.key, this.required = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Text(label, style: _inter(13, FontWeight.w500, C.textSecondary)),
      if (required) ...[
        const SizedBox(width: 3),
        Text('*', style: _inter(13, FontWeight.w600, C.red500)),
      ],
    ]),
  );
}

// ─── EMPTY STATE ─────────────────────────────────────────

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key, required this.icon, required this.title, required this.subtitle,
    this.actionLabel, this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 66, height: 66,
          decoration: const BoxDecoration(color: C.surf2, shape: BoxShape.circle),
          child: Icon(icon, size: 30, color: C.textTertiary),
        ),
        const SizedBox(height: 14),
        Text(title,
          textAlign: TextAlign.center,
          style: _inter(17, FontWeight.w700, C.textPrimary)),
        const SizedBox(height: 5),
        Text(subtitle,
          textAlign: TextAlign.center,
          style: _inter(13.5, FontWeight.w400, C.textSecondary).copyWith(height: 1.5)),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add_rounded, size: 16, color: C.teal600),
            label: Text(actionLabel!,
              style: _inter(13.5, FontWeight.w600, C.teal600)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              backgroundColor: C.teal50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: C.teal500.withValues(alpha: 0.3), width: 0.5),
              ),
            ),
          ),
        ],
      ]),
    ),
  );
}

// ─── FADE SLIDE ──────────────────────────────────────────

class FadeSlide extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Offset beginOffset;

  const FadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.beginOffset = const Offset(0, 0.15),
  });

  @override
  State<FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<FadeSlide> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: widget.beginOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(widget.delay, () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}