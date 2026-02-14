// [파일 위치: lib/pages/chat/chat_page.dart]
// 수정 내용:
// 1. [줄바꿈 해결] CallbackShortcuts에서 'Shift+Enter'에 대한 차단을 해제하여 기본 줄바꿈 동작 허용
// 2. [기존 기능 유지] 배지 해결, 한글 입력 해결, 백업 등 모든 기능 100% 유지

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
import 'dart:async'; // Timer 사용

import '../../services/sales_service.dart';
import '../../theme/app_theme.dart';

class ChatPage extends StatefulWidget {
  // 외부에서 화면 보임 여부를 전달받음 (배지 처리용)
  final bool isVisible;

  const ChatPage({super.key, this.isVisible = false});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _msgController = TextEditingController();
  final SalesService _salesService = SalesService();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isUploading = false;
  String? _lastMessageId;

  @override
  void initState() {
    super.initState();
    // 최초 실행 시 화면이 보이고 있다면 읽음 처리
    if (widget.isVisible) {
      _salesService.updateLastReadTime();
    }
    _deleteOldMessages();
  }

  // 화면 보임 여부가 바뀔 때(탭 이동 등) 감지하여 읽음 처리
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
      // print("자동 삭제 오류: $e");
    }
  }

  // ✅ [한글 해결] 포커스 깜빡임 전략
  void _sendMessage() async {
    String text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();

    await _salesService.addChatMessage(message: text);
    _salesService.updateLastReadTime();

    if (kIsWeb) {
      _focusNode.unfocus();
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) _focusNode.requestFocus();
      });
    } else {
      _focusNode.requestFocus();
    }
  }

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
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("사진 전송 실패")));
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

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
        // 헤더
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

        // 채팅 내용
        Expanded(
          child: Container(
            color: const Color(0xFFB2C7DA),
            child: StreamBuilder<QuerySnapshot>(
              stream: _salesService.getChatMessagesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final List<QueryDocumentSnapshot> docs = snapshot.hasData ? snapshot.data!.docs : <QueryDocumentSnapshot>[];

                // 새 글이 왔고, 화면이 보인다면 읽음 처리
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

        // 입력창
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
                  // ✅ [핵심 수정] Shift+Enter는 바인딩에서 제거하여 기본 동작(줄바꿈)을 하게 함
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.enter): () => _sendMessage(),
                      // ⚠️ Shift+Enter 바인딩 삭제함 -> 기본 TextField 동작(줄바꿈) 수행
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
                  child: IconButton(icon: const Icon(Icons.arrow_upward, color: Colors.black, size: 20), onPressed: _sendMessage, constraints: const BoxConstraints(minWidth: 40, minHeight: 40), padding: EdgeInsets.zero),
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