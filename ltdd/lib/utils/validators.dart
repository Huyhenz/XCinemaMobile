// File: lib/utils/validators.dart
// Validators cho các input fields

class Validators {
  // Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    }
    
    // Email regex pattern
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }
    
    return null;
  }

  // Validate phone number (Vietnam format)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    
    // Remove spaces and special characters
    String cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if starts with +84 and remove it, or check if starts with 0
    if (cleanPhone.startsWith('+84')) {
      cleanPhone = '0' + cleanPhone.substring(3);
    }
    
    // Vietnam phone number: 10 digits starting with 0
    final phoneRegex = RegExp(r'^0[0-9]{9}$');
    
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Số điện thoại phải có 10 chữ số và bắt đầu bằng 0';
    }
    
    return null;
  }

  // Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    
    return null;
  }

  // Validate name
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ tên';
    }
    
    if (value.trim().length < 2) {
      return 'Họ tên phải có ít nhất 2 ký tự';
    }
    
    return null;
  }

  // Validate date of birth (must be at least 13 years old)
  static String? validateDateOfBirth(DateTime? date) {
    if (date == null) {
      return 'Vui lòng chọn ngày tháng năm sinh';
    }
    
    final now = DateTime.now();
    final age = now.year - date.year - (now.month > date.month || (now.month == date.month && now.day >= date.day) ? 0 : 1);
    
    if (age < 13) {
      return 'Bạn phải đủ 13 tuổi trở lên';
    }
    
    if (date.isAfter(now)) {
      return 'Ngày sinh không thể là ngày tương lai';
    }
    
    // Check if too old (more than 150 years)
    if (age > 150) {
      return 'Ngày sinh không hợp lệ';
    }
    
    return null;
  }

  // Format phone number for display (adds spaces)
  static String formatPhoneNumber(String phone) {
    // Remove all non-digits
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // If starts with +84, convert to 0
    if (digits.startsWith('84') && digits.length == 11) {
      digits = '0' + digits.substring(2);
    }
    
    // Format: 0xxx xxx xxx
    if (digits.length == 10 && digits.startsWith('0')) {
      return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
    }
    
    return phone; // Return original if can't format
  }
}

