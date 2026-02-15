/**
 * [SM종합관리 서버 기능 정의서]
 * 1. optimizeUploadedImage: 사진 업로드 시 800x800 리사이징 (기존 기능 100% 유지)
 * 2. sendPushNotification: Firestore 'notifications' 컬렉션에 데이터가 쌓이면 -> 앱으로 '데이터 메시지' 발송 (신규 고도화)
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
// ✅ [기능 2] 알림 중복 방지 및 클릭 이동 고도화 (새로 추가됨)
// 설명: DB(notifications)에 알림이 저장되면 -> '데이터 전용 메시지'를 발송함
// 효과: 시스템 알림(중복) 차단 + 클릭 시 type 정보 전달
// ============================================================
exports.sendPushNotification = onDocumentCreated("notifications/{docId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    const targetUid = data.targetUid; // 알림 받을 사람의 UID

    if (!targetUid) {
        console.log("타겟 UID가 없습니다.");
        return;
    }

    try {
        // 1. 받을 사람의 토큰 가져오기 (users 컬렉션에서 조회)
        const userDoc = await admin.firestore().collection("users").doc(targetUid).get();
        const userToken = userDoc.data().fcmToken;

        if (!userToken) {
            console.log(`유저(${targetUid})의 FCM 토큰이 없습니다.`);
            return;
        }

        // 2. [핵심] 메시지 payload 구성 (notification 필드 삭제 -> data 필드로 통합)
        const payload = {
            token: userToken,
            data: {
                // 시각적 정보도 data에 숨겨서 보냅니다.
                title: data.title || "알림",
                body: data.body || "내용이 없습니다.",

                // 클릭 시 이동할 페이지 정보 (Flutter에서 이 값을 읽습니다)
                type: data.type || "default",
                click_action: "FLUTTER_NOTIFICATION_CLICK",

                // 추가 정보
                notificationId: event.params.docId
            },
            // 안드로이드 우선순위 설정
            android: {
                priority: "high",
            },
            // iOS 설정 (백그라운드에서 깨어나게 함)
            apns: {
                payload: {
                    aps: {
                        contentAvailable: true,
                    },
                },
            },
        };

        // 3. 발송
        await admin.messaging().send(payload);
        console.log(`✅ [알림 발송 성공] 유저: ${targetUid}, 타입: ${data.type}`);

    } catch (error) {
        console.error("❌ 알림 발송 실패:", error);
    }
});