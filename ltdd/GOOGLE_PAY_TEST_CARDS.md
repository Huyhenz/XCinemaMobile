# Hướng Dẫn Test Google Pay với Test Cards

## 🎯 Tổng Quan

Để test Google Pay, bạn cần:
1. **Test Cards** từ Stripe (cho test mode)
2. **Thêm thẻ vào Google Pay** trên thiết bị test
3. **Test thanh toán** trong app

## 💳 Test Cards từ Stripe

### Stripe Test Cards

Stripe cung cấp các test card numbers để test thanh toán. Dưới đây là các test cards phổ biến:

#### ✅ Thẻ Thành Công
```
Card Number: 4242 4242 4242 4242
Expiry: Bất kỳ tháng/năm tương lai (ví dụ: 12/25)
CVC: Bất kỳ 3 chữ số (ví dụ: 123)
ZIP: Bất kỳ 5 chữ số (ví dụ: 12345)
```

#### ❌ Thẻ Thất Bại
```
Card Number: 4000 0000 0000 0002
Expiry: Bất kỳ tháng/năm tương lai
CVC: Bất kỳ 3 chữ số
ZIP: Bất kỳ 5 chữ số
```

#### 🔒 Thẻ Yêu Cầu 3D Secure
```
Card Number: 4000 0025 0000 3155
Expiry: Bất kỳ tháng/năm tương lai
CVC: Bất kỳ 3 chữ số
ZIP: Bất kỳ 5 chữ số
```

### Xem Tất Cả Test Cards

1. Vào **Stripe Dashboard**: https://dashboard.stripe.com
2. Vào **Developers** → **Testing** → **Test cards**
3. Hoặc xem tại: https://stripe.com/docs/testing

## 📱 Cách Thêm Thẻ vào Google Pay để Test

### Trên Android

1. **Mở Google Pay App** trên thiết bị
2. Vào **Payment methods** (Phương thức thanh toán)
3. Click **Add payment method** (Thêm phương thức thanh toán)
4. Chọn **Add a card** (Thêm thẻ)
5. Nhập thông tin test card:
   - **Card number**: `4242 4242 4242 4242`
   - **Expiry**: `12/25` (hoặc bất kỳ tháng/năm tương lai)
   - **CVC**: `123`
   - **Name**: Tên bất kỳ
   - **Billing address**: Địa chỉ bất kỳ
6. Click **Save** (Lưu)

### Trên iOS (Apple Pay)

1. Mở **Settings** → **Wallet & Apple Pay**
2. Click **Add Card**
3. Nhập thông tin test card tương tự

## 🧪 Cách Test Google Pay trong App

### Bước 1: Đảm Bảo Test Mode

Kiểm tra file `assets/google_pay_config.json`:
```json
{
  "data": {
    "environment": "TEST",  // ← Phải là "TEST" để dùng test cards
    ...
  }
}
```

### Bước 2: Chạy App

```bash
flutter run
```

### Bước 3: Test Flow

1. Chọn phim → Showtime → Ghế
2. Nhấn "Thanh Toán"
3. Chọn "Google Pay"
4. Nhấn "Xác Nhận Thanh Toán"
5. Màn hình Google Pay sẽ hiển thị
6. Chọn thẻ test đã thêm vào Google Pay
7. Xác nhận thanh toán
8. Kết quả sẽ hiển thị

## 🔍 Kiểm Tra Test Cards trong Stripe

### Xem Test Payments

1. Vào **Stripe Dashboard**
2. Vào **Payments** (Thanh toán)
3. Bạn sẽ thấy tất cả test payments
4. Click vào payment để xem chi tiết

### Test Card Numbers Phổ Biến

| Card Number | Kết Quả | Mô Tả |
|------------|---------|-------|
| `4242 4242 4242 4242` | ✅ Thành công | Visa test card |
| `5555 5555 5555 4444` | ✅ Thành công | Mastercard test card |
| `4000 0000 0000 0002` | ❌ Thất bại | Card declined |
| `4000 0000 0000 9995` | ❌ Thất bại | Insufficient funds |
| `4000 0025 0000 3155` | 🔒 3D Secure | Yêu cầu xác thực |

## ⚠️ Lưu Ý Quan Trọng

### 1. Test Mode vs Production

- **Test Mode**: Dùng test cards, không tính phí thật
- **Production Mode**: Dùng thẻ thật, tính phí thật

### 2. Google Pay trên Emulator

- ⚠️ **Google Pay KHÔNG hoạt động trên emulator**
- ✅ **Chỉ hoạt động trên thiết bị thật** (Android/iOS)

### 3. Test Cards Chỉ Hoạt Động trong Test Mode

- Test cards chỉ hoạt động khi Stripe ở **Test Mode**
- Trong Production Mode, phải dùng thẻ thật

## 🎯 Quick Test Checklist

- [ ] Đã thêm test card vào Google Pay trên thiết bị
- [ ] File config có `"environment": "TEST"`
- [ ] Stripe Dashboard đang ở Test Mode
- [ ] Test trên thiết bị thật (không phải emulator)
- [ ] Đã test với thẻ thành công (`4242 4242 4242 4242`)
- [ ] Đã test với thẻ thất bại (nếu cần)

## 📚 Tài Liệu Tham Khảo

- [Stripe Test Cards](https://stripe.com/docs/testing)
- [Google Pay Testing](https://developers.google.com/pay/api/android/guides/test-and-deploy)
- [Stripe Testing Guide](https://stripe.com/docs/testing)

## 💡 Tips

1. **Lưu nhiều test cards** trong Google Pay để test các trường hợp khác nhau
2. **Xem logs** trong Stripe Dashboard để debug
3. **Test trên nhiều thiết bị** để đảm bảo tương thích
4. **Test cả thành công và thất bại** để đảm bảo error handling đúng

---

**Bây giờ bạn đã có test cards! Hãy thêm vào Google Pay và test thôi! 🚀**

