import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ltdd/models/user.dart';
import 'package:ltdd/screens/admin_dashboard_screen.dart';
import 'package:ltdd/screens/profile_screen.dart';
import 'package:ltdd/screens/cinema_selection_screen.dart';
import 'package:ltdd/services/database_services.dart';


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
    const CinemaSelectionScreen(), // Bắt đầu từ màn hình chọn rạp
    const ProfileScreen(),
  ];

  final List<Widget> _adminScreens = [
    const CinemaSelectionScreen(), // Bắt đầu từ màn hình chọn rạp
    const AdminDashboardScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      UserModel? user = await DatabaseService().getUser(userId);
      setState(() {
        _isAdmin = user?.role == 'admin';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
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

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _isAdmin ? _adminScreens : _screens,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _isAdmin ? _buildAdminNavItems() : _buildUserNavItems(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildUserNavItems() {
    return [
      _buildNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Trang Chủ',
        index: 0,
      ),
      _buildNavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Hồ Sơ',
        index: 1,
      ),
    ];
  }

  List<Widget> _buildAdminNavItems() {
    return [
      _buildNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Trang Chủ',
        index: 0,
      ),
      _buildNavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Quản Lý',
        index: 1,
      ),
      _buildNavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Hồ Sơ',
        index: 2,
      ),
    ];
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    bool isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentIndex = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
              colors: [Color(0xFFE50914), Color(0xFFB20710)],
            )
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? Colors.white : Colors.grey[600],
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}