# Script `send_noti.py`

Tài liệu này mô tả chi tiết cách hoạt động của script Python dùng để gửi FCM data message đánh thức ứng dụng mẫu Siprix.

## 1. Tải biến môi trường
- Sử dụng `dotenv` để đọc file `.env` cùng thư mục.
- Hàm `env(name, required=False)` giúp truy xuất biến môi trường và có thể ép bắt buộc.

## 2. Bộ dữ liệu mẫu `get_data_preset`
- `android_incoming_call`: payload dành cho cuộc gọi đến (action `incoming_call`, chứa callerName, callerNumber…).
- `android_wakeup`: payload nhẹ chỉ gồm `action: wake`.
- Có thể mở rộng thêm preset mới tùy nhu cầu.

## 3. Xây dựng thông điệp `build_message`
- Hard-code `device_token` phục vụ test nội bộ; cần cập nhật lại token thực tế khi cài lại app.
- Payload hiện tại là data-only để đánh thức app: `{ action: 'wake', wake: '1' }`.
- Mẫu payload đang sử dụng:
  ```json
  {
    "token": "<FCM_DEVICE_TOKEN>",
    "data": {
      "action": "wake",
      "wake": "1"
    },
    "android": {
      "priority": "high"
    }
  }
  ```
- Cấu hình `messaging.Message` với:
  - `token`: FCM device token.
  - `data`: payload ở trên.
  - `android`: `AndroidConfig(priority='high')` để đảm bảo ưu tiên wake-up.

## 4. Hàm `main`
1. Khởi tạo Firebase Admin:
   - Dùng Application Default Credentials (biến `GOOGLE_APPLICATION_CREDENTIALS` trỏ tới file service-account).
   - In ra access token để tiện so sánh với bản JS.
2. Gọi `build_message()` để tạo payload.
3. Gửi qua `messaging.send(msg, dry_run=False)` và log `Message sent` hoặc lỗi.

## 5. Cách chạy
```bash
python3 notification_test/send_noti.py
```
Yêu cầu:
- Đã cài `firebase_admin` và `python-dotenv`.
- Biến môi trường `GOOGLE_APPLICATION_CREDENTIALS` chỉ tới service-account JSON có quyền gửi FCM.
- Thiết bị đã đăng ký FCM token mới nhất và token đó được cập nhật trong script.

## 6. Tùy biến nhanh
- Đổi token: sửa biến `device_token`.
- Đổi payload: chỉnh dict `data` hoặc tận dụng `get_data_preset`.
- Gửi notification hiển thị: bổ sung trường `notification=messaging.Notification(...)` khi tạo `messaging.Message`.

Script này chủ đích gửi data message “wake” để Flutter background handler khởi động Siprix, không hiển thị UI nên cần tự bổ sung nếu muốn có banner thông báo. 

