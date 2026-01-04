import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../services/database_services.dart';
import '../utils/validators.dart';
import '../utils/dialog_helper.dart';
import '../widgets/navigation_provider.dart';
import 'booking_screen.dart';
import 'showtimes_screen.dart';
import 'movie_detail_screen.dart';

// Không cần import EmailVerificationScreen nữa vì AuthChecker tự lo

class LoginScreen extends StatefulWidget {
  final bool? isLoginMode; // null = tự động, true = đăng nhập, false = đăng ký
  final String? returnPath; // Đường dẫn quay lại sau khi đăng nhập thành công (ví dụ: 'booking:showtimeId')
  
  const LoginScreen({super.key, this.isLoginMode, this.returnPath});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _selectedDateOfBirth;
  late bool _isRegister;
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Nếu có isLoginMode từ widget, sử dụng nó, nếu không thì mặc định là false (đăng nhập)
    _isRegister = widget.isLoginMode == false;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _authAction() async {
    // Validate email
    String? emailError = Validators.validateEmail(_emailController.text);
    if (emailError != null) {
      _showSnackBar(emailError, isError: true);
      return;
    }

    // Validate password
    String? passwordError = Validators.validatePassword(_passwordController.text);
    if (passwordError != null) {
      _showSnackBar(passwordError, isError: true);
      return;
    }

    if (_isRegister) {
      // Validate name
      String? nameError = Validators.validateName(_nameController.text);
      if (nameError != null) {
        _showSnackBar(nameError, isError: true);
        return;
      }

      // Validate phone
      String? phoneError = Validators.validatePhone(_phoneController.text);
      if (phoneError != null) {
        _showSnackBar(phoneError, isError: true);
        return;
      }

      // Validate date of birth
      String? dateError = Validators.validateDateOfBirth(_selectedDateOfBirth);
      if (dateError != null) {
        _showSnackBar(dateError, isError: true);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (_isRegister) {
        // --- ĐĂNG KÝ ---
        // 1. Chỉ tạo Auth, KHÔNG LƯU DB
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (cred.user != null) {
          // 2. Lưu thông tin đăng ký tạm thời vào Firebase Database
          // Format phone number (remove spaces)
          String cleanPhone = _phoneController.text.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
          
          final tempData = {
            'name': _nameController.text.trim(),
            'phone': cleanPhone,
            'dateOfBirth': _selectedDateOfBirth!.millisecondsSinceEpoch,
            'email': _emailController.text.trim(),
          };
          
          print('📝 Saving to temp_registrations: name=${tempData['name']}, phone=${tempData['phone']}, dateOfBirth=${tempData['dateOfBirth']}');
          
          // Sử dụng DatabaseService để lưu an toàn
          await DatabaseService().saveTempRegistration(cred.user!.uid, tempData);
          
          print('✅ Saved to temp_registrations successfully');

          // 3. Gửi email xác thực
          await cred.user!.sendEmailVerification();

          // 4. KHÔNG SignOut -> AuthChecker ở main.dart sẽ tự chuyển sang màn hình Verify
          _showSnackBar('Đăng ký thành công. Vui lòng kiểm tra email.');
        }
      } else {
        // --- ĐĂNG NHẬP ---
        UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (cred.user != null) {
          // Reload để đảm bảo trạng thái emailVerified mới nhất
          await cred.user!.reload();
          final user = FirebaseAuth.instance.currentUser; // Lấy lại instance mới nhất

            if (user != null && user.emailVerified) {
            // --- TRƯỜNG HỢP 1: ĐÃ XÁC THỰC EMAIL ---
            
            final dbService = DatabaseService();
            
            // Kiểm tra xem đã có trong DB chưa (Lần đầu verify xong sẽ chưa có)
            UserModel? existingUser = await dbService.getUser(user.uid);
            
            if (existingUser == null) {
              // Tạo user mới từ temp_registrations nếu có
              print('📝 User chưa tồn tại trong DB, tạo user mới...');
              String name = 'New User';
              String? phone;
              int? dateOfBirth;
              
              // Lấy thông tin từ temp_registrations
              print('📝 Đang lấy thông tin từ temp_registrations...');
              Map<dynamic, dynamic>? tempData = await dbService.getTempRegistration(user.uid);
              
              if (tempData != null && tempData.isNotEmpty) {
                print('✅ Đã lấy được temp_registrations: $tempData');
                
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
                
                print('📝 Parsed from temp_registrations (new user): name=$name, phone=$phone, dateOfBirth=$dateOfBirth');
                
                // Xóa temp_registrations sau khi lấy
                try {
                  await FirebaseDatabase.instance
                      .ref('temp_registrations')
                      .child(user.uid)
                      .remove();
                  print('✅ Đã xóa temp_registrations sau khi lấy');
                } catch (e) {
                  print('⚠️ Error removing temp_registrations: $e');
                }
              } else {
                print('⚠️ Không có temp_registrations hoặc temp_registrations rỗng');
                print('⚠️ User sẽ được tạo với giá trị mặc định: name=$name, phone=$phone, dateOfBirth=$dateOfBirth');
              }
              
              // Tạo user mới
              UserModel newUser = UserModel(
                id: user.uid,
                name: name,
                email: _emailController.text.trim(),
                role: 'user',
                phone: phone,
                dateOfBirth: dateOfBirth,
              );
              
              print('📝 Creating new UserModel: name=$name, phone=$phone, dateOfBirth=$dateOfBirth');
              print('📝 UserModel.toMap(): ${newUser.toMap()}');
              await dbService.saveUser(newUser);
              print('✅ Đã khởi tạo user trong DB');
              
              // Verify lại sau khi save
              UserModel? verifyUser = await dbService.getUser(user.uid);
              if (verifyUser != null) {
                print('✅ Verified saved user: name=${verifyUser.name}, phone=${verifyUser.phone}, dateOfBirth=${verifyUser.dateOfBirth}');
              } else {
                print('❌ ERROR: User not found after saving!');
              }
            } else {
              // User đã tồn tại - Luôn kiểm tra và cập nhật các trường null từ temp_registrations
              print('📝 User đã tồn tại trong DB');
              print('📝 Current user data: name=${existingUser.name}, phone=${existingUser.phone}, dateOfBirth=${existingUser.dateOfBirth}');
              print('📝 Kiểm tra và cập nhật các trường null từ temp_registrations...');
              await dbService.updateUserFromTempRegistration(user.uid);
              
              // Verify lại sau khi update
              UserModel? verifyUser = await dbService.getUser(user.uid);
              if (verifyUser != null) {
                print('✅ Verified user after update: name=${verifyUser.name}, phone=${verifyUser.phone}, dateOfBirth=${verifyUser.dateOfBirth}');
              } else {
                print('❌ ERROR: User not found after update!');
              }
            }
            
            // Xử lý return path nếu có
            if (mounted && widget.returnPath != null) {
              _handleReturnPath(context, widget.returnPath!);
            } else if (mounted) {
              // Điều hướng về HomeScreen
              _navigateToHome(context);
            }
          } else {
            // --- TRƯỜNG HỢP 2: CHƯA XÁC THỰC EMAIL ---
            
            // Kiểm tra quá hạn 5 phút
            final creationTime = user!.metadata.creationTime;
            if (creationTime != null) {
              final difference = DateTime.now().difference(creationTime).inMinutes;
              
              if (difference >= 5) {
                 // QUÁ 5 PHÚT -> XÓA AUTH
                 await user.delete();
                 // SignOut để AuthChecker quay lại màn hình Login (thay vì màn Verify)
                 await FirebaseAuth.instance.signOut();
                 if (mounted) {
                   _showSnackBar('Link xác thực đã hết hạn (quá 5 phút). Tài khoản đã bị hủy. Vui lòng đăng ký lại.', isError: true);
                 }
                 return;
              }
            }
            
            // Nếu chưa quá 5 phút -> Hiển thị pop-up thông báo và chuyển sang màn hình Verify
            if (mounted) {
              await _showEmailNotVerifiedDialog(user);
              // SignOut để AuthChecker quay lại màn hình Login, sau đó AuthChecker sẽ tự chuyển sang màn Verify
              await FirebaseAuth.instance.signOut();
            }
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Có lỗi xảy ra: ${e.code}';
      // Khi đăng nhập sai email hoặc mật khẩu -> hiển thị thông báo chung
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Sai tài khoản hoặc mật khẩu. Vui lòng nhập lại';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email đã được sử dụng';
      } else if (e.code == 'weak-password') {
        message = 'Mật khẩu quá yếu';
      }
      
      _showSnackBar(message, isError: true);
      
      // Nếu lỗi login, đảm bảo signout để tránh kẹt trạng thái
      if (!_isRegister) {
        await FirebaseAuth.instance.signOut(); 
      }
    } catch (e) {
      _showSnackBar('Lỗi: $e', isError: true);
      await FirebaseAuth.instance.signOut();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // Google mặc định là đã verify, nên lưu luôn
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        UserModel user = UserModel(
          id: userCredential.user!.uid,
          name: googleUser.displayName ?? 'New User',
          email: googleUser.email,
          role: 'user',
        );
        await DatabaseService().saveUser(user);
      }
      
      // Xử lý return path nếu có
      if (mounted && widget.returnPath != null) {
        _handleReturnPath(context, widget.returnPath!);
      } else if (mounted) {
        // Điều hướng về HomeScreen
        _navigateToHome(context);
      }
    } catch (e) {
      _showSnackBar('Lỗi đăng nhập Google: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleReturnPath(BuildContext context, String returnPath) {
    // Parse return path: "booking:showtimeId", "showtimes:movieId:cinemaId", hoặc "movie:movieId:cinemaId"
    if (returnPath.startsWith('booking:')) {
      final showtimeId = returnPath.substring(8); // Bỏ "booking:"
      // Pop login screen trước, sau đó navigate đến booking screen
      Navigator.pop(context); // Đóng login screen
      // Sử dụng Future.microtask để đảm bảo pop hoàn tất trước khi push
      Future.microtask(() {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingScreen(showtimeId: showtimeId),
            ),
          );
        }
      });
    } else if (returnPath.startsWith('showtimes:')) {
      // Format: "showtimes:movieId:cinemaId" hoặc "showtimes:movieId"
      final parts = returnPath.substring(10).split(':'); // Bỏ "showtimes:"
      final movieId = parts[0];
      final cinemaId = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
      
      // Pop login screen trước, sau đó navigate đến showtimes screen
      Navigator.pop(context); // Đóng login screen
      // Sử dụng Future.microtask để đảm bảo pop hoàn tất trước khi push
      Future.microtask(() {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShowtimesScreen(
                movieId: movieId,
                cinemaId: cinemaId,
              ),
            ),
          );
        }
      });
    } else if (returnPath.startsWith('movie:')) {
      // Format: "movie:movieId" hoặc "movie:movieId:cinemaId"
      final parts = returnPath.substring(6).split(':'); // Bỏ "movie:"
      final movieId = parts[0];
      final cinemaId = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
      
      // Pop login screen trước, sau đó navigate đến movie detail screen
      Navigator.pop(context); // Đóng login screen
      // Sử dụng Future.microtask để đảm bảo pop hoàn tất trước khi push
      Future.microtask(() {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MovieDetailScreen(
                movieId: movieId,
                cinemaId: cinemaId,
              ),
            ),
          );
        }
      });
    } else {
      // Mặc định điều hướng về HomeScreen
      _navigateToHome(context);
    }
  }

  void _navigateToHome(BuildContext context) {
    // Pop login screen trước
    Navigator.pop(context);
    
    // Điều hướng về HomeScreen (tab index 0) thông qua NavigationProvider
    Future.microtask(() {
      if (context.mounted) {
        final navigationProvider = NavigationProvider.of(context);
        if (navigationProvider != null) {
          // Nếu có NavigationProvider, navigate về tab 0 (HomeScreen)
          navigationProvider.navigateTo(0);
        } else {
          // Nếu không có NavigationProvider, pop về MainWrapper (root)
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      }
    });
  }

  Future<void> _showSnackBar(String message, {bool isError = false}) async {
    if (isError) {
      await DialogHelper.showError(context, message);
    } else {
      await DialogHelper.showSuccess(context, message);
    }
  }

  Future<void> _showEmailNotVerifiedDialog(User user) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.email_outlined,
                color: Colors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Chưa xác nhận email',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tài khoản của bạn chưa được xác nhận qua email.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Email: ${user.email}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vui lòng kiểm tra hộp thư đến và xác nhận email của bạn để tiếp tục sử dụng ứng dụng.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Đóng',
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await user.sendEmailVerification();
                if (mounted) {
                  Navigator.of(context).pop();
                  await DialogHelper.showSuccess(
                    context,
                    'Đã gửi lại email xác thực. Vui lòng kiểm tra hộp thư đến của bạn.',
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  await DialogHelper.showError(
                    context,
                    'Lỗi gửi email: $e',
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Gửi lại email'),
          ),
        ],
      ),
    );
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 50),
                    _buildForm(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFE50914), Color(0xFFB20710), Color(0xFF8B0000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE50914).withOpacity(0.6),
                blurRadius: 40,
                spreadRadius: 8,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.movie_filter,
            size: 64,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 28),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFE50914), Color(0xFFFFD700), Color(0xFFFF6B6B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'CINEMA',
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            'Đặt vé xem phim dễ dàng',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[300],
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1F1F1F),
            Color(0xFF1A1A1A),
            Color(0xFF151515),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF2A2A2A).withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE50914).withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTabSelector(),
          const SizedBox(height: 24),
          if (_isRegister) ...[
            _buildNameField(),
            const SizedBox(height: 16),
            _buildPhoneField(),
            const SizedBox(height: 16),
            _buildDateOfBirthField(),
            const SizedBox(height: 16),
          ],
          _buildEmailField(),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 24),
          _buildLoginButton(),
          const SizedBox(height: 20),
          _buildDivider(),
          const SizedBox(height: 20),
          _buildGoogleButton(),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F0F0F), Color(0xFF151515)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2A2A2A).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Đăng Nhập', !_isRegister, Icons.login_rounded),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTabButton('Đăng Ký', _isRegister, Icons.person_add_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, bool isSelected, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isRegister = !_isRegister;
          // Reset các trường đăng ký khi chuyển sang đăng nhập
          if (!_isRegister) {
            _nameController.clear();
            _phoneController.clear();
            _selectedDateOfBirth = null;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFE50914), Color(0xFFB20710), Color(0xFF8B0000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFE50914).withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[500],
            ),
            const SizedBox(width: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[500],
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF252525)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE50914).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: 'Email',
          labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(Icons.email_outlined, color: Color(0xFFE50914), size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF252525)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE50914).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: 'Mật khẩu',
          labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(Icons.lock_outline, color: Color(0xFFE50914), size: 22),
          ),
          suffixIcon: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[400],
                size: 20,
              ),
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF252525)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE50914).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _nameController,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: 'Họ tên',
          labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(Icons.person_outline, color: Color(0xFFE50914), size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF252525)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE50914).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: 'Số điện thoại',
          labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(Icons.phone_outlined, color: Color(0xFFE50914), size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildDateOfBirthField() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF252525)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE50914).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
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
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Ngày tháng năm sinh',
            labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.calendar_today_outlined, color: Color(0xFFE50914), size: 22),
            ),
          ),
          child: Text(
            _selectedDateOfBirth == null
                ? 'Chọn ngày sinh'
                : DateFormat('dd/MM/yyyy').format(_selectedDateOfBirth!),
            style: TextStyle(
              color: _selectedDateOfBirth == null ? Colors.grey[400] : Colors.white,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE50914), Color(0xFFB20710), Color(0xFF8B0000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE50914).withOpacity(0.6),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _authAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isRegister ? Icons.person_add_rounded : Icons.login_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isRegister ? 'ĐĂNG KÝ' : 'ĐĂNG NHẬP',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey[700]!,
                  Colors.grey[700]!,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[800]!,
                width: 1,
              ),
            ),
            child: Text(
              'HOẶC',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey[700]!,
                  Colors.grey[700]!,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF252525)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[700]!.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Image.network(
            'https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png',
            height: 22,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.g_mobiledata,
              color: Colors.blue,
              size: 24,
            ),
          ),
        ),
        label: const Text(
          'Đăng nhập với Google',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
