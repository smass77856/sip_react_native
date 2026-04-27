## Node.js FCM notification tester

Send a test Firebase Cloud Messaging notification (legacy HTTP API) without any dependencies.

### Prerequisites
- Node.js 16+
- FCM Legacy Server Key (Firebase Console → Project Settings → Cloud Messaging → Cloud Messaging API (Legacy))
- Target device token or a topic name

### Configure
Create a file named `.env` in this folder with content like:

```
SERVER_KEY=YOUR_FCM_LEGACY_SERVER_KEY

# Provide either DEVICE_TOKEN or TOPIC
DEVICE_TOKEN=YOUR_DEVICE_REGISTRATION_TOKEN
# TOPIC=test_topic

TITLE=Test Notification
BODY=Hello from Node.js FCM tester
# DATA_JSON={"foo":"bar","answer":42}
```

Tip: Device token can be printed in your Flutter app (see `HomePage.initDeviceTokenData`).

### Run

```
node send.js
```

Or with npm:

```
npm run send
```

### HTTP v1 (Service Account) sender

This method uses `firebase-admin` and your service account JSON (the file you shared like `sipvoip-...firebase-adminsdk-....json`).

1) Install dependencies (first time only):

```
cd /Volumes/ssd/Desktop/Sip/siprix_voip_sdk/example/notification_test
npm install
```

2) Set credentials and target, then send:

```
export GOOGLE_APPLICATION_CREDENTIALS="/Volumes/ssd/Desktop/Sip/siprix_voip_sdk/example/notification_test/sipvoip-4e692-firebase-adminsdk-fbsvc-bc2c440d4b.json"
export DEVICE_TOKEN="YOUR_DEVICE_REGISTRATION_TOKEN"
# Optional: PRESET=android_incoming_call, TITLE, BODY, DATA_JSON, NOTIFICATION_DISABLED=1

npm run send:v1
```

3) For topics instead of device tokens:

```
unset DEVICE_TOKEN
export TOPIC="test_topic"
npm run send:v1
```

## End-to-end call flow (bao gồm Backend)

### Android (FCM data-only + SIP INVITE)
1) App khởi động
   - Firebase init, đăng ký `onMessage` + background handler
   - Siprix init, load accounts từ SharedPreferences
   - Khi thêm tài khoản: app gắn `X-Token = <FCM token>` vào SIP REGISTER
2) Backend (BE)
   - Lưu `X-Token` theo account/extension
   - Khi có cuộc gọi đến: gửi FCM data-only (ví dụ preset `android_incoming_call`) tới token để “đánh thức” app
3) Client nhận FCM
   - Foreground: `onMessage` xử lý
   - Background: handler gọi `_initializeSiprix()`, load accounts và `refreshRegistration()`
4) SIP server gửi SIP INVITE tới app (UA)
   - SDK nhận INVITE, hiển thị UI gọi (tab Calls)
   - Media RTP thiết lập sau 200 OK/ACK

Gợi ý payload FCM (data-only): dùng `.env` với `PRESET=android_incoming_call` hoặc `DATA_JSON={...}` và `NOTIFICATION_DISABLED=1` để tránh notification hiển thị mặc định.

### iOS (APNs VoIP + SIP INVITE + CallKit matching)
1) App khởi động
   - Siprix bật CallKit + PushKit, lấy PushKit token bằng `SiprixVoipSdk().getPushKitToken()`
   - Khi thêm tài khoản: gửi/ghi PushKit token để BE lưu
2) Backend (BE)
   - Lưu PushKit token theo account
   - Khi có cuộc gọi đến: gửi APNs VoIP push (payload trong `aps`) chứa `pushHint`, `callerNumber`, `callerName`, `withVideo`
3) Client nhận VoIP push
   - `onIncomingPush` mở CallKit UI, lưu `callkit_CallUUID` và `pushHint`
4) SIP server gửi INVITE (có header `X-PushHint` trùng với push)
   - SDK lấy `X-PushHint`, ghép với CallKit call và cập nhật `callId` vào CallKit

Payload APNs VoIP tham khảo (không gửi bằng script này):
```json
{
  "aps": {
    "pushHint": "demo-hint-123",
    "callerNumber": "1001",
    "callerName": "John Doe",
    "withVideo": false
  }
}
```

### Trách nhiệm Backend (tóm tắt)
- SIP/VoIP: xử lý REGISTER, lưu token (FCM/PushKit), phát INVITE tới UA; iOS thêm `X-PushHint` vào INVITE
- Push service: Android gửi FCM data-only; iOS gửi APNs VoIP tới PushKit token
- Bảo mật: ánh xạ token ↔ account an toàn, bảo vệ credentials, rotate khi cần

### Incoming-call payloads

Android (FCM data-only recommended to just wake the app; the SIP server should place the actual SIP INVITE):

Use preset:

```
# .env
SERVER_KEY=YOUR_FCM_LEGACY_SERVER_KEY
DEVICE_TOKEN=YOUR_DEVICE_REGISTRATION_TOKEN
PRESET=android_incoming_call
NOTIFICATION_DISABLED=1
```

Or craft your own data:

```
# .env
SERVER_KEY=YOUR_FCM_LEGACY_SERVER_KEY
DEVICE_TOKEN=YOUR_DEVICE_REGISTRATION_TOKEN
NOTIFICATION_DISABLED=1
DATA_JSON={"action":"incoming_call","callerName":"John Doe","callerNumber":"1001","withVideo":"false","pushHint":"demo-hint-123"}
```

Notes:
- This example sends keys under `data`. Your Flutter code can read them from `message.data` if needed.
- Siprix SDK mainly needs the push to wake the app; actual call flows via SIP after the app refreshes registration.

iOS (PushKit / APNs VoIP):

- The app’s iOS logic in `AppCallsModel.onIncomingPush` expects payload fields inside `aps`:

```json
{
  "aps": {
    "pushHint": "demo-hint-123",
    "callerNumber": "1001",
    "callerName": "John Doe",
    "withVideo": false
  }
}
```

- This script does NOT send APNs VoIP pushes. To test iOS incoming calls you must send a VoIP push via APNs using your VoIP certificate/key and the device’s PushKit token (obtained by `SiprixVoipSdk().getPushKitToken()`), not the FCM token.

### Notes
- This uses FCM Legacy API for simplicity. For production, prefer FCM HTTP v1 with OAuth2 service accounts.
- For topics, comment `DEVICE_TOKEN` and set `TOPIC` to your topic name.


