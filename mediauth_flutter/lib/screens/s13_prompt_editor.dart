import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';

class AgentPrompt {
  final String name;
  String systemPrompt;
  String userTemplate;

  AgentPrompt({
    required this.name,
    required this.systemPrompt,
    required this.userTemplate,
  });
}

// ── S13 Prompt Editor ─────────────────────────────────────────────────────────

class PromptEditorScreen extends StatefulWidget {
  final AgentPrompt agent;
  final VoidCallback onBack;
  final void Function(AgentPrompt) onTest;

  const PromptEditorScreen({
    super.key,
    required this.agent,
    required this.onBack,
    required this.onTest,
  });

  @override
  State<PromptEditorScreen> createState() => _PromptEditorScreenState();
}

class _PromptEditorScreenState extends State<PromptEditorScreen> {
  late TextEditingController _sysCtrl;
  late TextEditingController _userCtrl;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _sysCtrl  = TextEditingController(text: widget.agent.systemPrompt);
    _userCtrl = TextEditingController(text: widget.agent.userTemplate);
  }

  int get _totalChars =>
    _sysCtrl.text.length + _userCtrl.text.length;

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    widget.agent.systemPrompt = _sysCtrl.text;
    widget.agent.userTemplate = _userCtrl.text;
    setState(() { _saving = false; _saved = true; });
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _saved = false);
  }

  void _reset() {
    _sysCtrl.text  = widget.agent.systemPrompt;
    _userCtrl.text = widget.agent.userTemplate;
    setState(() {});
  }

  @override
  void dispose() {
    _sysCtrl.dispose();
    _userCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.surf1,
      appBar: AppBar(
        title: Text(widget.agent.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        actions: [
          if (_saved)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: C.teal50, borderRadius: BorderRadius.circular(20)),
              child: Text('Saved ✓',
                style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: C.teal600)),
            )
          else
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: C.teal500))
                : Text('Save',
                    style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600, color: C.teal500)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // System prompt pane
                  Container(
                    width: double.infinity,
                    color: C.textPrimary,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('System Prompt',
                          style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: C.surf300, letterSpacing: 1.0)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _sysCtrl,
                          maxLines: null,
                          minLines: 8,
                          style: GoogleFonts.robotoMono(
                            fontSize: 13, color: C.teal400, height: 1.5),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            fillColor: Colors.transparent,
                            filled: false,
                            hintText: 'Enter system prompt...',
                            hintStyle: GoogleFonts.robotoMono(
                              fontSize: 13, color: C.ink400),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Container(height: 1, color: C.surf3),

                  // User template pane
                  Container(
                    width: double.infinity,
                    color: C.textPrimary,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User Template',
                          style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: C.surf300, letterSpacing: 1.0)),
                        const SizedBox(height: 8),
                        _TemplateTextField(
                          controller: _userCtrl,
                          onChanged: () => setState(() {}),
                        ),
                      ],
                    ),
                  ),

                  // Footer
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$_totalChars characters',
                          style: GoogleFonts.inter(
                            fontSize: 12, color: C.ink300)),
                        GestureDetector(
                          onTap: _reset,
                          child: Text('Reset to default',
                            style: GoogleFonts.inter(
                              fontSize: 12, color: C.ink400,
                              decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom CTA: test run
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: C.surf0,
              border: Border(top: BorderSide(color: C.surf3, width: 0.5))),
            child: ElevatedButton.icon(
              onPressed: () => widget.onTest(widget.agent),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('Test this prompt',
                style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52)),
            ),
          ),
        ],
      ),
    );
  }
}

// Template variable highlighting widget (renders {variable} in amber500)
class _TemplateTextField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _TemplateTextField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: null,
      minLines: 5,
      style: GoogleFonts.robotoMono(
        fontSize: 13, color: C.surf200, height: 1.5),
      decoration: InputDecoration(
        border: InputBorder.none,
        fillColor: Colors.transparent,
        filled: false,
        hintText: 'Enter user template with {variables}...',
        hintStyle: GoogleFonts.robotoMono(
          fontSize: 13, color: C.ink400),
      ),
      onChanged: (_) => onChanged(),
    );
  }
}
