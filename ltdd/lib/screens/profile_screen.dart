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
import '../utils/booking_helper.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_widgets.dart';
import 'user_info_screen.dart';
import 'notification_screen.dart';
import 'chatbot_screen.dart';
import 'login_screen.dart';

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
              _buildHeader(),
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
                      _buildLoginButton(context),
                      const SizedBox(height: 16),
                      _buildRegisterButton(context),
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
          child: Scaffold(
            backgroundColor: const Color(0xFF0F0F0F),
            body: BlocBuilder<ProfileBloc, ProfileState>(
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
                    context.read<ProfileBloc>().add(RefreshProfile(userId));
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
                              _buildStatsCards(state),
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
          ),
        );
      },
    );
  }

  Widget _buildLoginButton(BuildContext context) {
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

  Widget _buildRegisterButton(BuildContext context) {
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

  Widget _buildHeader() {
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

  Widget _buildProfileHeader(ProfileState state) {
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

  Widget _buildStatsCards(ProfileState state) {
    final confirmedBookings = state.bookings.where((b) => b.booking.status == 'confirmed').length;
    final totalSpent = state.bookings
        .where((b) => b.booking.status == 'confirmed')
        .fold<double>(0, (sum, b) => sum + (b.booking.finalPrice ?? b.booking.totalPrice));

    return Container(
      margin: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Phim Đã Xem',
              confirmedBookings.toString(),
              Icons.movie_outlined,
              const Color(0xFFE50914),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Tổng Chi Tiêu',
              '${NumberFormat('#,###', 'vi_VN').format(totalSpent)}đ',
              Icons.payments_outlined,
              const Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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

  Widget _buildMenuSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        children: [
          _buildMenuItem(
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
          _buildDivider(),
          _buildMenuItem(
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
          _buildDivider(),
          _buildMenuItem(
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
          _buildDivider(),
          _buildMenuItem(Icons.help_outline, 'Trợ Giúp', () {}),
          _buildDivider(),
          _buildMenuItem(
            Icons.logout,
            'Đăng Xuất',
                () => FirebaseAuth.instance.signOut(),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap,
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

  Widget _buildDivider() {
    return Divider(
      color: const Color(0xFF2A2A2A),
      height: 1,
      indent: 60,
    );
  }

  Widget _buildBookingHistory(ProfileState state, BuildContext context) {
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
          if (state.bookings.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Chưa có lịch sử đặt vé',
              subtitle: 'Các vé bạn đặt sẽ hiển thị ở đây',
            )
          else
            ...state.bookings.map((detail) => _buildBookingCard(detail, context)),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingDetailModel detail, BuildContext context) {
    final booking = detail.booking;
    final dateFormat = DateFormat('dd/MM/yyyy - HH:mm', 'vi_VN');

    return GestureDetector(
      onTap: () => _showBookingDetail(context, detail),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
                        _buildInfoRow(
                          Icons.location_on_outlined,
                          detail.theaterName,
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          Icons.access_time,
                          dateFormat.format(detail.showtime),
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
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

  Widget _buildInfoRow(IconData icon, String text) {
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

  void _showBookingDetail(BuildContext context, BookingDetailModel detail) {
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
                  _buildDetailRow('Phim', detail.movieTitle),
                  const Divider(color: Color(0xFF3A3A3A)),
                  _buildDetailRow('Rạp', detail.theaterName),
                  const Divider(color: Color(0xFF3A3A3A)),
                  _buildDetailRow('Suất chiếu', dateFormat.format(detail.showtime)),
                  const Divider(color: Color(0xFF3A3A3A)),
                  _buildDetailRow('Ghế', booking.seats.join(', ')),
                  const Divider(color: Color(0xFF3A3A3A)),
                  _buildDetailRow(
                    'Tổng tiền',
                    '${NumberFormat('#,###', 'vi_VN').format(booking.finalPrice ?? booking.totalPrice)}đ',
                    isHighlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // ✅ Nút Xóa Booking (chỉ hiện nếu status = confirmed)
            if (booking.status == 'confirmed') ...[
              ElevatedButton(
                onPressed: () => _confirmDeleteBooking(context, booking.id, detail.movieTitle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(width: 8),
                    Text(
                      'Hủy Đặt Vé',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
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

  // ✅ Confirm Dialog trước khi xóa
  void _confirmDeleteBooking(BuildContext context, String bookingId, String movieTitle) {
    ConfirmationDialog.show(
      context: context,
      title: 'Xác Nhận Hủy Vé',
      message: 'Bạn có chắc muốn hủy vé xem phim "$movieTitle"?\n\nGhế sẽ được mở lại cho người khác đặt.',
      confirmText: 'Xác Nhận Hủy',
      cancelText: 'Không',
      isDestructive: true,
      icon: Icons.warning_amber_rounded,
      onConfirm: () async {
        Navigator.pop(context); // Đóng bottom sheet nếu đang mở
        await _deleteBooking(context, bookingId, movieTitle);
      },
    );
  }

  // ✅ Xóa booking và sync ghế
  Future<void> _deleteBooking(BuildContext context, String bookingId, String movieTitle) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AppLoadingIndicator(message: 'Đang xử lý...'),
      );

      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Delete booking (tự động sync ghế trong deleteBooking)
      await DatabaseService().deleteBooking(bookingId);

      // Tạo notification hủy vé
      await BookingHelper.createBookingCancelledNotification(
        userId: userId,
        bookingId: bookingId,
        movieTitle: movieTitle,
      );

      // Close loading
      if (context.mounted) Navigator.pop(context);

      // Refresh profile
      if (context.mounted) {
        context.read<ProfileBloc>().add(RefreshProfile(userId));
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hủy đặt vé. Ghế đã được mở lại!'),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Close loading if still open
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi hủy vé: $e'),
            backgroundColor: const Color(0xFFE50914),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
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