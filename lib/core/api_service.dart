import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiService extends ChangeNotifier {
  // Automatically use correct localhost for Android Emulator vs Web/Desktop
  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'https://japsanpay.com/backend/api';
    }
    return 'https://japsanpay.com/backend/api';
  }

  String? _token;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;

  String? get token => _token;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  String get userRole => _userProfile?['role'] ?? 'user';

  ApiService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final profileStr = prefs.getString('user_profile');
    if (profileStr != null) {
      _userProfile = json.decode(profileStr);
    }
    notifyListeners();
  }

  Future<void> _saveToken(String token, Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_profile', json.encode(profile));
    _token = token;
    _userProfile = profile;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_profile');
    _token = null;
    _userProfile = null;
    notifyListeners();
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Future<Map<String, dynamic>> sendOtp(String phone, String userType, {String purpose = 'login'}) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send_otp.php'),
        headers: _getHeaders(),
        body: json.encode({
          'phone': phone,
          'user_type': userType,
          'purpose': purpose,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> verifyOtp(
    String phone,
    String otp,
    String userType, {
    String purpose = 'login',
    String? name,
    String? referralCode,
  }) async {
    _setLoading(true);
    try {
      final bodyData = {
        'phone': phone, 
        'otp': otp, 
        'user_type': userType,
        'purpose': purpose,
      };
      if (name != null) bodyData['name'] = name;
      if (referralCode != null) bodyData['referral_code'] = referralCode;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify_otp.php'),
        headers: _getHeaders(),
        body: json.encode(bodyData),
      );
      final data = json.decode(response.body);
      if (data['success'] == true) {
        await _saveToken(data['data']['token'], data['data']['profile']);
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> uploadFile(String filePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload.php'));
      final headers = _getHeaders();
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.body.trim().isEmpty) {
        return {'success': false, 'message': 'Upload failed: Server returned empty response (Status ${response.statusCode})'};
      }
      
      try {
        return json.decode(response.body);
      } catch (e) {
        return {'success': false, 'message': 'Upload failed: Invalid server response (Status ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
        body: json.encode(data),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getWallet() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wallet/get_wallet.php'),
        headers: _getHeaders(),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getRoiDashboard(String period) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendors/roi_dashboard.php?period=$period'),
        headers: _getHeaders(),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getNearbyVendors(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/nearby_vendors.php?lat=$lat&lng=$lng'),
        headers: _getHeaders(),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getNetwork() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/network/dashboard.php'),
        headers: await _getHeaders(),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> scanVendorQR(String vendorId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/qr/scan.php?vendor_id=$vendorId'),
        headers: _getHeaders(),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> processUserPay(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/user_pay.php'),
        headers: _getHeaders(),
        body: json.encode(data),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- VENDOR APIS ---

  Future<Map<String, dynamic>> processVendorPayment(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/process_payment.php'),
        headers: _getHeaders(),
        body: json.encode(data),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getRewardSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendors/reward_settings.php'),
        headers: _getHeaders(),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateRewardSettings(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/vendors/reward_settings.php'),
        headers: _getHeaders(),
        body: json.encode(data),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getVendorOffers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendors/offers.php'),
        headers: _getHeaders(),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createVendorOffer(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vendors/offers.php'),
        headers: _getHeaders(),
        body: json.encode(data),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendVendorCampaign(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vendors/campaigns.php'),
        headers: _getHeaders(),
        body: json.encode(data),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getWithdrawals() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendors/withdraw.php'),
        headers: _getHeaders(),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> requestWithdraw(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vendors/withdraw.php'),
        headers: _getHeaders(),
        body: json.encode(data),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> registerVendor(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register_vendor.php'),
        headers: _getHeaders(),
        body: json.encode(data),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile.php?_t=${DateTime.now().millisecondsSinceEpoch}'),
        headers: _getHeaders(),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/profile.php'),
        headers: _getHeaders(),
        body: json.encode(data),
      );
      final res = json.decode(response.body);
      if (res['success'] == true) {
        await refreshProfile();
      }
      return res;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> userTransfer(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/user_transfer.php'),
        headers: _getHeaders(),
        body: json.encode(data),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createRazorpayOrder(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/create_order.php'),
        headers: _getHeaders(),
        body: json.encode(data),
      );
      
      try {
        return json.decode(response.body);
      } catch (e) {
        return {'success': false, 'message': 'Server returned an invalid response (Status: ${response.statusCode}). Please ensure backend is updated.'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> buyCoins(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/buy_coins.php'),
        headers: _getHeaders(),
        body: json.encode(data),
      );
      
      try {
        return json.decode(response.body);
      } catch (e) {
        return {'success': false, 'message': 'Server returned an invalid response (Status: ${response.statusCode}).'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getTransactions({Map<String, String>? params}) async {
    try {
      final uri = Uri.parse('$baseUrl/transactions/history.php').replace(queryParameters: params);
      final response = await http.get(uri, headers: _getHeaders());
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getVendorProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendors/profile.php?_t=${DateTime.now().millisecondsSinceEpoch}'),
        headers: _getHeaders(),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateVendorProfile(Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/vendors/profile.php'),
        headers: _getHeaders(),
        body: json.encode(data),
      );
      final res = json.decode(response.body);
      if (res['success'] == true) {
        await refreshProfile();
      }
      return res;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getVendorQR() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/qr/generate.php'),
        headers: _getHeaders(),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getReferrals() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/referral/get_referrals.php'),
        headers: _getHeaders(),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getNotifications({Map<String, String>? params}) async {
    try {
      final uri = Uri.parse('$baseUrl/notifications/list.php').replace(queryParameters: params);
      final response = await http.get(uri, headers: _getHeaders());
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> markNotifRead(Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/list.php'),
        headers: _getHeaders(),
        body: json.encode(data),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> refreshProfile() async {
    try {
      if (_userProfile == null) return;
      final isVendor = _userProfile?['role'] == 'vendor';
      final res = isVendor ? await getVendorProfile() : await getProfile();
      if (res['success'] == true && res['data'] != null) {
        _userProfile = res['data'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile', json.encode(_userProfile));
        notifyListeners();
      }
    } catch (e) {
      // Ignore
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
