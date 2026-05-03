import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'auth/auth_service.dart';
import 'theme/app_theme.dart';
import 'theme/colors.dart';

import 'screens/s01_splash.dart';
import 'screens/s02_login.dart';
import 'screens/s02a_signup.dart';
import 'screens/s00_profile.dart';

import 'screens/s03_dashboard.dart';
import 'screens/s04_patient_info.dart';
import 'screens/s05_medical_info.dart';
import 'screens/s06_review_submit.dart';
import 'screens/s06b_prompt_customization.dart';
import 'screens/s07_agent_pipeline.dart';
import 'screens/s08_approved.dart';
import 'screens/s09_denied.dart';
import 'screens/activity_screen.dart';
import 'screens/s12_agent_list.dart';
import 'screens/s13_prompt_editor.dart';

// ── Agent display name map (shared here so main doesn't need it in s12) ────────

const _agentDisplayNames = {
  'intake':           'Intake & History Agent',
  'medical_analysis': 'Medical Analysis Agent',
  'policy':           'Policy Intelligence Agent',
  'justification':    'Justification Writer',
  'submission':       'Submission Agent',
  'appeal':           'Denial & Appeal Agent',
  'claims':           'Claims Validation Agent',
};

// ── Entry point ───────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  await dotenv.load(fileName: '.env');
  
  // Initialize our custom API auth service (reads JWT from secure storage)
  await AuthService.instance.initialize();
  
  runApp(const MediAuthApp());
}

// ── App ───────────────────────────────────────────────────────────────────────

class MediAuthApp extends StatelessWidget {
  const MediAuthApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MediAuth AI',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const _AppRoot(),
  );
}

// ── Navigation enum ───────────────────────────────────────────────────────────

enum _Screen {
  splash,
  login,
  signup,
  resetPassword,
  shell,          // 3-tab shell
  newRequest,     // intake form (steps 1-3)
  promptCustom,   // screen 6B
  pipeline,       // screen 7
  approved,       // screen 8
  denied,         // screen 9
  agentDetail,    // screen 13 — pushed from agents tab
}

// ── Root ──────────────────────────────────────────────────────────────────────

class _AppRoot extends StatefulWidget {
  const _AppRoot();
  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  _Screen _screen = _Screen.splash;

  // Form state — reset on new request
  PatientFormData     _patient   = PatientFormData();
  TreatmentFormData   _treatment = TreatmentFormData();
  PromptSubmitPayload? _payload;
  int _intakeStep = 1;

  // Result from API
  Map<String, dynamic> _apiResult = {};

  // Agent detail
  String _agentKey         = '';
  String _agentDisplayName = '';

  void _go(_Screen s) => setState(() => _screen = s);

  @override
  void initState() {
    super.initState();
    AuthService.instance.onAuthStateChange.listen((data) {
      if (!mounted) return;
      switch (data.event) {
        case AuthChangeEvent.initialSession:
        case AuthChangeEvent.signedIn:
          final user = data.user;
          // Simple rule: if we have a user, proceed to shell. 
          // (Removed Supabase metadata checks for simplicity in custom auth)
          _go(user != null ? _Screen.shell : _Screen.login);
          break;

        case AuthChangeEvent.signedOut:
          _go(_Screen.login);
          break;

        default:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = switch (_screen) {
      // ── Auth ───────────────────────────────────────────────────────────
      _Screen.splash => SplashScreen(
        onDone: () {
          final user = AuthService.instance.currentUser;
          _go(user != null ? _Screen.shell : _Screen.login);
        },
      ),

      _Screen.login => LoginScreen(
        onLogin:  () => _go(_Screen.shell),
        onSignUp: () => _go(_Screen.signup),
      ),

      _Screen.signup => SignUpScreen(
        onSignUpSuccess: () => _go(_Screen.shell),
        onSignIn:        () => _go(_Screen.login),
      ),

      // Dummy reset password for now
      _Screen.resetPassword => const Scaffold(body: Center(child: Text("Reset not implemented"))),

      // ── Shell ──────────────────────────────────────────────────────────
      _Screen.shell => _ShellScreen(
        onNewRequest:  _startNewRequest,
        onRequestTap:  _openResult,
        onProfileTap:  () {}, // handled inside shell via 4th tab
        onAgentDetail: (key) {
          _agentKey         = key;
          _agentDisplayName = _agentDisplayNames[key] ?? key;
          _go(_Screen.agentDetail);
        },
      ),

      // ── Intake flow ────────────────────────────────────────────────────
      _Screen.newRequest => _buildIntake(),

      _Screen.promptCustom => PromptCustomizationScreen(
        patient:   _patient,
        treatment: _treatment,
        onBack:    () => setState(() { _intakeStep = 3; _screen = _Screen.newRequest; }),
        onSubmit:  (payload) { _payload = payload; _go(_Screen.pipeline); },
      ),

      _Screen.pipeline => AgentPipelineScreen(
        patient:   _patient,
        treatment: _treatment,
        payload:   _payload,
        onApproved: (r) { _apiResult = r; _go(_Screen.approved); },
        onDenied:   (r) { _apiResult = r; _go(_Screen.denied);   },
      ),

      // ── Results ────────────────────────────────────────────────────────
      _Screen.approved => ApprovedScreen(
        result:       _apiResult,
        onNewRequest: _startNewRequest,
        onHome:       () => _go(_Screen.shell),
      ),

      _Screen.denied => DeniedScreen(
        result:       _apiResult,
        onNewRequest: _startNewRequest,
        onHome:       () => _go(_Screen.shell),
        onApproved:   (r) { _apiResult = r; _go(_Screen.approved); },
      ),

      // ── Agent Detail ───────────────────────────────────────────────────
      _Screen.agentDetail => PromptEditorScreen(
        agentKey:    _agentKey,
        displayName: _agentDisplayName,
        onBack:      () => _go(_Screen.shell),
      ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (w, anim) {
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(anim),
            child: w,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(_screen),
        child: child,
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _startNewRequest() {
    setState(() {
      _patient    = PatientFormData();
      _treatment  = TreatmentFormData();
      _payload    = null;
      _intakeStep = 1;
      _screen     = _Screen.newRequest;
    });
  }

  void _openResult(Map<String, dynamic> raw) {
    _apiResult = raw;
    final status = (raw['workflow_status'] ?? '').toString().toLowerCase();
    if (status.contains('approved')) {
      _go(_Screen.approved);
    } else {
      _go(_Screen.denied);
    }
  }

  Widget _buildIntake() => switch (_intakeStep) {
    1 => PatientInfoScreen(
      data:   _patient,
      onBack: () => _go(_Screen.shell),
      onNext: () => setState(() => _intakeStep = 2),
    ),
    2 => MedicalInfoScreen(
      data:   _patient,
      onBack: () => setState(() => _intakeStep = 1),
      onNext: () => setState(() => _intakeStep = 3),
    ),
    _ => ReviewSubmitScreen(
      patient:    _patient,
      treatment:  _treatment,
      onBack:     () => setState(() => _intakeStep = 2),
      onSubmit:   () => _go(_Screen.pipeline),
      onCustomize: () => _go(_Screen.promptCustom),
    ),
  };
}

// ── 4-Tab Shell ───────────────────────────────────────────────────────────────

class _ShellScreen extends StatefulWidget {
  final VoidCallback onNewRequest;
  final void Function(Map<String, dynamic> result) onRequestTap;
  final VoidCallback onProfileTap;
  final void Function(String agentKey) onAgentDetail;

  const _ShellScreen({
    required this.onNewRequest,
    required this.onRequestTap,
    required this.onProfileTap,
    required this.onAgentDetail,
  });

  @override
  State<_ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<_ShellScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DashboardScreen(
        onNewRequest: widget.onNewRequest,
        onRequestTap: widget.onRequestTap,
        onProfileTap: () => setState(() => _tab = 3),
      ),
      ActivityScreen(onRequestTap: widget.onRequestTap),
      AgentListScreen(onAgentTap: widget.onAgentDetail),
      ProfileScreen(onLogout: () {
        AuthService.instance.signOut();
      }),
    ];

    return Scaffold(
      extendBody: true, // Allow content to flow under the floating nav
      body: IndexedStack(index: _tab, children: tabs),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: C.surf0.withOpacity(0.95), // Semi-transparent for modern feel
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
              border: Border.all(color: C.surf3, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavItem(
                  icon:       Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  active: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                _NavItem(
                  icon:       Icons.history_outlined,
                  activeIcon: Icons.history_rounded,
                  label: 'History',
                  active: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
                _NavItem(
                  icon:       Icons.smart_toy_outlined,
                  activeIcon: Icons.smart_toy_rounded,
                  label: 'Agents',
                  active: _tab == 2,
                  onTap: () => setState(() => _tab = 2),
                ),
                _NavItem(
                  icon:       Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  active: _tab == 3,
                  onTap: () => setState(() => _tab = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav item ──────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: active ? 18 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: active ? C.teal50 : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 24,
              color: active ? C.teal700 : C.textTertiary,
            ),
            if (active) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: C.teal700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}