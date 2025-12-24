# Firebase Realtime Database Rules

## Vấn đề hiện tại
Lỗi "type 'String' is not a subtype of type 'Map<dynamic, dynamic>'" xảy ra khi query Firebase Database. Điều này có thể do:
1. Firebase Database rules không hỗ trợ query đúng cách
2. Cấu trúc dữ liệu trong database không đúng
3. Thiếu index cho query

## Rules được đề xuất

Cập nhật Firebase Realtime Database Rules trong Firebase Console:

```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null",
    "showtimes": {
      ".indexOn": ["movieId", "theaterId", "startTime"]
    },
    "bookings": {
      ".indexOn": ["userId", "showtimeId", "status"]
    },
    "notifications": {
      ".indexOn": ["userId", "isRead"]
    },
    "users": {
      ".indexOn": ["email", "phone"]
    }
  }
}
```

## Giải thích

1. **`.read` và `.write`**: Yêu cầu authentication để đọc/ghi
2. **`.indexOn`**: Tạo index cho các field thường được query để tăng hiệu suất

## Cách cập nhật Rules

1. Vào Firebase Console: https://console.firebase.google.com
2. Chọn project của bạn
3. Vào **Realtime Database** > **Rules**
4. Paste rules ở trên
5. Click **Publish**

## Fallback Method

Code đã được cập nhật với fallback methods:
- Khi query `orderByChild` thất bại, hệ thống sẽ tự động load tất cả data và filter trong code
- Điều này đảm bảo ứng dụng vẫn hoạt động ngay cả khi query không thành công

## Kiểm tra dữ liệu

Đảm bảo cấu trúc dữ liệu trong Firebase đúng format:

**Showtimes:**
```json
{
  "showtimes": {
    "-N123abc": {
      "movieId": "movie1",
      "theaterId": "theater1",
      "startTime": 1234567890,
      "price": 100000,
      "availableSeats": ["A1", "A2", "B1"]
    }
  }
}
```

**Bookings:**
```json
{
  "bookings": {
    "-N456def": {
      "userId": "user1",
      "showtimeId": "-N123abc",
      "seats": ["A1", "A2"],
      "totalPrice": 200000,
      "status": "confirmed"
    }
  }
}
```

**KHÔNG được có:**
- String thay vì Map ở root level
- Null values ở root level
- Invalid data types

