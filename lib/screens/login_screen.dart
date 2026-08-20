import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import 'vendor_register_screen.dart';
import '../widgets/app_loading.dart';
import 'app_lock_screen.dart';
import 'setup_pin_screen.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _referralController = TextEditingController();
  bool _otpSent = false;
  String _userType = 'user'; // 'user' or 'vendor'
  bool _isReferralLocked = false;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _checkReferralCode();
    _initAppLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _initAppLinks() async {
    _appLinks = AppLinks();

    // Check initial link if app was in cold state (terminated)
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint("Failed to get initial link: $e");
    }

    // Handle link when app is in warm state (foreground or background)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint("Failed to handle deep link: $err");
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.queryParameters.containsKey('ref')) {
      final refCode = uri.queryParameters['ref'];
      if (refCode != null && refCode.isNotEmpty && mounted) {
        setState(() {
          _referralController.text = refCode;
          _isReferralLocked = true;
          _userType = 'user';
        });
      }
    }
  }

  Future<void> _checkReferralCode() async {
    String? refCode;
    
    // Check URL parameters for web
    try {
      if (Uri.base.queryParameters.containsKey('ref')) {
        refCode = Uri.base.queryParameters['ref'];
      }
    } catch (e) {
      // Ignore UnsupportedError on mobile platforms
    }

    // Check Clipboard
    if (refCode == null || refCode.isEmpty) {
      try {
        ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
        if (data != null && data.text != null) {
          String text = data.text!;
          if (text.contains('ref=')) {
            refCode = text.split('ref=').last.split('&').first.split(' ').first;
          } else if (text.startsWith('USR') || text.startsWith('VND')) {
            refCode = text.trim();
          }
        }
      } catch (e) {
        // Ignore clipboard errors
      }
    }

    if (refCode != null && refCode.isNotEmpty) {
      if (mounted) {
        setState(() {
          _referralController.text = refCode!;
          _isReferralLocked = true;
        });
      }
    }
  }

  void _sendOtp() async {
    final api = context.read<ApiService>();
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter phone number')));
      return;
    }
    final res = await api.sendOtp(_phoneController.text, _userType);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      
      // Auto-fill OTP in development mode
      if (res['otp_dev'] != null) {
        _otpController.text = res['otp_dev'];
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Error sending OTP'), backgroundColor: Colors.red));
    }
  }

  void _verifyOtp() async {
    final api = context.read<ApiService>();
    if (_otpController.text.isEmpty) return;
    
    final res = await api.verifyOtp(
      _phoneController.text, 
      _otpController.text, 
      _userType,
      name: _nameController.text.isNotEmpty ? _nameController.text : null,
      referralCode: _referralController.text.isNotEmpty ? _referralController.text : null,
    );
    if (!mounted) return;
    if (res['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Invalid OTP'), backgroundColor: Colors.red));
    } else {
      bool hasPin = res['has_pin'] == true;
      if (hasPin) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppLockScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SetupPinScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ApiService>().isLoading;
    
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset('assets/JapSan.png', height: 250, width: 250, fit: BoxFit.cover)
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(duration: 3.seconds, color: Colors.white24),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'JAPSAN PAY',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 36, letterSpacing: 2),
                ).animate().fade().slideY(begin: 0.3, end: 0, duration: 500.ms),
                const SizedBox(height: 8),
                // Text(
                //   'Premium Gold Ecosystem',
                //   textAlign: TextAlign.center,
                //   style: Theme.of(context).textTheme.bodyMedium?.copyWith(letterSpacing: 1.5),
                // ).animate().fade(delay: 200.ms),
                const SizedBox(height: 50),
                
                // Toggle User Type
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _userType = 'user'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _userType == 'user' ? AppTheme.primaryGold.withAlpha(51) : Colors.transparent,
                            border: Border(bottom: BorderSide(color: _userType == 'user' ? AppTheme.primaryGold : Colors.transparent, width: 2)),
                          ),
                          child: Center(
                            child: Text('User Login', style: TextStyle(color: _userType == 'user' ? AppTheme.primaryGold : Colors.white54, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _userType = 'vendor'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _userType == 'vendor' ? AppTheme.primaryGold.withAlpha(51) : Colors.transparent,
                            border: Border(bottom: BorderSide(color: _userType == 'vendor' ? AppTheme.primaryGold : Colors.transparent, width: 2)),
                          ),
                          child: Center(
                            child: Text('Vendor Login', style: TextStyle(color: _userType == 'vendor' ? AppTheme.primaryGold : Colors.white54, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fade(delay: 300.ms),
                const SizedBox(height: 30),

                // Inputs
                TextField(
                  controller: _phoneController,
                  enabled: !_otpSent && !isLoading,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ).animate().fade(delay: 400.ms).slideX(begin: 0.1),

                if (_userType == 'user' && !_otpSent) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    enabled: !isLoading,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                    decoration: const InputDecoration(
                      labelText: 'Full Name (Optional for existing users)',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ).animate().fade(delay: 450.ms).slideX(begin: 0.1),
                  if (_isReferralLocked) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _referralController,
                      enabled: false,
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                      decoration: const InputDecoration(
                        labelText: 'Referral Code (Applied via Link)',
                        prefixIcon: Icon(Icons.local_activity, color: AppTheme.primaryGold),
                      ),
                    ).animate().fade(delay: 500.ms).slideX(begin: 0.1),
                  ],
                ],
                
                if (_otpSent) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _otpController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    obscuringCharacter: '●',
                    maxLength: 6,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, letterSpacing: 12),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: '6-Digit OTP',
                      prefixIcon: Icon(Icons.lock_outline),
                      counterText: '',
                    ),
                  ).animate().fade().slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading ? null : _sendOtp,
                      child: const Text('Resend OTP', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                    ),
                  ).animate().fade(),
                ],
                const SizedBox(height: 40),
                
                ElevatedButton(
                  onPressed: isLoading ? null : (_otpSent ? _verifyOtp : _sendOtp),
                  child: isLoading 
                    ? const SizedBox(height: 24, width: 24, child: AppLoading(size: 24))
                    : Text(_otpSent ? 'VERIFY OTP' : 'SEND OTP'),
                ).animate().scale(delay: 500.ms),
                
                if (_userType == 'vendor') ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorRegisterScreen())),
                    child: const Text('New Vendor? Register Here', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                  ).animate().fade(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
