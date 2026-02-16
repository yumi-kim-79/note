/**
 * [SM종합관리 서버 기능 정의서 - 최종 완성 버전]
 * 1. optimizeUploadedImage: 사진 업로드 시 800x800 리사이징 (기존 기능 100% 유지)
 * 2. sendPushNotification: 사용자 설정(알림 켜기/끄기, 소리 등)을 확인하고 발송하는 똑똑한 알림 시스템
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

// 전역 설정 (서울 리전)
setGlobalOptions({ region: "asia-northeast3", memory: "1GiB" });

// ============================================================
// ✅ [기능 1] 사진 변환 비서 (기존 기능 100% 유지)
// 코드를 건드리지 않았습니다. 기존과 동일하게 작동합니다.
// ============================================================
exports.optimizeUploadedImage = onObjectFinalized(async (event) => {
    const object = event.data;
    const fileBucket = object.bucket;
    const filePath = object.name;
    const contentType = object.contentType;

    // 1. 처리 대상 확인
    if (!contentType.startsWith('image/') || filePath.includes('_800x800')) {
        return console.log('처리 대상 아님 (이미 처리되었거나 이미지가 아님).');
    }

    // 2. 경로 설정
    const fileName = path.basename(filePath);
    const fileDir = path.dirname(filePath);
    const fileNameWithoutExt = path.parse(fileName).name;
    const newFileName = `${fileNameWithoutExt}_800x800.jpg`;
    const newFilePath = path.join(fileDir, newFileName);

    // 3. 임시 경로
    const bucket = admin.storage().bucket(fileBucket);
    const tempFilePath = path.join(os.tmpdir(), fileName);
    const tempNewFilePath = path.join(os.tmpdir(), newFileName);

    // 4. 다운로드
    await bucket.file(filePath).download({ destination: tempFilePath });

    // 5. 변환
    await spawn('convert', [
        tempFilePath,
        '-auto-orient',
        '-resize', '800x800>',
        tempNewFilePath
    ]);

    // 6. 업로드
    await bucket.upload(tempNewFilePath, {
        destination: newFilePath,
        metadata: { contentType: 'image/jpeg' },
    });

    // 7. 청소
    fs.unlinkSync(tempFilePath);
    fs.unlinkSync(tempNewFilePath);
});


// ============================================================
// ✅ [기능 2] 알림 중복 방지 및 사용자 설정 연동 (핵심 고도화)
// 설명: DB에 알림이 생성되면 -> 사용자의 설정(알림 끄기 등)을 확인 후 -> 조건에 맞을 때만 발송
// ============================================================
exports.sendPushNotification = onDocumentCreated("notifications/{docId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return; // 데이터가 없으면 종료

    const data = snapshot.data();
    const targetUid = data.targetUid; // 알림 받을 사람의 UID

    if (!targetUid) {
        console.log("타겟 UID가 없습니다.");
        return;
    }

    try {
        // 1. 받을 사람의 정보(토큰 + 설정값) 가져오기
        const userDoc = await admin.firestore().collection("users").doc(targetUid).get();

        // 유저 정보가 없으면 중단
        if (!userDoc.exists) {
            console.log(`유저(${targetUid}) 정보가 존재하지 않습니다.`);
            return;
        }

        const userData = userDoc.data();
        const userToken = userData.fcmToken;

        // 토큰이 없으면 중단
        if (!userToken) {
            console.log(`[PASS] 유저(${targetUid})의 FCM 토큰이 없습니다.`);
            return;
        }

        // 🛑 [설정 검문소] 사용자가 알림을 껐는지 확인
        // 값이 없으면(undefined) 기본적으로 '받음(true)'으로 처리합니다.
        const allowChat = userData.allowChatPush !== false;      // 업무 톡톡 설정
        const allowSchedule = userData.allowSchedulePush !== false; // 일정 관리 설정

        // 메시지 타입 확인
        const msgType = data.type || "default";

        // 검문 1: '업무 톡톡' 알림인데, 사용자가 껐다면? -> 발송 중단
        if (msgType === 'chat' && !allowChat) {
            console.log(`🚫 [차단됨] 유저(${targetUid})가 업무 톡톡 알림을 거부했습니다.`);
            return;
        }

        // 검문 2: '일정 관리' 알림인데, 사용자가 껐다면? -> 발송 중단
        if (msgType === 'schedule' && !allowSchedule) {
            console.log(`🚫 [차단됨] 유저(${targetUid})가 일정 알림을 거부했습니다.`);
            return;
        }

        // 🔊 [소리 설정 확인]
        // 사용자가 소리를 껐다면 false, 켰거나 설정이 없으면 true
        const isSoundEnabled = userData.isSound !== false;

        // 2. 메시지 Payload 구성 (웹 중복 방지를 위한 Data-Only 유지)
        const payload = {
            token: userToken,

            // [데이터 필드] notification 필드 없이 data에만 담습니다. (웹 중복 방지 핵심)
            data: {
                title: data.title || "알림",
                body: data.body || "내용이 없습니다.",
                type: msgType,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                notificationId: event.params.docId
            },

            // [안드로이드 설정] 우선순위 높임
            android: {
                priority: "high",
            },

            // [iOS 설정] 앱에서는 배너가 뜨도록 설정
            apns: {
                payload: {
                    aps: {
                        contentAvailable: true, // 백그라운드 깨우기
                        alert: {
                            title: data.title,
                            body: data.body
                        },
                        // 🔇 소리 설정 로직:
                        // isSoundEnabled가 true일 때만 sound: "default"를 추가합니다.
                        // false면 아예 sound 항목을 넣지 않아서 무음으로 처리합니다.
                        ...(isSoundEnabled && { sound: "default" }),

                        badge: 1
                    },
                },
            },
        };

        // 3. 발송
        await admin.messaging().send(payload);
        console.log(`✅ [발송 성공] ${targetUid} (타입: ${msgType}, 소리: ${isSoundEnabled ? 'ON' : 'OFF'})`);

    } catch (error) {
        console.error("❌ 알림 발송 실패:", error);
    }
});