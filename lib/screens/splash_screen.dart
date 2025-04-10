import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'admin_dashboard.dart';
import 'judge_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = GetIt.instance<AuthService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  Future<void> _checkAuthState() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        if (!mounted) return;
        _navigateToLogin();
        return;
      }

      final userModel = await _authService.getUserById(user.uid);
      if (!mounted) return;

      if (userModel == null) {
        _navigateToLogin();
        return;
      }

      _navigateToDashboard(userModel);
    } catch (e) {
      if (!mounted) return;
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _navigateToDashboard(UserModel userModel) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => userModel.role == UserRole.admin
            ? const AdminDashboard()
            : const JudgeDashboard(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
