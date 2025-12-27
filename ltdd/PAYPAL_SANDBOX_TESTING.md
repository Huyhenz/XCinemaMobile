# Hướng Dẫn Test PayPal Sandbox - Quan Trọng! ⚠️

## ❌ Lỗi Thường Gặp: CANNOT_PAY_SELF

### Vấn Đề
Khi test PayPal payment, bạn có thể gặp lỗi:
```
Error code: Q0FOTk9UX1BBWV9TRUxG (CANNOT_PAY_SELF)
```

### Nguyên Nhân
Lỗi này xảy ra khi bạn sử dụng **cùng một tài khoản** cho:
- **Merchant account** (tài khoản nhận tiền - từ PayPal Developer Dashboard)
- **Payer account** (tài khoản thanh toán - khi login vào PayPal)

PayPal không cho phép thanh toán cho chính mình trong sandbox mode.

## ✅ Giải Pháp

### Bước 1: Tạo Sandbox Test Accounts

1. Vào **PayPal Developer Dashboard**: https://developer.paypal.com
2. Chọn **"Sandbox"** mode (không phải Live)
3. Vào **"Testing Tools"** → **"Sandbox Accounts"**
4. Tạo **2 tài khoản khác nhau**:
   - **Business Account** (Merchant): Để nhận tiền
   - **Personal Account** (Payer): Để thanh toán

### Bước 2: Sử Dụng Đúng Tài Khoản

**Khi test payment:**
- **Merchant Account**: Dùng Client ID và Secret từ Business Account
- **Payer Account**: Login vào PayPal với Personal Account (không phải Business Account)

### Bước 3: Test Payment Flow

1. App sử dụng **Business Account** credentials (Client ID/Secret)
2. Khi WebView mở PayPal checkout:
   - **KHÔNG** login bằng Business Account
   - **Login bằng Personal Account** (tài khoản khác)
3. Approve payment
4. Payment sẽ thành công!

## 📝 Checklist

- [ ] Đã tạo 2 sandbox accounts (Business + Personal)
- [ ] App dùng Business Account credentials
- [ ] Test payment với Personal Account (không phải Business)
- [ ] Không dùng cùng một account cho cả merchant và payer

## 🔍 Cách Kiểm Tra

Nếu vẫn gặp lỗi `CANNOT_PAY_SELF`:
1. Kiểm tra bạn đang login bằng account nào
2. Đảm bảo account login **KHÁC** với merchant account
3. Tạo Personal Account mới nếu cần

## 💡 Lưu Ý

- Sandbox accounts chỉ dùng để test
- Không dùng tài khoản thật để test
- Mỗi lần test nên dùng Personal Account khác với Merchant Account

