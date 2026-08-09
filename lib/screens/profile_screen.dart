import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../core/theme.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final api = context.read<ApiService>();
    final isVendor = api.userRole == 'vendor';
    final res = isVendor ? await api.getVendorProfile() : await api.getProfile();
    
    if (res['success'] == true) {
      if (mounted) setState(() => profileData = res['data'] ?? res);
    }
    if (mounted) setState(() => isLoading = false);
  }
  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiService>();
    final user = profileData ?? api.userProfile;
    final kycStatus = user?['kyc_status'] ?? 'pending';
    final role = api.userRole;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: AppTheme.surfaceDark,
                  backgroundImage: user?['profile_photo'] != null && user!['profile_photo'].toString().isNotEmpty
                      ? NetworkImage(user['profile_photo'])
                      : null,
                  child: (user?['profile_photo'] == null || user!['profile_photo'].toString().isEmpty)
                      ? Text(((user?['name'] ?? user?['owner_name'])?.isNotEmpty == true) ? (user!['name'] ?? user!['owner_name'])[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 40, color: AppTheme.primaryGold, fontWeight: FontWeight.bold))
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppTheme.primaryGold, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, size: 20, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(child: Text(user?['name'] ?? user?['owner_name'] ?? 'User Name', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary))),
          Center(child: Text(user?['phone'] ?? '', style: const TextStyle(color: AppTheme.textSecondary))),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryGold.withAlpha(50)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code_2, size: 16, color: AppTheme.primaryGold),
                  const SizedBox(width: 8),
                  Text(
                    '${user?['phone'] ?? ''}@japsan',
                    style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: '${user?['phone'] ?? ''}@japsan'));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI ID copied to clipboard')));
                    },
                    child: const Icon(Icons.copy, size: 16, color: AppTheme.primaryGold),
                  ),
                ],
              ),
            ),
          ),
          if ((user?['city'] != null && user!['city'].toString().isNotEmpty) || (user?['area'] != null && user!['area'].toString().isNotEmpty) || (user?['business_address'] != null && user!['business_address'].toString().isNotEmpty)) ...[
            const SizedBox(height: 8),
            Center(child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, size: 14, color: AppTheme.textDim),
                const SizedBox(width: 4),
                Flexible(child: Text([user?['business_address'] ?? user?['area'], user?['city']].where((e) => e != null && e.toString().isNotEmpty).join(', '), style: const TextStyle(color: AppTheme.textDim, fontSize: 12), textAlign: TextAlign.center)),
              ],
            )),
          ],
          const SizedBox(height: 32),
          
          Text('ACCOUNT SETTINGS', style: TextStyle(color: AppTheme.primaryGold.withAlpha(200), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          _buildListTile(Icons.person_outline, 'Edit Profile', subtitle: 'Update your personal details', onTap: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            if (result == true) {
              setState(() => isLoading = true);
              _fetchProfile();
            }
          }),
          _buildListTile(Icons.badge, 'KYC Status', 
            subtitle: kycStatus.toUpperCase(), 
            color: kycStatus == 'approved' ? Colors.green : Colors.orange,
            onTap: () {}
          ),
          if (role == 'vendor') 
            _buildListTile(Icons.store, 'Business Settings', subtitle: 'Manage your vendor profile', onTap: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
              if (result == true) {
                setState(() => isLoading = true);
                _fetchProfile();
              }
            }),
            
          const SizedBox(height: 24),
          Text('MORE OPTIONS', style: TextStyle(color: AppTheme.primaryGold.withAlpha(200), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          _buildListTile(Icons.info_outline, 'About Us', subtitle: 'Learn more about Japsan Pay', onTap: () {
            _showAboutUsDialog(context);
          }),
          _buildListTile(Icons.help_outline, 'Support & Help', subtitle: 'Get assistance', onTap: () {
            _showSupportDialog(context);
          }),
          _buildListTile(Icons.question_answer, 'FAQs / Q&A', subtitle: 'Frequently asked questions', onTap: () {
            _showFAQDialog(context);
          }),
          _buildListTile(Icons.privacy_tip_outlined, 'Privacy Policy', subtitle: 'Read our policies', onTap: () {
            _showPrivacyPolicyDialog(context);
          }),
          
          const SizedBox(height: 30),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withAlpha(30), 
              foregroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            onPressed: () {
              api.logout();
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showAboutUsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/JapSan.png', height: 32, width: 32, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            const Flexible(child: Text('About Us', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: const Text(
          'Japsan Pay Ecosystem is a revolutionary platform connecting users and vendors through a dynamic rewards and payment system. \n\nOur mission is to empower local businesses and reward customers for their loyalty through a seamless, decentralized digital ecosystem.',
          style: TextStyle(color: AppTheme.textDim, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Support & Help', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: const Text(
          'For any assistance, please contact our support team:\n\nEmail: support@japsan pay.com\nPhone: +91 98765 43210\n\nOur team is available 24/7 to resolve your queries regarding wallet transactions, vendor payments, and coin purchases.',
          style: TextStyle(color: AppTheme.textDim, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showFAQDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('FAQs / Q&A', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Text(
            'Q: How do I earn Japsan Coins?\nA: You earn coins by scanning and paying at registered vendors, referring friends, and from holding rewards.\n\nQ: How do I withdraw coins?\nA: If you are a vendor, you can withdraw your coins to your bank account via the Withdraw section. Users can use coins to buy from vendors.\n\nQ: When do referral coins unlock?\nA: Referral coins are locked initially. They unlock after the referred user makes their first valid transaction.\n\nQ: How does the network tree work?\nA: The network tree tracks your direct and indirect referrals. You earn joining bonuses and transaction rewards up to 3 levels deep!',
            style: TextStyle(color: AppTheme.textDim, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Privacy Policy', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Text(
            'At Japsan Pay Ecosystem, your privacy is our priority.\n\n1. Data Collection: We collect only essential information such as your name, mobile number, and transaction history to securely manage your wallet.\n\n2. KYC & Compliance: Any KYC documents (Aadhar/PAN) uploaded are securely encrypted and only used for identity verification purposes.\n\n3. Data Sharing: We do not share your personal data with any third-party advertisers. Vendor transactions are kept strictly confidential between the buyer and the seller.\n\nBy continuing to use this application, you agree to these privacy terms.',
            style: TextStyle(color: AppTheme.textDim, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, {String? subtitle, Color? color, VoidCallback? onTap}) {
    return Card(
      color: AppTheme.surfaceDark,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primaryGold.withAlpha(20), width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (color ?? AppTheme.primaryGold).withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color ?? AppTheme.primaryGold),
        ),
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: color ?? AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)) : null,
        trailing: const Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary, size: 16),
        onTap: onTap,
      ),
    );
  }
}
