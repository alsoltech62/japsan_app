import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../core/theme.dart';

class VendorAdvertisingScreen extends StatefulWidget {
  const VendorAdvertisingScreen({super.key});

  @override
  State<VendorAdvertisingScreen> createState() => _VendorAdvertisingScreenState();
}

class _VendorAdvertisingScreenState extends State<VendorAdvertisingScreen> {
  Map<String, dynamic>? adData;
  bool isLoading = true;
  bool isPurchasing = false;
  int selectedDays = 7;
  final TextEditingController _customDaysCtrl = TextEditingController();
  String paymentMethod = 'coins';

  @override
  void initState() {
    super.initState();
    _fetchAdStatus();
  }

  @override
  void dispose() {
    _customDaysCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAdStatus() async {
    final api = context.read<ApiService>();
    final res = await api.getVendorAdStatus();
    if (res['success'] == true && mounted) {
      setState(() => adData = res['data']);
    }
    if (mounted) setState(() => isLoading = false);
  }

  int get effectiveDays {
    if (_customDaysCtrl.text.trim().isNotEmpty) {
      return int.tryParse(_customDaysCtrl.text.trim()) ?? 1;
    }
    return selectedDays;
  }

  double get totalFee {
    final dailyFee = (adData?['daily_fee'] as num?)?.toDouble() ?? 50.0;
    final days = effectiveDays;
    double discount = 0.0;
    if (days >= 30) {
      discount = 0.15;
    } else if (days >= 15) {
      discount = 0.10;
    } else if (days >= 7) {
      discount = 0.05;
    }

    return (dailyFee * days * (1.0 - discount)).roundToDouble();
  }

  Future<void> _activateAd() async {
    final days = effectiveDays;
    if (days < 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least 1 day')));
      return;
    }

    final coinBalance = (adData?['coin_balance'] as num?)?.toDouble() ?? 0.0;
    if (paymentMethod == 'coins' && coinBalance < totalFee) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient JC coins! Required: ${totalFee.toInt()} JC, Available: ${coinBalance.toInt()} JC'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isPurchasing = true);
    final api = context.read<ApiService>();
    final res = await api.buyVendorAd(days, paymentMethod: paymentMethod);
    if (!mounted) return;
    setState(() => isPurchasing = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Boost activated!'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchAdStatus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to activate boost'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyFee = (adData?['daily_fee'] as num?)?.toDouble() ?? 50.0;
    final isSponsored = adData?['is_sponsored'] == true;
    final remainingDays = adData?['remaining_days'] ?? 0;
    final coinBalance = (adData?['coin_balance'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Store Advertising & Boost')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Highlight Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB8860B), Color(0xFFFFD700)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.workspace_premium, color: Colors.black, size: 24),
                          SizedBox(width: 8),
                          Text(
                            '👑 TOP 1-3 NEARBY RANKING',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Feature your store at the top of Nearby Stores within 50km radius with a shining Golden badge. Attract maximum customers!',
                        style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.3),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryGold.withAlpha(50)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current Status', style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(isSponsored ? Icons.check_circle : Icons.info_outline, color: isSponsored ? Colors.green : AppTheme.textDim, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                isSponsored ? 'ACTIVE ($remainingDays Days Left)' : 'Not Active',
                                style: TextStyle(
                                  color: isSponsored ? Colors.green : AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('JC Coin Balance', style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            '${coinBalance.toInt()} JC',
                            style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text('Select Duration (Days)', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Configured daily rate: ${dailyFee.toInt()} JC / Day', style: const TextStyle(color: AppTheme.textDim, fontSize: 12)),
                const SizedBox(height: 12),

                // Preset Duration Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.6,
                  children: [
                    _buildDurationCard(3, '3 Days Boost', (dailyFee * 3).toInt(), 0),
                    _buildDurationCard(7, '7 Days (Top 1-3)', (dailyFee * 7 * 0.95).toInt(), 5),
                    _buildDurationCard(15, '15 Days (Popular)', (dailyFee * 15 * 0.90).toInt(), 10),
                    _buildDurationCard(30, '30 Days (VIP)', (dailyFee * 30 * 0.85).toInt(), 15),
                  ],
                ),

                const SizedBox(height: 16),

                // Custom Days
                TextField(
                  controller: _customDaysCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Or Enter Custom Days (e.g. 10)',
                    labelStyle: const TextStyle(color: AppTheme.textDim),
                    filled: true,
                    fillColor: AppTheme.surfaceDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: _customDaysCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.textDim),
                            onPressed: () {
                              _customDaysCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 24),

                // Summary & Pay Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryGold),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Duration:', style: TextStyle(color: AppTheme.textDim)),
                          Text('$effectiveDays Days', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Fee:', style: TextStyle(color: AppTheme.textDim)),
                          Text('${totalFee.toInt()} JC Coins', style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isPurchasing ? null : _activateAd,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGold,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isPurchasing
                              ? const CircularProgressIndicator(color: Colors.black)
                              : Text(
                                  'ACTIVATE BOOST (${totalFee.toInt()} JC)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDurationCard(int days, String label, int fee, int discount) {
    final isSelected = _customDaysCtrl.text.isEmpty && selectedDays == days;
    return GestureDetector(
      onTap: () {
        _customDaysCtrl.clear();
        setState(() => selectedDays = days);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGold.withAlpha(40) : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGold : AppTheme.primaryGold.withAlpha(30),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$days Days', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                if (discount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
                    child: Text('$discount% OFF', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppTheme.textDim, fontSize: 11)),
            const SizedBox(height: 4),
            Text('$fee JC', style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
