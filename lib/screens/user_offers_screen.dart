import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../core/api_service.dart';
import '../core/theme.dart';
import 'user_scan_pay_screen.dart';

class UserOffersScreen extends StatefulWidget {
  const UserOffersScreen({super.key});

  @override
  State<UserOffersScreen> createState() => _UserOffersScreenState();
}

class _UserOffersScreenState extends State<UserOffersScreen> {
  List<dynamic> offers = [];
  List<dynamic> filteredOffers = [];
  bool isLoading = true;
  String selectedType = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> offerTypes = [
    'All',
    'Cashback Offer',
    'Festival Offer',
    'Happy Hour Offer',
    'Bonus Coin Offer'
  ];

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOffers() async {
    final api = context.read<ApiService>();
    try {
      Position pos = await Geolocator.getCurrentPosition();
      final res = await api.getUserOffers(pos.latitude, pos.longitude);
      if (res['success'] == true && mounted) {
        setState(() {
          offers = res['data'] ?? [];
          _filterOffers();
        });
      }
    } catch (e) {
      final res = await api.getUserOffers(22.5726, 88.3639);
      if (res['success'] == true && mounted) {
        setState(() {
          offers = res['data'] ?? [];
          _filterOffers();
        });
      }
    }
    if (mounted) setState(() => isLoading = false);
  }

  void _filterOffers() {
    List<dynamic> list = List.from(offers);
    if (selectedType != 'All') {
      list = list.where((o) => o['type'] == selectedType).toList();
    }
    if (_searchController.text.trim().isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      list = list.where((o) {
        final title = (o['title'] ?? '').toString().toLowerCase();
        final desc = (o['description'] ?? '').toString().toLowerCase();
        final store = (o['business_name'] ?? '').toString().toLowerCase();
        return title.contains(query) || desc.contains(query) || store.contains(query);
      }).toList();
    }
    setState(() => filteredOffers = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hot Offers & Deals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              _fetchOffers();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _filterOffers(),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search offers, festival deals, or stores...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGold),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textDim, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _filterOffers();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.primaryGold.withAlpha(50)),
                ),
              ),
            ),
          ),

          // Categories Filter
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: offerTypes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final type = offerTypes[index];
                final isSelected = selectedType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        selectedType = type;
                        _filterOffers();
                      });
                    }
                  },
                  selectedColor: AppTheme.primaryGold,
                  backgroundColor: AppTheme.surfaceDark,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
                : filteredOffers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.local_offer_outlined, size: 64, color: AppTheme.textDim),
                            SizedBox(height: 12),
                            Text('No active offers found', style: TextStyle(color: AppTheme.textDim, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredOffers.length,
                        itemBuilder: (context, index) {
                          final o = filteredOffers[index];
                          return Card(
                            color: AppTheme.surfaceDark,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: AppTheme.primaryGold.withAlpha(40)),
                            ),
                            elevation: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Banner
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFE65100), Color(0xFFFF9800)],
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        o['type'] ?? 'Deal',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time, color: Colors.white, size: 12),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Valid till ${o['valid_until']}',
                                            style: const TextStyle(color: Colors.white, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Content
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        o['title'] ?? 'Special Offer',
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (o['description'] != null && o['description'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          o['description'],
                                          style: const TextStyle(color: AppTheme.textDim, fontSize: 13),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      const Divider(color: Colors.white10, height: 1),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Icon(Icons.storefront, size: 16, color: AppTheme.primaryGold),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '${o['business_name'] ?? 'Partner Store'} • ${o['city'] ?? ''}',
                                              style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (_) => const UserScanPayScreen()),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primaryGold,
                                              foregroundColor: Colors.black,
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: const Text('Avail Deal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
