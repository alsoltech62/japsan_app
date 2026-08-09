import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/api_service.dart';
import '../core/theme.dart';

class VendorScanCustomerScreen extends StatefulWidget {
  const VendorScanCustomerScreen({super.key});

  @override
  State<VendorScanCustomerScreen> createState() => _VendorScanCustomerScreenState();
}

class _VendorScanCustomerScreenState extends State<VendorScanCustomerScreen> {
  final userPhoneCtrl = TextEditingController();
  final billAmountCtrl = TextEditingController();
  final coinsToUseCtrl = TextEditingController();
  final manualBonusCtrl = TextEditingController();
  
  bool isLoading = false;
  bool _showScanner = false;
  final MobileScannerController _scannerController = MobileScannerController();

  Future<void> _processPayment() async {
    if (userPhoneCtrl.text.isEmpty || billAmountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter customer phone and bill amount')));
      return;
    }
    setState(() => isLoading = true);
    
    final payload = {
      'user_phone': userPhoneCtrl.text,
      'bill_amount': double.tryParse(billAmountCtrl.text) ?? 0,
      'coins_to_use': double.tryParse(coinsToUseCtrl.text) ?? 0,
      'manual_bonus_coins': double.tryParse(manualBonusCtrl.text) ?? 0,
      'payment_method': 'cash'
    };

    final res = await context.read<ApiService>().processVendorPayment(payload);
    setState(() => isLoading = false);

    if (res['success'] == true) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Complete! Reward given.'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Payment failed'), backgroundColor: Colors.red));
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _showScanner = false;
        });
        
        // If the QR contains JSON { user_id: '...', type: '...' } or just the user's phone, we can handle it.
        // For simplicity, let's just populate the field with whatever we get.
        // In real app, we might parse JSON.
        try {
          // If it's the JSON from My QR
          // qrValue = jsonEncode({'user_id': user?['id'], 'type': 'japsan_user_qr'});
          // but we actually need phone. If we don't have phone, backend should support user_id. 
          // Assuming userPhoneCtrl can accept user_id or phone.
          userPhoneCtrl.text = barcode.rawValue!; 
        } catch (e) {
          userPhoneCtrl.text = barcode.rawValue!;
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bill Customer / Accept Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Use this feature to accept payments and bill your customers.\n\n'
              'Tap the QR Code icon to scan a user\'s Japsan QR, or manually enter their Phone/ID.\n'
              'Based on your Reward Settings, users will automatically receive cashback coins after the payment is complete.',
              style: TextStyle(color: AppTheme.textDim, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_showScanner)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(border: Border.all(color: AppTheme.primaryGold, width: 2), borderRadius: BorderRadius.circular(16)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 30),
                    onPressed: () => setState(() => _showScanner = false),
                  )
                ],
              )
            else
              GestureDetector(
                onTap: () => setState(() => _showScanner = true),
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(color: AppTheme.primaryGold.withAlpha(50), borderRadius: BorderRadius.circular(20)),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, size: 60, color: AppTheme.primaryGold),
                      SizedBox(height: 8),
                      Text('Tap to Scan User', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold))
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),
            const Text('Or Enter Details Manually', style: TextStyle(color: AppTheme.textDim)),
            const SizedBox(height: 24),

            TextField(
              controller: userPhoneCtrl,
              keyboardType: TextInputType.text,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Customer Phone or ID',
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: billAmountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Bill Amount (₹)',
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: coinsToUseCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Coins to Use (Optional)',
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: manualBonusCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Manual Reward Bonus (Optional JC)',
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold, 
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              onPressed: isLoading ? null : _processPayment,
              child: isLoading 
                ? const CircularProgressIndicator(color: Colors.black) 
                : const Text('Complete Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            )
          ],
        ),
      ),
    );
  }
}
