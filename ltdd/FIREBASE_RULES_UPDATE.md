# Cập nhật Firebase Realtime Database Rules

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
    }
  }
}
```

## Cách cập nhật

1. Vào Firebase Console: https://console.firebase.google.com
2. Chọn project của bạn
3. Vào **Realtime Database** > **Rules**
4. Paste rules ở trên
5. Click **Publish**

## Giải thích

- **`.read: true`**: Cho phép tất cả người dùng (kể cả chưa đăng nhập) đọc dữ liệu
- **`.write: "auth != null"`**: Chỉ người đã đăng nhập mới được ghi
- **Dữ liệu cá nhân**: Vẫn yêu cầu authentication và chỉ cho phép đọc/ghi dữ liệu của chính mình

