// [파일 위치: lib/services/sales_service.dart]
// 수정 내용:
// 1. [스마트 업로드] XFile(웹)은 readAsBytes(), File(앱)은 putFile() 사용
// 2. [미리보기 연결] 웹 업로드 시, 서버 변환(HEIC->JPG) 완료까지 대기 후 변환된 URL 반환
// 3. [기존 기능 유지] 채팅, 공지사항 등 다른 모든 기능 100% 동일

import 'dart:io';
import 'dart:typed_data'; // Uint8List 사용
import 'dart:async';      // Future.delayed 사용
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // kIsWeb 체크용
import 'package:image_picker/image_picker.dart'; // XFile 사용

class SalesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  FirebaseAuth get auth => _auth;

  // ===============================================================
  // [공통] 이미지 업로드 - ✅ 스마트 대기 로직 적용 (HEIC 대응)
  // ===============================================================
  Future<String> uploadImage(dynamic image, String path) async {
    final storageRef = _storage.ref().child(path);
    UploadTask uploadTask;
    String mimeType = 'image/jpeg'; // 기본값

    // [CASE 1] XFile (Camera/Gallery에서 선택한 경우)
    if (image is XFile) {
      mimeType = image.mimeType ?? 'image/jpeg';

      // 파일 확장자가 heic인지 확인 (메타데이터용)
      if (image.name.toLowerCase().endsWith('heic')) {
        mimeType = 'image/heic';
      }

      if (kIsWeb) {
        // 🌐 웹: 데이터(Bytes)로 업로드
        // (웹 브라우저는 파일 경로에 접근할 수 없으므로 readAsBytes 필수)
        final data = await image.readAsBytes();

        // 메타데이터를 명시해야 서버 트리거가 정확히 작동함
        final metadata = SettableMetadata(
          contentType: mimeType,
          customMetadata: {'originalName': image.name},
        );
        uploadTask = storageRef.putData(data, metadata);
      } else {
        // 📱 앱: 파일 경로(Path)로 업로드 (효율적)
        uploadTask = storageRef.putFile(File(image.path));
      }
    }
    // [CASE 2] Uint8List (웹에서 드래그앤드롭 하거나, 메모리 이미지인 경우)
    else if (image is Uint8List) {
      uploadTask = storageRef.putData(image, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      throw Exception("지원하지 않는 이미지 형식입니다.");
    }

    // 1. 업로드 실행 및 대기
    await uploadTask;

    // 2. [핵심] 웹(Web)인 경우, 서버가 이미지를 변환할 시간을 줌
    if (kIsWeb) {
      // JPG로 변환된 파일(_800x800.jpg)의 주소를 찾아서 반환
      return await _waitForResizedImage(path);
    }

    // 앱은 변환 불필요 (또는 클라이언트 압축 사용) 하므로 원본 주소 반환
    return await storageRef.getDownloadURL();
  }

  // 🔍 [보조 함수] 서버가 만든 '변환된 이미지'를 기다리는 로직
  Future<String> _waitForResizedImage(String originalPath) async {
    // Firebase Extensions(Resize Images)는 보통 원본명 + _800x800 형식으로 파일 생성
    // 예: sales/photo.HEIC  ->  sales/photo_800x800.jpg

    String pathWithoutExt = originalPath;
    if (originalPath.contains('.')) {
      pathWithoutExt = originalPath.substring(0, originalPath.lastIndexOf('.'));
    }
    // 변환 예상 경로 (JPG로 변경됨)
    String resizedPath = '${pathWithoutExt}_800x800.jpg';

    print("🔎 변환된 이미지 찾는 중: $resizedPath");

    final resizedRef = _storage.ref().child(resizedPath);

    // 1초 간격으로 5번(5초) 확인
    for (int i = 0; i < 5; i++) {
      try {
        await Future.delayed(const Duration(seconds: 1));
        String url = await resizedRef.getDownloadURL();
        print("✅ 변환된 이미지 발견! ($url)");
        return url; // 성공 시 변환된 JPG 주소 반환
      } catch (e) {
        print("⏳ 변환 대기 중... (${i + 1}/5)");
      }
    }

    print("⚠️ 변환 시간 초과. 원본 URL을 반환합니다.");
    // 실패 시 원본 주소라도 반환 (없는 것보단 나음)
    return await _storage.ref().child(originalPath).getDownloadURL();
  }

  // ===============================================================
  // [1] 영업 노트 (Sales Note) - 100% 기존 유지
  // ===============================================================
  Future<void> addSalesNote({
    required String title,
    required String content,
    required String visitType,
    String? imageUrl,
    List<String>? imageUrls,
    bool isPrivate = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>? ?? {};

    String name = userData['name'] ?? '사용자';
    String rank = userData['rank'] ?? '';
    String authorDisplayName = rank.isNotEmpty ? "$name $rank" : name;

    await _firestore.collection('sales_notes').add({
      'uid': user.uid,
      'author': authorDisplayName,
      'title': title,
      'content': content,
      'visitType': visitType,
      'imageUrl': imageUrl ?? "",
      'imageUrls': imageUrls ?? [],
      'isPrivate': isPrivate,
      'clientName': '',
      'contactInfo': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getSalesNotesStream() {
    return _firestore.collection('sales_notes').orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> deleteSalesNote(String docId) async {
    await _firestore.collection('sales_notes').doc(docId).delete();
  }

  Future<void> updateSalesNote(String docId, String title, String content, {bool? isPrivate}) async {
    Map<String, dynamic> data = {
      'title': title,
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (isPrivate != null) {
      data['isPrivate'] = isPrivate;
    }
    await _firestore.collection('sales_notes').doc(docId).update(data);
  }

  // ===============================================================
  // [2] 일정 관리 (Schedule) - 100% 기존 유지
  // ===============================================================
  Future<void> addSchedule({
    required String title, required String content, required DateTime date,
    required DateTime startTime, required DateTime endTime, required int colorCode,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('schedules').add({
      'uid': user.uid,
      'title': title, 'content': content,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'colorCode': colorCode,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getSchedulesStream() {
    return _firestore.collection('schedules').snapshots();
  }

  Future<void> updateSchedule({
    required String docId, required String title, required String content,
    required DateTime date, required DateTime startTime, required DateTime endTime, required int colorCode,
  }) async {
    await _firestore.collection('schedules').doc(docId).update({
      'title': title, 'content': content,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'colorCode': colorCode,
    });
  }

  Future<void> deleteSchedule(String docId) async {
    await _firestore.collection('schedules').doc(docId).delete();
  }

  // ===============================================================
  // [3] 공지사항 (Notice) - 100% 기존 유지
  // ===============================================================
  Future<void> addNotice({required String title, required String content, String imageUrl = ""}) async {
    await _firestore.collection('notices').add({
      'title': title, 'content': content, 'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getNoticesStream() {
    return _firestore.collection('notices').orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> deleteNotice(String docId) async {
    await _firestore.collection('notices').doc(docId).delete();
  }

  Future<void> updateNotice(String docId, String title, String content) async {
    await _firestore.collection('notices').doc(docId).update({
      'title': title, 'content': content,
    });
  }

  // ===============================================================
  // [4] 체크리스트 (Checklist) - 100% 기존 유지
  // ===============================================================
  Stream<QuerySnapshot> getChecklistsStream() {
    return _firestore.collection('checklists').orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> addChecklist({
    required String buildingName,
    required String address,
    required DateTime contractDate,
    required String prevCompany,
    required List<dynamic> committeeMembers,
    required String remarks,
    required List<dynamic> checkItems,
    required String author,
    String bldArea = "",
    String bldFloor = "",
    String bldUsage = "",
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('checklists').add({
      'uid': user.uid,
      'buildingName': buildingName,
      'address': address,
      'contractDate': Timestamp.fromDate(contractDate),
      'prevCompany': prevCompany,
      'committeeMembers': committeeMembers,
      'remarks': remarks,
      'checkItems': checkItems,
      'author': author,
      'bldArea': bldArea,
      'bldFloor': bldFloor,
      'bldUsage': bldUsage,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateChecklist({
    required String docId,
    required String buildingName,
    required String address,
    required DateTime contractDate,
    required String prevCompany,
    required List<dynamic> committeeMembers,
    required String remarks,
    required List<dynamic> checkItems,
    String bldArea = "",
    String bldFloor = "",
    String bldUsage = "",
  }) async {
    await _firestore.collection('checklists').doc(docId).update({
      'buildingName': buildingName,
      'address': address,
      'contractDate': Timestamp.fromDate(contractDate),
      'prevCompany': prevCompany,
      'committeeMembers': committeeMembers,
      'remarks': remarks,
      'checkItems': checkItems,
      'bldArea': bldArea,
      'bldFloor': bldFloor,
      'bldUsage': bldUsage,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteChecklist(String docId) async {
    await _firestore.collection('checklists').doc(docId).delete();
  }

  // ===============================================================
  // [5] 업무 톡톡 (Chat) - 100% 기존 유지
  // ===============================================================
  Future<void> addChatMessage({required String message, String imageUrl = ""}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String authorName = "직원";
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String name = userData['name'] ?? '사용자';
        String rank = userData['rank'] ?? '';
        authorName = rank.isNotEmpty ? "$name $rank" : name;
      }
    } catch (e) {
      print("작성자 정보 로드 실패: $e");
    }

    await _firestore.collection('chats').add({
      'uid': user.uid,
      'author': authorName,
      'message': message,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteChatMessage(String docId) async {
    await _firestore.collection('chats').doc(docId).delete();
  }

  Stream<QuerySnapshot> getChatMessagesStream() {
    return _firestore.collection('chats').orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> updateLastReadTime() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set({
      'lastReadTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<int> getUnreadMessageCountStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore.collection('users').doc(user.uid).snapshots().asyncMap((userSnapshot) async {
      if (!userSnapshot.exists) return 0;

      Timestamp? lastReadTs = (userSnapshot.data() as Map<String, dynamic>)['lastReadTime'];

      QuerySnapshot chatSnapshot = await _firestore
          .collection('chats')
          .where('createdAt', isGreaterThan: lastReadTs ?? Timestamp.fromDate(DateTime(2000, 1, 1)))
          .get();

      int count = 0;
      for (var doc in chatSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['uid'] != user.uid) { // 내가 쓴 글 제외
          count++;
        }
      }
      return count;
    });
  }

  // ===============================================================
  // [NEW] 건물 DB 정보 - 100% 기존 유지
  // ===============================================================
  Future<void> addBuildingInfo(String name, String address) async {
    await _firestore.collection('buildings').add({
      'name': name,
      'address': address,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getBuildingsStream() {
    return _firestore.collection('buildings').orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> deleteBuildingInfo(String docId) async {
    await _firestore.collection('buildings').doc(docId).delete();
  }

  Future<void> updateBuildingInfo(String docId, String name, String address) async {
    await _firestore.collection('buildings').doc(docId).update({
      'name': name,
      'address': address,
    });
  }
}