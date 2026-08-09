import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../core/theme.dart';
import 'dashboard_screen.dart';

class SetupPinScreen extends StatefulWidget {
  const SetupPinScreen({super.key});
  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  bool _isLoading = false;

  void _setupPin() async {
    if (_pinCtrl.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN must be 4 digits')));
      return;
    }
    if (_pinCtrl.text != _confirmPinCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PINs do not match')));
      return;
    }

    setState(() => _isLoading = true);
    final api = context.read<ApiService>();
    try {
      final res = await api.post('/auth/set_pin.php', {'pin': _pinCtrl.text});
      setState(() => _isLoading = false);
      if (res['success'] == true) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const DashboardScreen())
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to set PIN')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error setting PIN')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryNavy,
      appBar: AppBar(title: const Text('Setup App PIN', style: TextStyle(color: Colors.white)), automaticallyImplyLeading: false, backgroundColor: AppTheme.primaryNavy),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Create a 4-digit PIN for App Lock and Payments', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 32),
            TextField(
              controller: _pinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              obscuringCharacter: '●',
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                labelText: 'Enter 4-Digit PIN',
                labelStyle: const TextStyle(color: AppTheme.textDim),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              obscuringCharacter: '●',
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                labelText: 'Confirm 4-Digit PIN',
                labelStyle: const TextStyle(color: AppTheme.textDim),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              onPressed: _isLoading ? null : _setupPin,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text('Set PIN & Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}
