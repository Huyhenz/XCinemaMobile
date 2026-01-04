// File: lib/services/email_service.dart
// Service để gửi email xác nhận đặt vé qua SMTP

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../models/cinema.dart';
import '../models/movie.dart';
import '../models/showtime.dart';
import '../models/theater.dart';
import '../models/snack.dart';
import 'database_services.dart';

class EmailService {
  static final DatabaseService _dbService = DatabaseService();

  /// Gửi email xác nhận đặt vé thành công
  static Future<bool> sendBookingConfirmationEmail({
    required String userEmail,
    required String userName,
    required BookingModel booking,
    required String bookingId,
  }) async {
    try {
      print('📧 Bắt đầu gửi email xác nhận đặt vé...');
      
      // Lấy thông tin chi tiết
      ShowtimeModel? showtime = await _dbService.getShowtime(booking.showtimeId);
      if (showtime == null) {
        print('❌ Không tìm thấy lịch chiếu');
        return false;
      }

      MovieModel? movie = await _dbService.getMovie(showtime.movieId);
      if (movie == null) {
        print('❌ Không tìm thấy phim');
        return false;
      }

      TheaterModel? theater = await _dbService.getTheater(showtime.theaterId);
      CinemaModel? cinema = await _dbService.getCinema(booking.cinemaId);
      
      // Load snacks nếu có
      Map<String, SnackModel> snackMap = {};
      if (booking.snacks != null && booking.snacks!.isNotEmpty) {
        try {
          final allSnacks = await _dbService.getAllSnacks();
          for (var snack in allSnacks) {
            if (booking.snacks!.containsKey(snack.id)) {
              snackMap[snack.id] = snack;
            }
          }
        } catch (e) {
          print('⚠️ Error loading snacks for email: $e');
        }
      }

      // Đọc cấu hình SMTP từ .env
      String smtpHost;
      int smtpPort;
      String smtpUsername;
      String smtpPassword;
      String smtpFromEmail;
      String smtpFromName;

      try {
        smtpHost = dotenv.env['SMTP_HOST'] ?? 'smtp.gmail.com';
        smtpPort = int.tryParse(dotenv.env['SMTP_PORT'] ?? '587') ?? 587;
        smtpUsername = dotenv.env['SMTP_USERNAME'] ?? '';
        smtpPassword = dotenv.env['SMTP_PASSWORD'] ?? '';
        smtpFromEmail = dotenv.env['SMTP_FROM_EMAIL'] ?? smtpUsername;
        smtpFromName = dotenv.env['SMTP_FROM_NAME'] ?? 'XCinema';

        // Debug: Log các giá trị đã đọc (ẩn password)
        print('📧 SMTP Config Check:');
        print('   Host: $smtpHost');
        print('   Port: $smtpPort');
        print('   Username: ${smtpUsername.isNotEmpty ? "${smtpUsername.substring(0, smtpUsername.length > 5 ? 5 : smtpUsername.length)}..." : "EMPTY"}');
        print('   Password: ${smtpPassword.isNotEmpty ? "***" : "EMPTY"}');
        print('   From Email: $smtpFromEmail');
        print('   From Name: $smtpFromName');

        if (smtpUsername.isEmpty || smtpPassword.isEmpty) {
          print('⚠️ SMTP credentials chưa được cấu hình trong .env');
          print('💡 Để gửi email xác nhận, thêm các biến sau vào file .env:');
          print('   SMTP_HOST=smtp.gmail.com');
          print('   SMTP_PORT=587');
          print('   SMTP_USERNAME=your-email@gmail.com');
          print('   SMTP_PASSWORD=your-app-password');
          print('   SMTP_FROM_EMAIL=your-email@gmail.com');
          print('   SMTP_FROM_NAME=XCinema');
          print('💡 Với Gmail: Sử dụng App Password (không phải mật khẩu thường)');
          print('💡 Tạo App Password tại: https://myaccount.google.com/apppasswords');
          // Không return false, chỉ log warning và tiếp tục
          // App vẫn hoạt động bình thường, chỉ không gửi email
          return false;
        }
      } catch (e) {
        print('❌ Lỗi khi đọc SMTP config từ .env: $e');
        print('💡 Đảm bảo file .env đã được load trong main.dart');
        return false;
      }

      // Tạo SMTP server
      final smtpServer = SmtpServer(
        smtpHost,
        port: smtpPort,
        username: smtpUsername,
        password: smtpPassword,
        ssl: smtpPort == 465,
        allowInsecure: smtpPort == 587, // Allow insecure for STARTTLS
      );

      // Format thông tin
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'vi_VN');
      final showtimeDate = dateFormat.format(
        DateTime.fromMillisecondsSinceEpoch(showtime.startTime),
      );
      
      // Format booking date
      String bookingDateStr = 'N/A';
      if (booking.bookedAt != null) {
        bookingDateStr = dateFormat.format(
          DateTime.fromMillisecondsSinceEpoch(booking.bookedAt!),
        );
      }
      
      // Format payment method
      String paymentMethodStr = 'N/A';
      if (booking.paymentMethod != null) {
        switch (booking.paymentMethod!.toLowerCase()) {
          case 'paypal':
            paymentMethodStr = 'PayPal';
            break;
          case 'vnpay':
            paymentMethodStr = 'VNPay';
            break;
          case 'zalopay':
            paymentMethodStr = 'ZaloPay';
            break;
          default:
            paymentMethodStr = booking.paymentMethod!;
        }
      }
      
      // Format danh sách ghế - đảm bảo có giá trị
      final seats = booking.seats.isNotEmpty 
          ? booking.seats.join(', ')
          : 'Chưa có thông tin';
      final seatCount = booking.seats.length;
      
      // Sử dụng finalPrice nếu có (sau khi áp dụng voucher), nếu không thì dùng totalPrice
      final displayPrice = booking.finalPrice ?? booking.totalPrice;
      final totalPrice = NumberFormat('#,###', 'vi_VN').format(displayPrice);
      final originalPrice = booking.finalPrice != null 
          ? NumberFormat('#,###', 'vi_VN').format(booking.totalPrice)
          : null;
      final discountAmount = booking.finalPrice != null
          ? NumberFormat('#,###', 'vi_VN').format(booking.totalPrice - booking.finalPrice!)
          : null;
      
      // Format snacks HTML
      String snacksHtml = '';
      if (booking.snacks != null && booking.snacks!.isNotEmpty && snackMap.isNotEmpty) {
        final snacksList = booking.snacks!.entries.map((entry) {
          final snack = snackMap[entry.key];
          if (snack == null) return '';
          final quantity = entry.value;
          final snackTotal = snack.price * quantity;
          final formattedPrice = NumberFormat('#,###', 'vi_VN').format(snackTotal);
          return '''
          <div class="info-row" style="padding-left: 20px;">
            <span class="info-label">${snack.name} x$quantity</span>
            <span class="info-value">${formattedPrice}đ</span>
          </div>
          ''';
        }).where((html) => html.isNotEmpty).join('');
        
        if (snacksList.isNotEmpty) {
          snacksHtml = '''
        <div class="info-row" style="border-bottom: none;">
          <span class="info-label">Bắp nước:</span>
          <span class="info-value"></span>
        </div>
        $snacksList
          ''';
        }
      }
      
      // Generate QR code
      final qrCode = _generateQRCode(bookingId);

      // Tạo nội dung email HTML
      final emailBody = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: linear-gradient(135deg, #E50914 0%, #B20710 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
    .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
    .success-icon { font-size: 48px; margin-bottom: 10px; }
    .info-box { background: white; padding: 20px; margin: 15px 0; border-radius: 8px; border-left: 4px solid #E50914; }
    .info-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee; }
    .info-label { font-weight: bold; color: #666; }
    .info-value { color: #333; }
    .qr-code-box { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; text-align: center; border: 2px solid #E50914; }
    .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="success-icon">✅</div>
      <h1>Đặt Vé Thành Công!</h1>
      <p>Cảm ơn bạn đã sử dụng dịch vụ của chúng tôi</p>
    </div>
    <div class="content">
      <h2>Xin chào ${userName},</h2>
      <p>Vé xem phim của bạn đã được đặt thành công. Chi tiết đặt vé như sau:</p>
      
      <div class="info-box">
        <div class="info-row">
          <span class="info-label">Mã đặt vé:</span>
          <span class="info-value"><strong>${bookingId}</strong></span>
        </div>
        <div class="info-row">
          <span class="info-label">Tên phim:</span>
          <span class="info-value">${movie.title}</span>
        </div>
        <div class="info-row">
          <span class="info-label">Rạp chiếu:</span>
          <span class="info-value">${cinema?.name ?? 'N/A'}</span>
        </div>
        <div class="info-row">
          <span class="info-label">Phòng chiếu:</span>
          <span class="info-value">${theater?.name ?? 'N/A'}</span>
        </div>
        <div class="info-row">
          <span class="info-label">Suất chiếu:</span>
          <span class="info-value">${showtimeDate}</span>
        </div>
        <div class="info-row">
          <span class="info-label">Ghế đã chọn:</span>
          <span class="info-value"><strong>${seats}</strong></span>
        </div>
        <div class="info-row">
          <span class="info-label">Số lượng ghế:</span>
          <span class="info-value"><strong>${seatCount} ghế</strong></span>
        </div>
        <div class="info-row">
          <span class="info-label">Số lượng vé:</span>
          <span class="info-value"><strong>${seatCount} vé</strong></span>
        </div>
        $snacksHtml
        <div class="info-row">
          <span class="info-label">Tổng tiền:</span>
          <span class="info-value"><strong style="color: #E50914;">${totalPrice}₫</strong></span>
        </div>
        <div class="info-row">
          <span class="info-label">Ngày giờ đặt vé:</span>
          <span class="info-value">${bookingDateStr}</span>
        </div>
        <div class="info-row">
          <span class="info-label">Cách thức thanh toán:</span>
          <span class="info-value"><strong>${paymentMethodStr}</strong></span>
        </div>
      </div>

      <div class="qr-code-box" style="background: white; padding: 20px; margin: 20px 0; border-radius: 8px; text-align: center; border: 2px solid #E50914;">
        <h3 style="color: #E50914; margin-bottom: 15px;">Mã QR Vé</h3>
        <div style="background: white; padding: 20px; display: inline-block; border: 2px solid #ddd; border-radius: 8px;">
          <img src="https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(qrCode)}" alt="QR Code" style="width: 200px; height: 200px;" />
        </div>
        <p style="margin-top: 15px; color: #666; font-size: 12px;">Vui lòng mang mã QR này khi đến rạp</p>
      </div>

      <p><strong>Lưu ý:</strong></p>
      <ul>
        <li>Vui lòng đến rạp trước 15 phút để làm thủ tục vào rạp</li>
        <li>Mang theo mã đặt vé này khi đến rạp</li>
        <li>Vé đã được thanh toán thành công</li>
      </ul>

      <div class="footer">
        <p>Trân trọng,<br><strong>XCinema</strong></p>
        <p>Nếu có thắc mắc, vui lòng liên hệ: support@xcinema.app</p>
      </div>
    </div>
  </div>
</body>
</html>
      ''';

      // Tạo message
      final message = Message()
        ..from = Address(smtpFromEmail, smtpFromName)
        ..recipients.add(userEmail)
        ..subject = 'Xác Nhận Đặt Vé Thành Công - ${movie.title}'
        ..html = emailBody
        ..text = '''
Xin chào ${userName},

Vé xem phim của bạn đã được đặt thành công.

Chi tiết đặt vé:
- Mã đặt vé: ${bookingId}
- Tên phim: ${movie.title}
- Rạp chiếu: ${cinema?.name ?? 'N/A'}
- Phòng chiếu: ${theater?.name ?? 'N/A'}
- Suất chiếu: ${showtimeDate}
- Ghế đã chọn: ${seats}
- Số lượng ghế: ${seatCount} ghế
- Số lượng vé: ${seatCount} vé
- Tổng tiền: ${totalPrice}₫
- Ngày giờ đặt vé: ${bookingDateStr}
- Cách thức thanh toán: ${paymentMethodStr}
- Mã QR vé: ${qrCode}

Lưu ý:
- Vui lòng đến rạp trước 15 phút để làm thủ tục vào rạp
- Mang theo mã đặt vé này khi đến rạp
- Vé đã được thanh toán thành công

Trân trọng,
XCinema
        ''';

      // Gửi email
      try {
        final sendReport = await send(message, smtpServer);
        print('✅ Email đã được gửi thành công!');
        print('   To: $userEmail');
        print('   Subject: ${message.subject}');
        return true;
      } on MailerException catch (e) {
        print('❌ Lỗi gửi email: ${e.message}');
        if (e.message.contains('authentication')) {
          print('💡 Kiểm tra lại SMTP_USERNAME và SMTP_PASSWORD trong .env');
          print('💡 Với Gmail, cần sử dụng App Password thay vì mật khẩu thường');
        }
        return false;
      } catch (e) {
        print('❌ Lỗi không xác định khi gửi email: $e');
        return false;
      }
    } catch (e) {
      print('❌ Lỗi trong sendBookingConfirmationEmail: $e');
      return false;
    }
  }
  
  /// Generate QR code - sử dụng bookingId làm mã QR (giống với mã đặt vé)
  static String _generateQRCode(String bookingId) {
    // Trả về chính bookingId làm mã QR (giống với mã đặt vé)
    return bookingId;
  }
}

