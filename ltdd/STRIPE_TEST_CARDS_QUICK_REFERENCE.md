# Stripe Test Cards - Quick Reference

## ✅ Thẻ Thành Công (Success)

### Visa
```
Card Number: 4242 4242 4242 4242
Expiry: 12/25 (hoặc bất kỳ tháng/năm tương lai)
CVC: 123
ZIP: 12345
```

### Mastercard
```
Card Number: 5555 5555 5555 4444
Expiry: 12/25
CVC: 123
ZIP: 12345
```

### American Express
```
Card Number: 3782 822463 10005
Expiry: 12/25
CVC: 1234
ZIP: 12345
```

## ❌ Thẻ Thất Bại (Declined)

### Card Declined
```
Card Number: 4000 0000 0000 0002
Expiry: 12/25
CVC: 123
ZIP: 12345
```

### Insufficient Funds
```
Card Number: 4000 0000 0000 9995
Expiry: 12/25
CVC: 123
ZIP: 12345
```

## 🔒 Thẻ Yêu Cầu 3D Secure

```
Card Number: 4000 0025 0000 3155
Expiry: 12/25
CVC: 123
ZIP: 12345
```

## 📝 Cách Sử Dụng

1. **Thêm vào Google Pay**:
   - Mở Google Pay app
   - Thêm thẻ mới
   - Nhập thông tin test card ở trên

2. **Test trong App**:
   - Chọn Google Pay
   - Chọn thẻ test đã thêm
   - Xác nhận thanh toán

3. **Kiểm Tra Kết Quả**:
   - Xem trong Stripe Dashboard → Payments
   - Xem trong app (màn hình thành công/thất bại)

## ⚠️ Lưu Ý

- Chỉ hoạt động trong **Stripe Test Mode**
- Chỉ hoạt động trên **thiết bị thật** (không phải emulator)
- Không tính phí thật

