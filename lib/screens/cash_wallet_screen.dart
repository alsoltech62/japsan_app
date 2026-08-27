import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../core/theme.dart';

class CashWalletScreen extends StatefulWidget {
  const CashWalletScreen({super.key});

  @override
  State<CashWalletScreen> createState() => _CashWalletScreenState();
}

class _CashWalletScreenState extends State<CashWalletScreen> {
  Map<String, dynamic>? walletData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    final api = context.read<ApiService>();
    final res = await api.getWallet();
    if (res['success'] == true) {
      if(mounted) setState(() => walletData = res['data']);
    }
    if(mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.primaryNavy)));
    }

    final wallet = walletData?['wallet'] ?? {};
    final history = walletData?['transactions'] as List? ?? [];
    
    // Filter out only cash-related transactions
    final cashHistory = history.where((tx) {
      final amt = double.tryParse(tx['amount_inr']?.toString() ?? '0') ?? 0;
      final cashPaid = double.tryParse(tx['cash_paid']?.toString() ?? '0') ?? 0;
      return amt > 0 || cashPaid > 0 || tx['type'] == 'vendor_withdrawal' || tx['type'] == 'user_withdrawal';
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Cash Wallet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primaryNavy, Color(0xFF1E3A8A)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available Cash Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                Text('₹${double.tryParse(wallet['cash_wallet_balance']?.toString() ?? '0')?.toStringAsFixed(2) ?? "0.00"}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Text('Cash Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)),
          const SizedBox(height: 16),
          if (cashHistory.isEmpty)
            const Center(child: Text('No cash transactions yet', style: TextStyle(color: AppTheme.textDim)))
          else
            ...cashHistory.map((tx) {
                bool isUser = context.read<ApiService>().userRole == 'user';
                bool isWithdrawal = tx['type'] == 'vendor_withdrawal' || tx['type'] == 'user_withdrawal';
                
                String displayAmount = tx['amount_inr']?.toString() ?? '0';
                if (tx['type'] == 'payment' && isUser) {
                  // If user made a payment, their cash paid is a deduction
                  displayAmount = tx['cash_paid']?.toString() ?? '0';
                  isWithdrawal = true; // Treats payment as deduction for user
                } else if (tx['type'] == 'payment' && !isUser) {
                  // If vendor received a payment, they receive amount_inr
                  displayAmount = tx['amount_inr']?.toString() ?? '0';
                  isWithdrawal = false; // Treats as addition
                }

                return Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isWithdrawal ? Colors.red.withAlpha(20) : Colors.green.withAlpha(20),
                      child: Icon(isWithdrawal ? Icons.remove : Icons.add, color: isWithdrawal ? Colors.red : Colors.green),
                    ),
                    title: Text(tx['description'] ?? tx['type'], style: const TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold)),
                    subtitle: Text(tx['created_at'].toString().substring(0, 10), style: const TextStyle(color: AppTheme.textDim)),
                    trailing: Text(
                      '${isWithdrawal ? '-' : '+'}₹${double.tryParse(displayAmount)?.toStringAsFixed(2)}',
                      style: TextStyle(color: isWithdrawal ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                );
            }).toList(),
        ],
      ),
    );
  }
}
