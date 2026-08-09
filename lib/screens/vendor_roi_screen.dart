import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../core/theme.dart';

class VendorRoiScreen extends StatefulWidget {
  const VendorRoiScreen({super.key});

  @override
  State<VendorRoiScreen> createState() => _VendorRoiScreenState();
}

class _VendorRoiScreenState extends State<VendorRoiScreen> {
  Map<String, dynamic>? data;
  bool isLoading = true;
  String period = '30';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    final res = await context.read<ApiService>().getRoiDashboard(period);
    if (res['success'] == true) {
      if(mounted) setState(() => data = res['data']);
    }
    if(mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ROI Dashboard'),
        actions: [
          DropdownButton<String>(
            value: period,
            dropdownColor: AppTheme.surfaceDark,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryGold),
            style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold),
            items: const [
              DropdownMenuItem(value: '7', child: Text('7 Days')),
              DropdownMenuItem(value: '30', child: Text('30 Days')),
              DropdownMenuItem(value: '90', child: Text('90 Days')),
              DropdownMenuItem(value: '365', child: Text('1 Year')),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => period = v);
                _fetchData();
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
        : _buildBody(),
    );
  }

  Widget _buildBody() {
    final s = data?['summary'] ?? {};
    final topCustomers = data?['top_customers'] as List? ?? [];
    
    // We'll use a simplified chart display since we don't have recharts in Flutter out-of-the-box
    // but we can show the stats clearly.
    
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Platform Message
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Platform Message', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              Text(s['extra_revenue_msg'] ?? 'No data yet. Start transacting to see your ROI!', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              if ((double.tryParse(s['roi_score']?.toString() ?? '0') ?? 0) > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('${s['roi_score']}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ROI Score', style: TextStyle(color: Colors.white, fontSize: 12)),
                        Text('out of 100', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    )
                  ],
                )
              ]
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard('Total Customers', '${s['total_customers'] ?? 0}', Icons.people, Colors.blue),
            _buildStatCard('Repeat Customers', '${s['repeat_customers'] ?? 0} (${s['repeat_percent'] ?? 0}%)', Icons.repeat, Colors.green),
            _buildStatCard('Total Revenue', '₹${double.tryParse(s['total_revenue']?.toString() ?? '0')?.toStringAsFixed(0)}', Icons.monetization_on, Colors.orange),
            _buildStatCard('Avg Order Value', '₹${double.tryParse(s['avg_order_value']?.toString() ?? '0')?.toStringAsFixed(0)}', Icons.show_chart, Colors.purple),
            _buildStatCard('Coins Distributed', '${double.tryParse(s['coins_distributed']?.toString() ?? '0')?.toStringAsFixed(0)} 🪙', Icons.card_giftcard, Colors.yellow),
            _buildStatCard('Coins Cost (INR)', '₹${double.tryParse(s['coin_cost_inr']?.toString() ?? '0')?.toStringAsFixed(0)}', Icons.money_off, Colors.red),
            _buildStatCard('Net Profit Est.', '₹${double.tryParse(s['net_profit']?.toString() ?? '0')?.toStringAsFixed(0)}', Icons.emoji_events, Colors.greenAccent),
            _buildStatCard('Transactions', '${s['transaction_count'] ?? 0}', Icons.receipt_long, Colors.grey),
          ],
        ),
        
        if (topCustomers.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('🏆 Top Customers', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...topCustomers.asMap().entries.map((entry) {
            int idx = entry.key;
            var c = entry.value;
            return Card(
              color: AppTheme.surfaceDark,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: Colors.orange.withAlpha(50), child: Text('${idx + 1}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                title: Text(c['name'] ?? 'Customer', style: const TextStyle(color: Colors.white)),
                subtitle: Text('${c['visit_count']} visits', style: const TextStyle(color: AppTheme.textDim, fontSize: 12)),
                trailing: Text('₹${double.tryParse(c['total_spent']?.toString() ?? '0')?.toStringAsFixed(0)}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            );
          }),
        ] else ...[
          const SizedBox(height: 48),
          const Center(
            child: Column(
              children: [
                Text('📊', style: TextStyle(fontSize: 48)),
                SizedBox(height: 16),
                Text('No transaction data yet', style: TextStyle(color: AppTheme.textDim)),
              ],
            ),
          )
        ]
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.textDim),
              const SizedBox(width: 4),
              Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textDim, fontSize: 11), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
