import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../core/theme.dart';

class VendorRewardSettingsScreen extends StatefulWidget {
  const VendorRewardSettingsScreen({super.key});

  @override
  State<VendorRewardSettingsScreen> createState() => _VendorRewardSettingsScreenState();
}

class _VendorRewardSettingsScreenState extends State<VendorRewardSettingsScreen> {
  bool isLoading = true;
  bool isSaving = false;
  Map<String, dynamic> settings = {
    'base_cashback': '',
    'smart_rules': [],
    'loyalty_enabled': false,
    'loyalty_visits': '',
    'loyalty_reward': ''
  };

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    final api = context.read<ApiService>();
    final res = await api.getRewardSettings();
    if (res['success'] == true && res['data'] != null) {
      if(mounted) setState(() => settings = Map<String,dynamic>.from(res['data']));
    }
    if(mounted) setState(() => isLoading = false);
  }

  Future<void> _saveSettings() async {
    setState(() => isSaving = true);
    final api = context.read<ApiService>();
    final res = await api.updateRewardSettings(settings);
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Settings updated')));
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)));

    return Scaffold(
      appBar: AppBar(title: const Text('Reward Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Configure how much cashback your customers receive. Set a base percentage, or enable loyalty rules to give extra rewards after multiple visits.',
            style: TextStyle(color: AppTheme.textDim, fontSize: 13),
          ),
          const SizedBox(height: 24),
          const Text('Automatic Cashback (%)', style: TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.primaryNavy),
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. 10'),
            controller: TextEditingController(text: settings['base_cashback'].toString())..selection = TextSelection.collapsed(offset: settings['base_cashback'].toString().length),
            onChanged: (val) => settings['base_cashback'] = val,
          ),
          const SizedBox(height: 24),

          SwitchListTile(
            title: const Text('Enable Loyalty Program', style: TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold)),
            activeColor: AppTheme.primaryGold,
            value: settings['loyalty_enabled'] == true,
            onChanged: (val) => setState(() => settings['loyalty_enabled'] = val),
          ),
          if (settings['loyalty_enabled'] == true) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('After ', style: TextStyle(color: AppTheme.textSecondary)),
                Expanded(child: TextField(
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.primaryNavy),
                  decoration: const InputDecoration(isDense: true),
                  controller: TextEditingController(text: settings['loyalty_visits'].toString())..selection = TextSelection.collapsed(offset: settings['loyalty_visits'].toString().length),
                  onChanged: (val) => settings['loyalty_visits'] = val,
                )),
                const Text(' visits, give ', style: TextStyle(color: AppTheme.textSecondary)),
                Expanded(child: TextField(
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.primaryNavy),
                  decoration: const InputDecoration(isDense: true),
                  controller: TextEditingController(text: settings['loyalty_reward'].toString())..selection = TextSelection.collapsed(offset: settings['loyalty_reward'].toString().length),
                  onChanged: (val) => settings['loyalty_reward'] = val,
                )),
                const Text(' JC', style: TextStyle(color: AppTheme.textSecondary)),
              ],
            )
          ],
          
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, minimumSize: const Size.fromHeight(50)),
            onPressed: isSaving ? null : _saveSettings,
            child: Text(isSaving ? 'Saving...' : 'Save Settings', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
