import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // keep for SystemChrome
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'theme/colors.dart';
import 'screens/s01_splash.dart';
import 'screens/s02_login.dart';
import 'screens/s02a_signup.dart';
import 'screens/s03_dashboard.dart';
import 'screens/s04_patient_info.dart';
import 'screens/s05_medical_info.dart';
import 'screens/s06_review_submit.dart';
import 'screens/s06b_prompt_customization.dart'; // ← NEW
import 'screens/s07_agent_pipeline.dart';
import 'screens/s08_approved.dart';
import 'screens/s09_denied.dart';
import 'screens/s10_s11_appeal.dart';
import 'screens/activity_screen.dart';
import 'screens/s00_profile.dart';
import 'screens/s12_agent_list.dart';
import 'screens/s_reset_password.dart'; // ← new screen

import 'widgets/shared_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    debug: false,
  );

  runApp(const MediAuthApp());
}

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

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

enum _Screen {
  splash,
  login,
  signup,
  shell,
  newRequest,
  promptCustomization, // ← NEW (Screen 6B)
  pipeline,
  approved,
  denied,
  appeal,
  escalation,
  profile,
  resetPassword, // ← new

}

class _AppRootState extends State<_AppRoot> {
  _Screen _screen = _Screen.splash;

  final _patient   = PatientFormData();
  final _treatment = TreatmentFormData();
  PromptSubmitPayload? _payload;
  int   _intakeStep = 1;

  /// Stores the raw API response from POST /api/v1/authorize.
  /// Populated by AgentPipelineScreen before navigating to the result screen.
  Map<String, dynamic>? _apiResult;


  void _go(_Screen s) => setState(() => _screen = s);

  // ── Auth state listener ──────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // supabase_flutter v2 automatically intercepts the deep-link callback
    // (via authCallbackUrlHostname in Supabase.initialize()) and fires
    // onAuthStateChange with AuthChangeEvent.signedIn — no custom channel needed.
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      switch (data.event) {
        // ── Existing session on cold start ────────────────────────────────
        case AuthChangeEvent.initialSession:
          if (data.session != null) {
            // User is already logged in → skip login entirely
            _go(_Screen.shell);
          }
          break;

        case AuthChangeEvent.passwordRecovery:
          _go(_Screen.resetPassword);
          break;

        case AuthChangeEvent.signedIn:
          // Fires after a fresh sign-in (email/password or OAuth callback).
          // Navigate to shell from any pre-auth screen.
          if (_screen != _Screen.shell) {
            _go(_Screen.shell);
          }
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
    return switch (_screen) {
      _Screen.splash => SplashScreen(
        onDone: () {
          // If an active session exists, go straight to shell
          final user = Supabase.instance.client.auth.currentUser;
          _go(user != null ? _Screen.shell : _Screen.login);
        },
      ),

      _Screen.login  => LoginScreen(
        onLogin:  () => _go(_Screen.shell),
        onSignUp: () => _go(_Screen.signup),
      ),

      _Screen.signup => SignUpScreen(
        onSignUpSuccess: () => _go(_Screen.shell),
        onSignIn: () => _go(_Screen.login),
      ),

      // ── New: Reset Password screen ─────────────────────────────────────

      _Screen.resetPassword => ResetPasswordScreen(
        onDone: () => _go(_Screen.login),
      ),

      _Screen.shell  => _ShellScreen(
        onNewRequest: () {
          _intakeStep = 1;
          _go(_Screen.newRequest);
        },
        onRequestTap: (r) {
          switch (r.status) {
            case AuthStatus.approved:  _go(_Screen.approved); break;
            case AuthStatus.denied:    _go(_Screen.denied); break;
            case AuthStatus.appealing: _go(_Screen.appeal); break;
            case AuthStatus.pending:
            case AuthStatus.submitted:
              _go(_Screen.pipeline); break;
          }
        },
        onProfileTap: () => _go(_Screen.profile),
      ),

      _Screen.newRequest => _buildIntake(),

      // ── Screen 6B — Prompt Customization (NEW) ─────────────────────────
      _Screen.promptCustomization => PromptCustomizationScreen(
        onBack: () {
          // Return to Screen 6 (review step, intakeStep = 3)
          setState(() {
            _intakeStep = 3;
            _screen = _Screen.newRequest;
          });
        },
        onSkip: () {
          _payload = null;
          _go(_Screen.pipeline);
        },
        onSubmit: (payload) {
          _payload = payload;
          _go(_Screen.pipeline);
        },
      ),

      _Screen.pipeline => AgentPipelineScreen(
        patient: _patient,
        treatment: _treatment,
        payload: _payload,
        onApproved: (result) {
          _apiResult = result;
          _go(_Screen.approved);
        },
        onDenied: (result) {
          _apiResult = result;
          _go(_Screen.denied);
        },
      ),

      _Screen.approved => ApprovedScreen(
        apiResult: _apiResult,
        onDone: () => _go(_Screen.shell)),

      _Screen.denied => DeniedScreen(
        apiResult: _apiResult,
        onAppeal:    () => _go(_Screen.appeal),
        onDashboard: () => _go(_Screen.shell),
      ),

      _Screen.appeal => AppealProgressScreen(
        level: 1,
        onEscalate: () => _go(_Screen.escalation),
        onDone: () => _go(_Screen.shell),
      ),

      _Screen.escalation => EscalationScreen(
        onDone: () => _go(_Screen.shell)),

      _Screen.profile => ProfileScreen(
        onLogout: () => _go(_Screen.login)),
    };
  }

  Widget _buildIntake() => switch (_intakeStep) {
    1 => PatientInfoScreen(
      data: _patient,
      onBack: () => _go(_Screen.shell),
      onNext: () => setState(() => _intakeStep = 2),
    ),
    2 => MedicalInfoScreen(
      data: _patient,
      onBack: () => setState(() => _intakeStep = 1),
      onNext: () => setState(() => _intakeStep = 3),
    ),
    _ => ReviewSubmitScreen(
      patient: _patient,
      treatment: _treatment,
      onBack: () => setState(() => _intakeStep = 2),
      onSubmit: () => _go(_Screen.pipeline),
      onEditStep: (s) => setState(() => _intakeStep = s),
      onCustomizePrompts: () => _go(_Screen.promptCustomization), // ← NEW
    ),
  };
}

// ── 3-Tab Shell ───────────────────────────────────────────────────────────────

class _ShellScreen extends StatefulWidget {
  final VoidCallback onNewRequest;
  final void Function(AuthRequest) onRequestTap;
  final VoidCallback onProfileTap;

  const _ShellScreen({
    required this.onNewRequest,
    required this.onRequestTap,
    required this.onProfileTap,
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
        onNewRequest:  widget.onNewRequest,
        onRequestTap:  widget.onRequestTap,
        onProfileTap:  widget.onProfileTap,
      ),
      ActivityScreen(onRequestTap: widget.onRequestTap),
      const AgentListScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: tabs),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 12, bottom: 24, left: 16, right: 16),
        decoration: const BoxDecoration(
          color: C.surf0,
          border: Border(top: BorderSide(color: C.surf3, width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavBarItem(
              icon: Icons.grid_view_rounded,
              label: 'Dashboard',
              isSelected: _tab == 0,
              onTap: () => setState(() => _tab = 0),
            ),
            _NavBarItem(
              icon: Icons.history_rounded,
              label: 'Activity',
              isSelected: _tab == 1,
              onTap: () => setState(() => _tab = 1),
            ),
            _NavBarItem(
              icon: Icons.smart_toy_outlined,
              label: 'AI Prompts',
              isSelected: _tab == 2,
              onTap: () => setState(() => _tab = 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? C.teal50 : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
              size: 22,
              color: isSelected ? C.teal700 : C.textTertiary),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(label,
                  style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: C.teal700)),
              ),
          ],
        ),
      ),
    );
  }
}