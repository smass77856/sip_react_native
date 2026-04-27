
const admin = require('firebase-admin');
require('dotenv').config({ path: require('path').resolve(__dirname, '.env') });

function env(name, required = false) {
  const v = process.env[name];
  if (required && (!v || v.trim() === '')) {
    console.error(`Missing environment variable: ${name}`);
    process.exit(1);
  }
  return v;
}

function getDataPreset(preset) {
  if (preset === 'android_incoming_call') {
    return {
      action: 'incoming_call',
      callerName: 'John Doe',
      callerNumber: '1001',
      withVideo: 'false',
      pushHint: 'demo-hint-123',
    };
  }
  if (preset === 'android_wakeup') {
    return { action: 'wake' };
  }
  return undefined;
}

function buildMessage() {
  // Hard-code device token để test wake ứng dụng
  const deviceToken =
    'fdmcevdpTKOcBzt0H7Whxz:APA91bELgkjdvzNiiAPyisX8UjX6wClaDlTlSUmFokwUsfU0bdiCn-tLeEXoam4Af9qZ-NVZw6yXZt3CTxNU_occ-ps7f6NJkLwbYBQN_DwQfARye7WCqNo';

  // Payload chỉ để wake app, không hiển thị notification
  const data = {
    action: 'wake',
    wake: '1',
  };

  const message = {
    token: deviceToken,
    data,
    // ưu tiên cao để FCM cố gắng deliver + wake service
    android: {
      priority: 'high',
    },
  };

  return message;
}

async function main() {
  // Initialize admin with ADC (Application Default Credentials)
  try {
    const credential = admin.credential.applicationDefault();
    admin.initializeApp({
      credential,
    });
    const { access_token } = await credential.getAccessToken();
    console.log('[FCM v1] Access token:', access_token);
  } catch (e) {
    console.error('Failed to initialize firebase-admin. Ensure GOOGLE_APPLICATION_CREDENTIALS is set.');
    console.error(e);
    process.exit(1);
  }

  const msg = buildMessage();
  try {
    const id = await admin.messaging().send(msg, false);
    console.log('[FCM v1] Message sent:', id);
  } catch (err) {
    console.error('[FCM v1] Send error:', err);
    process.exitCode = 1;
  }
}

main();


