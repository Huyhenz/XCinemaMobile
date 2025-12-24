import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_services.dart';

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
          UserModel? existingUser = await DatabaseService().getUser(updatedUser.uid);
            
          if (existingUser == null) {
            // Lấy thông tin đăng ký tạm thời nếu có
            String name = 'New User';
            String? phone;
            int? dateOfBirth;
            
            try {
              final tempSnapshot = await FirebaseDatabase.instance
                  .ref('temp_registrations')
                  .child(updatedUser.uid)
                  .get();
              
              if (tempSnapshot.exists && tempSnapshot.value != null) {
                final tempData = Map<dynamic, dynamic>.from(tempSnapshot.value as Map);
                name = tempData['name'] ?? 'New User';
                phone = tempData['phone'];
                dateOfBirth = tempData['dateOfBirth'];
                
                // Xóa dữ liệu tạm thời sau khi lấy
                await FirebaseDatabase.instance
                    .ref('temp_registrations')
                    .child(updatedUser.uid)
                    .remove();
              }
            } catch (e) {
              print('Lỗi khi lấy thông tin đăng ký tạm thời: $e');
            }
            
            UserModel newUser = UserModel(
              id: updatedUser.uid,
              name: name,
              email: widget.email, // Dùng email từ widget cho chắc chắn
              role: 'user',
              phone: phone,
              dateOfBirth: dateOfBirth,
            );
            await DatabaseService().saveUser(newUser);
            print('✅ Đã khởi tạo user trong DB từ màn hình Verify');
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Xác thực thành công! Đang vào ứng dụng...'),
                backgroundColor: Color(0xFF4CAF50),
              ),
            );
          }
          // AuthChecker (lắng nghe userChanges) sẽ tự động chuyển màn hình
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vẫn chưa xác thực. Vui lòng kiểm tra email của bạn.')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng xuất: $e')),
        );
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã gửi lại link xác thực mới vào email của bạn.')),
            );
         }
       } catch (e) {
         if (mounted) {
             // Kiểm tra lỗi too-many-requests
             if (e.toString().contains('too-many-requests')) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gửi quá nhiều lần. Vui lòng đợi một chút rồi thử lại.')),
                );
             } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi gửi mail: $e')),
                );
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
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2A2A2A),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE50914).withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 80,
                    color: Color(0xFFE50914),
                  ),
                ),
                const SizedBox(height: 40),
                
                const Text(
                  'Kiểm tra email của bạn',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3A3A3A)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.timer_outlined, color: Colors.orange, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Link xác thực sẽ hết hạn sau 5 phút. Nếu không xác thực kịp, tài khoản sẽ bị hủy.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Nút Tôi đã xác thực
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _checkVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                      'TÔI ĐÃ XÁC THỰC',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Nút Gửi lại
                TextButton(
                  onPressed: _isLoading ? null : _resendEmail,
                  child: const Text('Gửi lại email xác thực (Link mới)', style: TextStyle(color: Colors.grey)),
                ),
                
                const SizedBox(height: 30),
                
                // Nút Quay lại đăng nhập (Sign Out)
                TextButton.icon(
                  onPressed: _isLoading ? null : _handleSignOut,
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  label: const Text(
                    'Quay lại đăng nhập',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
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