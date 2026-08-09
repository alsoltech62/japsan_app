import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/api_service.dart';
import '../core/theme.dart';

class UserScanPayScreen extends StatefulWidget {
  const UserScanPayScreen({super.key});

  @override
  State<UserScanPayScreen> createState() => _UserScanPayScreenState();
}

class _UserScanPayScreenState extends State<UserScanPayScreen> {
  String _activeTab = 'scan';
  final TextEditingController _idCtrl = TextEditingController();
  final TextEditingController _billAmountCtrl = TextEditingController();
  final TextEditingController _coinsCtrl = TextEditingController();
  final TextEditingController _pinCtrl = TextEditingController();

  Map<String, dynamic>? _vendorDetails;
  Map<String, dynamic>? _userDetails;
  Map<String, dynamic>? _wallet;
  bool _isLoading = false;
  bool _showScanner = false;
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<ApiService>().userProfile;
      if (user?['name'] == null || user!['name'].toString().isEmpty || user['city'] == null || user['city'].toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please complete your profile (Name, City) to make payments'),
          backgroundColor: Colors.red,
        ));
        Navigator.pop(context);
      }
    });
  }

  Future<void> _handleScan(String query) async {
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter ID to scan')));
      return;
    }
    setState(() => _isLoading = true);
    final api = context.read<ApiService>();
    
    try {
      final res = await api.scanVendorQR(query);
      if (res['success'] == true) {
        final data = res['data'];
        if (data['vendor'] != null) {
          _vendorDetails = data['vendor'];
          _userDetails = null;
        } else if (data['user'] != null) {
          _userDetails = data['user'];
          _vendorDetails = null;
        }
        final wRes = await api.getWallet();
        if (wRes['success'] == true) {
          _wallet = wRes['data']['wallet'];
        }
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Not found')));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid QR or user/vendor not found')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _payVendor() async {
    if (_billAmountCtrl.text.isEmpty) return;
    if (_pinCtrl.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter 4-digit PIN')));
      return;
    }
    setState(() => _isLoading = true);
    final api = context.read<ApiService>();
    final payload = {
      'vendor_id': _vendorDetails!['id'],
      'bill_amount': double.tryParse(_billAmountCtrl.text) ?? 0,
      'coins_to_use': double.tryParse(_coinsCtrl.text) ?? 0,
      'payment_method': 'online',
      'pin': _pinCtrl.text
    };
    final res = await api.processUserPay(payload);
    setState(() => _isLoading = false);
    
    if (res['success'] == true) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Successful!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Payment failed'), backgroundColor: Colors.red));
    }
  }

  Future<void> _transferToUser() async {
    if (_billAmountCtrl.text.isEmpty) return;
    if (_pinCtrl.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter 4-digit PIN')));
      return;
    }
    setState(() => _isLoading = true);
    final api = context.read<ApiService>();
    final payload = {
      'receiver_id': _userDetails!['id'],
      'amount': double.tryParse(_billAmountCtrl.text) ?? 0,
      'pin': _pinCtrl.text
    };
    final res = await api.userTransfer(payload);
    setState(() => _isLoading = false);
    
    if (res['success'] == true) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer Successful!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Transfer failed'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ApiService>().userProfile;
    final qrValue = jsonEncode({'user_id': user?['id'], 'type': 'japsan_user_qr'});

    return Scaffold(
      appBar: AppBar(title: const Text('Scan & Pay')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = 'scan'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _activeTab == 'scan' ? AppTheme.primaryGold : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text('Scan QR', style: TextStyle(color: _activeTab == 'scan' ? Colors.black : AppTheme.textPrimary, fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = 'my_qr'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _activeTab == 'my_qr' ? AppTheme.primaryGold : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text('My QR', style: TextStyle(color: _activeTab == 'my_qr' ? Colors.black : AppTheme.textPrimary, fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: _activeTab == 'my_qr' 
                ? _buildMyQR(qrValue, user)
                : (_vendorDetails != null ? _buildVendorPayment() : (_userDetails != null ? _buildUserTransfer() : _buildScanner())),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMyQR(String qrValue, Map<String, dynamic>? user) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Show this QR to receive coins', style: TextStyle(color: AppTheme.textDim)),
        const SizedBox(height: 24),
        if (user?['profile_photo'] != null && user!['profile_photo'].toString().isNotEmpty)
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(user['profile_photo']),
          )
        else
          const CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.darkGold,
            child: Icon(Icons.person, color: AppTheme.primaryGold, size: 30),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primaryGold, width: 4),
          ),
          child: QrImageView(
            data: qrValue,
            version: QrVersions.auto,
            size: 200.0,
            foregroundColor: Colors.black,
          ),
        ),
        const SizedBox(height: 24),
        Text('Name: ${user?['name'] ?? 'Japsan User'}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Phone: ${user?['phone'] ?? ''}', style: const TextStyle(color: AppTheme.textDim, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppTheme.primaryGold.withAlpha(50), borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${user?['phone'] ?? ''}@japsan', style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: '${user?['phone'] ?? ''}@japsan'));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI ID copied to clipboard')));
                },
                child: const Icon(Icons.copy, size: 16, color: AppTheme.primaryGold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScanner() {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (_showScanner)
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(border: Border.all(color: AppTheme.primaryGold, width: 2), borderRadius: BorderRadius.circular(16)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: MobileScanner(
                      controller: _scannerController,
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          if (barcode.rawValue != null) {
                            setState(() => _showScanner = false);
                            _idCtrl.text = barcode.rawValue!;
                            _handleScan(barcode.rawValue!);
                            break;
                          }
                        }
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 30),
                  onPressed: () => setState(() => _showScanner = false),
                )
              ],
            )
          else
            GestureDetector(
              onTap: () => setState(() => _showScanner = true),
              child: Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(color: AppTheme.primaryGold.withAlpha(50), borderRadius: BorderRadius.circular(20)),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, size: 60, color: AppTheme.primaryGold),
                    SizedBox(height: 8),
                    Text('Tap to Scan QR', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold))
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 32),
          const Text('Or enter Vendor/User ID manually', style: TextStyle(color: AppTheme.textDim)),
          const SizedBox(height: 16),
          TextField(
            controller: _idCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.surfaceDark,
              hintText: 'Enter ID or Phone',
              hintStyle: const TextStyle(color: AppTheme.textDim),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            onPressed: _isLoading ? null : () => _handleScan(_idCtrl.text),
            child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text('PROCEED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }

  Widget _buildVendorPayment() {
    final addr = _vendorDetails!['address'];
    final city = _vendorDetails!['city'];
    final loc = [if (addr != null && addr.toString().isNotEmpty) addr, if (city != null && city.toString().isNotEmpty) city].join(', ');
    return _buildPaymentForm(
      icon: Icons.store,
      title: _vendorDetails!['business_name'] ?? _vendorDetails!['owner_name'],
      subtitle: loc.isEmpty ? 'Local Shop' : loc,
      isVendor: true,
      profilePhoto: _vendorDetails!['profile_photo'],
    );
  }

  Widget _buildUserTransfer() {
    return _buildPaymentForm(
      icon: Icons.person,
      title: _userDetails!['name'],
      subtitle: '${_userDetails!['phone']} • ${_userDetails!['city'] ?? ''}',
      isVendor: false
    );
  }

  Widget _buildPaymentForm({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isVendor,
    String? profilePhoto,
  }) {
    final maxCoins = double.tryParse(_wallet?['coin_balance']?.toString() ?? '0') ?? 0;
    return SingleChildScrollView(
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
              onPressed: () => setState(() { _vendorDetails = null; _userDetails = null; _idCtrl.clear(); }),
            ),
          ),
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primaryGold.withAlpha(50),
            backgroundImage: profilePhoto != null && profilePhoto.isNotEmpty ? NetworkImage(profilePhoto) : null,
            child: (profilePhoto == null || profilePhoto.isEmpty) ? Icon(icon, size: 40, color: AppTheme.primaryGold) : null,
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: AppTheme.textDim)),
          const SizedBox(height: 24),
          
          if (!isVendor)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.withAlpha(30), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Available Balance:', style: TextStyle(color: Colors.orange)),
                  Text('$maxCoins 🪙', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
          const SizedBox(height: 16),
          TextField(
            controller: _billAmountCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: isVendor ? 'Bill Amount (₹)' : 'Amount to Transfer (Coins)',
              labelStyle: const TextStyle(color: AppTheme.textDim, fontSize: 14),
              filled: true,
              fillColor: AppTheme.surfaceDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          
          if (isVendor) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _coinsCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18),
              decoration: InputDecoration(
                labelText: 'Use Coins (Max: $maxCoins)',
                labelStyle: const TextStyle(color: AppTheme.textDim, fontSize: 14),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixIcon: TextButton(
                  onPressed: () => _coinsCtrl.text = maxCoins.toString(),
                  child: const Text('MAX', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                )
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          TextField(
            controller: _pinCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            obscuringCharacter: '●',
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Enter 4-Digit PIN',
              labelStyle: const TextStyle(color: AppTheme.textDim, fontSize: 14, letterSpacing: 0),
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
            onPressed: _isLoading ? null : (isVendor ? _payVendor : _transferToUser),
            child: _isLoading 
              ? const CircularProgressIndicator(color: Colors.black) 
              : Text(isVendor ? 'Confirm Payment' : 'Send Coins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          )
        ],
      ),
    );
  }
}
