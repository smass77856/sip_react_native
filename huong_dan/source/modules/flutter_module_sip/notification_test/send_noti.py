import os
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, messaging

from dotenv import load_dotenv

# Load file .env nằm cùng thư mục với script
BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / '.env')


def env(name, required=False):
    v = os.getenv(name)
    if required and (not v or v.strip() == ''):
        print(f"Missing environment variable: {name}")
        raise SystemExit(1)
    return v


def get_data_preset(preset):
    if preset == 'android_incoming_call':
        return {
            'action': 'incoming_call',
            'callerName': 'John Doe',
            'callerNumber': '1001',
            'withVideo': 'false',
            'pushHint': 'demo-hint-123',
        }
    if preset == 'android_wakeup':
        return {'action': 'wake'}
    return None


def build_message():
    # Hard-code device token để test incoming call wake
    device_token = (
        'cHo6MRyxT2S6X4xmmSfYJ8:APA91bG1gxBZWE39lnkx0vMPKGVCGemLWE16gAAkCn3I-LA71YY2xrWtJPnOUfSV8w97o7XDrFliKHSwgbFObxOK5AYDEqSzsDmilMjn0TTNEUaRSSjzoWw'
    )

    # Payload incoming call giống server thực tế
    data = get_data_preset('android_incoming_call')
    if not data:
        raise ValueError("Missing preset 'android_incoming_call'")

    message = messaging.Message(
        token=device_token,
        data=data,
        android=messaging.AndroidConfig(
            priority='high',
        ),
    )

    return message


def main():
    # Initialize admin with ADC (Application Default Credentials)
    try:
        cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred)

        # Lấy access token để log giống bản JS
        access_token_info = cred.get_access_token()
        access_token = getattr(access_token_info, 'access_token', str(access_token_info))
        print('[FCM v1] Access token:', access_token)
    except Exception as e:
        print('Failed to initialize firebase-admin. Ensure GOOGLE_APPLICATION_CREDENTIALS is set.')
        print(e)
        raise SystemExit(1)

    msg = build_message()
    try:
        # dry_run=False giống tham số thứ 2 trong admin.messaging().send(msg, false)
        message_id = messaging.send(msg, dry_run=False)
        print('[FCM v1] Message sent:', message_id)
    except Exception as err:
        print('[FCM v1] Send error:', err)
        raise SystemExit(1)


if __name__ == '__main__':
    main()