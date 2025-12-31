# Hướng Dẫn Tích Hợp Backend cho Google Pay

## 📋 Tổng Quan

Sau khi Google Pay trả về payment token, bạn cần gửi token này đến backend để xử lý thanh toán thật thông qua Payment Gateway.

## 🔧 Bước 1: Cập Nhật Code Frontend

Trong `lib/services/payment_service.dart`, sau khi nhận được `paymentResult`, bạn cần gửi đến backend:

```dart
if (paymentResult != null) {
  print('✅ Google Pay payment completed');
  print('   Payment data: ${paymentResult.toString()}');
  
  try {
    // Gửi payment token đến backend
    final response = await http.post(
      Uri.parse('YOUR_BACKEND_URL/api/payments/google-pay'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer YOUR_AUTH_TOKEN', // Nếu cần
      },
      body: json.encode({
        'paymentData': paymentResult.toString(),
        'amount': payAmount,
        'currency': payCurrency,
        'description': description,
        'bookingId': bookingId, // Nếu có
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final transactionId = data['transactionId'];
      final success = data['success'] ?? true;
      
      if (success) {
        return PaymentResult(
          success: true,
          transactionId: transactionId,
          message: 'Thanh toán Google Pay thành công',
        );
      } else {
        return PaymentResult(
          success: false,
          transactionId: null,
          message: data['message'] ?? 'Thanh toán thất bại',
        );
      }
    } else {
      print('❌ Backend error: ${response.statusCode}');
      return PaymentResult(
        success: false,
        transactionId: null,
        message: 'Lỗi kết nối với server. Vui lòng thử lại.',
      );
    }
  } catch (e) {
    print('❌ Error sending to backend: $e');
    return PaymentResult(
      success: false,
      transactionId: null,
      message: 'Lỗi xử lý thanh toán: $e',
    );
  }
}
```

## 🔧 Bước 2: Tạo Backend Endpoint

### Node.js/Express Example

```javascript
const express = require('express');
const stripe = require('stripe')('YOUR_STRIPE_SECRET_KEY');
const router = express.Router();

router.post('/api/payments/google-pay', async (req, res) => {
  try {
    const { paymentData, amount, currency, description, bookingId } = req.body;
    
    // Parse payment data từ Google Pay
    const paymentMethodData = JSON.parse(paymentData);
    const token = paymentMethodData.paymentMethodData.tokenizationData.token;
    
    // Xử lý thanh toán qua Stripe
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Convert to cents
      currency: currency.toLowerCase(),
      payment_method_data: {
        type: 'card',
        card: {
          token: token,
        },
      },
      confirm: true,
      description: description,
      metadata: {
        bookingId: bookingId || '',
        paymentMethod: 'google_pay',
      },
    });
    
    if (paymentIntent.status === 'succeeded') {
      // Lưu vào database
      await savePaymentRecord({
        transactionId: paymentIntent.id,
        bookingId: bookingId,
        amount: amount,
        currency: currency,
        status: 'success',
        paymentMethod: 'google_pay',
      });
      
      res.json({
        success: true,
        transactionId: paymentIntent.id,
        message: 'Thanh toán thành công',
      });
    } else {
      res.status(400).json({
        success: false,
        message: 'Thanh toán không thành công',
      });
    }
  } catch (error) {
    console.error('Payment error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi xử lý thanh toán: ' + error.message,
    });
  }
});

module.exports = router;
```

### Python/Flask Example

```python
from flask import Flask, request, jsonify
import stripe
import json

app = Flask(__name__)
stripe.api_key = 'YOUR_STRIPE_SECRET_KEY'

@app.route('/api/payments/google-pay', methods=['POST'])
def process_google_pay():
    try:
        data = request.json
        payment_data = json.loads(data['paymentData'])
        amount = data['amount']
        currency = data['currency']
        description = data.get('description', '')
        booking_id = data.get('bookingId', '')
        
        # Extract token from Google Pay response
        token = payment_data['paymentMethodData']['tokenizationData']['token']
        
        # Create payment intent with Stripe
        payment_intent = stripe.PaymentIntent.create(
            amount=int(amount * 100),  # Convert to cents
            currency=currency.lower(),
            payment_method_data={
                'type': 'card',
                'card': {
                    'token': token,
                },
            },
            confirm=True,
            description=description,
            metadata={
                'bookingId': booking_id,
                'paymentMethod': 'google_pay',
            },
        )
        
        if payment_intent.status == 'succeeded':
            # Save to database
            save_payment_record({
                'transactionId': payment_intent.id,
                'bookingId': booking_id,
                'amount': amount,
                'currency': currency,
                'status': 'success',
                'paymentMethod': 'google_pay',
            })
            
            return jsonify({
                'success': True,
                'transactionId': payment_intent.id,
                'message': 'Thanh toán thành công',
            })
        else:
            return jsonify({
                'success': False,
                'message': 'Thanh toán không thành công',
            }), 400
            
    except Exception as e:
        print(f'Payment error: {e}')
        return jsonify({
            'success': False,
            'message': f'Lỗi xử lý thanh toán: {str(e)}',
        }), 500
```

## 🔧 Bước 3: Cấu Hình Payment Gateway

### Stripe Configuration

1. **Đăng ký tài khoản Stripe**: https://stripe.com
2. **Lấy API Keys**:
   - **Publishable Key** (cho frontend - **CẦN THIẾT** để cấu hình Google Pay)
     - Format: `pk_live_...` (production) hoặc `pk_test_...` (test)
     - Lấy từ: Dashboard → Developers → API keys → Publishable key
     - **Công dụng**: Được dùng trong file `assets/google_pay_config.json` để Google Pay biết cách tokenize payment data với Stripe
     - **An toàn**: Key này là công khai, an toàn khi đặt trong frontend code
   - **Secret Key** (cho backend - **BẢO MẬT**, không được expose ra frontend!)
     - Format: `sk_live_...` (production) hoặc `sk_test_...` (test)
     - Lấy từ: Dashboard → Developers → API keys → Secret key
     - **Công dụng**: Dùng trên backend để xử lý payment token và tạo charge
     - **Bảo mật**: Phải giữ bí mật, chỉ dùng trên server
3. **Cấu hình Google Pay trong Stripe Dashboard**:
   - Vào Settings → Payment methods
   - Kích hoạt Google Pay
   - Lấy Gateway Merchant ID (nếu cần)

4. **Cập nhật `assets/google_pay_config.json`**:

```json
{
  "provider": "google_pay",
  "data": {
    "environment": "PRODUCTION",
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
            "stripe:publishableKey": "pk_live_YOUR_PUBLISHABLE_KEY",
            "stripe:version": "2023-10-16"
          }
        }
      }
    ],
    "merchantInfo": {
      "merchantId": "YOUR_GOOGLE_PAY_MERCHANT_ID",
      "merchantName": "XCinema"
    }
  }
}
```

**Lưu ý quan trọng**:
- **Publishable Key** là công khai, an toàn khi đặt trong frontend code
- **Secret Key** phải được giữ bí mật, chỉ dùng trên backend
- Publishable Key được dùng trong `google_pay_config.json` để Google Pay biết cách tokenize payment data

### Square Configuration

1. **Đăng ký tài khoản Square**: https://squareup.com
2. **Lấy Application ID và Access Token**
3. **Cập nhật config**:

```json
{
  "tokenizationSpecification": {
    "type": "PAYMENT_GATEWAY",
    "parameters": {
      "gateway": "square",
      "gatewayMerchantId": "YOUR_SQUARE_APPLICATION_ID"
    }
  }
}
```

## 🔒 Bảo Mật

1. **Không bao giờ** lưu Secret Key trên frontend
2. **Luôn** xử lý thanh toán trên backend
3. **Xác thực** payment token trước khi xử lý
4. **Log** tất cả giao dịch để audit
5. **Sử dụng HTTPS** cho tất cả API calls

## 📝 Checklist

- [ ] Đã tạo backend endpoint `/api/payments/google-pay`
- [ ] Đã cấu hình Payment Gateway (Stripe/Square/etc.)
- [ ] Đã cập nhật `google_pay_config.json` với thông tin thật
- [ ] Đã cập nhật code frontend để gửi payment token đến backend
- [ ] Đã test với test mode
- [ ] Đã test với production mode
- [ ] Đã implement error handling
- [ ] Đã implement logging
- [ ] Đã implement database storage

## 🔗 Tài Liệu Tham Khảo

- [Stripe Google Pay Integration](https://stripe.com/docs/google-pay)
- [Square Google Pay Integration](https://developer.squareup.com/docs/payment-form/overview)
- [Google Pay API Documentation](https://developers.google.com/pay/api)

