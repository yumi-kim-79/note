/**
 * [SM종합관리 서버 기능 정의서 - 네이버 검색 중계 추가 버전]
 * 1. optimizeUploadedImage: 사진 업로드 시 800x800 리사이징 (기존 유지)
 * 2. sendPushNotification: 다중 환경 대응 푸시 알림 (기존 유지)
 * 🌟 [신규 추가] searchNaverProxy: 네이버 지역 검색 API 중계 (CORS 돌파용)
 */

const { onObjectFinalized } = require("firebase-functions/v2/storage");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https"); // 🌟 신규 추가
const { setGlobalOptions } = require("firebase-functions/v2/options");
const admin = require("firebase-admin");
const spawn = require("child-process-promise").spawn;
const path = require("path");
const os = require("os");
const fs = require("fs");
const axios = require("axios"); // 🌟 네이버 통신용 추가
const cors = require("cors")({ origin: true }); // 🌟 CORS 허용용 추가

admin.initializeApp();

// 전역 설정 (서울 리전 고정)
setGlobalOptions({ region: "asia-northeast3", memory: "1GiB" });

// ============================================================
// ✅ [신규 기능] 네이버 검색 중계 비서 (🌟 더보기 기능 추가 버전)
// ============================================================
exports.searchNaverProxy = onRequest({ cors: true }, async (req, res) => {
    const query = req.query.query;
    // 🌟 플러터 앱에서 "다음 5개"를 요청할 수 있도록 start 파라미터 추가!
    const start = req.query.start || 1;

    if (!query) {
        res.status(400).send("검색어가 없습니다.");
        return;
    }

    const clientId = 'KPhWlXHDEKhnzWtFlbQ2';
    const clientSecret = 'u5XMjAdAR4';

    try {
        const response = await axios.get("https://openapi.naver.com/v1/search/local.json", {
            params: {
                query: query,
                display: 5,
                start: start // 🌟 이거 하나 추가된 겁니다!
            },
            headers: {
                "X-Naver-Client-Id": clientId,
                "X-Naver-Client-Secret": clientSecret
            }
        });

        console.log(`🔍 네이버 검색 중계 성공: ${query} (시작점: ${start})`);
        res.status(200).send(response.data);
    } catch (error) {
        console.error("❌ 네이버 API 중계 실패:", error.message);
        res.status(500).send("네이버 통신 중 오류가 발생했습니다.");
    }
});

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
// ✅ [기능 2] 알림 발송 및 자동 토큰 청소 (기존 기능 100% 유지)
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

        const allowChat = userData.allowChatPush !== false;
        const allowSchedule = userData.allowSchedulePush !== false;
        const allowNotice = userData.allowNoticePush !== false;
        const isSoundEnabled = userData.isSound !== false;

        const msgType = data.type || "default";

        if (msgType === 'chat' && !allowChat) return console.log(`🚫 업무톡톡 거부: ${targetUid}`);
        if (msgType === 'schedule' && !allowSchedule) return console.log(`🚫 일정알림 거부: ${targetUid}`);
        if (msgType === 'notice' && !allowNotice) return console.log(`🚫 공지사항 거부: ${targetUid}`);

        let targetUrl = '/#/';
        if (msgType === 'chat') targetUrl = '/#/chat';
        else if (msgType === 'schedule') targetUrl = '/#/schedule';
        else if (msgType === 'notice') targetUrl = '/#/notice';
        else if (msgType === 'report') targetUrl = '/#/report';

        const payload = {
            token: userToken,
            notification: {
                title: data.title || "알림",
                body: data.body || "내용이 없습니다."
            },
            data: {
                type: msgType,
                notificationId: event.params.docId,
                url: targetUrl
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "high_importance_channel",
                    sound: isSoundEnabled ? "default" : undefined,
                    clickAction: "FLUTTER_NOTIFICATION_CLICK"
                }
            },
            apns: {
                payload: {
                    aps: {
                        contentAvailable: true,
                        ...(isSoundEnabled && { sound: "default" }),
                        badge: 1
                    },
                },
            },
            webpush: {
                headers: {
                    Urgency: "high"
                },
                notification: {
                    icon: "/icons/Icon-192.png",
                    badge: "/icons/Icon-192.png",
                    requireInteraction: true,
                    ...(isSoundEnabled && {
                        sound: "default",
                        vibrate: [200, 100, 200, 100, 200]
                    })
                },
                fcmOptions: {
                    link: targetUrl
                }
            }
        };

        await admin.messaging().send(payload);
        console.log(`✅ 발송 성공: ${targetUid} (Type: ${msgType}, Sound: ${isSoundEnabled})`);

    } catch (error) {
        console.error("❌ 발송 실패 상세:", error);

        if (error.code === 'messaging/invalid-registration-token' ||
            error.code === 'messaging/registration-token-not-registered') {

            await admin.firestore().collection("users").doc(targetUid).update({
                fcmToken: admin.firestore.FieldValue.delete()
            });
            console.log(`🧹 토큰 청소 완료: 유저(${targetUid})의 만료된 토큰을 제거했습니다.`);
        }
    }
});