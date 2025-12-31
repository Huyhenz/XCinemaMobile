# Hướng Dẫn Chi Tiết: Lấy API Keys từ Stripe và Cấu Hình

## 📍 Bước 1: Đã Thấy API Keys trong Stripe Dashboard

Bạn đã thấy phần **"API keys"** trong Stripe dashboard với:
- **Public key**: `pk_test_51SkM1bF20g1...` (hoặc tương tự)
- **Secret key**: `sk_test_51SkM1bF20g1...` (hoặc tương tự)

## 📋 Bước 2: Copy API Keys

### 2.1. Copy Publishable Key (Public key)
1. Click vào **"Public key"** trong phần API keys
2. Copy toàn bộ key (ví dụ: `pk_test_51SkM1bF20g1...`)
3. **Lưu lại** để dùng cho frontend

### 2.2. Copy Secret Key
1. Click vào **"Secret key"** trong phần API keys
2. Click nút **"Reveal test key"** hoặc **"Show"** để hiển thị full key
3. Copy toàn bộ key (ví dụ: `sk_test_51SkM1bF20g1...`)
4. **Lưu lại** để dùng cho backend (BẢO MẬT!)

## 🔧 Bước 3: Cập Nhật File Config Frontend

### 3.1. Mở file `assets/google_pay_config.json`

### 3.2. Cập nhật Publishable Key

Thay đổi phần này:
```json
"tokenizationSpecification": {
  "type": "PAYMENT_GATEWAY",
  "parameters": {
    "gateway": "stripe",
    "stripe:publishableKey": "pk_test_51SkM1bF20g1...",  // ← Dán key của bạn vào đây
    "stripe:version": "2023-10-16"
  }
}
```

**Ví dụ sau khi cập nhật:**
```json
{
  "provider": "google_pay",
  "data": {
    "environment": "TEST",
    "apiVersion": 2,
    "apiVersionMinor": 0,
    "allowedPaymentMethods": [
      {
        "type": "CARD",
        "parameters": {
          "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
          "allowedCardNetworks": ["AMEX", "DISCOVER", "JCB", "MASTERCARD", "VISA"]
        },
        "tokenizationSpecification": {
          "type": "PAYMENT_GATEWAY",
          "parameters": {
            "gateway": "stripe",
            "stripe:publishableKey": "pk_test_51SkM1bF20g1YOUR_ACTUAL_KEY_HERE",
            "stripe:version": "2023-10-16"
          }
        }
      }
    ],
    "merchantInfo": {
      "merchantId": "01234567890123456789",
      "merchantName": "XCinema"
    }
  }
}
```

## ⚙️ Bước 4: Kích Hoạt Google Pay trong Stripe (Nếu Chưa)

1. Trong Stripe Dashboard, vào **Settings** (biểu tượng bánh răng ở trên cùng)
2. Chọn **Payment methods** (hoặc **Payment settings**)
3. Tìm **Google Pay** trong danh sách
4. **Kích hoạt** (toggle ON) Google Pay
5. Lưu thay đổi

## 🔐 Bước 5: Lưu Secret Key cho Backend

1. Tạo file `.env` trong project (nếu chưa có)
2. Thêm Secret Key vào file `.env`:
   ```env
   STRIPE_SECRET_KEY=sk_test_51SkM1bF20g1YOUR_ACTUAL_SECRET_KEY_HERE
   ```
3. **QUAN TRỌNG**: Không commit file `.env` vào Git!

## ✅ Bước 6: Kiểm Tra

Sau khi hoàn thành:
- ✅ Publishable Key đã được cập nhật trong `google_pay_config.json`
- ✅ Secret Key đã được lưu trong `.env` (cho backend)
- ✅ Google Pay đã được kích hoạt trong Stripe Dashboard

## 🚀 Bước Tiếp Theo

Sau khi cấu hình xong:
1. **Frontend**: Code sẽ tự động load config từ `google_pay_config.json`
2. **Backend**: Sử dụng Secret Key từ `.env` để xử lý payment
3. **Test**: Chạy app và test Google Pay payment

## 📝 Lưu Ý

- **Test mode**: Keys bắt đầu bằng `pk_test_` và `sk_test_` là cho test
- **Production mode**: Khi sẵn sàng, chuyển sang keys bắt đầu bằng `pk_live_` và `sk_live_`
- **Environment**: Trong `google_pay_config.json`, đổi `"environment": "TEST"` thành `"PRODUCTION"` khi dùng live keys

