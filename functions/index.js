/**
 * [SM종합관리 서버 기능 정의서 - 최적화 완료 버전]
 * 1. optimizeUploadedImage: 사진 업로드 시 800x800 리사이징 (기존 기능 100% 유지)
 * 2. sendPushNotification: 다중 사용자 환경 대응 및 유효하지 않은 토큰 자동 청소 고도화
 * 🌟 [핵심 고도화] PWA(웹) 및 안드로이드 절전모드 완벽 돌파 (소리/진동 강제 적용)
 * 🌟 [경로 고도화] 공지사항, 업무보고 클릭 시 해당 페이지로 정확히 꽂히도록 라우팅 추가
 */

const { onObjectFinalized } = require("firebase-functions/v2/storage");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2/options");
const admin = require("firebase-admin");
const spawn = require("child-process-promise").spawn;
const path = require("path");
const os = require("os");
const fs = require("fs");

admin.initializeApp();

// 전역 설정 (서울 리전 고정)
setGlobalOptions({ region: "asia-northeast3", memory: "1GiB" });

// ============================================================
// ✅ [기능 1] 사진 변환 비서 (기존 기능 100% 유지)
// ============================================================
exports.optimizeUploadedImage = onObjectFinalized(async (event) => {
    const object = event.data;
    const fileBucket = object.bucket;
    const filePath = object.name;
    const contentType = object.contentType;

    if (!contentType.startsWith('image/') || filePath.includes('_800x800')) {
        return console.log('처리 대상 아님.');
    }

    const fileName = path.basename(filePath);
    const fileDir = path.dirname(filePath);
    const fileNameWithoutExt = path.parse(fileName).name;
    const newFileName = `${fileNameWithoutExt}_800x800.jpg`;
    const newFilePath = path.join(fileDir, newFileName);

    const bucket = admin.storage().bucket(fileBucket);
    const tempFilePath = path.join(os.tmpdir(), fileName);
    const tempNewFilePath = path.join(os.tmpdir(), newFileName);

    await bucket.file(filePath).download({ destination: tempFilePath });

    await spawn('convert', [
        tempFilePath,
        '-auto-orient',
        '-resize', '800x800>',
        tempNewFilePath
    ]);

    await bucket.upload(tempNewFilePath, {
        destination: newFilePath,
        metadata: { contentType: 'image/jpeg' },
    });

    fs.unlinkSync(tempFilePath);
    fs.unlinkSync(tempNewFilePath);
});


// ============================================================
// ✅ [기능 2] 알림 발송 및 자동 토큰 청소 (WebPush & Android 고도화 버전)
// ============================================================
exports.sendPushNotification = onDocumentCreated("notifications/{docId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    const targetUid = data.targetUid; // 알림 받을 사람

    if (!targetUid) {
        console.log("타겟 UID가 없습니다.");
        return;
    }

    try {
        // 1. 유저 정보 및 토큰 가져오기
        const userDoc = await admin.firestore().collection("users").doc(targetUid).get();

        if (!userDoc.exists) {
            console.log(`유저(${targetUid}) 정보 없음.`);
            return;
        }

        const userData = userDoc.data();
        const userToken = userData.fcmToken;

        if (!userToken) {
            console.log(`[PASS] 유저(${targetUid})의 토큰 없음.`);
            return;
        }

        // 🛑 [검문소] 사용자 개별 설정 확인 (기본값 true)
        const allowChat = userData.allowChatPush !== false;
        const allowSchedule = userData.allowSchedulePush !== false;
        const allowNotice = userData.allowNoticePush !== false;
        const isSoundEnabled = userData.isSound !== false;

        const msgType = data.type || "default";

        // 타입별 발송 차단 로직 (중복 제거 및 최적화)
        if (msgType === 'chat' && !allowChat) return console.log(`🚫 업무톡톡 거부: ${targetUid}`);
        if (msgType === 'schedule' && !allowSchedule) return console.log(`🚫 일정알림 거부: ${targetUid}`);
        if (msgType === 'notice' && !allowNotice) return console.log(`🚫 공지사항 거부: ${targetUid}`);

        // 🌟 [핵심 고도화] 클릭 시 이동할 URL 경로 설정 (공지사항, 업무보고 등 전체 확장)
        let targetUrl = '/#/'; // 기본 홈 화면
        if (msgType === 'chat') targetUrl = '/#/chat';
        else if (msgType === 'schedule') targetUrl = '/#/schedule';
        else if (msgType === 'notice') targetUrl = '/#/notice';
        else if (msgType === 'report') targetUrl = '/#/report';

        // 2. 메시지 구성 (🌟 PWA 및 안드로이드 절전모드 완벽 대응)
        const payload = {
            token: userToken,
            // 🌟 [핵심 1] 브라우저/OS가 시스템 권한으로 직접 알림을 띄우게 함 (Data-Only 탈피)
            notification: {
                title: data.title || "알림",
                body: data.body || "내용이 없습니다."
            },
            // 기존 Data 유지 (클릭 시 이동 등 내부 처리용)
            data: {
                type: msgType,
                notificationId: event.params.docId,
                url: targetUrl
            },
            // 🌟 [핵심 2] 안드로이드 절전모드(Doze) 격파 및 소리 강제 설정
            android: {
                priority: "high",
                notification: {
                    channelId: "high_importance_channel", // (선택) 앱 개발 시 사용할 채널
                    sound: isSoundEnabled ? "default" : undefined,
                    clickAction: "FLUTTER_NOTIFICATION_CLICK"
                }
            },
            // [기존 유지] iOS 네이티브 앱용 (추후 앱 출시 대비)
            apns: {
                payload: {
                    aps: {
                        contentAvailable: true,
                        ...(isSoundEnabled && { sound: "default" }),
                        badge: 1
                    },
                },
            },
            // 🌟 [핵심 3] 웹 브라우저(PWA) 전용 강제 진동, 소리, 깨우기 세팅
            webpush: {
                headers: {
                    Urgency: "high" // 브라우저 배터리 최적화 무시하고 즉시 발송
                },
                notification: {
                    icon: "/icons/Icon-192.png", // PWA 알림 아이콘
                    badge: "/icons/Icon-192.png",
                    requireInteraction: true, // 사용자가 닫기 전까지 화면에 남겨둠
                    // 사용자가 소리 알림을 켜두었을 때만 진동/소리 적용
                    ...(isSoundEnabled && {
                        sound: "default",
                        vibrate: [200, 100, 200, 100, 200] // 징- 징- 징- 패턴
                    }),
                    data: {
                        url: targetUrl // 서비스 워커에서 클릭 시 이동할 주소
                    }
                }
            }
        };

        // 3. 발송 및 성공 로그
        await admin.messaging().send(payload);
        console.log(`✅ 발송 성공: ${targetUid} (Type: ${msgType}, Sound: ${isSoundEnabled})`);

    } catch (error) {
        console.error("❌ 발송 실패 상세:", error);

        // ✅ [고도화] 유효하지 않은 토큰인 경우 DB에서 자동 삭제 (청소 기능)
        if (error.code === 'messaging/invalid-registration-token' ||
            error.code === 'messaging/registration-token-not-registered') {

            await admin.firestore().collection("users").doc(targetUid).update({
                fcmToken: admin.firestore.FieldValue.delete()
            });
            console.log(`🧹 토큰 청소 완료: 유저(${targetUid})의 만료된 토큰을 제거했습니다.`);
        }
    }
});