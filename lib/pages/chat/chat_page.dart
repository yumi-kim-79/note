// [파일 위치: lib/pages/chat/chat_page.dart]
// 역할: 실시간 채팅, 이미지 전송, 대화 백업 및 타 사용자에게 실시간 푸시 알림 발송

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:async';

import '../../services/sales_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

class ChatPage extends StatefulWidget {
  final bool isVisible;
  const ChatPage({super.key, this.isVisible = false});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _msgController = TextEditingController();
  final SalesService _salesService = SalesService();
  final NotificationService _notificationService = NotificationService();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isUploading = false;
  bool _isSending = false; // 중복 전송 방지 플래그

  @override
  void initState() {
    super.initState();
    if (widget.isVisible) {
      _salesService.updateLastReadTime();
    }
    _deleteOldMessages();
  }

  @override
  void didUpdateWidget(covariant ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isVisible && widget.isVisible) {
      _salesService.updateLastReadTime();
    }
  }

  @override
  void dispose() {
    if (widget.isVisible) {
      _salesService.updateLastReadTime();
    }
    _msgController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // 30일 지난 메시지 자동 삭제 (기존 유지)
  Future<void> _deleteOldMessages() async {
    DateTime cutOffDate = DateTime.now().subtract(const Duration(days: 30));
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutOffDate))
          .get();
      if (snapshot.docs.isNotEmpty) {
        WriteBatch batch = FirebaseFirestore.instance.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint("메시지 자동 삭제 중 오류: $e");
    }
  }

  // ✅ [고도화 및 최적화된 메시지 전송 로직]
  // 1. 중복 전송 100% 차단 및 버튼 상태 즉시 반영
  // 2. 웹(Chrome) 한글 잔상 버그 해결 유지
  // 3. 모바일/태블릿 키보드 내려감(깜빡임) 현상 완벽 해결
  void _sendMessage() async {
    String text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // ✅ [고도화] setState를 추가하여 전송 버튼을 즉시 비활성화(중복 클릭 방지)
    setState(() => _isSending = true);

    try {
      // 내 이름 정보 가져오기
      DocumentSnapshot myDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      String myName = (myDoc.data() as Map<String, dynamic>?)?['name'] ?? '누군가';

      // 1. 입력창 즉시 비우기 (사용자 체감 속도 향상)
      _msgController.clear();

      // 2. [핵심 고도화] 모바일/태블릿은 'await' 지연이 발생하기 전에 포커스를 재요청합니다.
      // 이렇게 하면 시스템에 "아직 입력 중"이라는 신호를 즉시 보내 키보드 유지를 보장합니다.
      if (!kIsWeb) {
        _focusNode.requestFocus();
      } else {
        // 웹(Web) 환경 한글 잔상 방지 로직 유지
        _focusNode.unfocus();
        Future.delayed(const Duration(milliseconds: 30), () {
          if (mounted) _focusNode.requestFocus();
        });
      }

      // 3. 데이터 저장 및 알림 발송 (이제 여기서 지연이 생겨도 키보드가 내려가지 않습니다)
      await _salesService.addChatMessage(message: text);
      _salesService.updateLastReadTime();
      _sendChatNotification(myName, text, currentUser.uid);

    } catch (e) {
      debugPrint("전송 중 에러 발생: $e");
    } finally {
      // 4. 전송 보호 해제 및 상태 갱신
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  // 알림 발송 (기존 로직 100% 유지)
  Future<void> _sendChatNotification(String senderName, String message, String myUid) async {
    try {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('fcmToken', isNotEqualTo: null)
          .get();
      for (var doc in userSnapshot.docs) {
        String userUid = doc.id;
        String? token = (doc.data() as Map<String, dynamic>)['fcmToken'];
        if (token != null && token.isNotEmpty && userUid != myUid) {
          await _notificationService.sendNotification(
            targetToken: token,
            targetUid: userUid,
            title: "💬 업무 톡톡: $senderName",
            body: message,
            type: 'chat',
          );
        }
      }
    } catch (e) {
      debugPrint("채팅 알림 발송 실패: $e");
    }
  }

  // 이미지 전송 (기존 유지)
  Future<void> _sendImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await image.readAsBytes();
        String fileName = "chat/${DateTime.now().millisecondsSinceEpoch}_${image.name}";
        String downloadUrl = await _salesService.uploadImage(bytes, fileName);
        await _salesService.addChatMessage(message: "(사진)", imageUrl: downloadUrl);
        _salesService.updateLastReadTime();

        final currentUser = FirebaseAuth.instance.currentUser;
        DocumentSnapshot myDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).get();
        String myName = (myDoc.data() as Map<String, dynamic>?)?['name'] ?? '누군가';
        _sendChatNotification(myName, "📷 사진을 보냈습니다.", currentUser?.uid ?? "");
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("사진 전송 실패")));
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  // 대화 백업 (기존 유지)
  Future<void> _backupChat() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .orderBy('createdAt', descending: false)
          .get();
      if (snapshot.docs.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("백업할 대화 내용이 없습니다.")));
        return;
      }
      StringBuffer sb = StringBuffer();
      sb.writeln("========================================");
      sb.writeln("[SM 업무 톡톡 대화 백업]");
      sb.writeln("저장일시: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}");
      sb.writeln("========================================\n");
      for (var doc in snapshot.docs) {
        var data = doc.data();
        DateTime date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        String author = data['author'] ?? '알수없음';
        String message = data['message'] ?? '(사진)';
        String time = DateFormat('yyyy-MM-dd HH:mm').format(date);
        sb.writeln("[$time] $author : $message");
      }
      String content = sb.toString();
      if (kIsWeb) {
        final bytes = utf8.encode(content);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = 'SM_Talk_Backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.txt';
        html.document.body!.children.add(anchor);
        anchor.click();
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } else {
        await Share.share(content, subject: 'SM 업무 톡톡 백업');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("백업 중 오류가 발생했습니다.")));
    }
  }

  void _showDeleteOption(String docId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.errorColor),
                title: const Text("삭제하기", style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(context);
                  await _salesService.deleteChatMessage(docId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text("취소"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("💬 업무 톡톡 (전체 대화방)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              OutlinedButton.icon(
                onPressed: _backupChat,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text("대화 백업"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSub,
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
              )
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFB2C7DA),
            child: StreamBuilder<QuerySnapshot>(
              stream: _salesService.getChatMessagesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final List<QueryDocumentSnapshot> docs = snapshot.hasData ? snapshot.data!.docs : <QueryDocumentSnapshot>[];
                if (snapshot.hasData && widget.isVisible) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _salesService.updateLastReadTime();
                  });
                }
                if (docs.isEmpty) return const Center(child: Text("첫 메시지를 남겨보세요!", style: TextStyle(color: Colors.black54)));
                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final String docId = docs[index].id;
                    final bool isMe = data['uid'] == currentUser?.uid;
                    final DateTime date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                    bool showDateSeparator = false;
                    if (index < docs.length - 1) {
                      final prevData = docs[index + 1].data() as Map<String, dynamic>;
                      final prevDate = (prevData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                      if (date.day != prevDate.day || date.month != prevDate.month) showDateSeparator = true;
                    } else {
                      showDateSeparator = true;
                    }
                    return Column(
                      children: [
                        if (showDateSeparator) _buildDateSeparator(date),
                        _buildMessageBubble(
                          isMe: isMe,
                          author: data['author'] ?? '알수없음',
                          message: data['message'] ?? '',
                          imageUrl: data['imageUrl'],
                          date: date,
                          docId: docId,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
        if (_isUploading) const LinearProgressIndicator(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          color: Colors.white,
          child: SafeArea(
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.add_box_outlined, color: Colors.grey, size: 30), onPressed: _sendImage, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                const SizedBox(width: 10),
                Expanded(
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.enter): () {
                        if (!_isSending) _sendMessage();
                      },
                    },
                    child: TextField(
                      focusNode: _focusNode,
                      controller: _msgController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: "메시지 입력 (Enter:전송, Shift+Enter:줄바꿈)",
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        filled: true, fillColor: const Color(0xFFF2F2F2),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(color: const Color(0xFFFEE500), borderRadius: BorderRadius.circular(8)),
                  child: IconButton(
                      icon: const Icon(Icons.arrow_upward, color: Colors.black, size: 20),
                      onPressed: _isSending ? null : _sendMessage,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR').format(date), style: const TextStyle(fontSize: 11, color: Colors.white))));
  }

  Widget _buildMessageBubble({required bool isMe, required String author, required String message, String? imageUrl, required DateTime date, required String docId}) {
    String timeStr = DateFormat('a h:mm', 'ko_KR').format(date);
    Widget bubble = Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: imageUrl != null ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(color: isMe ? const Color(0xFFFEE500) : Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 1, offset: const Offset(0, 1))]),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? GestureDetector(onTap: () => _showZoomableImage(context, imageUrl), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, fit: BoxFit.cover)))
            : Text(message, style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black))
    );
    if (isMe) {
      bubble = GestureDetector(onLongPress: () => _showDeleteOption(docId), onDoubleTap: () => _showDeleteOption(docId), child: bubble);
    }
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [if (!isMe) Container(margin: const EdgeInsets.only(right: 8), child: Column(children: [CircleAvatar(radius: 18, backgroundColor: Colors.white, child: Text(author.isNotEmpty ? author[0] : '?', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)))])) , Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [if (!isMe) Padding(padding: const EdgeInsets.only(left: 2, bottom: 4), child: Text(author, style: const TextStyle(fontSize: 12, color: Colors.black54))), Row(crossAxisAlignment: CrossAxisAlignment.end, children: [if (isMe) Padding(padding: const EdgeInsets.only(right: 6, bottom: 2), child: Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.black54))), bubble, if (!isMe) Padding(padding: const EdgeInsets.only(left: 6, bottom: 2), child: Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.black54)))])])]));
  }

  void _showZoomableImage(BuildContext context, String imageUrl) { showDialog(context: context, builder: (context) => Dialog(backgroundColor: Colors.black, insetPadding: EdgeInsets.zero, child: Stack(children: [Center(child: InteractiveViewer(child: Image.network(imageUrl))), Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)))]))); }
}