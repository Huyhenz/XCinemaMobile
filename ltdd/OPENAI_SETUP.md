# Hướng Dẫn Tích Hợp OpenAI API

## 📋 Tổng Quan

Chatbot hiện tại đã được tích hợp với OpenAI GPT API. Khi người dùng hỏi các câu hỏi mà hệ thống không hiểu (unknown intent), chatbot sẽ tự động gọi OpenAI API để trả lời một cách thông minh hơn.

## 🔑 Lấy OpenAI API Key

1. **Truy cập OpenAI Platform**:
   - Vào: https://platform.openai.com/api-keys
   - Đăng nhập hoặc tạo tài khoản mới

2. **Tạo API Key**:
   - Click "Create new secret key"
   - Đặt tên cho key (ví dụ: "Cinema Chatbot")
   - Copy API key ngay lập tức (sẽ không hiển thị lại)

3. **Kiểm tra Credits**:
   - Đảm bảo tài khoản có credits (OpenAI có $5 free credits cho tài khoản mới)
   - Vào: https://platform.openai.com/usage để xem usage

## 📝 Cấu Hình API Key

### Thêm vào file `.env`

1. Mở file `.env` ở root project
2. Thêm dòng sau:

```env
# OpenAI API Configuration
OPENAI_API_KEY=sk-your-api-key-here
```

**Ví dụ**:
```env
OPENAI_API_KEY=sk-1234567890abcdefghijklmnopqrstuvwxyz
```

### Lưu ý
- ⚠️ **KHÔNG** commit API key vào Git
- ✅ File `.env` đã có trong `.gitignore`
- 🔒 Giữ API key bí mật

## ✅ Kiểm Tra Cấu Hình

Sau khi thêm API key vào `.env`, chạy app và kiểm tra log:

```
✅ OpenAI API key found in .env
📝 OpenAI API Key: sk-1234567...
```

Nếu không có API key:
```
⚠️ OpenAI API key not found in .env (chatbot will use rule-based responses)
💡 To enable AI-powered chatbot, add OPENAI_API_KEY to .env file
```

## 🤖 Cách Hoạt Động

### Hybrid Approach (Kết hợp Rule-based và AI)

1. **Rule-based (Ưu tiên)**: 
   - Các intent đặc biệt như "Tìm phim", "Xem lịch chiếu", "Giá vé" vẫn dùng rule-based
   - Vì cần lấy dữ liệu từ database

2. **AI-powered (Fallback)**:
   - Khi intent là "unknown" (không hiểu câu hỏi)
   - Chatbot sẽ gọi OpenAI API để trả lời thông minh hơn
   - Có context từ lịch sử trò chuyện

### Ví dụ

**Câu hỏi rule-based**:
- "Phim đang chiếu" → Rule-based (lấy từ database)
- "Lịch chiếu" → Rule-based
- "Giá vé" → Rule-based

**Câu hỏi AI-powered**:
- "Bạn có khỏe không?" → OpenAI API
- "Kể cho tôi nghe về Cinema" → OpenAI API
- "App này làm gì?" → OpenAI API

## 💰 Chi Phí

- **Model sử dụng**: `gpt-3.5-turbo` (rẻ nhất)
- **Giá**: ~$0.0015 per 1K tokens (rất rẻ)
- **Free credits**: $5 cho tài khoản mới (đủ dùng hàng nghìn requests)
- **Max tokens**: 500 tokens/response (giới hạn để tiết kiệm)

## 🛠️ Tùy Chỉnh

### Đổi Model

Trong file `lib/services/openai_service.dart`:

```dart
'model': 'gpt-3.5-turbo', // Hoặc 'gpt-4' nếu có
```

### Điều Chỉnh Temperature

```dart
'temperature': 0.7, // 0.0-2.0 (0.7 = cân bằng, cao hơn = sáng tạo hơn)
```

### Điều Chỉnh Max Tokens

```dart
'max_tokens': 500, // Số ký tự tối đa (tăng = tốn tiền hơn)
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
- Kiểm tra `OPENAI_API_KEY` có đúng format không
- Restart app sau khi thêm API key

### Lỗi: "Insufficient quota"
- Kiểm tra credits trong tài khoản OpenAI
- Nạp thêm credits nếu cần

### Lỗi: "Invalid API key"
- Kiểm tra API key có đúng không
- Tạo API key mới nếu cần

### Lỗi: "Rate limit exceeded"
- Giảm số lượng requests
- Hoặc upgrade plan trên OpenAI

## 📚 Tài Liệu Tham Khảo

- OpenAI API Docs: https://platform.openai.com/docs/api-reference
- Pricing: https://openai.com/pricing
- API Keys: https://platform.openai.com/api-keys

