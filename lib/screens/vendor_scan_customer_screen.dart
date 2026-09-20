import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/api_service.dart';
import '../core/theme.dart';
import 'buy_coins_screen.dart';

class VendorScanCustomerScreen extends StatefulWidget {
  const VendorScanCustomerScreen({super.key});

  @override
  State<VendorScanCustomerScreen> createState() => _VendorScanCustomerScreenState();
}

class _VendorScanCustomerScreenState extends State<VendorScanCustomerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Controllers
  final userPhoneCtrl = TextEditingController();
  final rewardCoinsCtrl = TextEditingController();
  final rewardNoteCtrl = TextEditingController();
  
  final billAmountCtrl = TextEditingController();
  final coinsToUseCtrl = TextEditingController();
  final manualBonusCtrl = TextEditingController();

  bool isLoading = false;
  bool _showScanner = false;
  Map<String, dynamic>? _customerDetails;
  Map<String, dynamic>? _walletData;
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchWallet();
  }

  @override
  void dispose() {
    _tabController.dispose();
    userPhoneCtrl.dispose();
    rewardCoinsCtrl.dispose();
    rewardNoteCtrl.dispose();
    billAmountCtrl.dispose();
    coinsToUseCtrl.dispose();
    manualBonusCtrl.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _fetchWallet() async {
    final res = await context.read<ApiService>().getWallet();
    if (res['success'] == true && mounted) {
      setState(() => _walletData = res['data']);
    }
  }

  double get _vendorBalance {
    final bal = _walletData?['wallet']?['coin_balance']?.toString() ?? '0';
    return double.tryParse(bal) ?? 0.0;
  }

  Future<void> _fetchCustomerDetails(String query) async {
    final clean = query.trim().replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return;
    setState(() => isLoading = true);
    final res = await context.read<ApiService>().scanVendorQR(clean);
    setState(() {
      isLoading = false;
      if (res['success'] == true && res['data'] != null && res['data']['user'] != null) {
        _customerDetails = res['data']['user'];
        userPhoneCtrl.text = _customerDetails!['phone'] ?? clean;
      } else {
        _customerDetails = null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Customer not found (will be auto-registered on reward)'))
        );
      }
    });
  }

  // Handle Direct Reward (Send Coins from Wallet)
  Future<void> _sendDirectReward() async {
    final cleanPhone = userPhoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty || cleanPhone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit customer mobile number'))
      );
      return;
    }

    final coins = double.tryParse(rewardCoinsCtrl.text) ?? 0.0;
    if (coins <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the number of coins to give'))
      );
      return;
    }

    if (coins > _vendorBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Insufficient balance! You have ${_vendorBalance.toStringAsFixed(0)} JC in your wallet.'))
      );
      return;
    }

    setState(() => isLoading = true);

    final payload = {
      'user_phone': cleanPhone,
      'bill_amount': 0,
      'manual_bonus_coins': coins,
      'payment_method': 'cash',
      'note': rewardNoteCtrl.text.trim().isNotEmpty ? rewardNoteCtrl.text.trim() : 'Direct Vendor Reward'
    };

    final res = await context.read<ApiService>().processVendorPayment(payload);
    setState(() => isLoading = false);

    if (res['success'] == true) {
      await _fetchWallet();
      if (mounted) {
        _showSuccessDialog(
          title: 'Reward Sent Successfully! 🎉',
          coinsGiven: coins,
          ref: res['data']?['transaction_ref'] ?? '',
          isDirect: true,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to send reward'), backgroundColor: Colors.red)
        );
      }
    }
  }

  // Handle Counter Billing & Cashback
  Future<void> _processBillPayment() async {
    final cleanPhone = userPhoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty || cleanPhone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit customer mobile number'))
      );
      return;
    }

    final bill = double.tryParse(billAmountCtrl.text) ?? 0.0;
    if (bill <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid bill amount'))
      );
      return;
    }

    setState(() => isLoading = true);

    final payload = {
      'user_phone': cleanPhone,
      'bill_amount': bill,
      'coins_to_use': double.tryParse(coinsToUseCtrl.text) ?? 0,
      'manual_bonus_coins': double.tryParse(manualBonusCtrl.text) ?? 0,
      'payment_method': 'cash'
    };

    final res = await context.read<ApiService>().processVendorPayment(payload);
    setState(() => isLoading = false);

    if (res['success'] == true) {
      await _fetchWallet();
      if (mounted) {
        _showSuccessDialog(
          title: 'Bill & Cashback Processed! ✅',
          coinsGiven: double.tryParse(res['data']?['cashback_coins']?.toString() ?? '0') ?? 0,
          ref: res['data']?['transaction_ref'] ?? '',
          isDirect: false,
          billAmount: bill,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to process bill'), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _showScanner = false);
        String scannedId = '';
        try {
          final data = jsonDecode(barcode.rawValue!);
          if (data['user_id'] != null) {
            scannedId = data['user_id'].toString();
          } else if (data['phone'] != null) {
            scannedId = data['phone'].toString();
          } else {
            scannedId = barcode.rawValue!;
          }
        } catch (e) {
          scannedId = barcode.rawValue!;
        }
        userPhoneCtrl.text = scannedId;
        _fetchCustomerDetails(scannedId);
        break;
      }
    }
  }

  void _showSuccessDialog({
    required String title,
    required double coinsGiven,
    required String ref,
    required bool isDirect,
    double billAmount = 0,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0x202E9E4D),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 50),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Coins Rewarded:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      Text('+${coinsGiven.toStringAsFixed(0)} JC 🪙', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success, fontSize: 15)),
                    ],
                  ),
                  if (!isDirect && billAmount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Bill Amount:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        Text('₹${billAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Remaining Wallet:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      Text('${_vendorBalance.toStringAsFixed(0)} JC', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.premiumGold, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            if (ref.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Ref: $ref', style: const TextStyle(fontSize: 11, color: AppTheme.textLight, fontFamily: 'monospace')),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  userPhoneCtrl.clear();
                  rewardCoinsCtrl.clear();
                  rewardNoteCtrl.clear();
                  billAmountCtrl.clear();
                  coinsToUseCtrl.clear();
                  manualBonusCtrl.clear();
                  setState(() => _customerDetails = null);
                },
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Text('Customer Rewards & Billing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vendor Live Balance Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F2247), Color(0xFF1D376B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryNavy.withAlpha(40), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(child: Text('🪙', style: TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Coin Wallet Balance', style: TextStyle(color: Color(0xFFE7C46A), fontSize: 11, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('${_vendorBalance.toStringAsFixed(0)} JC', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.premiumGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BuyCoinsScreen())).then((_) => _fetchWallet()),
                    child: const Text('+ Buy Coins', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab Bar Switcher
            Container(
              decoration: BoxDecoration(
                color: AppTheme.secondaryBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.primaryNavy,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: '🎁 Give Direct Coins'),
                  Tab(text: '🧾 Bill & Cashback'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // QR Scanner Box (if open)
            if (_showScanner) ...[
              Container(
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.premiumGold, width: 2),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red, size: 28),
                        onPressed: () => setState(() => _showScanner = false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Customer Phone / Verification
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Customer Mobile Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                      InkWell(
                        onTap: () => setState(() => _showScanner = !_showScanner),
                        child: Row(
                          children: [
                            Icon(Icons.qr_code_scanner, size: 16, color: AppTheme.premiumGold),
                            const SizedBox(width: 4),
                            Text(_showScanner ? 'Close Scanner' : 'Scan QR', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.premiumGold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.lightBorder),
                        ),
                        child: const Text('+91', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: userPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          decoration: const InputDecoration(
                            hintText: '10-digit mobile number',
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isLoading ? null : () => _fetchCustomerDetails(userPhoneCtrl.text),
                        child: const Text('Verify'),
                      ),
                    ],
                  ),
                  if (_customerDetails != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0x152E9E4D),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.success.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, color: AppTheme.success, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_customerDetails!['name']} (${_customerDetails!['city'] ?? 'Customer'})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // TAB CONTENT
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                if (_tabController.index == 0) {
                  // TAB 1: GIVE DIRECT REWARD COINS
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0x15C89B3C),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.premiumGold.withAlpha(60)),
                          ),
                          child: const Row(
                            children: [
                              Text('💡', style: TextStyle(fontSize: 18)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Reward coins are deducted directly from your coin balance. No UPI/Card payment needed!',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF6E5114)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Coins to Give (JC 🪙)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: rewardCoinsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Enter number of coins',
                            suffixText: 'JC 🪙',
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Quick Coin Presets
                        Row(
                          children: [10, 25, 50, 100, 250].map((amt) {
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    side: const BorderSide(color: AppTheme.lightBorder),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => rewardCoinsCtrl.text = amt.toString(),
                                  child: Text('+$amt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Text('Reward Reason (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: rewardNoteCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Regular customer bonus, store gift',
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryNavy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: isLoading ? null : _sendDirectReward,
                            icon: const Icon(Icons.card_giftcard, color: AppTheme.premiumGold),
                            label: Text(isLoading ? 'Sending...' : 'Send Coins from Wallet', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // TAB 2: STORE COUNTER BILLING & CASHBACK
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0x152D7FF9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.info.withAlpha(60)),
                          ),
                          child: const Row(
                            children: [
                              Text('🧾', style: TextStyle(fontSize: 18)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Bill customer in-store. Cash is collected at counter and cashback coins are credited from your wallet!',
                                  style: TextStyle(fontSize: 12, color: AppTheme.primaryNavy),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Total Bill Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: billAmountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            prefixText: '₹ ',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Customer Coins to Redeem (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: coinsToUseCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Coins for discount (1 JC = ₹0.70)',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Extra Bonus Cashback Coins (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: manualBonusCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Additional bonus coins',
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryNavy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: isLoading ? null : _processBillPayment,
                            icon: const Icon(Icons.check_circle_outline, color: AppTheme.premiumGold),
                            label: Text(isLoading ? 'Processing...' : 'Complete Bill & Give Cashback', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
