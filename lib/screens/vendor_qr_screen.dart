import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../core/theme.dart';

class VendorQrScreen extends StatefulWidget {
  const VendorQrScreen({super.key});

  @override
  State<VendorQrScreen> createState() => _VendorQrScreenState();
}

class _VendorQrScreenState extends State<VendorQrScreen> {
  Map<String, dynamic>? qrData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQR();
  }

  Future<void> _fetchQR() async {
    final api = context.read<ApiService>();
    final res = await api.getVendorQR();
    if (res['success'] == true) {
      if (mounted) setState(() => qrData = res['data']);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to load QR')));
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<ApiService>().userProfile;
    final String? profilePhoto = user?['profile_photo'];
    final String? businessName = user?['business_name'];
    final String? address = user?['business_address'];
    final String? city = user?['city'];
    final String loc = [if (address != null && address.isNotEmpty) address, if (city != null && city.isNotEmpty) city].join(', ');

    return Scaffold(
      appBar: AppBar(title: const Text('My QR Code')),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
        : qrData == null
          ? const Center(child: Text('QR Code not available', style: TextStyle(color: Colors.white)))
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.primaryGold.withAlpha(50), width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20)],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.primaryGold.withAlpha(50),
                        backgroundImage: profilePhoto != null && profilePhoto.isNotEmpty ? NetworkImage(profilePhoto) : null,
                        child: (profilePhoto == null || profilePhoto.isEmpty) ? const Icon(Icons.store, size: 40, color: AppTheme.primaryGold) : null,
                      ),
                      const SizedBox(height: 16),
                      Text(businessName ?? 'My Store', 
                        style: const TextStyle(color: AppTheme.primaryGold, fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      if (loc.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(loc, style: const TextStyle(color: AppTheme.textDim, fontSize: 14), textAlign: TextAlign.center),
                      ],
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryGold, width: 4),
                        ),
                        // Since we don't have a QR package installed by default, we'll display a fallback or if the API gives an image URL.
                        // Let's assume the API returns a 'qr_image_url' or we just show an icon for now.
                        child: qrData?['qr_image_url'] != null 
                            ? Image.network(qrData!['qr_image_url'], width: 220, height: 220)
                            : const Icon(Icons.qr_code_2, size: 220, color: Colors.black),
                      ),
                      const SizedBox(height: 32),
                      Text('Vendor ID: ${qrData?['vendor_id'] ?? ''}', style: const TextStyle(color: AppTheme.textDim, fontSize: 16)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: AppTheme.primaryGold.withAlpha(30), borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${user?['phone'] ?? ''}@japsan', style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: '${user?['phone'] ?? ''}@japsan'));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI ID copied to clipboard')));
                              },
                              child: const Icon(Icons.copy, size: 20, color: AppTheme.primaryGold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Scan to Pay', style: TextStyle(color: AppTheme.textDim, fontSize: 12, letterSpacing: 2)),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
