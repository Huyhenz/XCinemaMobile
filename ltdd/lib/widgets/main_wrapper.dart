import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ltdd/models/user.dart';
import 'package:ltdd/screens/admin_dashboard_screen.dart';
import 'package:ltdd/screens/profile_screen.dart';
import 'package:ltdd/screens/home_screen.dart';
import 'package:ltdd/blocs/movies/movies_bloc.dart';
import 'package:ltdd/services/database_services.dart';
import 'package:ltdd/widgets/navigation_provider.dart';


class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  bool _isAdmin = false;
  bool _isLoading = true;

  final List<Widget> _screens = [
    BlocProvider(
      create: (context) => MovieBloc(),
      child: const HomeScreen(),
    ),
    const ProfileScreen(),
  ];

  final List<Widget> _adminScreens = [
    BlocProvider(
      create: (context) => MovieBloc(),
      child: const HomeScreen(),
    ),
    const AdminDashboardScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    // Lắng nghe thay đổi auth state để update admin role
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _checkUserRole();
    });
  }

  Future<void> _checkUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final bool wasAdmin = _isAdmin;
      
      if (user != null) {
        UserModel? userModel = await DatabaseService().getUser(user.uid);
        if (mounted) {
          setState(() {
            _isAdmin = userModel?.role == 'admin';
            _isLoading = false;
            // Nếu admin status thay đổi, reset về tab đầu tiên để tránh lỗi index out of range
            if (wasAdmin != _isAdmin) {
              _currentIndex = 0;
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isAdmin = false;
            _isLoading = false;
            // Khi đăng xuất, reset về tab đầu tiên
            _currentIndex = 0;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Đảm bảo index luôn hợp lệ
          final maxIndex = (_isAdmin ? _adminScreens : _screens).length - 1;
          if (_currentIndex > maxIndex) {
            _currentIndex = 0;
          }
        });
      }
    }
  }

  void _navigateTo(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE50914)),
        ),
      );
    }

    // Đảm bảo _currentIndex luôn hợp lệ
    final currentScreens = _isAdmin ? _adminScreens : _screens;
    final maxIndex = currentScreens.length - 1;
    final safeIndex = _currentIndex > maxIndex ? 0 : _currentIndex;

    return NavigationProvider(
      navigateTo: _navigateTo,
      currentIndex: safeIndex,
      isAdmin: _isAdmin,
      child: Scaffold(
        body: IndexedStack(
          index: safeIndex,
          children: currentScreens,
        ),
      ),
    );
  }
}