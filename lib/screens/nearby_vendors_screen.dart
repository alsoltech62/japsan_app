import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../core/theme.dart';
import 'package:geolocator/geolocator.dart';

class NearbyVendorsScreen extends StatefulWidget {
  const NearbyVendorsScreen({super.key});

  @override
  State<NearbyVendorsScreen> createState() => _NearbyVendorsScreenState();
}

class _NearbyVendorsScreenState extends State<NearbyVendorsScreen> {
  List<dynamic> vendors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVendors();
  }

  Future<void> _fetchVendors() async {
    final api = context.read<ApiService>();
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location disabled');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied)
          throw Exception('Permission denied');
      }

      Position pos = await Geolocator.getCurrentPosition();
      final res = await api.getNearbyVendors(pos.latitude, pos.longitude);
      if (res['success'] == true) {
        var data = res['data'] ?? [];
        setState(() => vendors = data);
      }
    } catch (e) {
      // Fallback or error handling
      final res = await api.getNearbyVendors(
        22.5726,
        88.3639,
      ); // Fallback to Kolkata
      if (res['success'] == true) {
        var data = res['data'] ?? [];
        setState(() => vendors = data);
      }
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Vendors')),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGold),
            )
          : vendors.isEmpty
          ? const Center(
              child: Text(
                'No vendors found nearby.',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vendors.length,
              itemBuilder: (context, index) {
                final v = vendors[index];
                final isSponsored = v['is_sponsored_active'] == true || v['is_sponsored'] == true || v['is_sponsored'] == 1;
                return GestureDetector(
                  onTap: () => _showVendorDetails(context, v),
                  child: Card(
                    color: AppTheme.surfaceDark,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSponsored ? AppTheme.primaryGold : AppTheme.primaryGold.withAlpha(30),
                        width: isSponsored ? 1.5 : 1,
                      ),
                    ),
                    elevation: isSponsored ? 6 : 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isSponsored)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.black, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  '👑 TOP FEATURED #${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Logo / Dummy Placeholder
                              Container(
                                width: 75,
                                height: 75,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.darkGold,
                                      AppTheme.primaryGold.withAlpha(150),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  image:
                                      (v['profile_photo'] != null &&
                                          v['profile_photo']
                                              .toString()
                                              .isNotEmpty)
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            v['profile_photo'],
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(50),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child:
                                    (v['profile_photo'] == null ||
                                        v['profile_photo'].toString().isEmpty)
                                    ? const Icon(
                                        Icons.storefront,
                                        color: Colors.white,
                                        size: 40,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v['business_name'] ?? 'Store',
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    if (v['business_address'] != null &&
                                        v['business_address']
                                            .toString()
                                            .isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 14,
                                            color: AppTheme.textDim,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              '${v['business_address']}',
                                              style: const TextStyle(
                                                color: AppTheme.textDim,
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withAlpha(30),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            '${v['cashback_percent']}% Cashback',
                                            style: const TextStyle(
                                              color: Colors.orange,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withAlpha(30),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            '${v['distance'] ?? 0} km',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Beautiful Offer Banner at the bottom of the card
                        if (v['latest_offer'] != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF00C853),
                                  Color(0xFF009624),
                                ], // Vibrant Green
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.yellowAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '🔥 ACTIVE OFFER',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      Text(
                                        '${v['latest_offer']['title']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (v['latest_offer']['description'] != null && v['latest_offer']['description'].toString().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            '${v['latest_offer']['description']}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showVendorDetails(BuildContext context, dynamic vendor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.darkGold,
                    backgroundImage:
                        (vendor['profile_photo'] != null &&
                            vendor['profile_photo'].toString().isNotEmpty)
                        ? NetworkImage(vendor['profile_photo'])
                        : null,
                    child:
                        (vendor['profile_photo'] == null ||
                            vendor['profile_photo'].toString().isEmpty)
                        ? const Icon(
                            Icons.store,
                            color: AppTheme.primaryGold,
                            size: 30,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor['business_name'] ?? 'Store',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vendor['business_address'] != null &&
                                  vendor['business_address']
                                      .toString()
                                      .isNotEmpty
                              ? '${vendor['business_address']}'
                              : '${vendor['city'] ?? 'Unknown'}',
                          style: const TextStyle(
                            color: AppTheme.textDim,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: AppTheme.lightBorder),
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.person,
                'Owner',
                vendor['owner_name'] ?? 'N/A',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.location_city,
                'Address',
                vendor['business_address'] != null && vendor['business_address'].toString().isNotEmpty
                    ? vendor['business_address']
                    : (vendor['city'] ?? 'N/A'),
              ),
              const SizedBox(height: 12),
              if (vendor['latest_offer'] != null) ...[
                _buildDetailRow(
                  Icons.star,
                  'Special Offer',
                  vendor['latest_offer']['title'] ?? '',
                ),
                if (vendor['latest_offer']['description'] != null &&
                    vendor['latest_offer']['description'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 32,
                      top: 4,
                      bottom: 12,
                    ),
                    child: Text(
                      vendor['latest_offer']['description'],
                      style: const TextStyle(color: AppTheme.textDim),
                    ),
                  ),
              ],
              _buildDetailRow(
                Icons.local_offer,
                'Cashback',
                'Get flat ${vendor['cashback_percent'] ?? 0}% JC cashback on all items!',
              ),
              const SizedBox(height: 12),
              if (vendor['distance'] != null)
                _buildDetailRow(
                  Icons.location_on,
                  'Distance',
                  '${double.tryParse(vendor['distance'].toString())?.toStringAsFixed(2) ?? vendor['distance']} km away',
                ),
              if (vendor['visiting_card_photo'] != null && vendor['visiting_card_photo'].toString().isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Visiting Card',
                  style: TextStyle(
                    color: AppTheme.textDim,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      vendor['visiting_card_photo'],
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGold, size: 20),
        const SizedBox(width: 12),
        Text(
          '$title: ',
          style: const TextStyle(color: AppTheme.textDim, fontSize: 16),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
