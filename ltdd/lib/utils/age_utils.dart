// File: lib/utils/age_utils.dart
// Utility functions for age calculation and age rating parsing

class AgeUtils {
  /// Tính tuổi từ ngày sinh (dateOfBirth timestamp in milliseconds)
  /// Returns null nếu dateOfBirth là null
  static int? calculateAge(int? dateOfBirthTimestamp) {
    if (dateOfBirthTimestamp == null) return null;
    
    final birthDate = DateTime.fromMillisecondsSinceEpoch(dateOfBirthTimestamp);
    final now = DateTime.now();
    
    int age = now.year - birthDate.year;
    
    // Kiểm tra xem đã qua sinh nhật trong năm nay chưa
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  /// Parse độ tuổi xem từ ageRating string
  /// Ví dụ: "T13" -> 13, "T16" -> 16, "T18" -> 18, "P" -> 0 (Phổ thông), null -> null
  /// Returns null nếu ageRating là null hoặc empty
  /// Returns 0 nếu là "P" (Phổ thông - tất cả độ tuổi)
  static int? parseAgeRating(String? ageRating) {
    if (ageRating == null || ageRating.isEmpty) return null;
    
    final trimmed = ageRating.trim().toUpperCase();
    
    // Nếu là "P" (Phổ thông) thì return 0 (cho phép tất cả độ tuổi)
    if (trimmed == 'P') return 0;
    
    // Parse "T13", "T16", "T18", etc.
    if (trimmed.startsWith('T')) {
      final ageStr = trimmed.substring(1);
      final age = int.tryParse(ageStr);
      return age;
    }
    
    // Nếu không match format nào, thử parse trực tiếp số
    return int.tryParse(trimmed);
  }

  /// Kiểm tra xem user có đủ tuổi để xem phim không
  /// Returns true nếu đủ tuổi hoặc không có age restriction
  /// Returns false nếu không đủ tuổi
  static bool isAgeEligible(int? userAge, String? movieAgeRating) {
    // Nếu không có age rating hoặc là "P" (Phổ thông), cho phép tất cả
    final requiredAge = parseAgeRating(movieAgeRating);
    if (requiredAge == null || requiredAge == 0) return true;
    
    // Nếu không có thông tin tuổi của user, không cho phép (cần có ngày sinh)
    if (userAge == null) return false;
    
    // Kiểm tra tuổi
    return userAge >= requiredAge;
  }
}


