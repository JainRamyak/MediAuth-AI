import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

// ── Agent display name map ────────────────────────────────────────────────────

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
    statusBarColor:           Colors.transparent,
    statusBarIconBrightness:  Brightness.light, // white icons over dark header
  ));
  await dotenv.load(fileName: '.env');
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
  shell,
  newRequest,
  promptCustom,
  pipeline,
  approved,
  denied,
  agentDetail,
}

// ── Root ──────────────────────────────────────────────────────────────────────

class _AppRoot extends StatefulWidget {
  const _AppRoot();
  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  _Screen _screen = _Screen.splash;

  PatientFormData      _patient   = PatientFormData();
  TreatmentFormData    _treatment = TreatmentFormData();
  PromptSubmitPayload? _payload;
  int _intakeStep = 1;

  Map<String, dynamic> _apiResult = {};

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
          _go(data.user != null ? _Screen.shell : _Screen.login);
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

      _Screen.resetPassword => const Scaffold(
        body: Center(child: Text('Reset not implemented')),
      ),

      _Screen.shell => _ShellScreen(
        onNewRequest:  _startNewRequest,
        onRequestTap:  _openResult,
        onProfileTap:  () {},
        onAgentDetail: (key) {
          _agentKey         = key;
          _agentDisplayName = _agentDisplayNames[key] ?? key;
          _go(_Screen.agentDetail);
        },
      ),

      _Screen.newRequest => _buildIntake(),

      _Screen.promptCustom => PromptCustomizationScreen(
        patient:   _patient,
        treatment: _treatment,
        onBack:    () => setState(() { _intakeStep = 3; _screen = _Screen.newRequest; }),
        onSubmit:  (payload) { _payload = payload; _go(_Screen.pipeline); },
      ),

      _Screen.pipeline => AgentPipelineScreen(
        patient:    _patient,
        treatment:  _treatment,
        payload:    _payload,
        onApproved: (r) { _apiResult = r; _go(_Screen.approved); },
        onDenied:   (r) { _apiResult = r; _go(_Screen.denied);   },
      ),

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

      _Screen.agentDetail => PromptEditorScreen(
        agentKey:    _agentKey,
        displayName: _agentDisplayName,
        onBack:      () => _go(_Screen.shell),
      ),
    };

    return Scaffold(
      backgroundColor: C.surf1,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve:  Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (w, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end:   Offset.zero,
                ).animate(anim),
                child: w,
              ),
            ),
            child: KeyedSubtree(key: ValueKey(_screen), child: child),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _startNewRequest() => setState(() {
    _patient    = PatientFormData();
    _treatment  = TreatmentFormData();
    _payload    = null;
    _intakeStep = 1;
    _screen     = _Screen.newRequest;
  });

  void _openResult(Map<String, dynamic> raw) {
    _apiResult = raw;
    final status = (raw['workflow_status'] ?? '').toString().toLowerCase();
    _go(status.contains('approved') ? _Screen.approved : _Screen.denied);
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
      patient:     _patient,
      treatment:   _treatment,
      onBack:      () => setState(() => _intakeStep = 2),
      onSubmit:    () => _go(_Screen.pipeline),
      onCustomize: () => _go(_Screen.promptCustom),
    ),
  };
}

// ── 4-Tab Shell ───────────────────────────────────────────────────────────────

class _ShellScreen extends StatefulWidget {
  final VoidCallback onNewRequest;
  final void Function(Map<String, dynamic>) onRequestTap;
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
        onProfileTap: () => setState(() => _tab = 4),
      ),
      ActivityScreen(onRequestTap: widget.onRequestTap),
      const Scaffold(body: Center(child: Text('New Request Placeholder'))), // Center tab (not used directly)
      AgentListScreen(onAgentTap: widget.onAgentDetail),
      ProfileScreen(onLogout: () => AuthService.instance.signOut()),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _tab, children: tabs),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 10),
        width: 64, height: 64,
        child: FloatingActionButton(
          onPressed: widget.onNewRequest,
          backgroundColor: C.primary500,
          elevation: 8,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
      bottomNavigationBar: Container(
        height: 80 + MediaQuery.of(context).padding.bottom,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: BottomAppBar(
          padding: EdgeInsets.zero,
          color: Colors.white,
          elevation: 0,
          notchMargin: 10,
          shape: const CircularNotchedRectangle(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, active: _tab == 0, onTap: () => setState(() => _tab = 0)),
              _NavItem(icon: Icons.history_rounded, active: _tab == 1, onTap: () => setState(() => _tab = 1)),
              const SizedBox(width: 48), // Space for FAB
              _NavItem(icon: Icons.chat_bubble_outline_rounded, active: _tab == 3, onTap: () => setState(() => _tab = 3)),
              _NavItem(icon: Icons.person_rounded, active: _tab == 4, onTap: () => setState(() => _tab = 4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          size: 26,
          color: active ? C.primary500 : C.textTertiary,
        ),
      ),
    );
  }
}
