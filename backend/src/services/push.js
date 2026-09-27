// 모바일 앱 푸시 알림 (FCM) 담당 서비스
// FCM_SERVER_KEY가 없으면 콘솔 로그만 남기고 넘어간다 (개발 단계에서는 이걸로 충분)

async function sendPushNotification({ title, body, data }) {
  const serverKey = process.env.FCM_SERVER_KEY;

  if (!serverKey) {
    console.log('[FCM mock] 푸시 알림 (실제 전송 안 됨):', { title, body, data });
    return { mocked: true };
  }

  // 실제 FCM 연동 시 여기에 fetch/axios로 FCM API 호출 로직 작성
  // https://firebase.google.com/docs/cloud-messaging/send-message
  console.log('[FCM] 실제 전송 로직은 FCM_SERVER_KEY 발급 후 구현하세요.');
  return { mocked: false };
}

module.exports = { sendPushNotification };
