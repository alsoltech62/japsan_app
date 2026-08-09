import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../core/theme.dart';

class VendorWithdrawScreen extends StatefulWidget {
  const VendorWithdrawScreen({super.key});

  @override
  State<VendorWithdrawScreen> createState() => _VendorWithdrawScreenState();
}

class _VendorWithdrawScreenState extends State<VendorWithdrawScreen> {
  Map<String, dynamic>? wallet;
  List<dynamic> withdrawals = [];
  Map<String, dynamic> config = {};
  
  bool isLoading = true;
  bool isSubmitting = false;
  final TextEditingController amtCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final api = context.read<ApiService>();
    // Need to fetch both wallet and withdrawals
    final wRes = await api.getWallet();
    final wdRes = await api.getWithdrawals();
    
    if (mounted) {
      setState(() {
        if (wRes['success'] == true) {
          wallet = wRes['data']?['wallet'];
          config = {
            'fee': wRes['data']?['withdrawal_fee'] ?? 5,
            'min': wRes['data']?['min_withdrawal'] ?? 100
          };
        }
        if (wdRes['success'] == true) {
          withdrawals = wdRes['data']?['withdrawals'] ?? [];
        }
        isLoading = false;
      });
    }
  }

  Future<void> _submitWithdrawal() async {
    final amt = double.tryParse(amtCtrl.text) ?? 0;
    final min = double.tryParse(config['min']?.toString() ?? '100') ?? 100;
    final max = double.tryParse(wallet?['cash_wallet_balance']?.toString() ?? '0') ?? 0;

    if (amt < min) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Minimum withdrawal is ₹$min')));
      return;
    }
    if (amt > max) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient cash balance')));
      return;
    }

    setState(() => isSubmitting = true);
    final api = context.read<ApiService>();
    final res = await api.requestWithdraw({'amount': amt});
    
    if (res['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal request submitted!'), backgroundColor: Colors.green));
        amtCtrl.clear();
      }
      await _fetchData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed'), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)));
    }

    final cashBalance = double.tryParse(wallet?['cash_wallet_balance']?.toString() ?? '0') ?? 0;
    final min = double.tryParse(config['min']?.toString() ?? '100') ?? 100;
    final fee = double.tryParse(config['fee']?.toString() ?? '5') ?? 5;
    
    // Listen to changes in text field for reactive UI
    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw to Bank')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryNavy, Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available Cash Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text('₹${cashBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 36, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.appBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Withdrawal Amount (₹)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 12),
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.primaryNavy, fontSize: 24, fontWeight: FontWeight.bold),
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Min ₹$min',
                    hintStyle: const TextStyle(color: AppTheme.textLight),
                    filled: true,
                    fillColor: AppTheme.secondaryBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.lightBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.lightBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.premiumGold, width: 2)),
                  ),
                ),
                
                if ((double.tryParse(amtCtrl.text) ?? 0) > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy.withAlpha(8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryNavy.withAlpha(30)),
                    ),
                    child: Column(
                      children: [
                        _buildBreakdownRow('Amount', '₹${(double.tryParse(amtCtrl.text) ?? 0).toStringAsFixed(2)}', AppTheme.primaryNavy),
                        const SizedBox(height: 8),
                        _buildBreakdownRow('Fee ($fee%)', '-₹${((double.tryParse(amtCtrl.text) ?? 0) * fee / 100).toStringAsFixed(2)}', AppTheme.error),
                        Divider(color: AppTheme.lightBorder, height: 24),
                        _buildBreakdownRow('You Receive', '₹${((double.tryParse(amtCtrl.text) ?? 0) - ((double.tryParse(amtCtrl.text) ?? 0) * fee / 100)).toStringAsFixed(2)}', AppTheme.success, isBold: true),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Expanded(child: Text('Settlement in 3 business days after approval', style: TextStyle(color: Colors.blue, fontSize: 12))),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: isSubmitting || (double.tryParse(amtCtrl.text) ?? 0) == 0 || (double.tryParse(amtCtrl.text) ?? 0) > cashBalance ? null : _submitWithdrawal,
                  child: isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.black) 
                    : const Text('Submit Withdrawal Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                )
              ],
            ),
          ),
          
          if (withdrawals.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Text('Withdrawal History', style: TextStyle(color: AppTheme.primaryNavy, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...withdrawals.map((w) {
              final statusColor = w['status'] == 'completed' || w['status'] == 'approved' ? Colors.green : (w['status'] == 'rejected' ? Colors.red : Colors.orange);
              return Card(
                color: AppTheme.cardBackground,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppTheme.primaryNavy.withAlpha(30))),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('₹${double.tryParse(w['amount_requested']?.toString() ?? '0')?.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: statusColor.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                            child: Text((w['status'] ?? 'pending').toString().toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Net: ₹${double.tryParse(w['amount_after_fee']?.toString() ?? '0')?.toStringAsFixed(2)} after ${w['fee_percent']}% fee', style: const TextStyle(color: AppTheme.textDim, fontSize: 12)),
                      if (w['settlement_date'] != null)
                        Text('Settlement: ${w['settlement_date']}', style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(w['created_at']?.toString().substring(0, 16) ?? '', style: const TextStyle(color: AppTheme.textDim, fontSize: 10)),
                    ],
                  ),
                ),
              );
            })
          ]
        ],
      ),
    );
  }
  
  Widget _buildBreakdownRow(String label, String val, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppTheme.textDim, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(val, style: TextStyle(color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
