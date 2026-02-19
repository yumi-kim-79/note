// [파일 위치: lib/pages/chat/chat_page.dart]
// [최종 고도화] 카카오톡 방식의 무중단 채팅 UI 구현
// 1. [Mobile] 엔터 키를 '줄바꿈'으로 변경하여 키보드 내려감(깜빡임) 원천 차단
// 2. [PC] 엔터 키로 '전송' 유지 (기존 100점 경험 보존)
// 3. [Focus] 메시지 전송 후 포커스를 강제로 유지하여 연속 입력 보장

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
import 'dart:io'; // 플랫폼 감지용

import '../../services/sales_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

// --- 메인 페이지 위젯 ---
class ChatPage extends StatefulWidget {
  final bool isVisible;
  const ChatPage({super.key, this.isVisible = false});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final SalesService _salesService = SalesService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.isVisible) _salesService.updateLastReadTime();
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
    if (widget.isVisible) _salesService.updateLastReadTime();
    _scrollController.dispose();
    super.dispose();
  }

  // 30일 지난 메시지 자동 삭제
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ChatHeader(),
        Expanded(
          child: Container(
            color: const Color(0xFFB2C7DA),
            child: _MessageList(
              salesService: _salesService,
              scrollController: _scrollController,
              isVisible: widget.isVisible,
            ),
          ),
        ),
        _ChatInput(
          salesService: _salesService,
          scrollController: _scrollController,
        ),
      ],
    );
  }
}

// --- 1. 헤더 위젯 ---
class _ChatHeader extends StatelessWidget {
  const _ChatHeader({super.key});

  // 🗑️ [관리자 전용] 전체 대화 삭제 기능
  Future<void> _deleteAllChats(BuildContext context) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠️ 전체 삭제 경고"),
        content: const Text("채팅방의 모든 대화 내용이 영구적으로 삭제됩니다.\n정말 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text("삭제하기")),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      var snapshot = await FirebaseFirestore.instance.collection('chats').get();
      if (snapshot.docs.isEmpty) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제할 대화가 없습니다.")));
        return;
      }
      WriteBatch batch = FirebaseFirestore.instance.batch();
      int count = 0;
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;
        if (count % 500 == 0) { await batch.commit(); batch = FirebaseFirestore.instance.batch(); }
      }
      await batch.commit();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("모든 대화 내용이 삭제되었습니다.")));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제 중 오류가 발생했습니다.")));
    }
  }

  // 💾 백업 기능
  Future<void> _backupChat(BuildContext context) async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('chats').orderBy('createdAt', descending: false).get();
      if (snapshot.docs.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("백업할 대화 내용이 없습니다.")));
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
        final anchor = html.document.createElement('a') as html.AnchorElement..href = url..style.display = 'none'..download = 'SM_Talk_Backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.txt';
        html.document.body!.children.add(anchor); anchor.click(); html.document.body!.children.remove(anchor); html.Url.revokeObjectUrl(url);
      } else {
        await Share.share(content, subject: 'SM 업무 톡톡 백업');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("백업 중 오류가 발생했습니다.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 1. 관리자 권한 확인 (이메일 체크)
    final user = FirebaseAuth.instance.currentUser;
    final bool isAdmin = user?.email == 'yuseok8052@gmail.com';

    // ✅ 2. 화면 너비 확인 (600px 미만이면 좁은 화면)
    final bool isCompact = MediaQuery.of(context).size.width < 600;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: const Text(
              "💬 업무 톡톡",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Row(
            children: [
              // 🔴 [관리자 전용] 전체 삭제 버튼 (isAdmin일 때만 보임)
              if (isAdmin)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: OutlinedButton(
                    onPressed: () => _deleteAllChats(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 16),
                      minimumSize: Size(isCompact ? 40 : 64, 36),
                    ),
                    // 화면이 좁으면 아이콘만, 넓으면 글자까지
                    child: isCompact
                        ? const Icon(Icons.delete_forever, size: 20)
                        : const Row(
                      children: [
                        Icon(Icons.delete_forever, size: 16),
                        SizedBox(width: 8),
                        Text("전체삭제"),
                      ],
                    ),
                  ),
                ),

              // 💾 백업 버튼 (항상 보임)
              OutlinedButton(
                onPressed: () => _backupChat(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSub,
                  side: const BorderSide(color: AppTheme.borderColor),
                  padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 16),
                  minimumSize: Size(isCompact ? 40 : 64, 36),
                ),
                child: isCompact
                    ? const Icon(Icons.download_rounded, size: 20)
                    : const Row(
                  children: [
                    Icon(Icons.download_rounded, size: 16),
                    SizedBox(width: 8),
                    Text("대화 백업"),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

// --- 2. 메시지 목록 위젯 ---
class _MessageList extends StatelessWidget {
  final SalesService salesService;
  final ScrollController scrollController;
  final bool isVisible;

  const _MessageList({required this.salesService, required this.scrollController, required this.isVisible});

  void _showDeleteOption(BuildContext context, String docId) {
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
                  await salesService.deleteChatMessage(docId);
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
    return StreamBuilder<QuerySnapshot>(
      stream: salesService.getChatMessagesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final List<QueryDocumentSnapshot> docs = snapshot.hasData ? snapshot.data!.docs : <QueryDocumentSnapshot>[];
        if (snapshot.hasData && isVisible) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            salesService.updateLastReadTime();
          });
        }
        if (docs.isEmpty) return const Center(child: Text("첫 메시지를 남겨보세요!", style: TextStyle(color: Colors.black54)));
        return ListView.builder(
          reverse: true,
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          physics: const ClampingScrollPhysics(),
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
                  context: context,
                  isMe: isMe,
                  author: data['author'] ?? '알수없음',
                  message: data['message'] ?? '',
                  imageUrl: data['imageUrl'],
                  date: date,
                  onLongPress: isMe ? () => _showDeleteOption(context, docId) : null,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR').format(date), style: const TextStyle(fontSize: 11, color: Colors.white))));
  }

  Widget _buildMessageBubble({required BuildContext context, required bool isMe, required String author, required String message, String? imageUrl, required DateTime date, VoidCallback? onLongPress}) {
    String timeStr = DateFormat('a h:mm', 'ko_KR').format(date);
    Widget bubble = Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: imageUrl != null ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(color: isMe ? const Color(0xFFFEE500) : Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 1, offset: const Offset(0, 1))]),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? GestureDetector(onTap: () => _showZoomableImage(context, imageUrl), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, fit: BoxFit.cover)))
            : Text(message, style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black))
    );
    if (onLongPress != null) {
      bubble = GestureDetector(onLongPress: onLongPress, onDoubleTap: onLongPress, child: bubble);
    }
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [if (!isMe) Container(margin: const EdgeInsets.only(right: 8), child: Column(children: [CircleAvatar(radius: 18, backgroundColor: Colors.white, child: Text(author.isNotEmpty ? author[0] : '?', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)))])) , Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [if (!isMe) Padding(padding: const EdgeInsets.only(left: 2, bottom: 4), child: Text(author, style: const TextStyle(fontSize: 12, color: Colors.black54))), Row(crossAxisAlignment: CrossAxisAlignment.end, children: [if (isMe) Padding(padding: const EdgeInsets.only(right: 6, bottom: 2), child: Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.black54))), bubble, if (!isMe) Padding(padding: const EdgeInsets.only(left: 6, bottom: 2), child: Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.black54)))])])]));
  }

  void _showZoomableImage(BuildContext context, String imageUrl) { showDialog(context: context, builder: (context) => Dialog(backgroundColor: Colors.black, insetPadding: EdgeInsets.zero, child: Stack(children: [Center(child: InteractiveViewer(child: Image.network(imageUrl))), Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)))]))); }
}

// --- 3. 메시지 입력창 위젯 (Stateful) ---
class _ChatInput extends StatefulWidget {
  final SalesService salesService;
  final ScrollController scrollController;

  const _ChatInput({required this.salesService, required this.scrollController});

  @override
  State<_ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<_ChatInput> {
  final TextEditingController _msgController = TextEditingController();
  // ❌ [삭제] NotificationService는 이제 SalesService 내부에서 처리하므로 여기서 필요 없습니다.
  final FocusNode _focusNode = FocusNode();

  bool _isUploading = false;
  bool _isSending = false;

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void dispose() {
    _msgController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (widget.scrollController.hasClients) {
      widget.scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() async {
    final String text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => _isSending = true);
    _msgController.clear();
    _scrollToBottom();

    if (kIsWeb) {
      _focusNode.unfocus();
      Future.delayed(const Duration(milliseconds: 10), () {
        if (mounted) _focusNode.requestFocus();
      });
    } else {
      _focusNode.requestFocus();
    }

    try {
      // ✅ [여기서 끝!] addChatMessage를 부르면 SalesService가 알아서 알림까지 다 보냅니다.
      await widget.salesService.addChatMessage(message: text);
      widget.salesService.updateLastReadTime();

      // ❌ [삭제됨] 여기서 또 _sendChatNotification을 호출하면 알림이 중복됩니다.

      Future.delayed(const Duration(milliseconds: 100), () => _scrollToBottom());

    } catch (e) {
      debugPrint("전송 중 에러 발생: $e");
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
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

        // 업로드
        String downloadUrl = await widget.salesService.uploadImage(bytes, fileName);

        // ✅ [여기서 끝!] 메시지 저장 및 알림 발송 자동 처리
        await widget.salesService.addChatMessage(message: "(사진)", imageUrl: downloadUrl);
        widget.salesService.updateLastReadTime();

        // ❌ [삭제됨] _sendChatNotification 호출 제거

      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("사진 전송 실패")));
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  // ❌ [삭제] _sendChatNotification 함수 전체 삭제
  // 이유: SalesService.dart의 addChatMessage 함수 안에서 이미 전체 알림(Broadcast)을 수행하고 있습니다.

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                      textInputAction: _isMobile ? TextInputAction.newline : TextInputAction.send,
                      onSubmitted: _isMobile ? null : (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: _isMobile ? "메시지 입력" : "메시지 입력 (Enter:전송)",
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
}