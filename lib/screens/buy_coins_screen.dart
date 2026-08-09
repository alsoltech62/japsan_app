import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../core/theme.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class BuyCoinsScreen extends StatefulWidget {
  const BuyCoinsScreen({super.key});

  @override
  State<BuyCoinsScreen> createState() => _BuyCoinsScreenState();
}

class _BuyCoinsScreenState extends State<BuyCoinsScreen> {
  final List<Map<String, dynamic>> packages = [
    {'coins': 100, 'bonus': 0, 'label': 'Starter', 'popular': false},
    {'coins': 500, 'bonus': 0, 'label': 'Regular', 'popular': false},
    {'coins': 1000, 'bonus': 100, 'label': 'Popular', 'popular': true},
    {'coins': 2000, 'bonus': 200, 'label': 'Pro', 'popular': false},
    {'coins': 5000, 'bonus': 500, 'label': 'Premium', 'popular': false},
  ];

  Map<String, dynamic>? _selectedPkg;
  final _customCtrl = TextEditingController();
  late Razorpay _razorpay;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isLoading = true);
    final payload = {
      'coins_requested': _coins,
      'razorpay_payment_id': response.paymentId,
      'razorpay_order_id': response.orderId,
      'razorpay_signature': response.signature,
    };

    final res = await context.read<ApiService>().buyCoins(payload);
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      if (mounted) _showSuccessDialog(res['data'] ?? {});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Verification failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Razorpay Error'),
        content: Text('Code: ${response.code}\nMessage: ${response.message}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  int get _coins => _selectedPkg != null
      ? _selectedPkg!['coins']
      : (int.tryParse(_customCtrl.text) ?? 0);
  int get _bonus => _selectedPkg != null ? _selectedPkg!['bonus'] : 0;
  int get _total => _coins + _bonus;

  Future<void> _buyCoins() async {
    if (_coins < 10) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter at least 10 coins')));
      return;
    }

    setState(() => _isLoading = true);

    // Create Razorpay order first
    final orderRes = await context.read<ApiService>().createRazorpayOrder({
      'amount_inr': _coins,
    });

    setState(() => _isLoading = false);

    if (orderRes['success'] == true) {
      final orderData = orderRes['data'];
      var options = {
        'key': 'rzp_live_TN8KciymYkApmH',
        'name': 'Japsan Pay',
        'description': 'Purchase of $_coins coins',
        'order_id': orderData['order_id'],
        'prefill': {'contact': '9999999999', 'email': 'user@example.com'},
        'theme': {'color': '#f97316'},
      };

      debugPrint('Razorpay Options: $options');

      try {
        _razorpay.open(options);
      } catch (e) {
        debugPrint('Error launching Razorpay: $e');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              orderRes['message'] ?? 'Failed to create payment order',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            const Text(
              'Coins Purchased!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${data['total_coins'] ?? _total}',
              style: const TextStyle(
                color: AppTheme.primaryGold,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Total Coins Added',
              style: TextStyle(color: AppTheme.textDim),
            ),
            if ((data['bonus_coins'] ?? _bonus) > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${data['bonus_coins'] ?? _bonus} Bonus Coins!',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  Navigator.pop(ctx); // close dialog
                  Navigator.pop(context); // go back
                },
                child: const Text(
                  'OK',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
      appBar: AppBar(title: const Text('Buy Coins')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          const Text(
            'Select Package',
            style: TextStyle(
              color: AppTheme.textDim,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: packages.length,
            itemBuilder: (ctx, i) {
              final pkg = packages[i];
              final isSelected = _selectedPkg == pkg;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPkg = pkg;
                    _customCtrl.clear();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryGold.withAlpha(20)
                        : AppTheme.surfaceDark,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryGold
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${pkg['coins']} 🪙',
                            style: const TextStyle(
                              color: AppTheme.primaryNavy,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (pkg['bonus'] > 0)
                            Text(
                              '+${pkg['bonus']} bonus!',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            '= ₹${pkg['coins']}',
                            style: const TextStyle(
                              color: AppTheme.textDim,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            pkg['label'],
                            style: const TextStyle(
                              color: AppTheme.textDim,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      if (pkg['popular'] == true)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'POPULAR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          const Text(
            'Or enter custom amount',
            style: TextStyle(
              color: AppTheme.textDim,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _customCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.primaryNavy),
            onChanged: (v) {
              if (v.isNotEmpty)
                setState(() => _selectedPkg = null);
              else
                setState(() {}); // Update total
            },
            decoration: InputDecoration(
              hintText: 'Enter coins (min 10)',
              hintStyle: const TextStyle(color: AppTheme.textLight),
              filled: true,
              fillColor: AppTheme.secondaryBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.lightBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.lightBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.premiumGold,
                  width: 2,
                ),
              ),
            ),
          ),

          if (_coins > 0) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryNavy.withAlpha(8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryNavy.withAlpha(30)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Coins',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      Text(
                        '$_coins',
                        style: const TextStyle(
                          color: AppTheme.primaryNavy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_bonus > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bonus Coins',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        Text(
                          '+$_bonus',
                          style: const TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  Divider(
                    color: AppTheme.primaryNavy.withAlpha(30),
                    height: 24,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Coins',
                        style: TextStyle(
                          color: AppTheme.primaryNavy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$_total 🪙',
                        style: const TextStyle(
                          color: AppTheme.premiumGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Amount to Pay',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      Text(
                        '₹$_coins',
                        style: const TextStyle(
                          color: AppTheme.primaryNavy,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isLoading || _coins == 0 ? null : _buyCoins,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.black)
                : Text(
                    'Buy $_total Coins',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
