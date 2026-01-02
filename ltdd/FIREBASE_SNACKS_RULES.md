# Firebase Rules cho Snacks (Bắp Nước)

## Lỗi Permission Denied khi tạo Snack

Nếu bạn gặp lỗi "Permission denied" khi tạo bắp nước, cần cập nhật Firebase Realtime Database Rules.

## ⚠️ QUAN TRỌNG: Copy toàn bộ rules này vào Firebase Console

Rules này đã bao gồm **TẤT CẢ** các node cần thiết cho ứng dụng, đặc biệt là **snacks** để tạo bắp nước.

## Rules cần thêm

Thêm node `snacks` vào Firebase Realtime Database Rules:

```json
{
  "rules": {
    // ... các rules khác ...
    
    "snacks": {
      ".read": true,
      ".write": "auth != null"
    },
    
    // ... các rules khác ...
  }
}
```

## Rules đầy đủ (đã bao gồm snacks)

```json
{
  "rules": {
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

## Cách cập nhật

1. Vào Firebase Console: https://console.firebase.google.com
2. Chọn project của bạn
3. Vào **Realtime Database** > **Rules**
4. Copy toàn bộ rules ở trên và paste vào
5. Click **Publish**

## Giải thích

- **`"snacks": { ".read": true, ".write": "auth != null" }`**:
  - `.read: true`: Cho phép tất cả người dùng (kể cả chưa đăng nhập) đọc danh sách snacks
  - `.write: "auth != null"`: Chỉ người đã đăng nhập mới được tạo/sửa/xóa snacks

## Lưu ý

- Đảm bảo bạn đã đăng nhập với tài khoản admin khi tạo snack
- Nếu vẫn gặp lỗi, kiểm tra lại role của user trong database (phải có role = 'admin')

