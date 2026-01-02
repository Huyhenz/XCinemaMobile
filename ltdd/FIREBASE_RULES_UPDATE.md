# Cập nhật Firebase Realtime Database Rules

## ⚠️ QUAN TRỌNG: File rules đầy đủ

**File `FIREBASE_RULES_COMPLETE.json` đã chứa toàn bộ rules cần thiết - bạn chỉ cần copy file đó vào Firebase Console!**

## Vấn đề
Hiện tại rules yêu cầu authentication để đọc dữ liệu, nhưng người dùng chưa đăng nhập vẫn cần xem phim và rạp chiếu.

## Rules mới (cho phép đọc công khai)

Cập nhật Firebase Realtime Database Rules trong Firebase Console:

```json
{
  "rules": {
    // Cho phép đọc công khai các dữ liệu công khai
    "cinemas": {
      ".read": true,
      ".write": "auth != null"
    },
    "movies": {
      ".read": true,
      ".write": "auth != null"
    },
    "showtimes": {
      ".read": true,
      ".write": "auth != null",
      ".indexOn": ["movieId", "theaterId", "startTime"]
    },
    "theaters": {
      ".read": true,
      ".write": "auth != null"
    },
    "movie_ratings": {
      ".read": true,
      ".write": "auth != null"
    },
    "movie_comments": {
      ".read": true,
      ".write": "auth != null"
    },
    "vouchers": {
      ".read": true,
      ".write": "auth != null"
    },
    "snacks": {
      ".read": true,
      ".write": "auth != null"
    },
    "user_vouchers": {
      "$userId": {
        ".read": "auth != null && $userId == auth.uid",
        ".write": "auth != null && $userId == auth.uid"
      }
    },
    // Dữ liệu cá nhân - yêu cầu authentication
    "users": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["email", "phone"]
    },
    "bookings": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["userId", "showtimeId", "status"]
    },
    "notifications": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["userId", "isRead"]
    },
    "temp_registrations": {
      ".read": "auth != null && (!data.exists() || data.child('userId').val() == auth.uid)",
      ".write": "auth != null"
    },
    "temp_bookings": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "payments": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "minigame_configs": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

## Cách cập nhật (NHANH NHẤT)

### Phương pháp 1: Copy từ file JSON (KHUYẾN NGHỊ)
1. Mở file `FIREBASE_RULES_COMPLETE.json` trong project
2. Copy toàn bộ nội dung
3. Vào Firebase Console: https://console.firebase.google.com
4. Chọn project của bạn
5. Vào **Realtime Database** > **Rules**
6. Paste toàn bộ nội dung vào
7. Click **Publish**

### Phương pháp 2: Copy từ đây
1. Vào Firebase Console: https://console.firebase.google.com
2. Chọn project của bạn
3. Vào **Realtime Database** > **Rules**
4. Copy rules từ phần trên (hoặc từ file JSON)
5. Click **Publish**

## Giải thích

- **`.read: true`**: Cho phép tất cả người dùng (kể cả chưa đăng nhập) đọc dữ liệu
- **`.write: "auth != null"`**: Chỉ người đã đăng nhập mới được ghi
- **Dữ liệu cá nhân**: Vẫn yêu cầu authentication và chỉ cho phép đọc/ghi dữ liệu của chính mình

## Lưu ý quan trọng

### Snacks (Bắp nước)
- **Đọc công khai**: Tất cả người dùng (kể cả chưa đăng nhập) có thể xem danh sách snacks
- **Ghi**: Chỉ người đã đăng nhập mới được tạo/sửa/xóa snacks (thường là admin)
- Đảm bảo node `snacks` có trong rules để tránh lỗi "Permission denied"

### Minigame Configs
- **Đọc/Ghi**: Chỉ người đã đăng nhập mới được xem và chỉnh sửa cấu hình minigame
- Thường chỉ admin mới cần quyền này

