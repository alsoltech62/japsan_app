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
import 'user_withdraw_screen.dart';
import 'user_offers_screen.dart';
import 'vendor_advertising_screen.dart';

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
  Map<String, dynamic>? _latestNotif;
  bool _showNotifAlert = true;
  bool isLoading = true;
  final PageController _pageController = PageController();
  Timer? _bannerTimer;
  List<Map<String, dynamic>> _dynamicBanners = [];
  final List<String> _fallbackBanners = [
    'assets/ba1.jpeg',
    'assets/ba2.jpeg',
    'assets/ba3.jpeg'
  ];

  @override
  void initState() {
    super.initState();
    _fetchBalance();
    _fetchBanners();
    _fetchLatestNotification();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients) {
        final totalCount = _dynamicBanners.isNotEmpty ? _dynamicBanners.length : _fallbackBanners.length;
        if (totalCount > 1) {
          int nextPage = (_pageController.page?.round() ?? 0) + 1;
          if (nextPage >= totalCount) nextPage = 0;
          _pageController.animateToPage(nextPage, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
        }
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

  Future<void> _fetchBanners() async {
    final api = context.read<ApiService>();
    final res = await api.getBanners();
    if (res['success'] == true && res['data']?['banners'] != null) {
      final List list = res['data']['banners'];
      if (list.isNotEmpty && mounted) {
        setState(() {
          _dynamicBanners = list.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    }
  }

  Future<void> _fetchLatestNotification() async {
    final api = context.read<ApiService>();
    final res = await api.getNotifications(params: {'limit': '1'});
    if (res['success'] == true && res['data']?['notifications'] != null) {
      final List list = res['data']['notifications'];
      if (list.isNotEmpty && mounted) {
        final first = list.first;
        final isRead = first['is_read'] == 1 || first['is_read'] == true;
        if (!isRead) {
          setState(() {
            _latestNotif = first;
            _showNotifAlert = true;
          });
        }
      }
    }
  }

  void _showNotificationDetailModal(BuildContext context, dynamic notif, VoidCallback onDismiss) {
    final rawMsg = notif['message'] ?? '';
    final cleanMsg = rawMsg.replaceAll(RegExp(r'\[IMG:.+?\]'), '').trim();
    String? imgUrl;
    if (notif['image_url'] != null && notif['image_url'].toString().trim().isNotEmpty) {
      imgUrl = notif['image_url'].toString().trim();
    } else if (notif['image'] != null && notif['image'].toString().trim().isNotEmpty) {
      imgUrl = notif['image'].toString().trim();
    } else {
      final regExp = RegExp(r'\[IMG:(.+?)\]');
      final match = regExp.firstMatch(rawMsg);
      if (match != null && match.groupCount >= 1) {
        imgUrl = match.group(1)!.trim();
      }
    }

    if (imgUrl != null && !imgUrl.startsWith('http')) {
      String p = imgUrl.startsWith('/') ? imgUrl.substring(1) : imgUrl;
      imgUrl = p.startsWith('backend/') ? 'https://japsanpay.com/$p' : 'https://japsanpay.com/backend/$p';
    }

    if (notif['id'] != null) {
      context.read<ApiService>().markNotifRead({'notification_id': notif['id']});
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active, color: Colors.amber, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notif['title'] ?? 'Notification',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Colors.grey),
              onPressed: () => Navigator.pop(ctx),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imgUrl != null && imgUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imgUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 160,
                        color: Colors.grey.shade100,
                        child: const Center(child: CircularProgressIndicator(color: Colors.amber)),
                      );
                    },
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                cleanMsg,
                style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDismiss();
            },
            child: const Text('Dismiss', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDismiss();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('View All Notifications'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balanceStr = walletData?['wallet']?['coin_balance']?.toString() ?? '0';
    final balance = double.tryParse(balanceStr) ?? 0.0;
    final rateStr = walletData?['redemption_rate']?.toString() ?? '0.7';
    final rate = double.tryParse(rateStr) ?? 0.7;
    final estValue = (balance * rate).toStringAsFixed(2);
    final hasDynamic = _dynamicBanners.isNotEmpty;
    final bannerCount = hasDynamic ? _dynamicBanners.length : _fallbackBanners.length;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Dismissible Top Notification Alert Banner (Same as Web)
        if (_latestNotif != null && _showNotifAlert) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
              boxShadow: [
                BoxShadow(color: Colors.orange.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      _showNotificationDetailModal(context, _latestNotif!, () {
                        if (mounted) setState(() => _showNotifAlert = false);
                      });
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _latestNotif!['title'] ?? 'New Notification',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          (_latestNotif!['message'] ?? '').replaceAll(RegExp(r'\[IMG:.+?\]'), '').trim(),
                          style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFF92400E)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() => _showNotifAlert = false);
                  },
                ),
              ],
            ),
          ).animate().slideY(begin: -0.2, end: 0).fade(),
        ],

        _buildUserBalanceCard(context, '$balanceStr', estValue),
        const SizedBox(height: 24),
        // Main Promotional Banner
        SizedBox(
          height: 130,
          child: PageView.builder(
            controller: _pageController,
            itemCount: bannerCount,
            itemBuilder: (context, index) {
              if (hasDynamic) {
                final b = _dynamicBanners[index];
                final imgUrl = b['full_image_url'] ?? b['image_url'] ?? '';
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        _fallbackBanners[index % _fallbackBanners.length],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              } else {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: AssetImage(_fallbackBanners[index]),
                      fit: BoxFit.fill,
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                );
              }
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
            _buildQuickAccess(context, Icons.storefront, 'Nearby Stores', const NearbyVendorsScreen()),
            _buildQuickAccess(context, Icons.local_offer, 'Hot Offers', const UserOffersScreen()),
            _buildQuickAccess(context, Icons.account_balance, 'Withdraw', const UserWithdrawScreen()),
            _buildQuickAccess(context, Icons.card_giftcard_outlined, 'Refer & Earn', const ReferralScreen()),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Row(
                    children: [
                      Text('Estimated Value', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                      SizedBox(width: 4),
                    ],
                  ),
                  Text('₹$cashBalance', style: const TextStyle(color: AppTheme.premiumGold, fontSize: 26, fontWeight: FontWeight.w900)),
                ],
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
  Map<String, dynamic>? _latestNotif;
  bool _showNotifAlert = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchLatestNotification();
  }

  Future<void> _fetchData() async {
    final api = context.read<ApiService>();
    final res = await api.getWallet();
    if (res['success'] == true) {
      if(mounted) setState(() => data = res['data']);
    }
    if(mounted) setState(() => isLoading = false);
  }

  Future<void> _fetchLatestNotification() async {
    final api = context.read<ApiService>();
    final res = await api.getNotifications(params: {'limit': '1'});
    if (res['success'] == true && res['data']?['notifications'] != null) {
      final List list = res['data']['notifications'];
      if (list.isNotEmpty && mounted) {
        final first = list.first;
        final isRead = first['is_read'] == 1 || first['is_read'] == true;
        if (!isRead) {
          setState(() {
            _latestNotif = first;
            _showNotifAlert = true;
          });
        }
      }
    }
  }

  void _showNotificationDetailModal(BuildContext context, dynamic notif, VoidCallback onDismiss) {
    final rawMsg = notif['message'] ?? '';
    final cleanMsg = rawMsg.replaceAll(RegExp(r'\[IMG:.+?\]'), '').trim();
    String? imgUrl;
    if (notif['image_url'] != null && notif['image_url'].toString().trim().isNotEmpty) {
      imgUrl = notif['image_url'].toString().trim();
    } else if (notif['image'] != null && notif['image'].toString().trim().isNotEmpty) {
      imgUrl = notif['image'].toString().trim();
    } else {
      final regExp = RegExp(r'\[IMG:(.+?)\]');
      final match = regExp.firstMatch(rawMsg);
      if (match != null && match.groupCount >= 1) {
        imgUrl = match.group(1)!.trim();
      }
    }

    if (imgUrl != null && !imgUrl.startsWith('http')) {
      String p = imgUrl.startsWith('/') ? imgUrl.substring(1) : imgUrl;
      imgUrl = p.startsWith('backend/') ? 'https://japsanpay.com/$p' : 'https://japsanpay.com/backend/$p';
    }

    if (notif['id'] != null) {
      context.read<ApiService>().markNotifRead({'notification_id': notif['id']});
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active, color: Colors.amber, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notif['title'] ?? 'Notification',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Colors.grey),
              onPressed: () => Navigator.pop(ctx),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imgUrl != null && imgUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imgUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 160,
                        color: Colors.grey.shade100,
                        child: const Center(child: CircularProgressIndicator(color: Colors.amber)),
                      );
                    },
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                cleanMsg,
                style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDismiss();
            },
            child: const Text('Dismiss', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDismiss();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('View All Notifications'),
          ),
        ],
      ),
    );
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
        // Dismissible Top Notification Alert Banner (Same as Web)
        if (_latestNotif != null && _showNotifAlert) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
              boxShadow: [
                BoxShadow(color: Colors.orange.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      _showNotificationDetailModal(context, _latestNotif!, () {
                        if (mounted) setState(() => _showNotifAlert = false);
                      });
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _latestNotif!['title'] ?? 'New Notification',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          (_latestNotif!['message'] ?? '').replaceAll(RegExp(r'\[IMG:.+?\]'), '').trim(),
                          style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFF92400E)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() => _showNotifAlert = false);
                  },
                ),
              ],
            ),
          ).animate().slideY(begin: -0.2, end: 0).fade(),
        ],

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
            _buildQuickAccess(context, Icons.rocket_launch, 'Boost (Top 1-3)', const VendorAdvertisingScreen()),
            _buildQuickAccess(context, Icons.point_of_sale, 'Bill Customer', const VendorScanCustomerScreen()),
            _buildQuickAccess(context, Icons.qr_code, 'Show QR', const VendorQrScreen()),
            _buildQuickAccess(context, Icons.local_offer_outlined, 'Offers', const VendorOffersScreen()),
            _buildQuickAccess(context, Icons.account_balance, 'Withdraw', const VendorWithdrawScreen()),
            _buildQuickAccess(context, Icons.account_balance_wallet, 'Buy Coins', const BuyCoinsScreen()),
            _buildQuickAccess(context, Icons.settings_outlined, 'Rewards', const VendorRewardSettingsScreen()),
            _buildQuickAccess(context, Icons.campaign_outlined, 'Campaigns', const VendorCampaignsScreen()),
            _buildQuickAccess(context, Icons.person_outline, 'Profile', const ProfileScreen()),
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
