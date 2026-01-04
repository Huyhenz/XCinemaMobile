# Hướng Dẫn Tích Hợp Google Gemini API (FREE)

## 📋 Tổng Quan

Chatbot đã được tích hợp với **Google Gemini API** - một AI model miễn phí từ Google. Khi người dùng hỏi các câu hỏi mà hệ thống không hiểu (unknown intent), chatbot sẽ tự động gọi Gemini API để trả lời một cách thông minh hơn.

## 🆓 Tại Sao Chọn Gemini?

- ✅ **HOÀN TOÀN MIỄN PHÍ** - Không cần thẻ tín dụng
- ✅ **Free Tier rộng rãi** - 60 requests/phút, 1500 requests/ngày
- ✅ **Hỗ trợ tiếng Việt tốt**
- ✅ **Dễ đăng ký** - Chỉ cần tài khoản Google
- ✅ **Không giới hạn thời gian** - Free tier không hết hạn

## 🔑 Lấy Gemini API Key (MIỄN PHÍ)

### Bước 1: Truy cập Google AI Studio

1. Vào: **https://aistudio.google.com/app/apikey**
2. Đăng nhập bằng tài khoản Google của bạn

### Bước 2: Tạo API Key

1. Click nút **"Create API Key"** hoặc **"Get API Key"**
2. Chọn project (hoặc tạo project mới)
3. **Copy API key** ngay lập tức

**Lưu ý**: API key sẽ có dạng: `AIzaSy...` (bắt đầu bằng `AIza`)

### Bước 3: Kiểm tra API Key

- API key sẽ hoạt động ngay sau khi tạo
- Không cần xác thực thẻ tín dụng
- Free tier tự động được kích hoạt

## 📝 Cấu Hình API Key

### Thêm vào file `.env`

1. Mở file `.env` ở root project
2. Thêm dòng sau:

```env
# Google Gemini API Configuration (FREE)
GEMINI_API_KEY=AIzaSy-your-api-key-here
```

**Ví dụ**:
```env
GEMINI_API_KEY=AIzaSy1234567890abcdefghijklmnopqrstuvwxyz
```

### Lưu ý
- ⚠️ **KHÔNG** commit API key vào Git
- ✅ File `.env` đã có trong `.gitignore`
- 🔒 Giữ API key bí mật

## ✅ Kiểm Tra Cấu Hình

Sau khi thêm API key vào `.env`, chạy app và kiểm tra log:

```
✅ Google Gemini API key found in .env
📝 Gemini API Key: AIzaSy1234...
```

Nếu không có API key:
```
⚠️ Gemini API key not found in .env (chatbot will use rule-based responses)
💡 To enable AI-powered chatbot (FREE), add GEMINI_API_KEY to .env file
💡 Get FREE API key at: https://aistudio.google.com/app/apikey
```

## 🤖 Cách Hoạt Động

### Hybrid Approach (Kết hợp Rule-based và AI)

1. **Rule-based (Ưu tiên)**: 
   - Các intent đặc biệt như "Tìm phim", "Xem lịch chiếu", "Giá vé" vẫn dùng rule-based
   - Vì cần lấy dữ liệu từ database

2. **AI-powered (Fallback)**:
   - Khi intent là "unknown" (không hiểu câu hỏi)
   - Chatbot sẽ gọi Gemini API để trả lời thông minh hơn
   - Có context từ lịch sử trò chuyện

### Ví dụ

**Câu hỏi rule-based**:
- "Phim đang chiếu" → Rule-based (lấy từ database)
- "Lịch chiếu" → Rule-based
- "Giá vé" → Rule-based

**Câu hỏi AI-powered**:
- "Bạn có khỏe không?" → Gemini API
- "Kể cho tôi nghe về Cinema" → Gemini API
- "App này làm gì?" → Gemini API

## 💰 Giới Hạn Free Tier

- **60 requests/phút** - Đủ cho hầu hết các ứng dụng
- **1500 requests/ngày** - Rất rộng rãi
- **Không giới hạn thời gian** - Free tier không hết hạn
- **Không cần thẻ tín dụng** - Hoàn toàn miễn phí

## 🛠️ Tùy Chỉnh

### Đổi Model

Trong file `lib/services/gemini_service.dart`:

```dart
Uri.parse('$_baseUrl/models/gemini-pro:generateContent?key=$_apiKey'),
// Có thể đổi thành:
// - gemini-pro (mặc định, tốt nhất)
// - gemini-pro-vision (hỗ trợ hình ảnh)
```

### Điều Chỉnh Temperature

```dart
'temperature': 0.7, // 0.0-2.0 (0.7 = cân bằng, cao hơn = sáng tạo hơn)
```

### Điều Chỉnh Max Tokens

```dart
'maxOutputTokens': 500, // Số ký tự tối đa
```

### Tùy Chỉnh System Prompt

Trong file `lib/services/ai_agent_service.dart`, method `_handleUnknown`:

```dart
systemPrompt: 'Bạn là một chatbot hỗ trợ của hệ thống đặt vé xem phim Cinema. '
    'Bạn giúp người dùng tìm phim, xem lịch chiếu, và trả lời các câu hỏi về hệ thống. '
    'Hãy trả lời bằng tiếng Việt một cách thân thiện và hữu ích.',
```

## 🔍 Troubleshooting

### Lỗi: "API key not found"
- Kiểm tra file `.env` có đúng tên không
- Kiểm tra `GEMINI_API_KEY` có đúng format không (bắt đầu bằng `AIza`)
- Restart app sau khi thêm API key

### Lỗi: "API key not valid"
- Kiểm tra API key có đúng không
- Tạo API key mới tại: https://aistudio.google.com/app/apikey

### Lỗi: "Quota exceeded"
- Bạn đã vượt quá 60 requests/phút hoặc 1500 requests/ngày
- Đợi một chút rồi thử lại
- Hoặc upgrade lên paid plan (nếu cần)

### Lỗi: "Rate limit exceeded"
- Giảm số lượng requests
- Hoặc đợi một chút rồi thử lại

## 📚 Tài Liệu Tham Khảo

- Google AI Studio: https://aistudio.google.com/
- Gemini API Docs: https://ai.google.dev/docs
- Get API Key: https://aistudio.google.com/app/apikey
- Pricing (Free tier): https://ai.google.dev/pricing

## 🎉 Hoàn Tất!

Sau khi thêm `GEMINI_API_KEY` vào file `.env`, chatbot sẽ tự động sử dụng AI để trả lời các câu hỏi không hiểu. Hoàn toàn miễn phí và không cần thẻ tín dụng!

