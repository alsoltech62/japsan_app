import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../core/theme.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  Map<String, dynamic>? data;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReferrals();
  }

  Future<void> _fetchReferrals() async {
    final res = await context.read<ApiService>().getReferrals();
    if (res['success'] == true) {
      if(mounted) setState(() => data = res['data']);
    }
    if(mounted) setState(() => isLoading = false);
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)));

    final refCode = data?['referral_code'] ?? '';
    final link = data?['share_link'] ?? '';
    final stats = data?['stats'] ?? {};
    final cfg = data?['rewards_config'] ?? {};
    final list = data?['referrals'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Refer & Earn')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          // Referral Code Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2B2B2B), AppTheme.surfaceDark]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primaryGold.withAlpha(80)),
            ),
            child: Column(
              children: [
                const Text('Your Referral Code', style: TextStyle(color: AppTheme.textDim, fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(refCode, style: const TextStyle(color: AppTheme.primaryGold, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 3)),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white),
                      onPressed: () => _copyToClipboard(refCode, 'Code copied!'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white, elevation: 0),
                        icon: const Icon(Icons.link),
                        label: const Text('Copy Link'),
                        onPressed: () => _copyToClipboard(link, 'Link copied!'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0),
                        icon: const Icon(Icons.chat),
                        label: const Text('WhatsApp'),
                        onPressed: () async {
                           final msg = Uri.encodeComponent('Join Japsan Pay! Use my code: $refCode\n$link');
                           final url = Uri.parse('https://wa.me/?text=$msg');
                           try {
                             await launchUrl(url, mode: LaunchMode.externalApplication);
                           } catch (e) {
                             _copyToClipboard('Join Japsan Pay! Use my code: $refCode\n$link', 'Could not open WhatsApp, copied to clipboard!');
                           }
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 24),
          
          // Reward Structure
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.card_giftcard, color: AppTheme.primaryGold),
                    SizedBox(width: 8),
                    Text('Reward Structure', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRewardRow('Invite a User', '+${cfg['user_user'] ?? 50} JC'),
                const Divider(color: Colors.white10),
                _buildRewardRow('Invite a Vendor', '+${cfg['vendor_user'] ?? 100} JC'),
                const SizedBox(height: 12),
                Text('* Coins locked for ${cfg['lock_days'] ?? 0} days. Unlocked after first transaction.', style: const TextStyle(color: Colors.orange, fontSize: 12)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stats
          Row(
            children: [
              Expanded(child: _buildStatItem('Total Referrals', stats['total_referrals']?.toString() ?? '0', Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatItem('Coins Earned', stats['total_earned']?.toString() ?? '0', Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatItem('Unlocked', stats['total_unlocked']?.toString() ?? '0', Colors.green)),
            ],
          ),

          const SizedBox(height: 32),
          const Text('Your Referrals', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),

          if (list.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('No referrals yet.', style: TextStyle(color: AppTheme.textDim)),
            ))
          else
            ...list.map((r) {
              final isUnlocked = r['is_unlocked'] == 1 || r['is_unlocked'] == true;
              return Card(
                color: AppTheme.surfaceDark,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.withAlpha(30),
                    child: const Icon(Icons.person, color: Colors.orange),
                  ),
                  title: Text(r['referred_name'] ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(r['created_at'] != null ? r['created_at'].toString().substring(0, 10) : '', style: const TextStyle(color: AppTheme.textDim, fontSize: 12)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('+${r['coins_earned']} JC', style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(isUnlocked ? 'Unlocked' : 'Locked', style: TextStyle(color: isUnlocked ? Colors.green : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRewardRow(String title, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: AppTheme.textDim, fontSize: 14)),
        Text(val, style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildStatItem(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(val, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textDim, fontSize: 11)),
        ],
      ),
    );
  }
}
