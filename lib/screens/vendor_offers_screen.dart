import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../core/theme.dart';

class VendorOffersScreen extends StatefulWidget {
  const VendorOffersScreen({super.key});

  @override
  State<VendorOffersScreen> createState() => _VendorOffersScreenState();
}

class _VendorOffersScreenState extends State<VendorOffersScreen> {
  List<dynamic> offers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    final api = context.read<ApiService>();
    final res = await api.getVendorOffers();
    if (res['success'] == true) {
      if(mounted) setState(() => offers = res['data'] ?? []);
    }
    if(mounted) setState(() => isLoading = false);
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = 'Cashback Offer';
    String validUntil = DateTime.now().add(const Duration(days: 7)).toString().substring(0, 10);
    
    // Using StatefulBuilder to allow updating the dialog UI when dropdown/date changes
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      title: const Text('Create Offer', style: TextStyle(color: AppTheme.textPrimary)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, style: const TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: descCtrl, style: const TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: type,
              dropdownColor: AppTheme.surfaceDark,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Offer Type'),
              items: ['Cashback Offer', 'Festival Offer', 'Happy Hour Offer', 'Bonus Coin Offer']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setDialogState(() => type = val);
                }
              },
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.parse(validUntil),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setDialogState(() => validUntil = date.toString().substring(0, 10));
                }
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: TextEditingController(text: validUntil),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Valid Until'),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textDim))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
          onPressed: () async {
            Navigator.pop(ctx);
            setState(() => isLoading = true);
            final res = await context.read<ApiService>().createVendorOffer({
              'title': titleCtrl.text,
              'description': descCtrl.text,
              'type': type,
              'valid_until': validUntil
            });
            if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Action completed')));
            _fetchOffers();
          },
          child: const Text('Create', style: TextStyle(color: Colors.black)),
        )
      ],
    );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offer Management')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Create special offers that users will see when they view your profile in the "Nearby Vendors" section.',
              style: TextStyle(color: AppTheme.textDim, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)) :
              offers.isEmpty ? const Center(child: Text('No offers created', style: TextStyle(color: AppTheme.textDim))) :
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: offers.length,
          itemBuilder: (ctx, i) {
            final o = offers[i];
            return Card(
              color: Colors.orange.withAlpha(25),
              child: ListTile(
                title: Text(o['title'], style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${o['type']} • Valid till ${o['valid_until']}', style: const TextStyle(color: Colors.orange)),
                    if (o['description'] != null && o['description'].toString().isNotEmpty)
                      Text(o['description'], style: const TextStyle(color: AppTheme.textDim, fontSize: 12)),
                  ],
                ),
                trailing: Chip(label: Text(o['status'] ?? 'active', style: const TextStyle(color: Colors.black, fontSize: 10)), backgroundColor: AppTheme.primaryGold),
              ),
            );
          },
        ),
      ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppTheme.primaryGold,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
