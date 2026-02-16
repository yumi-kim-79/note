/**
 * [SM종합관리 서버 기능 정의서 - 최적화 완료 버전]
 * 1. optimizeUploadedImage: 사진 업로드 시 800x800 리사이징 (기존 기능 100% 유지)
 * 2. sendPushNotification: 다중 사용자 환경 대응 및 유효하지 않은 토큰 자동 청소 고도화
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
// ✅ [기능 2] 알림 발송 및 자동 토큰 청소 (고도화 버전)
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

        // 2. 메시지 구성 (Data-Only로 웹 중복 방지)
        const payload = {
            token: userToken,
            data: {
                title: data.title || "알림",
                body: data.body || "내용이 없습니다.",
                type: msgType,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                notificationId: event.params.docId
            },
            android: { priority: "high" },
            apns: {
                payload: {
                    aps: {
                        contentAvailable: true,
                        alert: { title: data.title, body: data.body },
                        ...(isSoundEnabled && { sound: "default" }),
                        badge: 1
                    },
                },
            },
        };

        // 3. 발송 및 성공 로그
        await admin.messaging().send(payload);
        console.log(`✅ 발송 성공: ${targetUid} (Type: ${msgType})`);

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