import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_services.dart';
import '../utils/dialog_helper.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isLoading = false;

  // Hàm reload user để kiểm tra xem đã verify chưa
  Future<void> _checkVerification() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload(); // Làm mới thông tin user từ Firebase
        
        // Cần lấy lại instance mới nhất sau khi reload
        final updatedUser = FirebaseAuth.instance.currentUser;
        
        if (updatedUser != null && updatedUser.emailVerified) {
          // --- QUAN TRỌNG: LƯU VÀO DB NGAY TẠI ĐÂY ---
          // Vì AuthChecker sẽ tự chuyển trang, ta cần đảm bảo DB có dữ liệu trước
          final dbService = DatabaseService();
          UserModel? existingUser = await dbService.getUser(updatedUser.uid);
          
          if (existingUser == null) {
            // Tạo user mới từ temp_registrations nếu có
            print('📝 User chưa tồn tại trong DB (verify), tạo user mới...');
            String name = 'New User';
            String? phone;
            int? dateOfBirth;
            
            // Lấy thông tin từ temp_registrations
            print('📝 Đang lấy thông tin từ temp_registrations (verify)...');
            Map<dynamic, dynamic>? tempData = await dbService.getTempRegistration(updatedUser.uid);
            
            if (tempData != null && tempData.isNotEmpty) {
              print('✅ Đã lấy được temp_registrations (verify): $tempData');
              
              name = tempData['name']?.toString().trim() ?? 'New User';
              
              final phoneValue = tempData['phone'];
              if (phoneValue != null && phoneValue.toString().trim().isNotEmpty) {
                phone = phoneValue.toString().trim();
              }
              
              final dateOfBirthValue = tempData['dateOfBirth'];
              if (dateOfBirthValue != null) {
                if (dateOfBirthValue is int) {
                  dateOfBirth = dateOfBirthValue;
                } else if (dateOfBirthValue is num) {
                  dateOfBirth = dateOfBirthValue.toInt();
                } else {
                  dateOfBirth = int.tryParse(dateOfBirthValue.toString());
                }
              }
              
              print('📝 Parsed from temp_registrations (verify, new user): name=$name, phone=$phone, dateOfBirth=$dateOfBirth');
              
              // Xóa temp_registrations sau khi lấy
              try {
                await FirebaseDatabase.instance
                    .ref('temp_registrations')
                    .child(updatedUser.uid)
                    .remove();
                print('✅ Đã xóa temp_registrations sau khi lấy (verify)');
              } catch (e) {
                print('⚠️ Error removing temp_registrations (verify): $e');
              }
            } else {
              print('⚠️ Không có temp_registrations hoặc temp_registrations rỗng (verify)');
              print('⚠️ User sẽ được tạo với giá trị mặc định: name=$name, phone=$phone, dateOfBirth=$dateOfBirth');
            }
            
            // Tạo user mới
            UserModel newUser = UserModel(
              id: updatedUser.uid,
              name: name,
              email: widget.email,
              role: 'user',
              phone: phone,
              dateOfBirth: dateOfBirth,
            );
            
            print('📝 Creating new UserModel (verify): name=$name, phone=$phone, dateOfBirth=$dateOfBirth');
            print('📝 UserModel.toMap() (verify): ${newUser.toMap()}');
            await dbService.saveUser(newUser);
            print('✅ Đã khởi tạo user trong DB từ màn hình Verify');
          } else {
            // User đã tồn tại - Luôn kiểm tra và cập nhật các trường null từ temp_registrations
            print('📝 User đã tồn tại trong DB (verify)');
            print('📝 Current user data (verify): name=${existingUser.name}, phone=${existingUser.phone}, dateOfBirth=${existingUser.dateOfBirth}');
            print('📝 Kiểm tra và cập nhật các trường null từ temp_registrations (verify)...');
            await dbService.updateUserFromTempRegistration(updatedUser.uid);
          }
          
          // Verify lại sau khi save/update
          UserModel? verifyUser = await dbService.getUser(updatedUser.uid);
          if (verifyUser != null) {
            print('✅ Verified saved/updated user (verify): name=${verifyUser.name}, phone=${verifyUser.phone}, dateOfBirth=${verifyUser.dateOfBirth}');
          } else {
            print('❌ ERROR: User not found after saving/updating (verify)!');
          }

          if (mounted) {
            await DialogHelper.showSuccess(context, 'Xác thực thành công! Đang vào ứng dụng...');
          }
          // AuthChecker (lắng nghe userChanges) sẽ tự động chuyển màn hình
        } else {
          if (mounted) {
            await DialogHelper.showInfo(context, 'Vẫn chưa xác thực. Vui lòng kiểm tra email của bạn.');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        await DialogHelper.showError(context, 'Lỗi: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signOut();
      // AuthChecker ở main.dart sẽ tự động điều hướng về LoginScreen
    } catch (e) {
      if (mounted) {
        await DialogHelper.showError(context, 'Lỗi đăng xuất: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _resendEmail() async {
     setState(() => _isLoading = true);
     final user = FirebaseAuth.instance.currentUser;
     if (user != null && !user.emailVerified) {
       try {
         // sendEmailVerification() tự động tạo link mới
         await user.sendEmailVerification();
         if (mounted) {
            await DialogHelper.showSuccess(context, 'Đã gửi lại link xác thực mới vào email của bạn.');
         }
       } catch (e) {
         if (mounted) {
             // Kiểm tra lỗi too-many-requests
             if (e.toString().contains('too-many-requests')) {
                 await DialogHelper.showWarning(context, 'Gửi quá nhiều lần. Vui lòng đợi một chút rồi thử lại.');
             } else {
                await DialogHelper.showError(context, 'Lỗi gửi mail: $e');
             }
         }
       } finally {
         if (mounted) setState(() => _isLoading = false);
       }
     } else {
        if (mounted) setState(() => _isLoading = false);
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0F0F),
              Color(0xFF1A1A1A),
              Color(0xFF0F0F0F),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE50914), Color(0xFFB20710)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE50914).withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 8,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE50914).withOpacity(0.2),
                        const Color(0xFFB20710).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE50914).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Text(
                    'Kiểm tra email của bạn',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                    children: [
                      const TextSpan(text: 'Link xác thực đã được gửi đến:\n'),
                      TextSpan(
                        text: widget.email,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF9800).withOpacity(0.2),
                        const Color(0xFFF57C00).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFF9800).withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Link xác thực sẽ hết hạn sau 5 phút. Nếu không xác thực kịp, tài khoản sẽ bị hủy.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Nút Tôi đã xác thực
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: _isLoading
                        ? LinearGradient(
                            colors: [
                              Colors.grey.withOpacity(0.3),
                              Colors.grey.withOpacity(0.2),
                            ],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFE50914), Color(0xFFB20710), Color(0xFF8B0000)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isLoading
                        ? null
                        : [
                            BoxShadow(
                              color: const Color(0xFFE50914).withOpacity(0.5),
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
                    border: _isLoading
                        ? null
                        : Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _checkVerification,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white, size: 26),
                                  SizedBox(width: 12),
                                  Text(
                                    'TÔI ĐÃ XÁC THỰC',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1,
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
                
                const SizedBox(height: 16),
                
                // Nút Gửi lại
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2A2A2A).withOpacity(0.8),
                        const Color(0xFF1A1A1A).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF2196F3).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _resendEmail,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.refresh,
                              color: _isLoading ? Colors.grey : const Color(0xFF2196F3),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Gửi lại email xác thực (Link mới)',
                              style: TextStyle(
                                color: _isLoading ? Colors.grey : const Color(0xFF2196F3),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Nút Quay lại đăng nhập (Sign Out)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2A2A2A).withOpacity(0.8),
                        const Color(0xFF1A1A1A).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _handleSignOut,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                            const SizedBox(width: 10),
                            const Text(
                              'Quay lại đăng nhập',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}