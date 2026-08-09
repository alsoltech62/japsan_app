import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../core/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class VendorCampaignsScreen extends StatefulWidget {
  const VendorCampaignsScreen({super.key});

  @override
  State<VendorCampaignsScreen> createState() => _VendorCampaignsScreenState();
}

class _VendorCampaignsScreenState extends State<VendorCampaignsScreen> {
  String type = 'push';
  String target = 'all';
  final msgCtrl = TextEditingController();
  bool isSending = false;

  Future<void> _sendCampaign() async {
    if (msgCtrl.text.isEmpty) return;
    setState(() => isSending = true);
    final res = await context.read<ApiService>().sendVendorCampaign({
      'type': type,
      'target': target,
      'message': msgCtrl.text,
    });
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Done')));
      setState(() => isSending = false);
      if (res['success'] == true) {
        if (type == 'whatsapp' && res['data']?['whatsapp_numbers'] != null) {
          List numbers = res['data']['whatsapp_numbers'];
          if (numbers.isNotEmpty) {
            final msg = Uri.encodeComponent(msgCtrl.text);
            final phone = numbers[0].toString().replaceAll(RegExp(r'\D'), '');
            final url = Uri.parse('https://wa.me/$phone?text=$msg');
            launchUrl(url, mode: LaunchMode.externalApplication).catchError((_) => false);
          }
        }
        msgCtrl.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campaigns')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Type section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Campaign Type', style: TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: RadioListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Push', style: TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.w600)),
                      value: 'push',
                      groupValue: type,
                      activeColor: AppTheme.premiumGold,
                      onChanged: (v) => setState(() => type = v.toString()),
                    )),
                    Expanded(child: RadioListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('WhatsApp', style: TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.w600)),
                      value: 'whatsapp',
                      groupValue: type,
                      activeColor: AppTheme.premiumGold,
                      onChanged: (v) => setState(() => type = v.toString()),
                    )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Target Audience
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Target Audience', style: TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: target,
                  style: const TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.w500),
                  dropdownColor: AppTheme.cardBackground,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.secondaryBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.lightBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.lightBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.premiumGold, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Customers', style: TextStyle(color: AppTheme.primaryNavy))),
                    DropdownMenuItem(value: 'repeat', child: Text('Repeat Customers', style: TextStyle(color: AppTheme.primaryNavy))),
                  ],
                  onChanged: (v) => setState(() => target = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Message', style: TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                TextField(
                  controller: msgCtrl,
                  maxLines: 4,
                  style: const TextStyle(color: AppTheme.primaryNavy),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: const TextStyle(color: AppTheme.textLight),
                    filled: true,
                    fillColor: AppTheme.secondaryBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.lightBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.lightBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.premiumGold, width: 2)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.premiumGold,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            onPressed: isSending ? null : _sendCampaign,
            child: Text(
              isSending ? 'Sending...' : 'Send Campaign',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
