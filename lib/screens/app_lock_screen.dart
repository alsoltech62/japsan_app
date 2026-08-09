import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../core/theme.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'setup_pin_screen.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});
  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _pinCtrl = TextEditingController();
  bool _isLoading = false;

  void _verifyPin() async {
    if (_pinCtrl.text.length != 4) return;

    setState(() => _isLoading = true);
    final api = context.read<ApiService>();
    try {
      final res = await api.post('/auth/verify_pin.php', {'pin': _pinCtrl.text});
      setState(() => _isLoading = false);
      if (res['success'] == true) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const DashboardScreen())
        );
      } else {
        if (!mounted) return;
        if (res['pin_not_set'] == true) {
           Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SetupPinScreen()));
        } else {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Invalid PIN')));
           _pinCtrl.clear();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error verifying PIN')));
    }
  }

  void _logout() async {
    await context.read<ApiService>().logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF2A2411), AppTheme.backgroundDark],
            center: Alignment.topRight,
            radius: 1.5,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset('assets/JapSan.png', height: 200, width: 200, fit: BoxFit.cover),
                ),
                const SizedBox(height: 32),
                const Text('Enter App PIN', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('To unlock Japsan Pay', style: TextStyle(color: AppTheme.textDim, fontSize: 16)),
                const SizedBox(height: 48),
                TextField(
                  controller: _pinCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  obscuringCharacter: '●',
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 32, letterSpacing: 16),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.surfaceDark,
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) {
                    if (val.length == 4) _verifyPin();
                  },
                ),
                const SizedBox(height: 32),
                if (_isLoading) const CircularProgressIndicator(color: AppTheme.primaryGold),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: _logout,
                  child: const Text('Logout / Reset PIN', style: TextStyle(color: Colors.redAccent)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
