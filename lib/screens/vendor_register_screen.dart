import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme.dart';
import '../core/api_service.dart';

class VendorRegisterScreen extends StatefulWidget {
  const VendorRegisterScreen({super.key});

  @override
  State<VendorRegisterScreen> createState() => _VendorRegisterScreenState();
}

class _VendorRegisterScreenState extends State<VendorRegisterScreen> {
  int _step = 0;
  bool _isLoading = false;
  bool _otpSent = false;

  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  final Map<String, TextEditingController> _ctrls = {
    'business_name': TextEditingController(),
    'owner_name': TextEditingController(),
    'email': TextEditingController(),
    'business_type': TextEditingController(),
    'business_address': TextEditingController(),
    'city': TextEditingController(),
    'state': TextEditingController(),
    'pincode': TextEditingController(),
    'gst_number': TextEditingController(),
    'pan_number': TextEditingController(),
    'bank_account_number': TextEditingController(),
    'bank_ifsc': TextEditingController(),
    'bank_name': TextEditingController(),
    'whatsapp_number': TextEditingController(),
    'referral_code': TextEditingController(),
    'cashback_percent': TextEditingController(text: '10'),
  };

  double? _lat;
  double? _lng;

  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter 10-digit phone number')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final res = await context.read<ApiService>().sendOtp(
      _phoneCtrl.text,
      'vendor',
      purpose: 'register',
    );
    setState(() => _isLoading = false);
    if (res['success'] == true) {
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP sent!')));
      if (res['otp_dev'] != null) {
        _otpCtrl.text = res['otp_dev'].toString();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to send OTP')),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    final res = await context.read<ApiService>().verifyOtp(
      _phoneCtrl.text,
      _otpCtrl.text,
      'vendor',
      purpose: 'register',
    );
    setState(() => _isLoading = false);

    // Even if it fails (maybe already registered), we allow them to proceed or we can strict block
    if (res['success'] == true) {
      setState(() => _step = 1);
    } else {
      setState(
        () => _step = 1,
      ); // Allow them to register anyway based on React logic
    }
  }

  Future<void> _getLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied)
          throw Exception('Permission denied');
      }
      Position pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Location captured!')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to get location')));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _register() async {
    if (_ctrls['business_name']!.text.isEmpty || _ctrls['city']!.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business name and city are required')),
      );
      return;
    }
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Location is required')));
      await _getLocation();
      return;
    }

    setState(() => _isLoading = true);
    final data = {'phone': _phoneCtrl.text, 'lat': _lat, 'lng': _lng};
    _ctrls.forEach((k, v) => data[k] = v.text);

    final res = await context.read<ApiService>().registerVendor(data);
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vendor registered!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryNavy,
      appBar: AppBar(title: const Text('Vendor Registration', style: TextStyle(color: Colors.white)), backgroundColor: AppTheme.primaryNavy, iconTheme: const IconThemeData(color: Colors.white)),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.premiumGold),
        ),
        child: Stepper(
        currentStep: _step,
        onStepContinue: () {
          if (_step == 0) {
            if (!_otpSent)
              _sendOtp();
            else
              _verifyOtp();
          } else if (_step == 1) {
            setState(() => _step = 2);
          } else {
            _register();
          }
        },
        onStepCancel: () {
          if (_step > 0)
            setState(() => _step -= 1);
          else
            Navigator.pop(context);
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _isLoading ? null : details.onStepContinue,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            _step == 0
                                ? (!_otpSent
                                      ? 'Send OTP'
                                      : 'Verify OTP')
                                : (_step == 2 ? 'Register' : 'Next'),
                          ),
                  ),
                ),
                if (_step > 0) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isLoading ? null : details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text(
              'Verify Phone',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              children: [
                _buildField('Phone Number', _phoneCtrl, TextInputType.phone),
                if (_otpSent || _isLoading)
                  const SizedBox(height: 12),
                if (_otpSent) ...[
                  _buildField('6-Digit OTP', _otpCtrl, TextInputType.number),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      child: const Text('Resend OTP', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
            isActive: _step >= 0,
            state: _step > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text(
              'Business Info',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              children: [
                _buildField('Business Name *', _ctrls['business_name']!),
                _buildField('Owner Name *', _ctrls['owner_name']!),
                _buildField('City *', _ctrls['city']!),
                _buildField('State *', _ctrls['state']!),
                _buildField(
                  'Cashback Percent (1-20)',
                  _ctrls['cashback_percent']!,
                  TextInputType.number,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _getLocation,
                  icon: const Icon(Icons.location_on),
                  label: Text(
                    _lat == null
                        ? 'Get GPS Location'
                        : 'Location Captured: $_lat, $_lng',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _lat == null
                        ? Colors.redAccent
                        : Colors.green,
                  ),
                ),
              ],
            ),
            isActive: _step >= 1,
            state: _step > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text(
              'Bank & KYC',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              children: [
                _buildField('GST Number', _ctrls['gst_number']!),
                _buildField('PAN Number', _ctrls['pan_number']!),
                _buildField(
                  'Bank Account Number',
                  _ctrls['bank_account_number']!,
                ),
                _buildField('IFSC Code', _ctrls['bank_ifsc']!),
                _buildField('Bank Name', _ctrls['bank_name']!),
              ],
            ),
            isActive: _step >= 2,
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, [
    TextInputType type = TextInputType.text,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textDim),
          filled: true,
          fillColor: AppTheme.surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
