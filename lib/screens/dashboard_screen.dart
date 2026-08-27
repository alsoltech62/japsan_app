import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../core/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'user_scan_pay_screen.dart';
import 'nearby_vendors_screen.dart';
import 'network_screen.dart';
import 'wallet_screen.dart';
import 'referral_screen.dart';
import 'profile_screen.dart';
import 'vendor_reward_settings_screen.dart';
import 'vendor_offers_screen.dart';
import 'vendor_campaigns_screen.dart';
import 'vendor_withdraw_screen.dart';
import 'vendor_scan_customer_screen.dart';
import 'vendor_qr_screen.dart';
import 'buy_coins_screen.dart';
import 'cash_wallet_screen.dart';
import 'notifications_screen.dart';
import 'vendor_roi_screen.dart';
import 'user_withdraw_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiService>();
    final user = api.userProfile;
    final isVendor = user?['role'] == 'vendor';

    final screens = isVendor ? [
      const VendorDashboard(),
      const WalletScreen(),
      const VendorOffersScreen(),
      const ProfileScreen(),
    ] : [
      const UserDashboard(),
      const NetworkScreen(),
      const WalletScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/JapSan.png', height: 32, width: 32, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Flexible(child: Text(isVendor ? 'Vendor Portal' : 'Japsan Pay', style: const TextStyle(fontSize: 18), overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
          ),
        ],
      ),
      body: screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (isVendor) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorScanCustomerScreen()));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const UserScanPayScreen()));
          }
        },
        backgroundColor: AppTheme.primaryNavy,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner, color: AppTheme.premiumGold, size: 28),
      ).animate().scale(delay: 500.ms),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppTheme.cardBackground,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
              _buildNavItem(isVendor ? Icons.account_balance_wallet_outlined : Icons.device_hub_outlined, isVendor ? Icons.account_balance_wallet : Icons.device_hub, isVendor ? 'Wallet' : 'Network', 1),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(isVendor ? Icons.local_offer_outlined : Icons.account_balance_wallet_outlined, isVendor ? Icons.local_offer : Icons.account_balance_wallet, isVendor ? 'Offers' : 'Wallet', 2),
              _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData outlineIcon, IconData filledIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? filledIcon : outlineIcon,
            color: isSelected ? AppTheme.primaryNavy : AppTheme.textLight,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppTheme.primaryNavy : AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHome(Map<String, dynamic>? user, bool isVendor) {
    if (isVendor) return const VendorDashboard();
    return const UserDashboard();
  }

  Widget _buildWallet(Map<String, dynamic>? user) {
    return const WalletScreen().animate().fade();
  }

  Widget _buildProfile(Map<String, dynamic>? user, ApiService api) {
    return const ProfileScreen().animate().fade();
  }
}

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  Map<String, dynamic>? walletData;
  bool isLoading = true;
  final PageController _pageController = PageController();
  Timer? _bannerTimer;
  final List<String> _banners = [
    'assets/ba1.jpeg',
    'assets/ba2.jpeg',
    'assets/ba3.jpeg'
  ];

  @override
  void initState() {
    super.initState();
    _fetchBalance();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.round() + 1;
        if (nextPage >= _banners.length) nextPage = 0;
        _pageController.animateToPage(nextPage, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchBalance() async {
    final api = context.read<ApiService>();
    final res = await api.getWallet();
    if (res['success'] == true) {
      if(mounted) setState(() => walletData = res['data']);
    }
    if(mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final balance = walletData?['wallet']?['coin_balance'] ?? 0;
    final cashBalance = walletData?['wallet']?['cash_wallet_balance'] ?? 0;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildUserBalanceCard(context, '$balance', '$cashBalance'),
        const SizedBox(height: 24),
        // Main Promotional Banner
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: AssetImage(_banners[index]),
                    fit: BoxFit.fill,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
              );
            },
          ),
        ).animate().fade().scale(),
        const SizedBox(height: 24),

        
        // Primary Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionItem(context, Icons.account_balance_wallet, 'Buy Coins', const BuyCoinsScreen(), Colors.blue),
            _buildActionItem(context, Icons.qr_code_scanner, 'Scan & Pay', const UserScanPayScreen(), Colors.indigo),
            _buildActionItem(context, Icons.qr_code, 'My QR', const UserScanPayScreen(), Colors.green),
            _buildActionItem(context, Icons.receipt_long, 'History', const WalletScreen(), Colors.orange),
          ],
        ).animate().fade().slideX(),
        const SizedBox(height: 24),

        // Promo Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.orange.shade50, Colors.orange.shade100]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Invite & Earn More', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryNavy)),
                    const SizedBox(height: 4),
                    const Text('Refer your friends and earn Unlimited JC Rewards', style: TextStyle(fontSize: 10, color: AppTheme.textDim)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 24),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Invite Now', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const Text('🎁', style: TextStyle(fontSize: 40)),
            ],
          ),
        ).animate().fade().slideY(),
        const SizedBox(height: 24),

        const Text('Quick Access', style: TextStyle(color: AppTheme.primaryNavy, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.9,
          children: [
            _buildQuickAccess(context, Icons.account_balance, 'Withdraw', const UserWithdrawScreen()),
            _buildQuickAccess(context, Icons.card_giftcard_outlined, 'Refer & Earn', const ReferralScreen()),
            _buildQuickAccess(context, Icons.local_offer_outlined, 'Nearby Offers', const NearbyVendorsScreen()),
            _buildQuickAccess(context, Icons.verified_user_outlined, 'KYC', const ProfileScreen()),
            _buildQuickAccess(context, Icons.help_outline, 'Help Center', const ProfileScreen()),
          ],
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Transactions', style: TextStyle(color: AppTheme.primaryNavy, fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
              child: const Text('View All', style: TextStyle(color: AppTheme.primaryNavy, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        if (walletData?['transactions'] == null || walletData!['transactions'].isEmpty)
          const Center(child: Text('No recent payments', style: TextStyle(color: AppTheme.textDim)))
        else
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: (walletData?['transactions'] as List?)?.length.clamp(0, 5) ?? 0,
              separatorBuilder: (c, i) => Divider(color: Colors.grey.shade100, height: 1),
              itemBuilder: (context, index) {
                final tx = walletData!['transactions'][index];
                bool isDeduction = ['payment', 'transfer_out', 'admin_debit', 'vendor_withdrawal'].contains(tx['type']);
                String displayAmount = tx['coins_amount']?.toString() ?? '0';
                if (tx['type'] == 'payment') {
                  displayAmount = tx['coins_used']?.toString() ?? '0';
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDeduction ? Colors.red.withAlpha(20) : Colors.green.withAlpha(20),
                    child: Icon(isDeduction ? Icons.remove : Icons.add, color: isDeduction ? Colors.red : Colors.green, size: 18),
                  ),
                  title: Text(tx['description'] ?? tx['type'] ?? 'Transaction', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryNavy), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(tx['created_at']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
                  trailing: Text('${isDeduction ? '-' : '+'}${double.tryParse(displayAmount)?.toStringAsFixed(2)} JC', style: TextStyle(color: isDeduction ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                );
              },
            ),
          ),
      ],
    ).animate().fade().slideY(begin: 0.1);
  }

  Widget _buildUserBalanceCard(BuildContext context, String coinBalance, String cashBalance) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryNavy, Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNavy.withAlpha(80),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('Total Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                  SizedBox(width: 8),
                  Icon(Icons.remove_red_eye_outlined, color: Colors.white70, size: 16),
                ],
              ),
              Image.asset('assets/JapSan.png', height: 40, width: 40),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Japsan Coins', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                  Text('$coinBalance JC', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                ],
              ),
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CashWalletScreen())),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Row(
                      children: [
                        Text('Cash Wallet', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        SizedBox(width: 4),
                        Icon(Icons.open_in_new, color: Colors.white70, size: 12),
                      ],
                    ),
                    Text('₹$cashBalance', style: const TextStyle(color: AppTheme.premiumGold, fontSize: 26, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withAlpha(50)),
              ),
              child: const Text('Wallet Details >', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ).animate().shimmer(duration: 2000.ms);
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String label, Widget screen, Color color) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        _fetchBalance();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(50)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildQuickAccess(BuildContext context, IconData icon, String label, Widget screen) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        _fetchBalance();
      },
      child: Column(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 26),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  Map<String, dynamic>? data;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final api = context.read<ApiService>();
    final res = await api.getWallet();
    if (res['success'] == true) {
      if(mounted) setState(() => data = res['data']);
    }
    if(mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryNavy));
    }

    final w = data?['wallet'] ?? {};
    final user = context.watch<ApiService>().userProfile;
    final kycStatus = w['kyc_status'] ?? 'pending';
    final isApproved = kycStatus == 'approved';

    final pendingWithdrawals = data?['pending_withdrawals'] as List? ?? [];
    final transactions = data?['transactions'] as List? ?? [];
    final coinBalance = double.tryParse(w['coin_balance']?.toString() ?? '0')?.toStringAsFixed(0) ?? '0';
    final cashBalance = double.tryParse(w['cash_wallet_balance']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00';

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('🏪 ${w['business_name'] ?? user?['name'] ?? ''}', style: const TextStyle(color: AppTheme.primaryNavy, fontSize: 20, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isApproved ? Colors.green.withAlpha(20) : Colors.orange.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isApproved ? Colors.green : Colors.orange),
              ),
              child: Text('KYC: ${kycStatus.toString().toUpperCase()}', style: TextStyle(color: isApproved ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildVendorBalanceCard(context, coinBalance, cashBalance),
        const SizedBox(height: 24),
        
        if (!isApproved)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KYC Pending', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(height: 4),
                      Text('Your KYC is under review. You will be able to process payments once approved.', style: TextStyle(color: Colors.orange, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const Text('Quick Access', style: TextStyle(color: AppTheme.primaryNavy, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.9,
          children: [
            _buildQuickAccess(context, Icons.person_outline, 'Profile', const ProfileScreen()),
            _buildQuickAccess(context, Icons.point_of_sale, 'Bill Customer', const VendorScanCustomerScreen()),
            _buildQuickAccess(context, Icons.qr_code, 'Show QR', const VendorQrScreen()),
            _buildQuickAccess(context, Icons.account_balance_wallet, 'Buy Coins', const BuyCoinsScreen()),
            _buildQuickAccess(context, Icons.account_balance, 'Withdraw', const VendorWithdrawScreen()),
            _buildQuickAccess(context, Icons.settings_outlined, 'Rewards', const VendorRewardSettingsScreen()),
            _buildQuickAccess(context, Icons.local_offer_outlined, 'Offers', const VendorOffersScreen()),
            _buildQuickAccess(context, Icons.campaign_outlined, 'Campaigns', const VendorCampaignsScreen()),
            _buildQuickAccess(context, Icons.share_outlined, 'Refer', const ReferralScreen()),
          ],
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('My Performance', style: TextStyle(color: AppTheme.primaryNavy, fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('This Month ⌵', style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryNavy.withAlpha(8), AppTheme.primaryNavy.withAlpha(18)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryNavy.withAlpha(40)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(children: [Text('📈 ', style: TextStyle(fontSize: 16)), Text('Total Revenue', style: TextStyle(color: AppTheme.primaryNavy, fontSize: 13, fontWeight: FontWeight.w600))]),
                  Text('₹${double.tryParse(w['total_revenue_generated']?.toString() ?? '0')?.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primaryNavy, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: AppTheme.primaryNavy.withAlpha(20), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(children: [Text('👥 ', style: TextStyle(fontSize: 16)), Text('Total Customers', style: TextStyle(color: AppTheme.primaryNavy, fontSize: 13, fontWeight: FontWeight.w600))]),
                  Text('${w['total_customers'] ?? 0}', style: const TextStyle(color: AppTheme.premiumGold, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: AppTheme.primaryNavy.withAlpha(20), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(children: [Text('🪙 ', style: TextStyle(fontSize: 16)), Text('Reward Given', style: TextStyle(color: AppTheme.primaryNavy, fontSize: 13, fontWeight: FontWeight.w600))]),
                  Text('${double.tryParse(w['total_coins_distributed']?.toString() ?? '0')?.toStringAsFixed(0)} JC', style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (pendingWithdrawals.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade100)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⏳ Pending Withdrawals', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...pendingWithdrawals.map((pw) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹${pw['amount_requested']}', style: const TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)),
                        child: Text('${pw['status']}', style: const TextStyle(color: Colors.blue, fontSize: 10)),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Transactions', style: TextStyle(color: AppTheme.primaryNavy, fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())), 
              child: const Text('View All', style: TextStyle(color: AppTheme.primaryNavy, fontSize: 12, fontWeight: FontWeight.bold))
            ),
          ],
        ),
        if (transactions.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No recent payments', style: TextStyle(color: AppTheme.textDim))))
        else
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length.clamp(0, 5),
              separatorBuilder: (c, i) => Divider(color: Colors.grey.shade100, height: 1),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                bool isDeduction = ['payment', 'transfer_out', 'admin_debit', 'vendor_withdrawal'].contains(tx['type']);
                String displayAmount = tx['coins_amount']?.toString() ?? '0';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDeduction ? Colors.red.withAlpha(20) : Colors.green.withAlpha(20),
                    child: Icon(isDeduction ? Icons.remove : Icons.add, color: isDeduction ? Colors.red : Colors.green, size: 18),
                  ),
                  title: Text(tx['description'] ?? tx['type'] ?? 'Transaction', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryNavy), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(tx['created_at']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
                  trailing: Text('${isDeduction ? '-' : '+'}${double.tryParse(displayAmount)?.toStringAsFixed(2)} JC', style: TextStyle(color: isDeduction ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                );
              },
            ),
          ),
      ],
    ).animate().fade().slideY(begin: 0.1);
  }

  Widget _buildVendorBalanceCard(BuildContext context, String coinBalance, String cashBalance) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryNavy, Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNavy.withAlpha(80),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('Total Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                  SizedBox(width: 8),
                  Icon(Icons.remove_red_eye_outlined, color: Colors.white70, size: 16),
                ],
              ),
              Image.asset('assets/JapSan.png', height: 40, width: 40),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Japsan Coins', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                  Text('$coinBalance JC', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                ],
              ),
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CashWalletScreen())),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Row(
                      children: [
                        Text('Cash Wallet', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        SizedBox(width: 4),
                        Icon(Icons.open_in_new, color: Colors.white70, size: 12),
                      ],
                    ),
                    Text('₹$cashBalance', style: const TextStyle(color: AppTheme.premiumGold, fontSize: 26, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withAlpha(50)),
              ),
              child: const Text('Wallet Details >', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ).animate().shimmer(duration: 2000.ms);
  }

  Widget _buildQuickAccess(BuildContext context, IconData icon, String label, Widget screen) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        _fetchData();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryNavy, Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryNavy.withAlpha(60),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: AppTheme.premiumGold, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppTheme.primaryNavy, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
