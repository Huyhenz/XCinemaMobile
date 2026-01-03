// File: lib/l10n/app_localizations.dart
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'vi': {
      // Profile Screen
      'profile': 'Hồ Sơ',
      'personal_info': 'Thông Tin Cá Nhân',
      'notifications': 'Thông Báo',
      'chatbot_support': 'Chatbot Hỗ Trợ',
      'settings': 'Cài Đặt',
      'logout': 'Đăng Xuất',
      'welcome_cinema': 'Chào mừng bạn đến với Cinema',
      'login_register_message': 'Đăng nhập hoặc đăng ký để xem thông tin cá nhân và lịch sử đặt vé',
      'login': 'ĐĂNG NHẬP',
      'register': 'ĐĂNG KÝ',
      'movies_watched': 'Phim Đã Xem',
      'total_spent': 'Tổng Chi Tiêu',
      'points': 'Điểm Tích Lũy',
      'redeem_voucher': 'Đổi Voucher',
      'get_voucher': 'Nhận Voucher',
      'booking_history': 'Lịch Sử Đặt Vé',
      'tickets': 'vé',
      'no_booking_history': 'Chưa có lịch sử đặt vé',
      'booking_history_subtitle': 'Các vé bạn đặt sẽ hiển thị ở đây',
      
      // Settings Screen
      'language': 'Ngôn Ngữ',
      'vietnamese': 'Tiếng Việt',
      'english': 'English',
      'theme': 'Giao Diện',
      'dark_mode': 'Chế Độ Tối',
      'light_mode': 'Chế Độ Sáng',
      'switched_to_vietnamese': 'Đã chuyển sang tiếng Việt',
      'switched_to_english': 'Switched to English',
      'switched_to_dark': 'Đã chuyển sang chế độ tối',
      'switched_to_light': 'Switched to light mode',
      
      // Movie Detail Screen
      'book_ticket_now': 'ĐẶT VÉ NGAY',
      'no_showtimes': 'CHƯA CÓ LỊCH CHIẾU',
      
      // Home Screen
      'now_showing': 'Đang Chiếu',
      'coming_soon': 'Sắp Chiếu',
      'popular': 'Phổ Biến',
      'search_placeholder': 'Tìm kiếm theo tên phim hoặc thể loại...',
      'no_movies_found': 'Không tìm thấy phim',
      'try_different_search': 'Thử tìm kiếm với từ khóa khác',
      'select_cinema': 'Chọn Rạp',
      'all_cinemas': 'Tất Cả Rạp',
      
      // Login Screen
      'login_tab': 'Đăng Nhập',
      'register_tab': 'Đăng Ký',
      'email': 'Email',
      'password': 'Mật khẩu',
      'name': 'Họ tên',
      'phone': 'Số điện thoại',
      'date_of_birth': 'Ngày tháng năm sinh',
      'select_date': 'Chọn ngày',
      'login_with_google': 'Đăng nhập với Google',
      'register_success': 'Đăng ký thành công. Vui lòng kiểm tra email.',
      'login_success': 'Đăng nhập thành công',
      'booking_easy': 'Đặt vé xem phim dễ dàng',
      
      // Showtimes Screen
      'select_showtime': 'Chọn Lịch Chiếu',
      'no_showtimes_available': 'Không có lịch chiếu',
      'no_showtimes_for_date': 'Không có lịch chiếu cho ngày này',
      'today': 'Hôm nay',
      'tomorrow': 'Ngày mai',
      
      // Booking Screen
      'select_seats': 'Chọn Ghế',
      'screen': 'MÀN HÌNH',
      'available': 'Trống',
      'selected': 'Đã chọn',
      'occupied': 'Đã đặt',
      'vip': 'VIP',
      'total': 'Tổng',
      'continue': 'Tiếp tục',
      'refresh': 'Làm mới',
      
      // Payment Screen
      'payment': 'Thanh Toán',
      'payment_method': 'Phương thức thanh toán',
      'order_summary': 'Tóm tắt đơn hàng',
      'tickets_count': 'Vé',
      'snacks': 'Đồ ăn',
      'subtotal': 'Tạm tính',
      'discount': 'Giảm giá',
      'total_price': 'Tổng tiền',
      'pay_now': 'Thanh Toán Ngay',
      
      // Notification Screen
      'no_notifications': 'Chưa có thông báo',
      'notifications_subtitle': 'Các thông báo mới sẽ hiển thị ở đây',
      'unread_count': 'chưa đọc',
      
      // User Info Screen
      'edit_profile': 'Chỉnh Sửa Hồ Sơ',
      'full_name': 'Họ và tên',
      'phone_number': 'Số điện thoại',
      'email_address': 'Địa chỉ email',
      'date_of_birth_label': 'Ngày sinh',
      'update_profile': 'Cập nhật hồ sơ',
      'profile_updated': 'Cập nhật hồ sơ thành công',
      
      // Admin Dashboard
      'admin_dashboard': 'Bảng Điều Khiển Admin',
      'create_movie': 'Tạo Phim',
      'create_showtime': 'Tạo Lịch Chiếu',
      'create_theater': 'Tạo Phòng Chiếu',
      'create_cinema': 'Tạo Rạp Chiếu',
      'create_voucher': 'Tạo Voucher',
      'edit_movie': 'Sửa Phim',
      'manage_cinemas': 'Quản Lý Rạp Chiếu',
      'manage_movies': 'Quản Lý Phim',
      'manage_showtimes': 'Quản Lý Lịch Chiếu',
      'manage_theaters': 'Quản Lý Phòng Chiếu',
      'manage_vouchers': 'Quản Lý Voucher',
      'manage_minigame': 'Quản Lý Minigame',
      'create_snack': 'Tạo Bắp Nước',
      'movie_title': 'Tên phim',
      'movie_description': 'Mô tả',
      'movie_genre': 'Thể loại',
      'movie_duration': 'Thời lượng (phút)',
      'trailer_url': 'URL Trailer',
      'age_rating': 'Độ tuổi',
      'poster_url': 'URL Poster',
      'select_cinema_label': 'Chọn Rạp Chiếu',
      'create_for_all_cinemas': 'Tạo cho tất cả rạp',
      'theater_name': 'Tên phòng',
      'theater_capacity': 'Số ghế',
      'theater_type': 'Loại phòng',
      'cinema_name': 'Tên rạp',
      'cinema_address': 'Địa chỉ',
      'voucher_code': 'Mã voucher',
      'voucher_discount': 'Giảm giá (%)',
      'voucher_min_spend': 'Giá trị đơn tối thiểu',
      'voucher_expiry': 'Ngày hết hạn',
      
      // Voucher Screens
      'get_voucher_title': 'Nhận Voucher',
      'get_voucher_subtitle': 'Chọn cách bạn muốn nhận voucher',
      'redeem_points_for_voucher': 'Đổi Điểm Lấy Voucher',
      'redeem_points_description': 'Sử dụng điểm tích lũy để đổi voucher',
      'complete_tasks': 'Thực Hiện Nhiệm Vụ',
      'complete_tasks_description': 'Hoàn thành nhiệm vụ để nhận điểm hoặc voucher',
      'play_minigame': 'Chơi Minigame',
      'play_minigame_description': 'Chơi game nhỏ để nhận điểm hoặc voucher',
      'view_all_vouchers': 'Xem Tất Cả Voucher',
      'view_all_vouchers_description': 'Xem danh sách tất cả voucher có thể lấy được',
      'redeem_voucher': 'Đổi Voucher',
      'confirm_redeem_voucher': 'Xác nhận đổi voucher',
      'confirm_redeem_message': 'Bạn có chắc muốn đổi voucher',
      'with_points': 'với',
      'points_label': 'điểm',
      'please_login': 'Vui lòng đăng nhập',
      'no_vouchers_to_redeem': 'Không có voucher nào để đổi',
      'not_enough_points': 'Không đủ điểm để đổi voucher. Cần',
      'you_have': 'bạn có',
      'voucher_redeemed_success': 'Đã đổi voucher thành công!',
      'change_game': 'Đổi trò chơi',
      'reward': 'Phần thưởng',
      'congratulations': 'Chúc mừng! Bạn đã nhận',
      'points_received': 'điểm!',
      
      // Chatbot Screen
      'chatbot_welcome': 'Xin chào! Tôi là chatbot hỗ trợ đặt vé xem phim. Tôi có thể giúp bạn:',
      'chatbot_find_movies': 'Tìm phim đang chiếu',
      'chatbot_showtimes': 'Xem lịch chiếu',
      'chatbot_prices': 'Hỏi về giá vé',
      'chatbot_faq': 'Trả lời câu hỏi thường gặp',
      'chatbot_how_can_i_help': 'Bạn cần hỗ trợ gì?',
      'chatbot_suggestion_now_showing': 'Phim đang chiếu',
      'chatbot_suggestion_coming_soon': 'Phim sắp chiếu',
      'chatbot_suggestion_cinemas': 'Rạp nào',
      'chatbot_suggestion_prices': 'Giá vé',
      'chatbot_suggestion_how_to_book': 'Cách đặt vé',
      'type_message': 'Nhập tin nhắn...',
      
      // Payment Success/Failure
      'payment_success': 'Thanh toán thành công!',
      'payment_success_message': 'Giao dịch của bạn đã được xử lý thành công.',
      'transaction_id': 'Mã giao dịch:',
      'payment_failed': 'Thanh toán thất bại',
      'payment_cancelled': 'Thanh toán đã bị hủy',
      'payment_cancelled_message': 'Bạn đã hủy giao dịch thanh toán.',
      'payment_failed_message': 'Giao dịch của bạn không thể được xử lý. Vui lòng thử lại.',
      'payment_info_cancelled': 'Vé của bạn vẫn được giữ trong giỏ hàng. Bạn có thể thử thanh toán lại.',
      'payment_info_failed': 'Vui lòng kiểm tra lại thông tin thanh toán hoặc thử lại sau.',
      'back_to_home': 'Về Trang Chủ',
      
      // Snack Selection
      'select_snacks': 'Chọn Bắp Nước',
      'skip': 'Bỏ qua',
      'continue_to_payment': 'Tiếp tục thanh toán',
      'no_snacks_available': 'Không có đồ ăn nào',
      
      // Email Verification
      'email_verification': 'Xác Thực Email',
      'verification_success': 'Xác thực thành công! Đang vào ứng dụng...',
      'verification_pending': 'Vẫn chưa xác thực. Vui lòng kiểm tra email của bạn.',
      'check_verification': 'Kiểm tra xác thực',
      'resend_email': 'Gửi lại email',
      'verification_sent': 'Email xác thực đã được gửi',
      'verification_info': 'Vui lòng kiểm tra email và nhấp vào liên kết để xác thực tài khoản của bạn.',
      
      // Cinema Selection
      'select_cinema_title': 'Chọn Rạp Chiếu',
      'no_cinemas_available': 'Chưa có rạp chiếu',
      'error_loading_cinemas': 'Lỗi tải danh sách rạp',
      
      // Voucher Tasks
      'voucher_tasks': 'Nhiệm Vụ',
      'reset_tasks': 'Reset Nhiệm Vụ',
      'reset_tasks_confirm': 'Bạn có chắc muốn reset nhiệm vụ hôm nay không? Tất cả tiến độ sẽ bị xóa và chọn lại nhiệm vụ mới.',
      'task_completed': 'Nhiệm vụ đã hoàn thành',
      'claim_reward': 'Nhận thưởng',
      'task_in_progress': 'Đang thực hiện',
      'task_claimed': 'Đã Nhận',
      'task_not_completed': 'Chưa Hoàn Thành',
      'task_complete': 'Hoàn Thành',
      'progress': 'Tiến độ',
      'available_tasks': 'Nhiệm Vụ Có Sẵn',
      
      // All Vouchers
      'all_vouchers': 'Tất Cả Voucher',
      'no_vouchers': 'Không có voucher nào',
      'unlocked': 'Đã mở khóa',
      'locked': 'Đã khóa',
      
      // Notification
      'notification_deleted': 'Đã xóa thông báo',
      'delete_notification': 'Xóa thông báo',
      'mark_as_read': 'Đánh dấu đã đọc',
      'mark_as_unread': 'Đánh dấu chưa đọc',
      
      // Login/Register Messages
      'register_success_check_email': 'Đăng ký thành công. Vui lòng kiểm tra email.',
      'verification_link_expired': 'Link xác thực đã hết hạn (quá 5 phút). Tài khoản đã bị hủy. Vui lòng đăng ký lại.',
      'google_login_error': 'Lỗi đăng nhập Google',
      'error_sending_email': 'Lỗi gửi mail',
      'too_many_requests': 'Gửi quá nhiều lần. Vui lòng đợi một chút rồi thử lại.',
      'verification_link_sent_to': 'Link xác thực đã được gửi đến:',
      'verification_link_expires': 'Link xác thực sẽ hết hạn sau 5 phút. Nếu không xác thực kịp, tài khoản sẽ bị hủy.',
      'i_verified': 'TÔI ĐÃ XÁC THỰC',
      'back_to_login': 'Quay lại đăng nhập',
      'check_your_email': 'Kiểm tra email của bạn',
      
      // User Info Screen
      'error_loading_info': 'Lỗi tải thông tin',
      'phone_number_label': 'Số Điện Thoại',
      'role': 'Vai Trò',
      'admin_role': 'Quản Trị Viên',
      'member_role': 'Thành Viên',
      'join_date': 'Ngày Tham Gia',
      
      // Booking Screen
      'seats_selected': 'ghế đã chọn',
      'error_loading_data': 'Lỗi tải dữ liệu',
      'error_cinema_not_found': 'Lỗi: Không tìm thấy thông tin rạp chiếu',
      'error_updating': 'Lỗi cập nhật',
      
      // Admin Dashboard - Additional Messages
      'select_movie': 'Chọn Phim',
      'please_select_movie': 'Vui lòng chọn phim',
      'showtime_will_be_created_for_all': 'Lịch chiếu sẽ được tạo cho tất cả phòng chiếu của tất cả rạp',
      'showtime_updated_success': '✅ Đã cập nhật lịch chiếu',
      'theater_updated_success': '✅ Đã cập nhật phòng chiếu',
      'couple_seat_price': 'Giá Ghế Đôi (₫)',
      'please_enter_couple_seat_price': 'Vui lòng nhập giá ghế đôi',
      'vip_bed_price': 'Giá Giường Đôi VIP (₫)',
      'please_enter_vip_bed_price': 'Vui lòng nhập giá giường đôi VIP',
      'price_must_be_greater_than_zero': 'Giá phải lớn hơn 0',
      'create_theater_for_all_cinemas': 'Tạo phòng chiếu này cho tất cả rạp cùng lúc',
      'please_select_cinema_or_all': 'Vui lòng chọn rạp chiếu hoặc chọn tạo cho tất cả rạp',
      'please_select_release_date': 'Vui lòng chọn ngày phát hành',
      'please_enter_movie_name': 'Vui lòng nhập tên phim',
      'please_enter_description': 'Vui lòng nhập mô tả',
      'please_enter_genre': 'Vui lòng nhập thể loại',
      'duration_minutes': 'Thời Lượng (phút)',
      'please_enter_duration': 'Vui lòng nhập thời lượng',
      'please_enter_valid_number': 'Vui lòng nhập số hợp lệ',
      'trailer_url': 'Link Trailer (URL)',
      'trailer_url_hint': 'https://youtube.com/watch?v=... hoặc link video khác',
      'please_enter_valid_url': 'Vui lòng nhập URL hợp lệ',
      'theater_created_success_for_cinemas': 'Đã tạo phòng chiếu thành công cho {count} rạp!',
      'theater_created_partial': 'Đã tạo phòng chiếu cho {success} rạp, thất bại {fail} rạp',
      'voucher_created_success': 'Đã tạo voucher {type} thành công!',
      'voucher_type_free': 'miễn phí',
      'voucher_type_task': 'nhiệm vụ',
      'voucher_type_points': 'điểm',
      'confirm_delete_voucher': 'Xác nhận xóa',
      'confirm_delete_voucher_message': 'Bạn có chắc chắn muốn xóa voucher "{id}"?\n\nHành động này không thể hoàn tác.',
      'movie_updated_success': 'Đã cập nhật phim thành công!',
      'theater_not_found': 'Không tìm thấy phòng chiếu',
      'rows_and_seats_must_be_greater_than_zero': 'Số hàng và số ghế phải lớn hơn 0',
      'please_enter_genre': 'Vui lòng nhập thể loại',
      'please_enter_duration': 'Vui lòng nhập thời lượng',
      'please_enter_valid_url': 'Vui lòng nhập URL hợp lệ (bắt đầu bằng http:// hoặc https://)',
      'age_rating': 'Độ Tuổi Xem (Tùy chọn)',
      'age_rating_hint': 'VD: T13, T16, T18, P (Phổ thông). Để trống = Tất cả độ tuổi',
      'release_date_label': 'Ngày Phát Hành',
      'please_select_theater': 'Vui lòng chọn phòng chiếu',
      'please_select_date': 'Vui lòng chọn ngày',
      'please_select_time': 'Vui lòng chọn giờ',
      'cinema_name_label': 'Tên Rạp Chiếu',
      'please_enter_cinema_name': 'Vui lòng nhập tên rạp',
      'address_label': 'Địa Chỉ',
      'please_enter_address': 'Vui lòng nhập địa chỉ',
      'cinema_image_url': 'Link Ảnh Rạp (URL)',
      'cinema_image_url_hint': 'https://example.com/cinema.jpg',
      'latitude': 'Vĩ Độ (Latitude)',
      'latitude_hint': '10.762622',
      'longitude': 'Kinh Độ (Longitude)',
      'longitude_hint': '106.660172',
      'create_cinema_button': 'TẠO RẠP CHIẾU',
      'select_cinema_label': 'Chọn Rạp Chiếu',
      'manage_snacks': 'Quản Lý Bắp Nước',
      'database_cleanup': 'Database Cleanup',
      'please_select_expiry_date': 'Vui lòng chọn ngày hết hạn',
      'points_voucher_need_valid_points': 'Voucher điểm cần nhập số điểm hợp lệ',
      'task_voucher_need_task_id': 'Voucher nhiệm vụ cần nhập ID nhiệm vụ',
      
      // Admin Dashboard - Success Messages
      'cinema_created_success': '✅ Đã tạo rạp chiếu thành công!',
      'cinema_deleted_success': '✅ Đã xóa rạp chiếu',
      'cinema_updated_success': '✅ Đã cập nhật rạp chiếu thành công!',
      'movie_created_success': '✅ Đã tạo phim thành công cho {count} rạp!',
      'movie_deleted_success': '✅ Đã xóa phim',
      'showtime_created_success': '✅ Đã tạo lịch chiếu thành công! ({count} lịch chiếu)',
      'showtime_deleted_success': '✅ Đã xóa lịch chiếu',
      'theater_deleted_success': '✅ Đã xóa phòng chiếu',
      'error_occurred': 'Lỗi',
      
      // Admin Dashboard - Confirm Dialogs
      'confirm_delete': 'Xác nhận xóa',
      'confirm_delete_cinema': 'Bạn có chắc chắn muốn xóa rạp chiếu "{name}"?\n\nHành động này không thể hoàn tác.',
      'confirm_delete_movie': 'Bạn có chắc chắn muốn xóa phim "{name}"?\n\nHành động này không thể hoàn tác.',
      'confirm_delete_showtime': 'Bạn có chắc chắn muốn xóa lịch chiếu "{name}"?\n\nThời gian: {time}\n\nHành động này không thể hoàn tác.',
      'confirm_delete_theater': 'Bạn có chắc chắn muốn xóa phòng chiếu "{name}"?\n\nHành động này không thể hoàn tác và sẽ xóa tất cả lịch chiếu liên quan.',
      'action_cannot_undo': 'Hành động này không thể hoàn tác',
      
      // Admin Dashboard - Buttons
      'delete': 'Xóa',
      'edit': 'Sửa',
      
      // Admin Dashboard - Tooltips
      'edit_cinema': 'Sửa rạp chiếu',
      'delete_cinema': 'Xóa rạp chiếu',
      'edit_showtime': 'Sửa lịch chiếu',
      'delete_showtime': 'Xóa lịch chiếu',
      'edit_theater': 'Sửa phòng chiếu',
      'delete_theater': 'Xóa phòng chiếu',
      'edit_movie_tooltip': 'Sửa phim',
      'delete_movie_tooltip': 'Xóa phim',
      'edit_voucher_tooltip': 'Sửa voucher',
      'delete_voucher_tooltip': 'Xóa voucher',
      'edit_snack_tooltip': 'Sửa',
      'delete_snack_tooltip': 'Xóa',
      
      // Admin Dashboard - Dialog Titles
      'edit_showtime_title': 'Sửa Lịch Chiếu',
      'edit_theater_title': 'Sửa Phòng Chiếu',
      
      // Admin Dashboard - Form Labels
      'cinema_name_label': 'Tên Rạp Chiếu *',
      'cinema_address_label': 'Địa Chỉ *',
      'cinema_phone_label': 'Số Điện Thoại',
      'cinema_image_url_label': 'Link Ảnh Rạp (URL)',
      'cinema_latitude_label': 'Vĩ Độ (Latitude)',
      'cinema_longitude_label': 'Kinh Độ (Longitude)',
      'please_enter_cinema_name': 'Vui lòng nhập tên rạp',
      'please_enter_cinema_address': 'Vui lòng nhập địa chỉ',
      
      // Admin Dashboard - Empty States
      'no_cinemas_yet': 'Chưa có rạp chiếu nào',
      'create_cinema_in_tab': 'Hãy tạo rạp chiếu mới ở tab "Tạo Rạp Chiếu"',
      'edit_cinema_title': 'Sửa Rạp Chiếu',
      
      // Admin Dashboard - Info Messages
      'create_for_all_cinemas_info': 'Tạo phim này cho tất cả rạp cùng lúc',
      'create_showtime_for_all_info': 'Tạo lịch chiếu cho tất cả rạp cùng lúc',
      'showtime_will_be_created_for_all': 'Lịch chiếu sẽ được tạo cho tất cả phòng chiếu của tất cả rạp',
      'create_theater_for_all_info': 'Tạo phòng chiếu này cho tất cả rạp cùng lúc',
      
      // Payment Screen
      'please_select_voucher': 'Vui lòng chọn voucher hoặc nhập mã voucher',
      'voucher_expired': 'Voucher đã hết hạn!',
      'voucher_inactive': 'Voucher không còn hoạt động!',
      'voucher_applied_success': 'Áp dụng voucher thành công!',
      'error_creating_temp_booking': 'Lỗi tạo booking tạm thời',
      'smtp_not_configured': 'SMTP chưa được cấu hình. Vui lòng kiểm tra file .env',
      'email_cannot_send': 'Email xác nhận không thể gửi được. Vui lòng kiểm tra cấu hình SMTP.',
      'email_cannot_send_title': 'Không thể gửi email xác nhận',
      
      // Admin Dashboard - Validators
      'please_enter_poster_url': 'Vui lòng nhập link ảnh poster',
      'please_enter_valid_url': 'Vui lòng nhập URL hợp lệ (bắt đầu bằng http:// hoặc https://)',
      'please_enter_theater_name': 'Vui lòng nhập tên phòng chiếu',
      'please_select_voucher_type': 'Vui lòng chọn loại voucher',
      'system_error': 'Lỗi hệ thống',
      'invalid_value': 'Lỗi giá trị',
      'please_select_movie': 'Vui lòng chọn phim',
      'please_select_cinema': 'Vui lòng chọn rạp chiếu',
      
      // Admin Dashboard - Messages
      'cannot_load_image': 'Không thể tải ảnh',
      'no_movies_in_system': 'Không có phim nào trong hệ thống. Vui lòng tạo phim trước.',
      'cinema_no_movies': 'Rạp này chưa có phim. Vui lòng tạo phim cho rạp này trước.',
      'cinema_no_theaters': 'Rạp này chưa có phòng chiếu. Vui lòng tạo phòng chiếu cho rạp này trước.',
      'not_available': 'N/A',
      'delete_showtime_tooltip': 'Xóa lịch chiếu',
      'theater_name_label': 'Tên Phòng Chiếu',
      'select_theater_label': 'Chọn Phòng Chiếu',
      'showtime': 'lịch chiếu',
      'showtime_date': 'Ngày chiếu',
      'showtime_time': 'Giờ chiếu',
      'showtime_date_time': 'Ngày và Giờ Chiếu',
      'rows_label': 'Số Hàng Ghế',
      'seats_per_row_label': 'Số Ghế Mỗi Hàng',
      'single_seat_price': 'Giá Ghế Đơn (₫)',
      'please_enter_rows': 'Vui lòng nhập số hàng',
      'please_enter_seats_per_row': 'Vui lòng nhập số ghế mỗi hàng',
      'please_enter_single_seat_price': 'Vui lòng nhập giá ghế đơn',
      'rows_must_be_positive': 'Số hàng phải là số dương',
      'seats_per_row_must_be_positive': 'Số ghế mỗi hàng phải là số dương',
      'random_time': 'Random thời gian',
      'random_time_description': 'Tự động tạo thời gian ngẫu nhiên từ 7h sáng đến 11h tối (chỉ áp dụng khi tạo cho tất cả rạp)',
      'theater_type': 'Loại phòng',
      'theater_type_normal': 'Thường',
      'theater_type_couple': 'Couple',
      'theater_type_vip': 'VIP',
      'theater_type_label': 'Loại Phòng Chiếu',
      'seats_per_row_auto': 'Số ghế mỗi hàng: {count} (tự động)',
      'poster_url_label': 'Link Ảnh Poster (URL)',
      'select_release_date': 'Chọn ngày phát hành',
      'genre_label': 'Thể Loại',
      'discount_type_label': 'Loại Giảm Giá',
      'available_seats': 'Ghế trống: {available}/{total}',
      
      // Common
      'confirm': 'Xác Nhận',
      'cancel': 'Hủy',
      'save': 'Lưu',
      'edit': 'Sửa',
      'delete': 'Xóa',
      'close': 'Đóng',
      'loading': 'Đang tải...',
      'error': 'Lỗi',
      'success': 'Thành công',
      'back': 'Quay lại',
      'next': 'Tiếp theo',
      'done': 'Hoàn thành',
      'yes': 'Có',
      'no': 'Không',
      'ok': 'OK',
    },
    'en': {
      // Profile Screen
      'profile': 'Profile',
      'personal_info': 'Personal Information',
      'notifications': 'Notifications',
      'chatbot_support': 'Chatbot Support',
      'settings': 'Settings',
      'logout': 'Logout',
      'welcome_cinema': 'Welcome to Cinema',
      'login_register_message': 'Login or register to view personal information and booking history',
      'login': 'LOGIN',
      'register': 'REGISTER',
      'movies_watched': 'Movies Watched',
      'total_spent': 'Total Spent',
      'points': 'Points',
      'redeem_voucher': 'Redeem Voucher',
      'get_voucher': 'Get Voucher',
      'booking_history': 'Booking History',
      'tickets': 'tickets',
      'no_booking_history': 'No booking history',
      'booking_history_subtitle': 'Your bookings will appear here',
      
      // Settings Screen
      'language': 'Language',
      'vietnamese': 'Tiếng Việt',
      'english': 'English',
      'theme': 'Theme',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'switched_to_vietnamese': 'Đã chuyển sang tiếng Việt',
      'switched_to_english': 'Switched to English',
      'switched_to_dark': 'Switched to dark mode',
      'switched_to_light': 'Switched to light mode',
      
      // Movie Detail Screen
      'book_ticket_now': 'BOOK NOW',
      'no_showtimes': 'NO SHOWTIMES',
      
      // Home Screen
      'now_showing': 'Now Showing',
      'coming_soon': 'Coming Soon',
      'popular': 'Popular',
      'search_placeholder': 'Search by movie name or genre...',
      'no_movies_found': 'No movies found',
      'try_different_search': 'Try a different search term',
      'select_cinema': 'Select Cinema',
      'all_cinemas': 'All Cinemas',
      
      // Login Screen
      'login_tab': 'Login',
      'register_tab': 'Register',
      'email': 'Email',
      'password': 'Password',
      'name': 'Full Name',
      'phone': 'Phone Number',
      'date_of_birth': 'Date of Birth',
      'select_date': 'Select Date',
      'login_with_google': 'Login with Google',
      'register_success': 'Registration successful. Please check your email.',
      'login_success': 'Login successful',
      'booking_easy': 'Easy movie ticket booking',
      
      // Showtimes Screen
      'select_showtime': 'Select Showtime',
      'no_showtimes_available': 'No showtimes available',
      'no_showtimes_for_date': 'No showtimes for this date',
      'today': 'Today',
      'tomorrow': 'Tomorrow',
      
      // Booking Screen
      'select_seats': 'Select Seats',
      'screen': 'SCREEN',
      'available': 'Available',
      'selected': 'Selected',
      'occupied': 'Occupied',
      'vip': 'VIP',
      'total': 'Total',
      'continue': 'Continue',
      'refresh': 'Refresh',
      
      // Payment Screen
      'payment': 'Payment',
      'payment_method': 'Payment Method',
      'order_summary': 'Order Summary',
      'tickets_count': 'Tickets',
      'snacks': 'Snacks',
      'subtotal': 'Subtotal',
      'discount': 'Discount',
      'total_price': 'Total',
      'pay_now': 'Pay Now',
      
      // Notification Screen
      'no_notifications': 'No notifications',
      'notifications_subtitle': 'New notifications will appear here',
      'unread_count': 'unread',
      
      // User Info Screen
      'edit_profile': 'Edit Profile',
      'full_name': 'Full Name',
      'phone_number': 'Phone Number',
      'email_address': 'Email Address',
      'date_of_birth_label': 'Date of Birth',
      'update_profile': 'Update Profile',
      'profile_updated': 'Profile updated successfully',
      
      // Admin Dashboard
      'admin_dashboard': 'Admin Dashboard',
      'create_movie': 'Create Movie',
      'create_showtime': 'Create Showtime',
      'create_theater': 'Create Theater',
      'create_cinema': 'Create Cinema',
      'create_voucher': 'Create Voucher',
      'edit_movie': 'Edit Movie',
      'manage_cinemas': 'Manage Cinemas',
      'manage_movies': 'Manage Movies',
      'manage_showtimes': 'Manage Showtimes',
      'manage_theaters': 'Manage Theaters',
      'manage_vouchers': 'Manage Vouchers',
      'manage_minigame': 'Manage Minigame',
      'create_snack': 'Create Snack',
      'movie_title': 'Movie Title',
      'movie_description': 'Description',
      'movie_genre': 'Genre',
      'movie_duration': 'Duration (minutes)',
      'trailer_url': 'Trailer URL',
      'age_rating': 'Age Rating',
      'poster_url': 'Poster URL',
      'select_cinema_label': 'Select Cinema',
      'create_for_all_cinemas': 'Create for all cinemas',
      'theater_name': 'Theater Name',
      'theater_capacity': 'Capacity',
      'theater_type': 'Theater Type',
      'cinema_name': 'Cinema Name',
      'cinema_address': 'Address',
      'voucher_code': 'Voucher Code',
      'voucher_discount': 'Discount (%)',
      'voucher_min_spend': 'Minimum Order Value',
      'voucher_expiry': 'Expiry Date',
      
      // Voucher Screens
      'get_voucher_title': 'Get Voucher',
      'get_voucher_subtitle': 'Choose how you want to get a voucher',
      'redeem_points_for_voucher': 'Redeem Points for Voucher',
      'redeem_points_description': 'Use accumulated points to redeem vouchers',
      'complete_tasks': 'Complete Tasks',
      'complete_tasks_description': 'Complete tasks to earn points or vouchers',
      'play_minigame': 'Play Minigame',
      'play_minigame_description': 'Play mini games to earn points or vouchers',
      'view_all_vouchers': 'View All Vouchers',
      'view_all_vouchers_description': 'View all available vouchers',
      'redeem_voucher': 'Redeem Voucher',
      'confirm_redeem_voucher': 'Confirm Redeem Voucher',
      'confirm_redeem_message': 'Are you sure you want to redeem voucher',
      'with_points': 'with',
      'points_label': 'points',
      'please_login': 'Please login',
      'no_vouchers_to_redeem': 'No vouchers available to redeem',
      'not_enough_points': 'Not enough points to redeem voucher. Need',
      'you_have': 'you have',
      'voucher_redeemed_success': 'Voucher redeemed successfully!',
      'change_game': 'Change Game',
      'reward': 'Reward',
      'congratulations': 'Congratulations! You received',
      'points_received': 'points!',
      
      // Chatbot Screen
      'chatbot_welcome': 'Hello! I am a chatbot that helps with movie ticket booking. I can help you:',
      'chatbot_find_movies': 'Find movies showing',
      'chatbot_showtimes': 'View showtimes',
      'chatbot_prices': 'Ask about ticket prices',
      'chatbot_faq': 'Answer frequently asked questions',
      'chatbot_how_can_i_help': 'How can I help you?',
      'chatbot_suggestion_now_showing': 'Movies showing',
      'chatbot_suggestion_coming_soon': 'Coming soon',
      'chatbot_suggestion_cinemas': 'Which cinema',
      'chatbot_suggestion_prices': 'Ticket prices',
      'chatbot_suggestion_how_to_book': 'How to book',
      'type_message': 'Type a message...',
      
      // Payment Success/Failure
      'payment_success': 'Payment Successful!',
      'payment_success_message': 'Your transaction has been processed successfully.',
      'transaction_id': 'Transaction ID:',
      'payment_failed': 'Payment Failed',
      'payment_cancelled': 'Payment Cancelled',
      'payment_cancelled_message': 'You have cancelled the payment transaction.',
      'payment_failed_message': 'Your transaction could not be processed. Please try again.',
      'payment_info_cancelled': 'Your tickets are still in your cart. You can try to pay again.',
      'payment_info_failed': 'Please check your payment information or try again later.',
      'back_to_home': 'Back to Home',
      
      // Snack Selection
      'select_snacks': 'Select Snacks',
      'skip': 'Skip',
      'continue_to_payment': 'Continue to Payment',
      'no_snacks_available': 'No snacks available',
      
      // Email Verification
      'email_verification': 'Email Verification',
      'verification_success': 'Verification successful! Entering app...',
      'verification_pending': 'Not verified yet. Please check your email.',
      'check_verification': 'Check Verification',
      'resend_email': 'Resend Email',
      'verification_sent': 'Verification email has been sent',
      'verification_info': 'Please check your email and click the link to verify your account.',
      
      // Cinema Selection
      'select_cinema_title': 'Select Cinema',
      'no_cinemas_available': 'No cinemas available',
      'error_loading_cinemas': 'Error loading cinemas list',
      
      // Voucher Tasks
      'voucher_tasks': 'Tasks',
      'reset_tasks': 'Reset Tasks',
      'reset_tasks_confirm': 'Are you sure you want to reset today\'s tasks? All progress will be deleted and new tasks will be selected.',
      'task_completed': 'Task Completed',
      'claim_reward': 'Claim Reward',
      'task_in_progress': 'In Progress',
      'task_claimed': 'Claimed',
      'task_not_completed': 'Not Completed',
      'task_complete': 'Complete',
      'progress': 'Progress',
      'available_tasks': 'Available Tasks',
      
      // All Vouchers
      'all_vouchers': 'All Vouchers',
      'no_vouchers': 'No vouchers',
      'unlocked': 'Unlocked',
      'locked': 'Locked',
      
      // Notification
      'notification_deleted': 'Notification deleted',
      'delete_notification': 'Delete notification',
      'mark_as_read': 'Mark as read',
      'mark_as_unread': 'Mark as unread',
      
      // Login/Register Messages
      'register_success_check_email': 'Registration successful. Please check your email.',
      'verification_link_expired': 'Verification link has expired (over 5 minutes). Account has been cancelled. Please register again.',
      'google_login_error': 'Google login error',
      'error_sending_email': 'Error sending email',
      'too_many_requests': 'Too many requests. Please wait a moment and try again.',
      'verification_link_sent_to': 'Verification link has been sent to:',
      'verification_link_expires': 'Verification link will expire after 5 minutes. If not verified in time, account will be cancelled.',
      'i_verified': 'I HAVE VERIFIED',
      'back_to_login': 'Back to login',
      'check_your_email': 'Check your email',
      
      // User Info Screen
      'error_loading_info': 'Error loading information',
      'phone_number_label': 'Phone Number',
      'role': 'Role',
      'admin_role': 'Administrator',
      'member_role': 'Member',
      'join_date': 'Join Date',
      
      // Booking Screen
      'seats_selected': 'seats selected',
      'error_loading_data': 'Error loading data',
      'error_cinema_not_found': 'Error: Cinema information not found',
      'error_updating': 'Error updating',
      
      // Admin Dashboard - Additional Messages
      'select_movie': 'Select Movie',
      'please_select_movie': 'Please select a movie',
      'showtime_will_be_created_for_all': 'Showtimes will be created for all theaters of all cinemas',
      'showtime_updated_success': '✅ Showtime updated successfully',
      'theater_updated_success': '✅ Theater updated successfully',
      'couple_seat_price': 'Couple Seat Price (₫)',
      'please_enter_couple_seat_price': 'Please enter couple seat price',
      'vip_bed_price': 'VIP Bed Price (₫)',
      'please_enter_vip_bed_price': 'Please enter VIP bed price',
      'price_must_be_greater_than_zero': 'Price must be greater than 0',
      'create_theater_for_all_cinemas': 'Create this theater for all cinemas at once',
      'please_select_cinema_or_all': 'Please select a cinema or choose to create for all cinemas',
      'please_select_release_date': 'Please select release date',
      'please_enter_movie_name': 'Please enter movie name',
      'please_enter_description': 'Please enter description',
      'please_enter_genre': 'Please enter genre',
      'duration_minutes': 'Duration (minutes)',
      'please_enter_duration': 'Please enter duration',
      'please_enter_valid_number': 'Please enter a valid number',
      'trailer_url': 'Trailer URL',
      'trailer_url_hint': 'https://youtube.com/watch?v=... or other video link',
      'please_enter_valid_url': 'Please enter a valid URL (starting with http:// or https://)',
      'age_rating': 'Age Rating (Optional)',
      'age_rating_hint': 'E.g: T13, T16, T18, P (General). Leave empty = All ages',
      'release_date_label': 'Release Date',
      'please_select_theater': 'Please select a theater',
      'please_select_date': 'Please select date',
      'please_select_time': 'Please select time',
      'create_showtime_for_all_cinemas': 'Create showtimes for all cinemas at once',
      'cinema_name_label': 'Cinema Name',
      'please_enter_cinema_name': 'Please enter cinema name',
      'address_label': 'Address',
      'please_enter_address': 'Please enter address',
      'cinema_image_url': 'Cinema Image URL',
      'cinema_image_url_hint': 'https://example.com/cinema.jpg',
      'latitude': 'Latitude',
      'latitude_hint': '10.762622',
      'longitude': 'Longitude',
      'longitude_hint': '106.660172',
      'create_cinema_button': 'CREATE CINEMA',
      'select_cinema_label': 'Select Cinema',
      'manage_snacks': 'Manage Snacks',
      'database_cleanup': 'Database Cleanup',
      'please_select_expiry_date': 'Please select expiry date',
      'points_voucher_need_valid_points': 'Points voucher needs valid points number',
      'task_voucher_need_task_id': 'Task voucher needs task ID',
      'please_select_cinema_label': 'Please select a cinema',
      
      // Admin Dashboard - Success Messages
      'cinema_created_success': '✅ Cinema created successfully!',
      'cinema_deleted_success': '✅ Cinema deleted',
      'cinema_updated_success': '✅ Cinema updated successfully!',
      'movie_created_success': '✅ Movie created successfully for {count} cinemas!',
      'movie_deleted_success': '✅ Movie deleted',
      'showtime_created_success': '✅ Showtime created successfully! ({count} showtimes)',
      'showtime_deleted_success': '✅ Showtime deleted',
      'theater_deleted_success': '✅ Theater deleted',
      'error_occurred': 'Error',
      
      // Admin Dashboard - Confirm Dialogs
      'confirm_delete': 'Confirm Delete',
      'confirm_delete_cinema': 'Are you sure you want to delete cinema "{name}"?\n\nThis action cannot be undone.',
      'confirm_delete_movie': 'Are you sure you want to delete movie "{name}"?\n\nThis action cannot be undone.',
      'confirm_delete_showtime': 'Are you sure you want to delete showtime "{name}"?\n\nTime: {time}\n\nThis action cannot be undone.',
      'confirm_delete_theater': 'Are you sure you want to delete theater "{name}"?\n\nThis action cannot be undone and will delete all related showtimes.',
      'action_cannot_undo': 'This action cannot be undone',
      
      // Admin Dashboard - Buttons
      'delete': 'Delete',
      'edit': 'Edit',
      
      // Admin Dashboard - Tooltips
      'edit_cinema': 'Edit cinema',
      'delete_cinema': 'Delete cinema',
      'edit_showtime': 'Edit showtime',
      'delete_showtime': 'Delete showtime',
      'edit_theater': 'Edit theater',
      'delete_theater': 'Delete theater',
      'edit_movie_tooltip': 'Edit movie',
      'delete_movie_tooltip': 'Delete movie',
      'edit_voucher_tooltip': 'Edit voucher',
      'delete_voucher_tooltip': 'Delete voucher',
      'edit_snack_tooltip': 'Edit',
      'delete_snack_tooltip': 'Delete',
      
      // Admin Dashboard - Dialog Titles
      'edit_showtime_title': 'Edit Showtime',
      'edit_theater_title': 'Edit Theater',
      
      // Admin Dashboard - Form Labels
      'cinema_name_label': 'Cinema Name *',
      'cinema_address_label': 'Address *',
      'cinema_phone_label': 'Phone Number',
      'cinema_image_url_label': 'Cinema Image URL',
      'cinema_latitude_label': 'Latitude',
      'cinema_longitude_label': 'Longitude',
      'please_enter_cinema_name': 'Please enter cinema name',
      'please_enter_cinema_address': 'Please enter address',
      
      // Admin Dashboard - Empty States
      'no_cinemas_yet': 'No cinemas yet',
      'create_cinema_in_tab': 'Please create a new cinema in the "Create Cinema" tab',
      'edit_cinema_title': 'Edit Cinema',
      
      // Admin Dashboard - Info Messages
      'create_for_all_cinemas_info': 'Create this movie for all cinemas at once',
      'create_showtime_for_all_info': 'Create showtime for all cinemas at once',
      'showtime_will_be_created_for_all': 'Showtimes will be created for all theaters of all cinemas',
      'create_theater_for_all_info': 'Create this theater for all cinemas at once',
      
      // Admin Dashboard - Validators
      'please_enter_poster_url': 'Please enter poster image URL',
      'please_enter_valid_url': 'Please enter a valid URL (starting with http:// or https://)',
      'please_enter_theater_name': 'Please enter theater name',
      'please_select_voucher_type': 'Please select voucher type',
      'system_error': 'System error',
      'invalid_value': 'Invalid value',
      'please_select_movie': 'Please select a movie',
      'please_select_cinema': 'Please select a cinema',
      
      // Admin Dashboard - Messages
      'cannot_load_image': 'Cannot load image',
      'no_movies_in_system': 'No movies in the system. Please create a movie first.',
      'cinema_no_movies': 'This cinema has no movies. Please create movies for this cinema first.',
      'cinema_no_theaters': 'This cinema has no theaters. Please create theaters for this cinema first.',
      'not_available': 'N/A',
      'delete_showtime_tooltip': 'Delete showtime',
      'theater_name_label': 'Theater Name',
      'select_theater_label': 'Select Theater',
      'showtime': 'showtime',
      'showtime_date': 'Show Date',
      'showtime_time': 'Show Time',
      'showtime_date_time': 'Date and Time',
      'rows_label': 'Number of Rows',
      'seats_per_row_label': 'Seats Per Row',
      'single_seat_price': 'Single Seat Price (₫)',
      'please_enter_rows': 'Please enter number of rows',
      'please_enter_seats_per_row': 'Please enter seats per row',
      'please_enter_single_seat_price': 'Please enter single seat price',
      'rows_must_be_positive': 'Number of rows must be positive',
      'seats_per_row_must_be_positive': 'Seats per row must be positive',
      'random_time': 'Random time',
      'random_time_description': 'Automatically create random times from 7 AM to 11 PM (only applies when creating for all cinemas)',
      'theater_type': 'Theater type',
      'theater_type_normal': 'Normal',
      'theater_type_couple': 'Couple',
      'theater_type_vip': 'VIP',
      'theater_type_label': 'Theater Type',
      'seats_per_row_auto': 'Seats per row: {count} (auto)',
      'poster_url_label': 'Poster Image URL',
      'select_release_date': 'Select release date',
      'genre_label': 'Genre',
      'discount_type_label': 'Discount Type',
      'available_seats': 'Available seats: {available}/{total}',
      
      // Payment Screen
      'please_select_voucher': 'Please select a voucher or enter voucher code',
      'voucher_expired': 'Voucher has expired!',
      'voucher_inactive': 'Voucher is no longer active!',
      'voucher_applied_success': 'Voucher applied successfully!',
      'error_creating_temp_booking': 'Error creating temporary booking',
      'smtp_not_configured': 'SMTP not configured. Please check .env file',
      'email_cannot_send': 'Confirmation email cannot be sent. Please check SMTP configuration.',
      
      // Common
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'save': 'Save',
      'edit': 'Edit',
      'delete': 'Delete',
      'close': 'Close',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'back': 'Back',
      'next': 'Next',
      'done': 'Done',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Getters for common translations
  String get profile => translate('profile');
  String get personalInfo => translate('personal_info');
  String get notifications => translate('notifications');
  String get chatbotSupport => translate('chatbot_support');
  String get settings => translate('settings');
  String get logout => translate('logout');
  String get welcomeCinema => translate('welcome_cinema');
  String get loginRegisterMessage => translate('login_register_message');
  String get login => translate('login');
  String get register => translate('register');
  String get moviesWatched => translate('movies_watched');
  String get totalSpent => translate('total_spent');
  String get points => translate('points');
  String get redeemVoucher => translate('redeem_voucher');
  String get getVoucher => translate('get_voucher');
  String get bookingHistory => translate('booking_history');
  String get tickets => translate('tickets');
  String get noBookingHistory => translate('no_booking_history');
  String get bookingHistorySubtitle => translate('booking_history_subtitle');
  String get language => translate('language');
  String get vietnamese => translate('vietnamese');
  String get english => translate('english');
  String get theme => translate('theme');
  String get darkMode => translate('dark_mode');
  String get lightMode => translate('light_mode');
  String get switchedToVietnamese => translate('switched_to_vietnamese');
  String get switchedToEnglish => translate('switched_to_english');
  String get switchedToDark => translate('switched_to_dark');
  String get switchedToLight => translate('switched_to_light');
  String get bookTicketNow => translate('book_ticket_now');
  String get noShowtimes => translate('no_showtimes');
  
  // Home Screen
  String get nowShowing => translate('now_showing');
  String get comingSoon => translate('coming_soon');
  String get popular => translate('popular');
  String get searchPlaceholder => translate('search_placeholder');
  String get noMoviesFound => translate('no_movies_found');
  String get tryDifferentSearch => translate('try_different_search');
  String get selectCinema => translate('select_cinema');
  String get allCinemas => translate('all_cinemas');
  
  // Login Screen
  String get loginTab => translate('login_tab');
  String get registerTab => translate('register_tab');
  String get email => translate('email');
  String get password => translate('password');
  String get name => translate('name');
  String get phone => translate('phone');
  String get dateOfBirth => translate('date_of_birth');
  String get selectDate => translate('select_date');
  String get loginWithGoogle => translate('login_with_google');
  String get registerSuccess => translate('register_success');
  String get loginSuccess => translate('login_success');
  String get bookingEasy => translate('booking_easy');
  
  // Showtimes Screen
  String get selectShowtime => translate('select_showtime');
  String get noShowtimesAvailable => translate('no_showtimes_available');
  String get noShowtimesForDate => translate('no_showtimes_for_date');
  String get today => translate('today');
  String get tomorrow => translate('tomorrow');
  
  // Booking Screen
  String get selectSeats => translate('select_seats');
  String get screen => translate('screen');
  String get available => translate('available');
  String get selected => translate('selected');
  String get occupied => translate('occupied');
  String get vip => translate('vip');
  String get total => translate('total');
  String get continueText => translate('continue');
  String get refresh => translate('refresh');
  
  // Payment Screen
  String get payment => translate('payment');
  String get paymentMethod => translate('payment_method');
  String get orderSummary => translate('order_summary');
  String get ticketsCount => translate('tickets_count');
  String get snacks => translate('snacks');
  String get subtotal => translate('subtotal');
  String get discount => translate('discount');
  String get totalPrice => translate('total_price');
  String get payNow => translate('pay_now');
  
  // Notification Screen
  String get noNotifications => translate('no_notifications');
  String get notificationsSubtitle => translate('notifications_subtitle');
  String get unreadCount => translate('unread_count');
  
  // User Info Screen
  String get editProfile => translate('edit_profile');
  String get fullName => translate('full_name');
  String get phoneNumber => translate('phone_number');
  String get emailAddress => translate('email_address');
  String get dateOfBirthLabel => translate('date_of_birth_label');
  String get updateProfile => translate('update_profile');
  String get profileUpdated => translate('profile_updated');
  
  // Admin Dashboard
  String get adminDashboard => translate('admin_dashboard');
  String get createMovie => translate('create_movie');
  String get createShowtime => translate('create_showtime');
  String get createTheater => translate('create_theater');
  String get createCinema => translate('create_cinema');
  String get createVoucher => translate('create_voucher');
  String get editMovie => translate('edit_movie');
  String get manageCinemas => translate('manage_cinemas');
  String get manageMovies => translate('manage_movies');
  String get manageShowtimes => translate('manage_showtimes');
  String get manageTheaters => translate('manage_theaters');
  String get manageVouchers => translate('manage_vouchers');
  String get manageMinigame => translate('manage_minigame');
  String get createSnack => translate('create_snack');
  String get manageSnacks => translate('manage_snacks');
  String get databaseCleanup => translate('database_cleanup');
  String get movieTitle => translate('movie_title');
  String get movieDescription => translate('movie_description');
  String get movieGenre => translate('movie_genre');
  String get movieDuration => translate('movie_duration');
  String get trailerUrl => translate('trailer_url');
  String get ageRating => translate('age_rating');
  String get posterUrl => translate('poster_url');
  String get selectCinemaLabel => translate('select_cinema_label');
  String get createForAllCinemas => translate('create_for_all_cinemas');
  String get theaterName => translate('theater_name');
  String get theaterCapacity => translate('theater_capacity');
  String get theaterType => translate('theater_type');
  String get cinemaName => translate('cinema_name');
  String get cinemaAddress => translate('cinema_address');
  String get voucherCode => translate('voucher_code');
  String get voucherDiscount => translate('voucher_discount');
  String get voucherMinSpend => translate('voucher_min_spend');
  String get voucherExpiry => translate('voucher_expiry');
  
  // Voucher Screens
  String get getVoucherTitle => translate('get_voucher_title');
  String get getVoucherSubtitle => translate('get_voucher_subtitle');
  String get redeemPointsForVoucher => translate('redeem_points_for_voucher');
  String get redeemPointsDescription => translate('redeem_points_description');
  String get completeTasks => translate('complete_tasks');
  String get completeTasksDescription => translate('complete_tasks_description');
  String get playMinigame => translate('play_minigame');
  String get playMinigameDescription => translate('play_minigame_description');
  String get viewAllVouchers => translate('view_all_vouchers');
  String get viewAllVouchersDescription => translate('view_all_vouchers_description');
  String get confirmRedeemVoucher => translate('confirm_redeem_voucher');
  String get confirmRedeemMessage => translate('confirm_redeem_message');
  String get withPoints => translate('with_points');
  String get pointsLabel => translate('points_label');
  String get pleaseLogin => translate('please_login');
  String get noVouchersToRedeem => translate('no_vouchers_to_redeem');
  String get notEnoughPoints => translate('not_enough_points');
  String get youHave => translate('you_have');
  String get voucherRedeemedSuccess => translate('voucher_redeemed_success');
  String get changeGame => translate('change_game');
  String get reward => translate('reward');
  String get congratulations => translate('congratulations');
  String get pointsReceived => translate('points_received');
  
  // Chatbot Screen
  String get chatbotWelcome => translate('chatbot_welcome');
  String get chatbotFindMovies => translate('chatbot_find_movies');
  String get chatbotShowtimes => translate('chatbot_showtimes');
  String get chatbotPrices => translate('chatbot_prices');
  String get chatbotFaq => translate('chatbot_faq');
  String get chatbotHowCanIHelp => translate('chatbot_how_can_i_help');
  String get chatbotSuggestionNowShowing => translate('chatbot_suggestion_now_showing');
  String get chatbotSuggestionComingSoon => translate('chatbot_suggestion_coming_soon');
  String get chatbotSuggestionCinemas => translate('chatbot_suggestion_cinemas');
  String get chatbotSuggestionPrices => translate('chatbot_suggestion_prices');
  String get chatbotSuggestionHowToBook => translate('chatbot_suggestion_how_to_book');
  String get typeMessage => translate('type_message');
  
  // Payment Success/Failure
  String get paymentSuccess => translate('payment_success');
  String get paymentSuccessMessage => translate('payment_success_message');
  String get transactionId => translate('transaction_id');
  String get paymentFailed => translate('payment_failed');
  String get paymentCancelled => translate('payment_cancelled');
  String get paymentCancelledMessage => translate('payment_cancelled_message');
  String get paymentFailedMessage => translate('payment_failed_message');
  String get paymentInfoCancelled => translate('payment_info_cancelled');
  String get paymentInfoFailed => translate('payment_info_failed');
  String get backToHome => translate('back_to_home');
  
  // Snack Selection
  String get selectSnacks => translate('select_snacks');
  String get skip => translate('skip');
  String get continueToPayment => translate('continue_to_payment');
  String get noSnacksAvailable => translate('no_snacks_available');
  
  // Email Verification
  String get emailVerification => translate('email_verification');
  String get verificationSuccess => translate('verification_success');
  String get verificationPending => translate('verification_pending');
  String get checkVerification => translate('check_verification');
  String get resendEmail => translate('resend_email');
  String get verificationSent => translate('verification_sent');
  String get verificationInfo => translate('verification_info');
  
  // Cinema Selection
  String get selectCinemaTitle => translate('select_cinema_title');
  String get noCinemasAvailable => translate('no_cinemas_available');
  String get errorLoadingCinemas => translate('error_loading_cinemas');
  
  // Voucher Tasks
  String get voucherTasks => translate('voucher_tasks');
  String get resetTasks => translate('reset_tasks');
  String get resetTasksConfirm => translate('reset_tasks_confirm');
  String get taskCompleted => translate('task_completed');
  String get claimReward => translate('claim_reward');
  String get taskInProgress => translate('task_in_progress');
  String get taskClaimed => translate('task_claimed');
  String get taskNotCompleted => translate('task_not_completed');
  String get taskComplete => translate('task_complete');
  String get progress => translate('progress');
  String get availableTasks => translate('available_tasks');
  
  // All Vouchers
  String get allVouchers => translate('all_vouchers');
  String get noVouchers => translate('no_vouchers');
  String get unlocked => translate('unlocked');
  String get locked => translate('locked');
  
  // Notification
  String get notificationDeleted => translate('notification_deleted');
  String get deleteNotification => translate('delete_notification');
  String get markAsRead => translate('mark_as_read');
  String get markAsUnread => translate('mark_as_unread');
  
  // Login/Register Messages
  String get registerSuccessCheckEmail => translate('register_success_check_email');
  String get verificationLinkExpired => translate('verification_link_expired');
  String get googleLoginError => translate('google_login_error');
  String get errorSendingEmail => translate('error_sending_email');
  String get tooManyRequests => translate('too_many_requests');
  String get verificationLinkSentTo => translate('verification_link_sent_to');
  String get verificationLinkExpires => translate('verification_link_expires');
  String get iVerified => translate('i_verified');
  String get backToLogin => translate('back_to_login');
  String get checkYourEmail => translate('check_your_email');
  
  // User Info Screen
  String get errorLoadingInfo => translate('error_loading_info');
  String get phoneNumberLabel => translate('phone_number_label');
  String get roleLabel => translate('role');
  String get adminRole => translate('admin_role');
  String get memberRole => translate('member_role');
  String get joinDate => translate('join_date');
  
  // Booking Screen
  String get seatsSelected => translate('seats_selected');
  String get errorLoadingData => translate('error_loading_data');
  String get errorCinemaNotFound => translate('error_cinema_not_found');
  String get errorUpdating => translate('error_updating');
  
  // Admin Dashboard - Additional Messages
  String get selectMovie => translate('select_movie');
  String get pleaseSelectMovie => translate('please_select_movie');
  String get showtimeWillBeCreatedForAll => translate('showtime_will_be_created_for_all');
  String get showtimeUpdatedSuccess => translate('showtime_updated_success');
  String get theaterUpdatedSuccess => translate('theater_updated_success');
  String get coupleSeatPrice => translate('couple_seat_price');
  String get pleaseEnterCoupleSeatPrice => translate('please_enter_couple_seat_price');
  String get vipBedPrice => translate('vip_bed_price');
  String get pleaseEnterVipBedPrice => translate('please_enter_vip_bed_price');
  String get priceMustBeGreaterThanZero => translate('price_must_be_greater_than_zero');
  String get createTheaterForAllCinemas => translate('create_theater_for_all_cinemas');
  String get pleaseSelectCinemaOrAll => translate('please_select_cinema_or_all');
  String get pleaseSelectReleaseDate => translate('please_select_release_date');
  String get pleaseEnterMovieName => translate('please_enter_movie_name');
  String get pleaseEnterDescription => translate('please_enter_description');
  String get pleaseEnterGenre => translate('please_enter_genre');
  String get durationMinutes => translate('duration_minutes');
  String get pleaseEnterDuration => translate('please_enter_duration');
  String get pleaseEnterValidNumber => translate('please_enter_valid_number');
  String get trailerUrlHint => translate('trailer_url_hint');
  String get pleaseEnterValidUrl => translate('please_enter_valid_url');
  String movieCreatedSuccess(int count) => translate('movie_created_success').replaceAll('{count}', count.toString());
  String showtimeCreatedSuccess(int count) => translate('showtime_created_success').replaceAll('{count}', count.toString());
  String theaterCreatedSuccessForCinemas(int count) => translate('theater_created_success_for_cinemas').replaceAll('{count}', count.toString());
  String theaterCreatedPartial(int success, int fail) => translate('theater_created_partial').replaceAll('{success}', success.toString()).replaceAll('{fail}', fail.toString());
  String voucherCreatedSuccess(String type) => translate('voucher_created_success').replaceAll('{type}', type);
  String get voucherTypeFree => translate('voucher_type_free');
  String get voucherTypeTask => translate('voucher_type_task');
  String get voucherTypePoints => translate('voucher_type_points');
  String get confirmDeleteVoucher => translate('confirm_delete_voucher');
  String confirmDeleteVoucherMessage(String id) => translate('confirm_delete_voucher_message').replaceAll('{id}', id);
  String get movieUpdatedSuccess => translate('movie_updated_success');
  String get theaterNotFound => translate('theater_not_found');
  String get rowsAndSeatsMustBeGreaterThanZero => translate('rows_and_seats_must_be_greater_than_zero');
  String get ageRatingHint => translate('age_rating_hint');
  String get releaseDateLabel => translate('release_date_label');
  String get pleaseSelectTheater => translate('please_select_theater');
  String get pleaseSelectDate => translate('please_select_date');
  String get pleaseSelectTime => translate('please_select_time');
  String get createShowtimeForAllCinemas => translate('create_showtime_for_all_cinemas');
  String get pleaseSelectCinemaLabel => translate('please_select_cinema_label');
  String get pleaseSelectExpiryDate => translate('please_select_expiry_date');
  String get pointsVoucherNeedValidPoints => translate('points_voucher_need_valid_points');
  String get taskVoucherNeedTaskId => translate('task_voucher_need_task_id');
  
  // Payment Screen
  String get pleaseSelectVoucher => translate('please_select_voucher');
  String get voucherExpired => translate('voucher_expired');
  String get voucherInactive => translate('voucher_inactive');
  String get voucherAppliedSuccess => translate('voucher_applied_success');
  String get errorCreatingTempBooking => translate('error_creating_temp_booking');
  String get smtpNotConfigured => translate('smtp_not_configured');
  String get emailCannotSend => translate('email_cannot_send');
  String get emailCannotSendTitle => translate('email_cannot_send_title');
  
  // Admin Dashboard - Validators
  String get pleaseEnterPosterUrl => translate('please_enter_poster_url');
  String get pleaseEnterTheaterName => translate('please_enter_theater_name');
  String get pleaseSelectVoucherType => translate('please_select_voucher_type');
  String get systemError => translate('system_error');
  String get invalidValue => translate('invalid_value');
  String get pleaseSelectCinema => translate('please_select_cinema');
  
  // Admin Dashboard - Messages
  String get cannotLoadImage => translate('cannot_load_image');
  String get noMoviesInSystem => translate('no_movies_in_system');
  String get cinemaNoMovies => translate('cinema_no_movies');
  String get cinemaNoTheaters => translate('cinema_no_theaters');
  String get notAvailable => translate('not_available');
  String get deleteShowtimeTooltip => translate('delete_showtime_tooltip');
  String get cinemaCreatedSuccess => translate('cinema_created_success');
  String get errorOccurred => translate('error_occurred');
  String get cinemaNameLabel => translate('cinema_name_label');
  String get pleaseEnterCinemaName => translate('please_enter_cinema_name');
  String get addressLabel => translate('address_label');
  String get pleaseEnterAddress => translate('please_enter_address');
  String get cinemaImageUrl => translate('cinema_image_url');
  String get cinemaImageUrlHint => translate('cinema_image_url_hint');
  String get latitude => translate('latitude');
  String get latitudeHint => translate('latitude_hint');
  String get longitude => translate('longitude');
  String get longitudeHint => translate('longitude_hint');
  String get createCinemaButton => translate('create_cinema_button');
  String get noCinemasYet => translate('no_cinemas_yet');
  String get createCinemaInTab => translate('create_cinema_in_tab');
  String get editCinema => translate('edit_cinema');
  String get deleteCinema => translate('delete_cinema');
  String get confirmDelete => translate('confirm_delete');
  String get cinemaDeletedSuccess => translate('cinema_deleted_success');
  String get editCinemaTitle => translate('edit_cinema_title');
  String get cinemaAddressLabel => translate('cinema_address_label');
  String get pleaseEnterCinemaAddress => translate('please_enter_cinema_address');
  String get cinemaPhoneLabel => translate('cinema_phone_label');
  String get cinemaImageUrlLabel => translate('cinema_image_url_label');
  String get cinemaLatitudeLabel => translate('cinema_latitude_label');
  String get cinemaLongitudeLabel => translate('cinema_longitude_label');
  String get cinemaUpdatedSuccess => translate('cinema_updated_success');
  String get createForAllCinemasInfo => translate('create_for_all_cinemas_info');
  String get showtimeDeletedSuccess => translate('showtime_deleted_success');
  String get theaterDeletedSuccess => translate('theater_deleted_success');
  String get movieDeletedSuccess => translate('movie_deleted_success');
  String get genre => translate('genre_label');
  String get showtime => translate('showtime');
  String get theaterNameLabel => translate('theater_name_label');
  String get editShowtime => translate('edit_showtime');
  String get deleteShowtime => translate('delete_showtime');
  String get editTheater => translate('edit_theater');
  String get deleteTheater => translate('delete_theater');
  String get editMovieTooltip => translate('edit_movie_tooltip');
  String get deleteMovieTooltip => translate('delete_movie_tooltip');
  String get editVoucherTooltip => translate('edit_voucher_tooltip');
  String get deleteVoucherTooltip => translate('delete_voucher_tooltip');
  String get editSnackTooltip => translate('edit_snack_tooltip');
  String get deleteSnackTooltip => translate('delete_snack_tooltip');
  String get editShowtimeTitle => translate('edit_showtime_title');
  String get editTheaterTitle => translate('edit_theater_title');
  String get selectTheaterLabel => translate('select_theater_label');
  String get showtimeDate => translate('showtime_date');
  String get showtimeTime => translate('showtime_time');
  String get showtimeDateTime => translate('showtime_date_time');
  String get rowsLabel => translate('rows_label');
  String get seatsPerRowLabel => translate('seats_per_row_label');
  String get singleSeatPrice => translate('single_seat_price');
  String get pleaseEnterRows => translate('please_enter_rows');
  String get pleaseEnterSeatsPerRow => translate('please_enter_seats_per_row');
  String get pleaseEnterSingleSeatPrice => translate('please_enter_single_seat_price');
  String get rowsMustBePositive => translate('rows_must_be_positive');
  String get seatsPerRowMustBePositive => translate('seats_per_row_must_be_positive');
  String get randomTime => translate('random_time');
  String get randomTimeDescription => translate('random_time_description');
  String get theaterTypeNormal => translate('theater_type_normal');
  String get theaterTypeCouple => translate('theater_type_couple');
  String get theaterTypeVip => translate('theater_type_vip');
  String get theaterTypeLabel => translate('theater_type_label');
  String seatsPerRowAuto(int count) => translate('seats_per_row_auto').replaceAll('{count}', count.toString());
  String get posterUrlLabel => translate('poster_url_label');
  String get selectReleaseDate => translate('select_release_date');
  String get genreLabel => translate('genre_label');
  String get discountTypeLabel => translate('discount_type_label');
  String availableSeats(int available, int total) => translate('available_seats').replaceAll('{available}', available.toString()).replaceAll('{total}', total.toString());
  String confirmDeleteShowtime(String name, String time) => translate('confirm_delete_showtime').replaceAll('{name}', name).replaceAll('{time}', time);
  String confirmDeleteCinema(String name) => translate('confirm_delete_cinema').replaceAll('{name}', name);
  String confirmDeleteMovie(String name) => translate('confirm_delete_movie').replaceAll('{name}', name);
  String confirmDeleteTheater(String name) => translate('confirm_delete_theater').replaceAll('{name}', name);
  
  // Common
  String get confirm => translate('confirm');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get edit => translate('edit');
  String get delete => translate('delete');
  String get close => translate('close');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get back => translate('back');
  String get next => translate('next');
  String get done => translate('done');
  String get yes => translate('yes');
  String get no => translate('no');
  String get ok => translate('ok');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['vi', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
