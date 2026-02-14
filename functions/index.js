const { onObjectFinalized } = require("firebase-functions/v2/storage");
const { setGlobalOptions } = require("firebase-functions/v2/options");
const admin = require("firebase-admin");
const spawn = require("child-process-promise").spawn;
const path = require("path");
const os = require("os");
const fs = require("fs");

admin.initializeApp();

// 전역 설정 (서울 리전, 메모리 1GB)
setGlobalOptions({ region: "asia-northeast3", memory: "1GiB" });

// ✅ [서울 리전] 사진 변환 비서 (Gen 2 - 신형)
exports.optimizeUploadedImage = onObjectFinalized(async (event) => {
    const object = event.data; // Gen 2는 event.data에 정보가 있음
    const fileBucket = object.bucket;
    const filePath = object.name;
    const contentType = object.contentType;

    // 1. 처리 대상 확인
    if (!contentType.startsWith('image/') || filePath.includes('_800x800')) {
        return console.log('처리 대상 아님.');
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