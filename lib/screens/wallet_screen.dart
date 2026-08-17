import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../core/theme.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
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
      setState(() => walletData = res['data']);
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)));
    }

    final wallet = walletData?['wallet'] ?? {};
    final history = walletData?['transactions'] as List? ?? [];
    final vendorLockedCoins = walletData?['vendor_locked_coins'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Reward Wallet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.darkGold, AppTheme.primaryGold]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available Japsan Pays', style: TextStyle(color: Colors.black87, fontSize: 16)),
                const SizedBox(height: 8),
                Text('${wallet['coin_balance'] ?? 0} JC', style: const TextStyle(color: Colors.black, fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSubBal('Total Earned', '${wallet['total_coins_earned'] ?? 0} JC'),
                    _buildSubBal(
                      context.read<ApiService>().userRole == 'vendor' ? 'Rewards Given' : 'Redeemed', 
                      '${context.read<ApiService>().userRole == 'vendor' ? (wallet['total_coins_distributed'] ?? wallet['total_coins_redeemed'] ?? 0) : (wallet['total_coins_redeemed'] ?? 0)} JC'
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          _buildMultiWalletList(walletData?['multi_wallet'] ?? {}, context.read<ApiService>().userRole == 'vendor'),
          
          const SizedBox(height: 24),
          const Text('Vendor Wise Locked Coins (90 Days)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          if (vendorLockedCoins.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('No vendor-locked coins available', style: TextStyle(color: AppTheme.textDim))))
          else
            ...vendorLockedCoins.map((vc) => Card(
              color: AppTheme.surfaceDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.primaryGold.withAlpha(50))),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: AppTheme.darkGold, child: Icon(Icons.store, color: Colors.white)),
                title: Text(vc['business_name'] ?? 'Vendor', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                subtitle: const Text('Use only at this vendor', style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
                trailing: Text('${vc['locked_amount']} JC', style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )),
          
          const SizedBox(height: 24),
          const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          if (history.isEmpty)
            const Center(child: Text('No transactions yet', style: TextStyle(color: AppTheme.textDim)))
          else
            ...history.map((tx) {
                bool isUser = context.read<ApiService>().userRole == 'user';
                bool isDeduction = ['payment', 'transfer_out', 'admin_debit', 'vendor_withdrawal'].contains(tx['type']);
                
                String displayAmount = tx['coins_amount']?.toString() ?? '0';
                if (tx['type'] == 'payment' && isUser) {
                  displayAmount = tx['coins_used']?.toString() ?? '0';
                }

                return Card(
                  color: AppTheme.surfaceDark,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isDeduction ? Colors.red : Colors.green,
                      child: Icon(isDeduction ? Icons.remove : Icons.add, color: Colors.white),
                    ),
                    title: Text(tx['description'] ?? tx['type'], style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                    subtitle: Text(tx['created_at'].toString().substring(0, 10), style: const TextStyle(color: AppTheme.textDim)),
                    trailing: Text(
                      '${isDeduction ? '-' : '+'}$displayAmount JC',
                      style: TextStyle(color: isDeduction ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildMultiWalletList(Map<String, dynamic> multiWallet, bool isVendor) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.lightBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.primaryNavy,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('My Wallets', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          _buildWalletRow(Icons.account_balance_wallet, 'Main Wallet (JC)', multiWallet['main_wallet'], true, 'Withdrawable (Purchased JC)', Colors.blue),
          _buildWalletRow(Icons.lock_clock, '90 Days Lock Wallet', multiWallet['lock_90d_wallet'], false, 'Non-Withdrawable (Unlocks in 90 Days)', Colors.orange),
          _buildWalletRow(Icons.group_add, 'Referral Reward Wallet', multiWallet['referral_wallet'], false, 'Non-Withdrawable', Colors.green),
          _buildWalletRow(Icons.card_giftcard, 'Cashback Wallet', multiWallet['cashback_wallet'], false, 'Non-Withdrawable', Colors.purple),
          
          if (!isVendor)
            _buildWalletRow(Icons.account_tree, 'Level Income Wallet', multiWallet['level_income_wallet'], false, 'Non-Withdrawable', Colors.redAccent),
          
          if ((multiWallet['vendor_settlement_wallet'] ?? 0) > 0)
            _buildWalletRow(Icons.store, 'Vendor Settlement Wallet', multiWallet['vendor_settlement_wallet'], true, 'Withdrawable (Purchased JC)', Colors.orange),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: const BoxDecoration(
              color: AppTheme.primaryNavy,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Balance (All Wallets)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('${multiWallet['total_balance'] ?? 0} JC', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletRow(IconData icon, String title, dynamic amount, bool withdrawable, String tag, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.lightBorder)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(tag, style: TextStyle(color: withdrawable ? Colors.green : Colors.red, fontSize: 10)),
              ],
            ),
          ),
          Text('${amount ?? 0} JC', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSubBal(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.black54, fontSize: 10)),
        Text(val, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
