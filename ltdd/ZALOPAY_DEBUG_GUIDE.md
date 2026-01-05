# 🔍 Hướng Dẫn Debug ZaloPay - Tìm Lỗi Cụ Thể

## ❌ Vấn Đề: Cả 3 Bộ Credentials Đều Không Hoạt Động

Nếu tất cả các bộ credentials đều không hoạt động, hãy làm theo các bước sau để tìm lỗi cụ thể:

## 📋 Bước 1: Kiểm Tra Logs Chi Tiết

Khi chạy app và test ZaloPay, hãy xem console logs để tìm lỗi cụ thể:

### Lỗi Thường Gặp:

1. **Lỗi -401 (Giao dịch thất bại)**
   ```
   ❌ ZaloPay order creation failed: Giao dịch thất bại
   ```
   - **Nguyên nhân**: Signature không đúng hoặc credentials không hợp lệ
   - **Giải pháp**: Xem Bước 2

2. **Lỗi -402 (App ID không hợp lệ)**
   ```
   ❌ ZaloPay order creation failed: App ID không hợp lệ
   ```
   - **Nguyên nhân**: App ID sai hoặc không tồn tại
   - **Giải pháp**: Thử bộ credentials khác

3. **Lỗi Timeout**
   ```
   ❌ Error creating ZaloPay order: TimeoutException
   ```
   - **Nguyên nhân**: Mạng chậm hoặc API không phản hồi
   - **Giải pháp**: Kiểm tra kết nối mạng

4. **Lỗi 404 (Not Found)**
   ```
   ❌ Failed to create ZaloPay order: 404
   ```
   - **Nguyên nhân**: URL API sai
   - **Giải pháp**: Kiểm tra Base URL

## 🔍 Bước 2: Test API Trực Tiếp

Tạo file test để kiểm tra API trực tiếp:

### Test Script (Dart)

Tạo file `test_zalopay.dart` ở root project:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

void main() async {
  // Test với Bộ 1
  await testZaloPay(
    appId: '2554',
    key1: 'sdngKKJmqEMzvh5QQcdD2A9XBSKUNaYn',
    key2: 'trMrHtvjo6myautxDUiAcYsVtaeQ8nhf',
    name: 'Bộ 1',
  );

  // Test với Bộ 2
  await testZaloPay(
    appId: '554',
    key1: '8NdU5pG5R2spGHGhyO99HN1OhD8IQJBn',
    key2: 'uUfsWgfLkRLzq6W2uNXTCxrfxs51auny',
    name: 'Bộ 2',
  );

  // Test với Bộ 3
  await testZaloPay(
    appId: '2553',
    key1: '8NdU5pG5R2spGHGhyO99HN1OhD8IQJBn',
    key2: 'uUfsWgfLkRLzq6W2uNXTCxrfxs51auny',
    name: 'Bộ 3',
  );
}

Future<void> testZaloPay({
  required String appId,
  required String key1,
  required String key2,
  required String name,
}) async {
  print('\n🧪 Testing $name...');
  print('   App ID: $appId');
  print('   Key1: ${key1.substring(0, 10)}...');

  try {
    final now = DateTime.now();
    final dateStr = '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomSuffix = (DateTime.now().millisecondsSinceEpoch % 1000000000).toString();
    final appTransId = '${dateStr}_${appId}_$randomSuffix';
    final appTransIdFinal = appTransId.length > 40 ? appTransId.substring(0, 40) : appTransId;
    
    final appTime = DateTime.now().millisecondsSinceEpoch;
    final amount = 10000; // 10,000 VND
    final item = 'Test Payment';
    final embedData = '';

    final params = <String, dynamic>{
      'app_id': appId,
      'app_user': 'XCinema_User',
      'app_time': appTime,
      'amount': amount,
      'app_trans_id': appTransIdFinal,
      'item': item,
      'embed_data': embedData,
    };

    // Create signature
    final macData = '${params['app_id']}|${params['app_trans_id']}|${params['app_user']}|${params['amount']}|${params['app_time']}|${params['embed_data']}|${params['item']}';
    print('   MAC Data: $macData');
    
    final key = utf8.encode(key1);
    final bytes = utf8.encode(macData);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    final mac = digest.toString();

    params['mac'] = mac;
    print('   MAC: $mac');

    final baseUrl = 'https://sb-openapi.zalopay.vn';
    final createOrderUrl = '$baseUrl/v2/create';
    
    print('   URL: $createOrderUrl');

    final response = await http.post(
      Uri.parse(createOrderUrl),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params.map((key, value) => MapEntry(key, value.toString())),
    ).timeout(const Duration(seconds: 30));

    print('   Status: ${response.statusCode}');
    print('   Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['return_code'] == 1) {
        print('   ✅ SUCCESS! Order URL: ${data['order_url']}');
      } else {
        print('   ❌ FAILED: ${data['return_message']} (Code: ${data['return_code']})');
      }
    } else {
      print('   ❌ HTTP Error: ${response.statusCode}');
    }
  } catch (e) {
    print('   ❌ Exception: $e');
  }
}
```

Chạy test:
```bash
dart test_zalopay.dart
```

## 🔧 Bước 3: Kiểm Tra Các Vấn Đề Thường Gặp

### 1. Kiểm Tra Format `app_trans_id`

Format phải đúng: `YYMMDD_appid_random` (max 40 chars)

**Ví dụ đúng:**
- `250101_2554_1234567890` ✅
- `250101_554_987654321` ✅

**Ví dụ sai:**
- `2025-01-01_2554_1234567890` ❌ (có dấu gạch ngang)
- `25010125541234567890` ❌ (thiếu dấu gạch dưới)

### 2. Kiểm Tra Signature (MAC)

MAC data format phải chính xác:
```
app_id|app_trans_id|app_user|amount|app_time|embed_data|item
```

**Lưu ý:**
- `embed_data` có thể là empty string
- Không có khoảng trắng thừa
- Tất cả giá trị phải là string (không có dấu ngoặc kép)

### 3. Kiểm Tra Base URL

Sandbox URL phải là: `https://sb-openapi.zalopay.vn`

**KHÔNG dùng:**
- `https://openapi.zalopay.vn` (production)
- `https://sandbox.zalopay.vn` (sai)

## 🚀 Giải Pháp Thay Thế: Dùng Cổng Thanh Toán Trung Gian

Nếu không muốn đăng ký ZaloPay trực tiếp, bạn có thể dùng cổng thanh toán trung gian:

### Option 1: Checkout.vn

**Ưu điểm:**
- ✅ Không cần đăng ký ZaloPay trực tiếp
- ✅ Hỗ trợ nhiều cổng thanh toán (ZaloPay, VNPay, MoMo, v.v.)
- ✅ API đơn giản hơn
- ✅ Có sandbox để test

**Cách dùng:**
1. Đăng ký tại: https://checkout.vn
2. Lấy API key
3. Tích hợp vào app

**Tài liệu:** https://help.checkout.vn/zalopay.html

### Option 2: PayOS

**Ưu điểm:**
- ✅ Hỗ trợ ZaloPay
- ✅ API REST đơn giản
- ✅ Có sandbox

**Cách dùng:**
1. Đăng ký tại: https://payos.vn
2. Lấy API key
3. Tích hợp vào app

### Option 3: Liên Hệ ZaloPay Hỗ Trợ

Nếu muốn dùng ZaloPay trực tiếp:

1. **Email**: support@zalopay.vn hoặc hotro@zalopay.vn
2. **Hotline**: 1900 545 436
3. **Nội dung email:**
   ```
   Chào ZaloPay Team,
   
   Tôi đang làm project [tên project] và cần tài khoản sandbox để test tích hợp.
   Tôi đã thử các public sandbox credentials (App ID: 2554, 554, 2553) nhưng đều không hoạt động.
   
   Vui lòng hỗ trợ:
   - Tạo tài khoản sandbox mới
   - Hoặc cung cấp credentials mới để test
   
   Thông tin của tôi:
   - Họ tên: [Tên]
   - Email: [Email]
   - Số điện thoại: [SĐT]
   - Mục đích: Test tích hợp thanh toán cho project [tên project]
   
   Cảm ơn!
   ```

## 📝 Checklist Debug

Trước khi liên hệ hỗ trợ, đảm bảo đã kiểm tra:

- [ ] Đã thử cả 3 bộ credentials
- [ ] Đã kiểm tra console logs để xem lỗi cụ thể
- [ ] Đã test API trực tiếp (dùng script test)
- [ ] Đã kiểm tra format `app_trans_id`
- [ ] Đã kiểm tra signature (MAC)
- [ ] Đã kiểm tra Base URL (phải là `https://sb-openapi.zalopay.vn`)
- [ ] Đã kiểm tra kết nối mạng
- [ ] Đã thử trên thiết bị khác hoặc emulator khác

## 🎯 Kết Luận

Nếu sau khi debug vẫn không hoạt động:

1. **Option tốt nhất**: Dùng cổng trung gian (Checkout.vn hoặc PayOS)
2. **Option thứ 2**: Liên hệ ZaloPay để được hỗ trợ
3. **Option cuối**: Đăng ký tài khoản sandbox riêng (cần thời gian chờ phản hồi)

---

**Lưu ý:** Public sandbox credentials có thể bị vô hiệu hóa hoặc thay đổi bất cứ lúc nào bởi ZaloPay. Để đảm bảo ổn định, nên đăng ký tài khoản sandbox riêng hoặc dùng cổng trung gian.






