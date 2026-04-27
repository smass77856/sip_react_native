# macOS Local Notifications Setup

## Tổng quan

Firebase Cloud Messaging (FCM) **KHÔNG hỗ trợ macOS**. Thay vào đó, app sử dụng **Local Notifications** để hiển thị thông báo khi app đang chạy.

## Cấu hình đã hoàn thành

### 1. Dependencies (pubspec.yaml)
```yaml
dependencies:
  flutter_local_notifications: ^18.0.1
```

### 2. Entitlements
Đã cấu hình trong:
- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/Release.entitlements`

```xml
<key>aps-environment</key>
<string>development</string> <!-- hoặc production -->
```

### 3. Code Implementation

#### Khởi tạo Local Notifications
```dart
Future<void> initLocalNotifications() async {
  const macOSSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  
  await _localNotifications.initialize(
    InitializationSettings(macOS: macOSSettings),
    onDidReceiveNotificationResponse: (details) {
      log('Notification tapped: ${details.payload}');
    },
  );
  
  // Request permissions
  await _localNotifications
      .resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin
      >()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
}
```

#### Hiển thị Notification
```dart
Future<void> _showLocalNotification(String title, String body, String payload) async {
  const macOSDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    sound: 'default',
  );

  await _localNotifications.show(
    DateTime.now().millisecond,
    title,
    body,
    NotificationDetails(macOS: macOSDetails),
    payload: payload,
  );
}
```

## Cách sử dụng

### Test Notification
1. Chạy app trên macOS
2. Click vào icon 🔔 (notifications_active) trên AppBar
3. Notification sẽ xuất hiện ở góc trên bên phải màn hình

### Trong Code
```dart
_showLocalNotification(
  'Incoming Call',
  'Call from +84123456789',
  'call_id_123',
);
```

## Lưu ý quan trọng

### ✅ Local Notifications có thể:
- Hiển thị thông báo khi app đang chạy (foreground)
- Hiển thị thông báo khi app đang ở background (nếu app chưa bị terminate)
- Phát âm thanh và hiển thị badge
- Xử lý khi user tap vào notification

### ❌ Local Notifications KHÔNG thể:
- Nhận push notifications từ server khi app đã bị terminate
- Đánh thức app từ trạng thái terminated
- Nhận notifications từ Firebase/APNs

## Giải pháp thay thế cho Push Notifications

Nếu cần nhận thông báo khi app không chạy, có thể:

1. **WebSocket/Polling**: Giữ kết nối realtime khi app đang chạy
2. **Background Service**: Chạy service trong background (giới hạn bởi macOS)
3. **iOS/Android**: Sử dụng FCM bình thường trên mobile platforms

## Kiểm tra Permissions

Vào **System Settings > Notifications** và tìm app của bạn để kiểm tra/bật notifications.

## Troubleshooting

### Không thấy notification
1. Kiểm tra System Settings > Notifications
2. Đảm bảo app có quyền hiển thị notifications
3. Kiểm tra logs để xem có lỗi không

### Permission bị từ chối
```dart
final granted = await _localNotifications
    .resolvePlatformSpecificImplementation<
      MacOSFlutterLocalNotificationsPlugin
    >()
    ?.requestPermissions(alert: true, badge: true, sound: true);
    
log("Notification permission: $granted");
```

## Platform Support Summary

| Platform | FCM Support | Local Notifications | Push từ Server |
|----------|-------------|---------------------|----------------|
| Android  | ✅ Yes      | ✅ Yes              | ✅ Yes         |
| iOS      | ✅ Yes      | ✅ Yes              | ✅ Yes         |
| macOS    | ❌ No       | ✅ Yes              | ❌ No          |
| Web      | ✅ Yes      | ⚠️ Limited          | ✅ Yes         |
| Windows  | ❌ No       | ✅ Yes              | ❌ No          |
| Linux    | ❌ No       | ✅ Yes              | ❌ No          |
