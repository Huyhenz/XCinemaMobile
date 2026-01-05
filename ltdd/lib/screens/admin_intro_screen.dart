// File: lib/screens/admin_intro_screen.dart
// Màn hình intro cho Admin Dashboard

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_dashboard_screen.dart';

class AdminIntroScreen extends StatefulWidget {
  final bool isFirstTime;
  
  const AdminIntroScreen({super.key, this.isFirstTime = false});

  @override
  State<AdminIntroScreen> createState() => _AdminIntroScreenState();
}

class _AdminIntroScreenState extends State<AdminIntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<IntroPage> _pages = [
    IntroPage(
      icon: Icons.admin_panel_settings,
      title: 'Chào Mừng Đến Admin Dashboard',
      description: 'Quản lý toàn bộ hệ thống rạp chiếu phim của bạn một cách dễ dàng và hiệu quả.',
      gradient: [Color(0xFFE50914), Color(0xFFB20710), Color(0xFF8B0000)],
    ),
    IntroPage(
      icon: Icons.theaters,
      title: 'Quản Lý Rạp Chiếu',
      description: 'Tạo và quản lý thông tin các rạp chiếu, bao gồm địa chỉ, số điện thoại và vị trí trên bản đồ.',
      gradient: [Color(0xFF2196F3), Color(0xFF1976D2), Color(0xFF0D47A1)],
    ),
    IntroPage(
      icon: Icons.movie,
      title: 'Quản Lý Phim',
      description: 'Thêm phim mới, cập nhật thông tin phim, quản lý poster và trailer cho từng bộ phim.',
      gradient: [Color(0xFF9C27B0), Color(0xFF7B1FA2), Color(0xFF4A148C)],
    ),
    IntroPage(
      icon: Icons.schedule,
      title: 'Quản Lý Lịch Chiếu',
      description: 'Tạo lịch chiếu cho các phim, quản lý thời gian và phòng chiếu cho từng suất chiếu.',
      gradient: [Color(0xFF4CAF50), Color(0xFF388E3C), Color(0xFF2E7D32)],
    ),
    IntroPage(
      icon: Icons.meeting_room,
      title: 'Quản Lý Phòng Chiếu',
      description: 'Tạo và quản lý các phòng chiếu với các loại khác nhau: Standard, VIP, Couple.',
      gradient: [Color(0xFFFF9800), Color(0xFFF57C00), Color(0xFFE65100)],
    ),
    IntroPage(
      icon: Icons.card_giftcard,
      title: 'Quản Lý Voucher',
      description: 'Tạo voucher miễn phí, voucher nhiệm vụ và voucher đổi điểm để khuyến khích người dùng.',
      gradient: [Color(0xFFE91E63), Color(0xFFC2185B), Color(0xFF880E4F)],
    ),
    IntroPage(
      icon: Icons.fastfood,
      title: 'Quản Lý Bắp Nước',
      description: 'Thêm và quản lý các sản phẩm bắp nước, combo với giá cả và hình ảnh sản phẩm.',
      gradient: [Color(0xFF00BCD4), Color(0xFF0097A7), Color(0xFF006064)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeIntro();
    }
  }

  void _skipIntro() {
    _completeIntro();
  }

  Future<void> _completeIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('admin_intro_completed', true);
    
    if (mounted) {
      if (widget.isFirstTime) {
        // Lần đầu tiên: replace với dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AdminDashboardScreen(),
          ),
        );
      } else {
        // Xem lại: chỉ pop về dashboard
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60), // Spacer để căn giữa
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: _currentPage == index
                                ? LinearGradient(
                                    colors: _pages[index].gradient,
                                  )
                                : null,
                            color: _currentPage == index
                                ? null
                                : Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.withOpacity(0.3),
                          Colors.grey.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: TextButton(
                      onPressed: _skipIntro,
                      child: const Text(
                        'Bỏ qua',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildIntroPage(_pages[index]);
                },
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.withOpacity(0.3),
                            Colors.grey.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: TextButton.icon(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                        label: const Text(
                          'Trước',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 80),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _pages[_currentPage].gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _pages[_currentPage].gradient[0].withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: TextButton.icon(
                      onPressed: _nextPage,
                      icon: Icon(
                        _currentPage == _pages.length - 1
                            ? Icons.check_circle
                            : Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        _currentPage == _pages.length - 1 ? 'Bắt Đầu' : 'Tiếp',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroPage(IntroPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: page.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: page.gradient[0].withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              page.icon,
              size: 70,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  page.gradient[0].withOpacity(0.2),
                  page.gradient[1].withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: page.gradient[0].withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: page.gradient[0].withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Description
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF2A2A2A),
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
            child: Text(
              page.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 16,
                height: 1.6,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IntroPage {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;

  IntroPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}

