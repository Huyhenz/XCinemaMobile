import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../services/database_services.dart';
import '../utils/validators.dart';
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
          await FirebaseDatabase.instance
              .ref('temp_registrations')
              .child(cred.user!.uid)
              .set(tempData);

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
            
            // Kiểm tra xem đã có trong DB chưa (Lần đầu verify xong sẽ chưa có)
            UserModel? existingUser = await DatabaseService().getUser(user.uid);
            
            if (existingUser == null) {
              // ==> ĐÂY LÀ LÚC LƯU VÀO DB <==
              // Lấy thông tin đăng ký tạm thời nếu có
              String name = 'New User';
              String? phone;
              int? dateOfBirth;
              
              try {
                final tempSnapshot = await FirebaseDatabase.instance
                    .ref('temp_registrations')
                    .child(user.uid)
                    .get();
                
                if (tempSnapshot.exists && tempSnapshot.value != null) {
                  final tempData = Map<dynamic, dynamic>.from(tempSnapshot.value as Map);
                  name = tempData['name'] ?? 'New User';
                  phone = tempData['phone'];
                  dateOfBirth = tempData['dateOfBirth'];
                  
                  // Xóa dữ liệu tạm thời sau khi lấy
                  await FirebaseDatabase.instance
                      .ref('temp_registrations')
                      .child(user.uid)
                      .remove();
                }
              } catch (e) {
                print('Lỗi khi lấy thông tin đăng ký tạm thời: $e');
              }
              
              UserModel newUser = UserModel(
                id: user.uid,
                name: name,
                email: _emailController.text.trim(),
                role: 'user',
                phone: phone,
                dateOfBirth: dateOfBirth,
              );
              await DatabaseService().saveUser(newUser);
              print('✅ Đã khởi tạo user trong DB sau khi verify');
            }
            
            // Xử lý return path nếu có
            if (mounted && widget.returnPath != null) {
              _handleReturnPath(context, widget.returnPath!);
            } else if (mounted) {
              // Quay lại màn hình trước
              Navigator.pop(context, true);
            }
          } else {
            // --- TRƯỜNG HỢP 2: CHƯA XÁC THỰC ---
            
            // Kiểm tra quá hạn 5 phút
            final creationTime = user!.metadata.creationTime;
            if (creationTime != null) {
              final difference = DateTime.now().difference(creationTime).inMinutes;
              
              if (difference >= 5) {
                 // QUÁ 5 PHÚT -> XÓA AUTH
                 await user.delete();
                 // SignOut để AuthChecker quay lại màn hình Login (thay vì màn Verify)
                 await FirebaseAuth.instance.signOut();
                 _showSnackBar('Link xác thực đã hết hạn (quá 5 phút). Tài khoản đã bị hủy. Vui lòng đăng ký lại.', isError: true);
                 return;
              }
            }
            
            // Nếu chưa quá 5 phút -> AuthChecker sẽ tự hiển thị màn hình Verify
            // Không cần làm gì thêm
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Có lỗi xảy ra: ${e.code}';
      if (e.code == 'user-not-found') message = 'Email không tồn tại';
      else if (e.code == 'wrong-password') message = 'Mật khẩu không đúng';
      else if (e.code == 'email-already-in-use') message = 'Email đã được sử dụng';
      else if (e.code == 'weak-password') message = 'Mật khẩu quá yếu';
      
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
        // Quay lại màn hình trước
        Navigator.pop(context, true);
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
      // Mặc định quay lại
      Navigator.pop(context, true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFE50914) : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFE50914), Color(0xFFB20710)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE50914).withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.movie_filter,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFE50914), Color(0xFFFF6B6B)],
          ).createShader(bounds),
          child: const Text(
            'CINEMA',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 6,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Đặt vé xem phim dễ dàng',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A2A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Đăng Nhập', !_isRegister),
          ),
          Expanded(
            child: _buildTabButton('Đăng Ký', _isRegister),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, bool isSelected) {
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            colors: [Color(0xFFE50914), Color(0xFFB20710)],
          )
              : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3A3A3A),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Email',
          labelStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFE50914)),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3A3A3A),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Mật khẩu',
          labelStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFE50914)),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[500],
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
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3A3A3A),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _nameController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Họ tên',
          labelStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFE50914)),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3A3A3A),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Số điện thoại',
          labelStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFFE50914)),
        ),
      ),
    );
  }

  Widget _buildDateOfBirthField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3A3A3A),
          width: 1,
        ),
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
            labelStyle: TextStyle(color: Colors.grey[500]),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            prefixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFFE50914)),
          ),
          child: Text(
            _selectedDateOfBirth == null
                ? 'Chọn ngày sinh'
                : DateFormat('dd/MM/yyyy').format(_selectedDateOfBirth!),
            style: TextStyle(
              color: _selectedDateOfBirth == null ? Colors.grey[500] : Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE50914), Color(0xFFB20710)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE50914).withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _authAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(
          _isRegister ? 'ĐĂNG KÝ' : 'ĐĂNG NHẬP',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: Colors.grey[800], thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'HOẶC',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.grey[800], thickness: 1),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3A3A3A),
          width: 1,
        ),
      ),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.network(
            'https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png',
            height: 20,
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
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}