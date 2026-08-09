import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api_service.dart';
import '../core/theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _cityController;
  late TextEditingController _areaController;
  late TextEditingController _dobController;
  
  // Vendor specific
  late TextEditingController _businessNameCtrl;
  late TextEditingController _bankAccountCtrl;
  late TextEditingController _bankIfscCtrl;
  late TextEditingController _bankNameCtrl;
  late TextEditingController _whatsappCtrl;
  
  bool _isLoading = false;
  bool _isVendor = false;
  
  String? _profilePhoto;
  String? _kycDocument;
  String? _kycDocumentBack;
  String? _visitingCardPhoto;
  bool _isUploading = false;
  bool _isUploadingBack = false;
  bool _isUploadingVisitingCard = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<ApiService>().userProfile;
    _isVendor = user?['role'] == 'vendor';
    _profilePhoto = user?['profile_photo'];
    _kycDocument = user?['kyc_document'];
    _kycDocumentBack = user?['kyc_document_back'];
    _visitingCardPhoto = user?['visiting_card_photo'];
    
    _nameController = TextEditingController(text: user?['name'] ?? user?['owner_name'] ?? '');
    _emailController = TextEditingController(text: user?['email'] ?? '');
    _cityController = TextEditingController(text: user?['city'] ?? '');
    _areaController = TextEditingController(text: user?['area'] ?? user?['business_address'] ?? '');
    _dobController = TextEditingController(text: user?['dob'] ?? '');
    
    _businessNameCtrl = TextEditingController(text: user?['business_name'] ?? '');
    _bankAccountCtrl = TextEditingController(text: user?['bank_account_number'] ?? '');
    _bankIfscCtrl = TextEditingController(text: user?['bank_ifsc'] ?? '');
    _bankNameCtrl = TextEditingController(text: user?['bank_name'] ?? '');
    _whatsappCtrl = TextEditingController(text: user?['whatsapp_number'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _dobController.dispose();
    _businessNameCtrl.dispose();
    _bankAccountCtrl.dispose();
    _bankIfscCtrl.dispose();
    _bankNameCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final api = context.read<ApiService>();

    final data = {
      'name': _nameController.text,
      'email': _emailController.text,
      'city': _cityController.text,
      'area': _areaController.text,
      'dob': _dobController.text,
    };
    
    if (_profilePhoto != null && _profilePhoto!.isNotEmpty) {
      data['profile_photo'] = _profilePhoto!;
    }
    if (_kycDocument != null && _kycDocument!.isNotEmpty) {
      data['kyc_document'] = _kycDocument!;
    }
    if (_kycDocumentBack != null && _kycDocumentBack!.isNotEmpty) {
      data['kyc_document_back'] = _kycDocumentBack!;
    }
    if (_visitingCardPhoto != null && _visitingCardPhoto!.isNotEmpty) {
      data['visiting_card_photo'] = _visitingCardPhoto!;
    }

    if (_isVendor) {
      data['owner_name'] = _nameController.text;
      data['business_name'] = _businessNameCtrl.text;
      data['business_address'] = _areaController.text;
      data['bank_account_number'] = _bankAccountCtrl.text;
      data['bank_ifsc'] = _bankIfscCtrl.text;
      data['bank_name'] = _bankNameCtrl.text;
      data['whatsapp_number'] = _whatsappCtrl.text;
    }

    final response = _isVendor 
        ? await api.updateVendorProfile(data) 
        : await api.updateProfile(data);

    setState(() => _isLoading = false);

    if (response['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to update profile'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage(String field) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    
    setState(() {
      if (field == 'kyc_document_back') {
        _isUploadingBack = true;
      } else if (field == 'visiting_card_photo') {
        _isUploadingVisitingCard = true;
      } else {
        _isUploading = true;
      }
    });
    
    final res = await context.read<ApiService>().uploadFile(file.path);
    
    setState(() {
      if (field == 'kyc_document_back') {
        _isUploadingBack = false;
      } else if (field == 'visiting_card_photo') {
        _isUploadingVisitingCard = false;
      } else {
        _isUploading = false;
      }
    });
    
    if (res['success'] == true) {
      setState(() {
        if (field == 'profile_photo') _profilePhoto = res['data']['url'];
        if (field == 'kyc_document') _kycDocument = res['data']['url'];
        if (field == 'kyc_document_back') _kycDocumentBack = res['data']['url'];
        if (field == 'visiting_card_photo') _visitingCardPhoto = res['data']['url'];
      });
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload successful!'), backgroundColor: Colors.green));
      }
    } else {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Upload failed'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _pickAndUploadImage('profile_photo'),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50, 
                          backgroundColor: AppTheme.surfaceDark, 
                          backgroundImage: _profilePhoto != null && _profilePhoto!.isNotEmpty ? NetworkImage(_profilePhoto!) : null,
                          child: _profilePhoto == null || _profilePhoto!.isEmpty ? const Icon(Icons.person, size: 50, color: AppTheme.primaryGold) : null,
                        ),
                        if (_isUploading) const Positioned.fill(child: CircularProgressIndicator()),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: AppTheme.primaryGold, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  if (_isVendor) ...[
                    _buildTextField('Business Name', _businessNameCtrl, Icons.store),
                    const SizedBox(height: 16),
                  ],
                  
                  _buildTextField(_isVendor ? 'Owner Name' : 'Full Name', _nameController, Icons.person),
                  const SizedBox(height: 16),
                  _buildTextField('Email', _emailController, Icons.email),
                  const SizedBox(height: 16),
                  
                  if (_isVendor) ...[
                    _buildTextField('WhatsApp Number', _whatsappCtrl, Icons.chat),
                    const SizedBox(height: 16),
                  ],
                  
                  _buildTextField('City', _cityController, Icons.location_city),
                  const SizedBox(height: 16),
                  _buildTextField(_isVendor ? 'Business Address' : 'Address', _areaController, Icons.map),
                  
                  if (!_isVendor) ...[
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppTheme.primaryNavy,
                                  onPrimary: Colors.white,
                                  surface: AppTheme.cardBackground,
                                  onSurface: AppTheme.textPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() {
                            _dobController.text = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: _buildTextField('Date of Birth (YYYY-MM-DD)', _dobController, Icons.cake),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.lightBorder),
                    ),
                    tileColor: AppTheme.cardBackground,
                    leading: const Icon(Icons.credit_card, color: AppTheme.primaryGold),
                    title: const Text('Aadhar/PAN (Front Side)', style: TextStyle(color: AppTheme.textPrimary)),
                    subtitle: Text(_kycDocument != null && _kycDocument!.isNotEmpty ? 'Uploaded' : 'Tap to upload', style: TextStyle(color: _kycDocument != null && _kycDocument!.isNotEmpty ? AppTheme.success : AppTheme.textSecondary)),
                    trailing: (_isUploading && !_isUploadingBack) ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : const Icon(Icons.upload_file, color: AppTheme.primaryGold),
                    onTap: () => _pickAndUploadImage('kyc_document'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.lightBorder),
                    ),
                    tileColor: AppTheme.cardBackground,
                    leading: const Icon(Icons.credit_card_outlined, color: AppTheme.primaryGold),
                    title: const Text('Aadhar/PAN (Back Side)', style: TextStyle(color: AppTheme.textPrimary)),
                    subtitle: Text(_kycDocumentBack != null && _kycDocumentBack!.isNotEmpty ? 'Uploaded' : 'Tap to upload', style: TextStyle(color: _kycDocumentBack != null && _kycDocumentBack!.isNotEmpty ? AppTheme.success : AppTheme.textSecondary)),
                    trailing: _isUploadingBack ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : const Icon(Icons.upload_file, color: AppTheme.primaryGold),
                    onTap: () => _pickAndUploadImage('kyc_document_back'),
                  ),
                  
                  if (_isVendor) ...[
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.lightBorder),
                      ),
                      tileColor: AppTheme.cardBackground,
                      leading: const Icon(Icons.storefront, color: AppTheme.primaryGold),
                      title: const Text('Visiting Card / Shop Photo', style: TextStyle(color: AppTheme.textPrimary)),
                      subtitle: Text(_visitingCardPhoto != null && _visitingCardPhoto!.isNotEmpty ? 'Uploaded' : 'Tap to upload (Shown to users)', style: TextStyle(color: _visitingCardPhoto != null && _visitingCardPhoto!.isNotEmpty ? AppTheme.success : AppTheme.textSecondary)),
                      trailing: _isUploadingVisitingCard ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : const Icon(Icons.upload_file, color: AppTheme.primaryGold),
                      onTap: () => _pickAndUploadImage('visiting_card_photo'),
                    ),
                    const SizedBox(height: 32),
                    const Text('Bank Details', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    _buildTextField('Bank Name', _bankNameCtrl, Icons.account_balance),
                    const SizedBox(height: 16),
                    _buildTextField('Account Number', _bankAccountCtrl, Icons.numbers),
                    const SizedBox(height: 16),
                    _buildTextField('IFSC Code', _bankIfscCtrl, Icons.code),
                  ],

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('SAVE CHANGES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryGold),
      ),
    );
  }
}
