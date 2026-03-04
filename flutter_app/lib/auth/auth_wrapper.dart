import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/pages/homepage.dart';
import 'package:flutter_app/pages/onboarding_page.dart';
import 'login_page.dart';
import 'signup_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool showLogin = false;
  bool? _onboardingComplete;
  bool _checkingOnboarding = false;

  Future<void> _checkOnboardingStatus(String userId) async {
    if (_checkingOnboarding) return;
    _checkingOnboarding = true;

    try {
      final profile = await Supabase.instance.client
          .from('patient_profiles')
          .select('onboarding_complete')
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _onboardingComplete = profile?['onboarding_complete'] == true;
          _checkingOnboarding = false;
        });
      }
    } catch (e) {
      // table might not exist yet or other error, show onboarding
      if (mounted) {
        setState(() {
          _onboardingComplete = false;
          _checkingOnboarding = false;
        });
      }
    }
  }

  void _completeOnboarding() {
    setState(() => _onboardingComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;

        // logged in
        if (session != null) {
          // check onboarding status
          if (_onboardingComplete == null && !_checkingOnboarding) {
            _checkOnboardingStatus(session.user.id);
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // still checking
          if (_onboardingComplete == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // needs onboarding
          if (_onboardingComplete == false) {
            return OnboardingPage(onComplete: _completeOnboarding);
          }

          // all good, go to home
          return const HomePage();
        }

        // reset onboarding check when logged out
        if (_onboardingComplete != null) {
          _onboardingComplete = null;
        }

        // logged out - show login or signup
        return showLogin
            ? LoginPage(onSwitch: () => setState(() => showLogin = false))
            : SignupPage(onSwitch: () => setState(() => showLogin = true));
      },
    );
  }
}
