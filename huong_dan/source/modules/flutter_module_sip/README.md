# Siprix VoIP SDK Example

Ứng dụng VoIP (Voice over IP) được xây dựng bằng Flutter, sử dụng Siprix VoIP SDK để thực hiện các cuộc gọi SIP.

- [Manual](https://docs.siprix-voip.com/rst/flutter.html)

---

## 🏗️ CẤU TRÚC PROJECT

### Công nghệ sử dụng
- **Flutter SDK** (Dart 3.7.2+)
- **Siprix VoIP SDK** - thư viện chính để xử lý SIP protocol
- **Provider** - quản lý state
- **Firebase** (FCM & PushKit) - nhận push notifications cho incoming calls
- **SharedPreferences** - lưu trữ dữ liệu local

### Các Model chính
```
├── AppAccountsModel - Quản lý tài khoản SIP
├── AppCallsModel - Quản lý cuộc gọi
├── MessagesModel - Quản lý tin nhắn SIP
├── SubscriptionsModel - Quản lý BLF (Busy Lamp Field)
├── CdrsModel - Lịch sử cuộc gọi (Call Detail Records)
├── DevicesModel - Quản lý thiết bị audio/video
├── NetworkModel - Theo dõi trạng thái mạng
└── LogsModel - Ghi log debug
```

### Các màn hình UI
```
├── HomePage - Màn hình chính với 5 tabs
│   ├── AccountsListPage - Danh sách tài khoản SIP
│   ├── CallsListPage - Danh sách cuộc gọi đang diễn ra
│   ├── SubscrListPage - Danh sách BLF subscriptions
│   ├── MessagesListPage - Tin nhắn SIP
│   └── LogsPage - Logs debug
├── AccountPage - Thêm/sửa tài khoản
├── CallAddPage - Thực hiện cuộc gọi mới
├── SubscrAddPage - Thêm subscription
└── SettingsPage - Cài đặt thiết bị
```

---

## 🔄 LUỒNG HOẠT ĐỘNG CHI TIẾT

### A. KHỞI ĐỘNG ỨNG DỤNG

```
1. main() → Khởi tạo Firebase
2. Tạo các Model (Accounts, Calls, Messages, etc.)
3. Khởi tạo Siprix SDK với license key
4. Đọc dữ liệu đã lưu từ SharedPreferences
5. Load accounts, subscriptions, CDRs, messages
6. Hiển thị HomePage
```

**Code flow:**
```dart
main() 
  → Firebase.initializeApp()
  → Tạo các Model instances
  → runApp(MultiProvider)
  → _MyAppState.initState()
  → _initializeSiprix() // Khởi tạo SDK
  → _readSavedState() // Đọc dữ liệu đã lưu
  → _loadModels() // Load accounts, messages, etc.
```

---

### B. QUẢN LÝ TÀI KHOẢN SIP

#### Thêm tài khoản
```
User nhập thông tin → AccountPage
  ├── SIP Server (domain)
  ├── Extension (username)
  ├── Password
  ├── Transport (UDP/TCP/TLS)
  └── Các cài đặt nâng cao (codecs, STUN/TURN, etc.)

→ Submit → AppAccountsModel.addAccount()
  → Lấy Push Token (iOS: PushKit, Android: FCM)
  → Thêm token vào SIP header (X-Token)
  → Gọi Siprix SDK để register
  → Lưu vào SharedPreferences
```

#### Trạng thái đăng ký
```
RegState.inProgress → Đang đăng ký
RegState.success → Đăng ký thành công (hiển thị icon xanh)
RegState.failed → Đăng ký thất bại (hiển thị icon đỏ)
```

---

### C. THỰC HIỆN CUỘC GỌI (OUTGOING CALL)

```
1. User chọn account từ dropdown
2. Nhập số điện thoại
3. Nhấn nút gọi (audio/video)

→ CallAddPage._invite()
  → Tạo CallDestination(phoneNumber, accountId, withVideo)
  → AppCallsModel.invite(dest)
  → Siprix SDK gửi SIP INVITE
  → Tạo CallModel mới
  → Chuyển sang CallsListPage
  → Hiển thị SwitchedCallWidget với controls
```

**Các trạng thái cuộc gọi:**
```
CallState.inviting → Đang gọi
CallState.ringing → Đổ chuông
CallState.connected → Đã kết nối
CallState.holding → Đang hold
CallState.held → Bị hold bởi remote
CallState.disconnecting → Đang ngắt
```

---

### D. NHẬN CUỘC GỌI (INCOMING CALL)

#### Luồng iOS (với PushKit)
```
1. Server gửi Push Notification
   → iOS PushKit nhận notification
   → onIncomingPush() được gọi
   → Parse payload (callerNumber, callerName, pushHint)
   → Cập nhật CallKit UI
   → Lưu CallMatcher (map giữa CallKit UUID và pushHint)

2. SIP INVITE đến
   → onIncomingSip() được gọi
   → Lấy X-PushHint từ SIP header
   → Match với CallMatcher đã lưu
   → Cập nhật CallKit với callId thực
   → Hiển thị UI Accept/Reject
```

#### Luồng Android (với FCM)
```
1. FCM nhận notification
2. SIP INVITE đến
   → onIncomingSip() được gọi
   → Tạo CallModel mới
   → Hiển thị notification
   → Chuyển sang CallsListPage
   → Hiển thị nút Accept/Reject
```

---

### E. QUẢN LÝ CUỘC GỌI

**Các chức năng trong cuộc gọi:**

```
1. Mute/Unmute Mic → CallModel.muteMic()
2. Mute/Unmute Camera → CallModel.muteCam()
3. Hold/Resume → CallModel.hold()
4. Send DTMF → CallModel.sendDtmf(tone)
5. Play file → CallModel.playFile(path)
6. Record → CallModel.recordFile(path)
7. Transfer Blind → CallModel.transferBlind(ext)
8. Transfer Attended → CallModel.transferAttended(toCallId)
9. Hangup → CallModel.bye()
```

**Video call:**
```
- Sử dụng SiprixVideoRenderer
- _localRenderer → Hiển thị camera preview
- _remoteRenderer → Hiển thị video từ remote
```

---

### F. TIN NHẮN SIP (MESSAGES)

```
1. User chọn account
2. Nhập số điện thoại đích
3. Nhập nội dung tin nhắn
4. Nhấn Send

→ MessagesModel.send()
  → Tạo MessageDestination
  → Siprix SDK gửi SIP MESSAGE
  → Lưu vào danh sách
  → Cập nhật UI với trạng thái sent
```

**Nhận tin nhắn:**
```
SIP MESSAGE đến
  → MessagesModel nhận event
  → Tạo MessageModel mới
  → Hiển thị trong MessagesListPage
```

---

### G. BLF SUBSCRIPTIONS (Busy Lamp Field)

```
1. User thêm subscription
   → Nhập extension cần theo dõi
   → Chọn account

2. AppBlfSubscrModel.subscribe()
   → Gửi SIP SUBSCRIBE request
   → Server trả về NOTIFY với XML body
   → Parse XML để lấy state (trying, confirmed, terminated, etc.)
   → Cập nhật UI với màu sắc tương ứng
```

**Các trạng thái BLF:**
```
BLFState.trying → Đang gọi
BLFState.confirmed → Đang trong cuộc gọi
BLFState.terminated → Rảnh
BLFState.early → Đổ chuông
```

---

### H. LƯU TRỮ DỮ LIỆU

**SharedPreferences lưu:**
```
- 'accounts' → JSON của tất cả accounts
- 'subscriptions' → JSON của subscriptions
- 'cdrs' → Lịch sử cuộc gọi
- 'msgs' → Tin nhắn
```

**Callback khi có thay đổi:**
```
Model thay đổi
  → onSaveChanges callback
  → Serialize to JSON
  → SharedPreferences.setString()
```

---

### I. PUSH NOTIFICATIONS

**iOS (PushKit):**
```
1. App lấy PushKit token
2. Gửi token trong SIP REGISTER (X-Token header)
3. Server lưu token
4. Khi có incoming call → Server gửi push
5. App wake up → Hiển thị CallKit
6. SIP INVITE đến → Match với CallKit call
```

**Android (FCM):**
```
1. App lấy FCM token
2. Gửi token trong SIP REGISTER
3. Server gửi FCM notification
4. App wake up → Hiển thị notification
5. User tap → Mở app → Accept/Reject call
```

---

### I.1. CHI TIẾT XỬ LÝ PUSH NOTIFICATION iOS (onIncomingPush)

#### 🎯 Mục đích
Xử lý push notification trên iOS khi có cuộc gọi đến. Push thường đến **trước** SIP INVITE để đánh thức app.

#### 📋 Luồng xử lý đầy đủ

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Server gửi Push Notification                            │
│    Payload: {pushHint: "call-123", callerName: "John"}     │
└─────────────────────┬───────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. onIncomingPush() được gọi                                │
│    Parameters:                                              │
│    - callkit_CallUUID: UUID do iOS CallKit tạo             │
│    - pushPayload: Dữ liệu từ push notification             │
└─────────────────────┬───────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Parse payload từ push                                    │
│    - pushHint: "call-123" (ID để match với SIP)            │
│    - callerNumber: "0901234567"                             │
│    - callerName: "Nguyễn Văn A"                             │
│    - withVideo: true/false                                  │
└─────────────────────┬───────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Kiểm tra SIP INVITE đã đến chưa                          │
│    Tìm trong _callMatchers với pushHint                     │
│                                                             │
│    Case 1: SIP đã đến trước (hiếm)                          │
│    → Lấy sipCallId từ CallMatcher                           │
│                                                             │
│    Case 2: Push đến trước (thường gặp)                      │
│    → Tạo CallMatcher mới(callkit_UUID, pushHint, 0)        │
│    → Đợi SIP INVITE đến sau                                 │
└─────────────────────┬───────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Cập nhật CallKit UI                                      │
│    updateCallKitCallDetails(                                │
│      callkit_UUID,                                          │
│      sipCallId,           // null nếu SIP chưa đến          │
│      "Nguyễn Văn A",      // Tên hiển thị                   │
│      "0901234567",        // Số điện thoại                   │
│      withVideo            // true/false                     │
│    )                                                        │
└─────────────────────┬───────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. iOS hiển thị màn hình incoming call                      │
│    "Nguyễn Văn A đang gọi..."                               │
│    [Từ chối]  [Chấp nhận]                                   │
└─────────────────────┬───────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. SIP INVITE đến (sau 1-3 giây)                            │
│    Header: X-PushHint: "call-123"                           │
└─────────────────────┬───────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────┐
│ 8. onIncomingSip() được gọi                                 │
│    - Lấy pushHint = "call-123" từ SIP header                │
│    - Tìm CallMatcher với pushHint = "call-123"              │
│    - Cập nhật CallMatcher.sip_CallId = 456                  │
│    - Cập nhật CallKit với callId thực                       │
│    - MATCH THÀNH CÔNG!                                      │
└─────────────────────────────────────────────────────────────┘
```

#### 🔧 CallMatcher Structure

```dart
class CallMatcher {
  String callkit_CallUUID;  // "ABC-123-XYZ" (do iOS CallKit tạo)
  String push_Hint;         // "call-123" (do server gửi trong push)
  int sip_CallId;           // 456 (do Siprix SDK tạo khi SIP đến)
}
```

**Lifecycle của CallMatcher:**
```
1. onIncomingPush()  → Tạo CallMatcher(UUID, "call-123", 0)
2. onIncomingSip()   → Cập nhật sip_CallId = 456
3. User accept/reject → Xử lý cuộc gọi
4. onTerminated()    → Xóa CallMatcher khỏi _callMatchers list
```

#### 💡 Tại sao cần Matching?

**Vấn đề:** iOS CallKit và SIP là 2 hệ thống riêng biệt:
- CallKit có UUID riêng (do iOS tạo): `"ABC-123-XYZ"`
- SIP có callId riêng (do Siprix SDK tạo): `456`

**Giải pháp:** Dùng `pushHint` làm "cầu nối":
```
CallKit UUID: "ABC-123-XYZ"  ←─┐
                                ├─ pushHint: "call-123"
SIP callId: 456              ←─┘
```

Nhờ đó app biết CallKit call nào tương ứng với SIP call nào.

#### 📦 Ví dụ Push Payload từ Server

```json
{
  "aps": {
    "pushHint": "call-12345",        // ID unique để match
    "callerNumber": "0901234567",    // Số điện thoại người gọi
    "callerName": "Nguyễn Văn A",    // Tên người gọi
    "withVideo": true                // Có video hay không
  }
}
```

#### 🔧 Cấu hình Server SIP

Server cần thực hiện:

1. **Lưu PushKit token** khi nhận SIP REGISTER:
   ```
   REGISTER sip:domain.com
   X-Token: <pushkit-token>
   ```

2. **Gửi push notification** khi có incoming call:
   ```json
   {
     "aps": {
       "pushHint": "unique-call-id",
       "callerNumber": "phone",
       "callerName": "name",
       "withVideo": false
     }
   }
   ```

3. **Thêm header vào SIP INVITE**:
   ```
   INVITE sip:user@domain.com
   X-PushHint: unique-call-id
   ```

#### ⚠️ Lưu ý quan trọng

1. **Chỉ dành cho iOS**: Android không sử dụng hàm này
2. **Server phải hỗ trợ**: Server SIP cần gửi `pushHint` trong cả push và SIP header
3. **Matching là bắt buộc**: Không match được = không nhận cuộc gọi đúng
4. **Timing**: Push thường đến trước SIP 1-3 giây
5. **Unique pushHint**: Mỗi cuộc gọi phải có pushHint unique để tránh nhầm lẫn

---

### J. THIẾT BỊ AUDIO/VIDEO

```
DevicesModel.load()
  → Lấy danh sách:
    - Playout devices (loa)
    - Recording devices (mic)
    - Video devices (camera)
  → User chọn trong SettingsPage
  → setPlayoutDevice() / setRecordingDevice() / setVideoDevice()
```

---

## 🎯 TÍNH NĂNG CHÍNH

1. **Multi-platform**: Hỗ trợ iOS, Android, macOS, Linux, Windows
2. **CallKit integration** (iOS): Tích hợp với hệ thống gọi native
3. **Push notifications**: Wake app khi có incoming call
4. **Video calls**: Hỗ trợ video với camera preview
5. **Multiple calls**: Quản lý nhiều cuộc gọi đồng thời, hold/resume, transfer
6. **SIP features**: DTMF, recording, file playback, secure media (SRTP)
7. **BLF monitoring**: Theo dõi trạng thái của extensions khác

---

## 📝 TÓM TẮT LUỒNG CHÍNH

```
Khởi động → Load accounts → Register SIP
                ↓
        Chờ incoming/outgoing calls
                ↓
    ┌───────────┴───────────┐
    ↓                       ↓
Incoming Call          Outgoing Call
    ↓                       ↓
Accept/Reject          Ringing → Connected
    ↓                       ↓
Connected              Manage call
    ↓                       ↓
Manage call            Hangup
    ↓
Hangup → Save CDR
```

---

## 🚀 HƯỚNG DẪN SỬ DỤNG

1. **Cài đặt dependencies:**
   ```bash
   flutter pub get
   ```

2. **Cấu hình Firebase** (cho push notifications):
   - Thêm `google-services.json` (Android)
   - Thêm `GoogleService-Info.plist` (iOS)
   - Cập nhật `firebase_options.dart`

3. **Cập nhật license key** trong `lib/main.dart`:
   ```dart
   iniData.license = "YOUR_LICENSE_KEY";
   ```

4. **Chạy ứng dụng:**
   ```bash
   flutter run
   ```

---

## 📂 CẤU TRÚC FILE

```
lib/
├── main.dart                 # Entry point, khởi tạo app
├── home.dart                 # Màn hình chính với tabs
├── accouns_model_app.dart    # Model quản lý accounts
├── accounts_list.dart        # UI danh sách accounts
├── account_add.dart          # UI thêm/sửa account
├── calls_model_app.dart      # Model quản lý calls
├── calls_list.dart           # UI danh sách calls
├── call_add.dart             # UI thực hiện cuộc gọi
├── subscr_model_app.dart     # Model quản lý BLF subscriptions
├── subscr_list.dart          # UI danh sách subscriptions
├── subscr_add.dart           # UI thêm subscription
├── messages.dart             # UI tin nhắn SIP
├── settings.dart             # UI cài đặt
└── firebase_options.dart     # Cấu hình Firebase
```
powershell -ExecutionPolicy Bypass -File build_release.ps1