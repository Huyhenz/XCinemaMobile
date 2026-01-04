// File: lib/screens/user_info_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../services/database_services.dart';
import '../utils/validators.dart';
import '../utils/dialog_helper.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  DateTime? _selectedDateOfBirth;
  UserModel? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  File? _selectedImageFile;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    setState(() => _isLoading = true);
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      _user = await DatabaseService().getUser(userId);
      if (_user != null) {
        _nameController.text = _user!.name;
        _phoneController.text = _user!.phone ?? '';
        _avatarUrlController.text = _user!.avatarUrl ?? '';
        if (_user!.dateOfBirth != null) {
          _selectedDateOfBirth = DateTime.fromMillisecondsSinceEpoch(_user!.dateOfBirth!);
        }
      }
    } catch (e) {
      _showSnackBar('Lỗi tải thông tin: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserInfo() async {
    // Validate name
    String? nameError = Validators.validateName(_nameController.text);
    if (nameError != null) {
      _showSnackBar(nameError, isError: true);
      return;
    }

    // Validate phone if provided
    if (_phoneController.text.trim().isNotEmpty) {
      String? phoneError = Validators.validatePhone(_phoneController.text);
      if (phoneError != null) {
        _showSnackBar(phoneError, isError: true);
        return;
      }
    }

    // Validate date of birth if provided
    if (_selectedDateOfBirth != null) {
      String? dateError = Validators.validateDateOfBirth(_selectedDateOfBirth);
      if (dateError != null) {
        _showSnackBar(dateError, isError: true);
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Format phone number
      String? phoneValue = _phoneController.text.trim().isEmpty 
          ? null 
          : _phoneController.text.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');

      // Xử lý avatar: ưu tiên URL nếu có, nếu không thì upload file
      String? avatarUrl = _user?.avatarUrl;
      
      // Nếu có URL mới nhập, sử dụng URL đó
      if (_avatarUrlController.text.trim().isNotEmpty) {
        avatarUrl = _avatarUrlController.text.trim();
      } else if (_selectedImageFile != null) {
        // Nếu không có URL nhưng có file, upload file
        try {
          avatarUrl = await _uploadAvatar(_selectedImageFile!, userId);
        } catch (e) {
          _showSnackBar('Lỗi upload ảnh đại diện: $e', isError: true);
          setState(() => _isLoading = false);
          return;
        }
      }

      // Update user info
      await DatabaseService().updateUser(userId, {
        'name': _nameController.text.trim(),
        'phone': phoneValue,
        'dateOfBirth': _selectedDateOfBirth?.millisecondsSinceEpoch,
        'avatarUrl': avatarUrl,
      });

      _showSnackBar('Cập nhật thành công!');
      setState(() {
        _isEditing = false;
        _selectedImageFile = null; // Reset selected image
      });
      await _loadUserInfo();
    } catch (e) {
      _showSnackBar('Lỗi cập nhật: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showSnackBar(String message, {bool isError = false}) async {
    if (isError) {
      await DialogHelper.showError(context, message);
    } else {
      await DialogHelper.showSuccess(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF2196F3).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2196F3).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Thông Tin Cá Nhân',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          if (!_isEditing && !_isLoading)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => setState(() => _isEditing = true),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFFE50914)),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildAvatar(),
            const SizedBox(height: 32),
            _buildInfoCard(),
            if (_isEditing) ...[
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Future<String> _uploadAvatar(File imageFile, String userId) async {
    try {
      // Tạo reference đến Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('$userId.jpg');

      // Upload file
      await storageRef.putFile(imageFile);

      // Lấy download URL
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading avatar: $e');
      rethrow;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Lỗi chọn ảnh: $e', isError: true);
    }
  }

  Widget _buildAvatar() {
    // Hiển thị ảnh đã chọn hoặc ảnh từ URL hoặc initial
    Widget avatarWidget;
    
    // Ưu tiên: file đã chọn > URL mới nhập > URL hiện tại > initial
    String? avatarUrlToShow = _selectedImageFile != null 
        ? null // Sẽ hiển thị file
        : (_avatarUrlController.text.trim().isNotEmpty 
            ? _avatarUrlController.text.trim() 
            : _user?.avatarUrl);
    
    if (_selectedImageFile != null) {
      // Hiển thị ảnh vừa chọn từ file
      avatarWidget = ClipOval(
        child: Image.file(
          _selectedImageFile!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    } else if (avatarUrlToShow != null && avatarUrlToShow.isNotEmpty) {
      // Hiển thị avatar từ URL
      avatarWidget = ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrlToShow!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 120,
            height: 120,
            color: const Color(0xFF2A2A2A),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 120,
            height: 120,
            color: const Color(0xFF2A2A2A),
            child: Text(
              _user?.name[0].toUpperCase() ?? 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    } else {
      // Hiển thị initial
      avatarWidget = CircleAvatar(
        radius: 60,
        backgroundColor: const Color(0xFF2A2A2A),
        child: Text(
          _user?.name[0].toUpperCase() ?? 'U',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _isEditing ? _pickImage : null,
      child: Stack(
        children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 4,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: avatarWidget,
              ),
            ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1A1A1A),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withOpacity(0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2196F3).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoField(
            'Họ Tên',
            _nameController,
            Icons.person_outline,
            enabled: _isEditing,
          ),
          const SizedBox(height: 20),
          _buildInfoField(
            'Email',
            TextEditingController(text: _user?.email ?? ''),
            Icons.email_outlined,
            enabled: false,
          ),
          const SizedBox(height: 20),
          _buildInfoField(
            'Số Điện Thoại',
            _phoneController,
            Icons.phone_outlined,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          _buildDateOfBirthField(),
          if (_isEditing) ...[
            const SizedBox(height: 20),
            _buildInfoField(
              'Link Avatar (URL)',
              _avatarUrlController,
              Icons.image_outlined,
              enabled: _isEditing,
              keyboardType: TextInputType.url,
            ),
          ],
          const SizedBox(height: 20),
          _buildReadOnlyInfo(
            'Vai Trò',
            _user?.role == 'admin' ? 'Quản Trị Viên' : 'Thành Viên',
            Icons.badge_outlined,
          ),
          if (_user?.createdAt != null) ...[
            const SizedBox(height: 20),
            _buildReadOnlyInfo(
              'Ngày Tham Gia',
              DateFormat('dd/MM/yyyy').format(
                DateTime.fromMillisecondsSinceEpoch(_user!.createdAt!),
              ),
              Icons.calendar_today_outlined,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoField(
      String label,
      TextEditingController controller,
      IconData icon, {
        bool enabled = true,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: enabled
                ? LinearGradient(
                    colors: [
                      const Color(0xFF2A2A2A).withOpacity(0.8),
                      const Color(0xFF1A1A1A).withOpacity(0.8),
                    ],
                  )
                : const LinearGradient(
                    colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
                  ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled
                  ? const Color(0xFF2196F3).withOpacity(0.3)
                  : const Color(0xFF2A2A2A).withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: enabled
                      ? const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.grey.withOpacity(0.3),
                            Colors.grey.withOpacity(0.2),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateOfBirthField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ngày Tháng Năm Sinh',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: _isEditing
                ? LinearGradient(
                    colors: [
                      const Color(0xFF2A2A2A).withOpacity(0.8),
                      const Color(0xFF1A1A1A).withOpacity(0.8),
                    ],
                  )
                : const LinearGradient(
                    colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
                  ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isEditing
                  ? const Color(0xFF2196F3).withOpacity(0.3)
                  : const Color(0xFF2A2A2A).withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: _isEditing
                ? [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            onTap: _isEditing
                ? () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFFE50914),
                              onPrimary: Colors.white,
                              surface: Color(0xFF1A1A1A),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDateOfBirth = picked;
                      });
                    }
                  }
                : null,
            child: InputDecorator(
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFFE50914)),
              ),
              child: Text(
                _selectedDateOfBirth == null
                    ? 'Chưa có thông tin'
                    : DateFormat('dd/MM/yyyy').format(_selectedDateOfBirth!),
                style: TextStyle(
                  color: _selectedDateOfBirth == null ? Colors.grey[600] : Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyInfo(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF2196F3).withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2196F3).withOpacity(0.3),
                      const Color(0xFF1976D2).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF2196F3), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isEditing = false;
                    _selectedImageFile = null; // Reset selected image
                    // Reset to original values
                    if (_user != null) {
                      _nameController.text = _user!.name;
                      _phoneController.text = _user!.phone ?? '';
                      _avatarUrlController.text = _user!.avatarUrl ?? '';
                      _selectedDateOfBirth = _user!.dateOfBirth != null
                          ? DateTime.fromMillisecondsSinceEpoch(_user!.dateOfBirth!)
                          : null;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Hủy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2196F3).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _updateUserInfo,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Lưu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}