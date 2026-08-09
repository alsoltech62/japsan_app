import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../core/theme.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  Map<String, dynamic>? networkData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNetwork();
  }

  Future<void> _fetchNetwork() async {
    final api = context.read<ApiService>();
    final res = await api.getNetwork();
    if (res['success'] == true && res['data'] != null) {
      if(mounted) setState(() => networkData = res['data']);
    } else {
      if(mounted) setState(() => networkData = {});
    }
    if(mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFE6F0FF),
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
      );
    }

    final data = networkData ?? {};
    final personal = double.tryParse(data['personalBusiness']?.toString() ?? '0') ?? 0;
    final level1 = double.tryParse(data['level1Business']?.toString() ?? '0') ?? 0;
    final totalBusiness = double.tryParse(data['totalTeamBusiness']?.toString() ?? '1') ?? 1;
    final indirectBiz = (totalBusiness - level1 - personal).clamp(0, double.infinity);
    final referrals = data['directReferrals'] as List? ?? [];
    final rankProgress = double.tryParse(data['rank_progress']?.toString() ?? '0.5') ?? 0.5;

    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FF), // Navy-50 background
      appBar: AppBar(
        title: const Text('My Network', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFF1A2357), // Navy-900
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Navy Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              decoration: const BoxDecoration(
                color: Color(0xFF1A2357), // Navy-900
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFB8860B)]),
                              border: Border.all(color: const Color(0xFF1A2357), width: 3),
                            ),
                            child: const Icon(Icons.emoji_events, color: Color(0xFF1A2357), size: 30),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFD4AF37).withAlpha(30), borderRadius: BorderRadius.circular(4)),
                                child: Text('RANK: ${data['rank']?.toString().toUpperCase() ?? 'STARTER'}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                              ),
                              const SizedBox(height: 4),
                              Text('Next: ${data['next_rank'] ?? 'Bronze'}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Text('Code', style: TextStyle(color: Colors.white54, fontSize: 10)),
                            Text('${data['referralCode'] ?? '---'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            

            
            // Tree View Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_tree, color: Color(0xFFD4AF37)),
                      SizedBox(width: 8),
                      Text('Network Tree', style: TextStyle(color: Color(0xFF1A2357), fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // ME
                  Container(
                    width: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2357),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD4AF37).withAlpha(80), width: 2),
                    ),
                    child: Column(
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -32),
                          child: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Center(child: Text('ME', style: TextStyle(color: Color(0xFF1A2357), fontWeight: FontWeight.w900, fontSize: 14))),
                          ),
                        ),
                        const Text('Personal Level', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Biz: JC ${personal.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12)),
                      ],
                    ),
                  ),
                  
                  // Connector
                  Container(width: 2, height: 24, color: Colors.grey.shade300),
                  
                  // Level 1
                  Container(
                    width: 260,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F0FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2B3D8F).withAlpha(50)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFD4AF37), borderRadius: BorderRadius.circular(4)),
                              child: const Text('LEVEL 1', style: TextStyle(color: Color(0xFF1A2357), fontSize: 10, fontWeight: FontWeight.w900)),
                            ),
                            const SizedBox(width: 8),
                            Text('Direct Team (${data['totalReferrals'] ?? 0})', style: const TextStyle(color: Color(0xFF1A2357), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('JC ${level1.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF1A2357), fontSize: 16, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...referrals.take(5).map((r) => Container(
                              margin: const EdgeInsets.only(right: 4),
                              width: 24, height: 24,
                              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
                              child: Center(child: Text(r['name']?.toString().substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(color: Color(0xFF1A2357), fontSize: 10, fontWeight: FontWeight.bold))),
                            )),
                            if (referrals.length > 5)
                              Container(
                                width: 24, height: 24,
                                decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
                                child: const Center(child: Text('+', style: TextStyle(color: Color(0xFF1A2357), fontSize: 12, fontWeight: FontWeight.bold))),
                              )
                          ],
                        )
                      ],
                    ),
                  ),
                  
                  // Connector
                  Container(width: 2, height: 24, color: Colors.grey.shade300),
                  
                  // Level 2 & 3
                  Container(
                    width: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                          child: const Text('LEVEL 2 & 3', style: TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(height: 8),
                        const Text('Extended Network', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Biz: JC ${indirectBiz.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Referrals Table Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Row(
                children: [
                  const Icon(Icons.group, color: Color(0xFFD4AF37)),
                  const SizedBox(width: 8),
                  const Text('Direct Network', style: TextStyle(color: Color(0xFF1A2357), fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${referrals.length} Members', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
            
            // Referrals List
            if (referrals.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No direct referrals yet.', style: TextStyle(color: Colors.black45)),
              )
            else
              ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: referrals.length,
                itemBuilder: (context, i) {
                  final r = referrals[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE6F0FF),
                        child: Text(r['name']?.toString().substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(color: Color(0xFF1A2357), fontWeight: FontWeight.bold)),
                      ),
                      title: Text(r['name'] ?? 'User', style: const TextStyle(color: Color(0xFF1A2357), fontWeight: FontWeight.bold)),
                      subtitle: Text('JC ${(double.tryParse(r['business']?.toString() ?? '0') ?? 0).toStringAsFixed(2)} Biz', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      trailing: const Text('ACTIVE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  );
                },
              ),
              
            const SizedBox(height: 24),
            
            // Level Benefits Info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.emoji_events, color: Color(0xFFD4AF37)),
                      SizedBox(width: 8),
                      Text('Network Level Benefits', style: TextStyle(color: Color(0xFF1A2357), fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitRow('Level 1 (Direct)', '50 JC Joining Bonus\n1.0 JC per Transaction', const Color(0xFFE6F0FF)),
                  const SizedBox(height: 12),
                  _buildBenefitRow('Level 2 (Extended)', '25 JC Joining Bonus\n0.5 JC per Transaction', Colors.grey.shade100),
                  const SizedBox(height: 12),
                  _buildBenefitRow('Level 3 (Deep)', '10 JC Joining Bonus\n0.25 JC per Transaction', Colors.grey.shade100),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Rank Progress Bar at the Bottom
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.track_changes, color: Color(0xFFD4AF37)),
                      SizedBox(width: 8),
                      Text('Goal & Rank Progress', style: TextStyle(color: Color(0xFF1A2357), fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Next: ${data['next_rank'] ?? 'Bronze'}', style: const TextStyle(color: Color(0xFF1A2357), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      Text('${(rankProgress * 100).toStringAsFixed(0)}% Achieved', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: rankProgress.clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFE6F0FF),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 16),
                  Text('🎯 Goal: ${data['next_rank_goal'] ?? 'Keep growing!'}', style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TOTAL BIZ', style: TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text('JC ${totalBusiness.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF1A2357), fontSize: 18, fontWeight: FontWeight.w900)),
                          ],
                        )
                      ),
                      Container(width: 1, height: 30, color: Colors.black12),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('EARNINGS', style: TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text('JC ${(double.tryParse(data['totalEarnings']?.toString() ?? '0') ?? 0).toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.w900)),
                          ],
                        )
                      )
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(String title, String desc, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars, color: Color(0xFFD4AF37), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF1A2357), fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
