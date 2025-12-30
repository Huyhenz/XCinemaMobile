// File: lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../blocs/profile/profile_bloc.dart';
import '../blocs/profile/profile_event.dart';
import '../blocs/profile/profile_state.dart';
import '../services/database_services.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_widgets.dart';
import 'user_info_screen.dart';
import 'notification_screen.dart';
import 'chatbot_screen.dart';
import 'login_screen.dart';
import 'redeem_voucher_screen.dart';
import 'get_voucher_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sử dụng StreamBuilder để lắng nghe thay đổi auth state
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        // Nếu chưa đăng nhập, hiển thị màn hình đăng nhập/đăng ký
        if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              ProfileScreen._buildHeaderStatic(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
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
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Chào mừng bạn đến với Cinema',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đăng nhập hoặc đăng ký để xem thông tin cá nhân và lịch sử đặt vé',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      ProfileScreen._buildLoginButtonStatic(context),
                      const SizedBox(height: 16),
                      ProfileScreen._buildRegisterButtonStatic(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
        }

        // Nếu đã đăng nhập, hiển thị profile bình thường
        final userId = user.uid;
    return BlocProvider(
      create: (context) => ProfileBloc()..add(LoadProfile(userId)),
          child: _ProfileContent(userId: userId),
        );
      },
    );
  }

  // Static methods để có thể gọi từ _ProfileContentState và từ chính ProfileScreen
  static Widget _buildHeaderStatic() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hồ Sơ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: const Icon(
                Icons.settings,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildLoginButtonStatic(BuildContext context) {
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginScreen(isLoginMode: true),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'ĐĂNG NHẬP',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  static Widget _buildRegisterButtonStatic(BuildContext context) {
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
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginScreen(isLoginMode: false),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'ĐĂNG KÝ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  // ========== TẤT CẢ CÁC STATIC METHODS ==========
  static Widget _buildProfileHeaderStatic(ProfileState state) {
    if (state.user == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFE50914), Color(0xFFB20710)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE50914).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF2A2A2A),
                child: Text(
                  state.user!.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            state.user!.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            state.user!.email,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          if (state.user!.phone != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone, color: Colors.grey[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  state.user!.phone!,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE50914), Color(0xFFB20710)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE50914).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  state.user!.role == 'admin' ? 'ADMIN' : 'MEMBER',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildStatsCardsStatic(BuildContext context, ProfileState state) {
    final confirmedBookings = state.bookings.where((b) => b.booking.status == 'confirmed').length;
    final totalSpent = state.bookings
        .where((b) => b.booking.status == 'confirmed')
        .fold<double>(0, (sum, b) => sum + (b.booking.finalPrice ?? b.booking.totalPrice));
    final userPoints = state.user?.points ?? 0;

    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
        children: [
          Expanded(
                child: _buildStatCardStatic(
              'Phim Đã Xem',
              confirmedBookings.toString(),
              Icons.movie_outlined,
              const Color(0xFFE50914),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
                child: _buildStatCardStatic(
              'Tổng Chi Tiêu',
              '${NumberFormat('#,###', 'vi_VN').format(totalSpent)}đ',
              Icons.payments_outlined,
              const Color(0xFF4CAF50),
            ),
          ),
            ],
          ),
          const SizedBox(height: 12),
          // Points card
          _buildPointsCardStatic(context, userPoints),
        ],
      ),
    );
  }

  static Widget _buildPointsCardStatic(BuildContext context, int points) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE50914).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE50914).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.stars,
              color: Color(0xFFE50914),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Điểm Tích Lũy',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$points điểm',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RedeemVoucherScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.card_giftcard, size: 18),
                label: const Text('Đổi Voucher'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GetVoucherScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.card_giftcard, size: 18),
                label: const Text('Nhận Voucher'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE50914),
                  side: const BorderSide(color: Color(0xFFE50914)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildStatCardStatic(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget _buildMenuSectionStatic(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        children: [
          _buildMenuItemStatic(
            Icons.person_outline,
            'Thông Tin Cá Nhân',
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserInfoScreen(),
                ),
              ).then((_) {
                if (context.mounted) {
                  final userId = FirebaseAuth.instance.currentUser!.uid;
                  context.read<ProfileBloc>().add(RefreshProfile(userId));
                }
              });
            },
          ),
          _buildDividerStatic(),
          _buildMenuItemStatic(
            Icons.notifications_outlined,
            'Thông Báo',
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
          _buildDividerStatic(),
          _buildMenuItemStatic(
            Icons.smart_toy,
            'Chatbot Hỗ Trợ',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatBotScreen(),
                ),
              );
            },
          ),
          _buildDividerStatic(),
          _buildMenuItemStatic(Icons.help_outline, 'Trợ Giúp', () {}),
          _buildDividerStatic(),
          _buildMenuItemStatic(
            Icons.logout,
            'Đăng Xuất',
                () => FirebaseAuth.instance.signOut(),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  static Widget _buildMenuItemStatic(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? const Color(0xFFE50914).withOpacity(0.2)
                      : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? const Color(0xFFE50914) : Colors.white70,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDestructive ? const Color(0xFFE50914) : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[600],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildDividerStatic() {
    return Divider(
      color: const Color(0xFF2A2A2A),
      height: 1,
      indent: 60,
    );
  }

  static Widget _buildBookingHistoryStatic(ProfileState state, BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lịch Sử Đặt Vé',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${state.bookings.length} vé',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Box chứa lịch sử đặt vé với thanh cuộn
          Container(
            height: MediaQuery.of(context).size.height * 0.5, // Chiều cao động dựa trên màn hình (50% chiều cao màn hình)
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: state.bookings.isEmpty
                  ? const Center(
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Chưa có lịch sử đặt vé',
                        subtitle: 'Các vé bạn đặt sẽ hiển thị ở đây',
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: state.bookings.asMap().entries.map((entry) {
                          final index = entry.key;
                          final detail = entry.value;
                          final isLast = index == state.bookings.length - 1;
                          return _buildBookingCardStatic(detail, context, removeBottomMargin: isLast);
                        }).toList(),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildBookingCardStatic(BookingDetailModel detail, BuildContext context, {bool removeBottomMargin = false}) {
    final booking = detail.booking;
    final dateFormat = DateFormat('dd/MM/yyyy - HH:mm', 'vi_VN');

    return GestureDetector(
      onTap: () => _showBookingDetailStatic(context, detail),
      child: Container(
        margin: EdgeInsets.only(bottom: removeBottomMargin ? 0 : 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: detail.moviePoster,
                      width: 80,
                      height: 110,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFE50914),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.movie, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.movieTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRowStatic(
                          Icons.location_on_outlined,
                          detail.theaterName,
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRowStatic(
                          Icons.access_time,
                          dateFormat.format(detail.showtime),
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRowStatic(
                          Icons.event_seat,
                          booking.seats.join(', '),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF2A2A2A), height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: booking.status == 'confirmed'
                          ? const Color(0xFF4CAF50).withOpacity(0.2)
                          : const Color(0xFFE50914).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      booking.status == 'confirmed' ? 'Đã Xác Nhận' : 'Đã Hủy',
                      style: TextStyle(
                        color: booking.status == 'confirmed'
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFE50914),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${NumberFormat('#,###', 'vi_VN').format(booking.finalPrice ?? booking.totalPrice)}đ',
                    style: const TextStyle(
                      color: Color(0xFFE50914),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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

  static Widget _buildInfoRowStatic(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static void _showBookingDetailStatic(BuildContext context, BookingDetailModel detail) {
    final booking = detail.booking;
    final dateFormat = DateFormat('dd/MM/yyyy - HH:mm', 'vi_VN');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: detail.qrCode,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    detail.qrCode,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildDetailRowStatic('Phim', detail.movieTitle),
                  const Divider(color: Color(0xFF3A3A3A)),
                  _buildDetailRowStatic('Rạp', detail.theaterName),
                  const Divider(color: Color(0xFF3A3A3A)),
                  _buildDetailRowStatic('Suất chiếu', dateFormat.format(detail.showtime)),
                  const Divider(color: Color(0xFF3A3A3A)),
                  _buildDetailRowStatic('Ghế', booking.seats.join(', ')),
                  const Divider(color: Color(0xFF3A3A3A)),
                  _buildDetailRowStatic(
                    'Tổng tiền',
                    '${NumberFormat('#,###', 'vi_VN').format(booking.finalPrice ?? booking.totalPrice)}đ',
                    isHighlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2A2A),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Đóng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  static Widget _buildDetailRowStatic(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: isHighlight ? const Color(0xFFE50914) : Colors.white,
                fontSize: isHighlight ? 18 : 14,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget riêng để xử lý logic kiểm tra ngày sinh
class _ProfileContent extends StatefulWidget {
  final String userId;
  const _ProfileContent({required this.userId});

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  bool _hasCheckedDateOfBirth = false;

  // Delegate các methods đến ProfileScreen static methods
  Widget _buildHeader() => ProfileScreen._buildHeaderStatic();
  Widget _buildProfileHeader(ProfileState state) => ProfileScreen._buildProfileHeaderStatic(state);
  Widget _buildStatsCards(BuildContext context, ProfileState state) => ProfileScreen._buildStatsCardsStatic(context, state);
  Widget _buildMenuSection(BuildContext context) => ProfileScreen._buildMenuSectionStatic(context);
  Widget _buildBookingHistory(ProfileState state, BuildContext context) => ProfileScreen._buildBookingHistoryStatic(state, context);

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        // Chỉ kiểm tra một lần khi user data đã load xong
        if (!_hasCheckedDateOfBirth && 
            !state.isLoading && 
            state.user != null && 
            state.user!.dateOfBirth == null) {
          _hasCheckedDateOfBirth = true;
          // Hiển thị dialog yêu cầu cập nhật ngày sinh
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showDateOfBirthDialog(context);
          });
        }
      },
      child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state.isLoading && state.user == null) {
              return const AppLoadingIndicator(message: 'Đang tải thông tin...');
            }

            if (state.error != null) {
              return EmptyState(
                icon: Icons.error_outline,
                title: 'Có lỗi xảy ra',
                subtitle: state.error,
                action: ElevatedButton(
                  onPressed: () {
                    final userId = FirebaseAuth.instance.currentUser!.uid;
                    context.read<ProfileBloc>().add(RefreshProfile(userId));
                  },
                  child: const Text('Thử lại'),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                    context.read<ProfileBloc>().add(RefreshProfile(widget.userId));
              },
              color: const Color(0xFFE50914),
              backgroundColor: const Color(0xFF1A1A1A),
              child: SafeArea(
                child: CustomScrollView(
                  slivers: [
                    _buildHeader(),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildProfileHeader(state),
                              _buildStatsCards(context, state),
                          _buildMenuSection(context),
                          _buildBookingHistory(state, context),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
    );
  }

  void _showDateOfBirthDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFFE50914), size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cập nhật thông tin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Vui lòng cập nhật ngày sinh trong thông tin cá nhân để có thể đặt vé phim có độ tuổi xem.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Để sau',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserInfoScreen(),
                ),
              ).then((_) {
                // Refresh profile sau khi cập nhật
                if (context.mounted) {
                  context.read<ProfileBloc>().add(RefreshProfile(widget.userId));
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
            ),
            child: const Text(
              'Cập nhật ngay',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}