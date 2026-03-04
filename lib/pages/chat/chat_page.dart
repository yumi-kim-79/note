// [파일 위치: lib/pages/chat/chat_page.dart]
// [최종 고도화] 카카오톡 방식의 무중단 채팅 UI 구현
// 1. [Mobile] 엔터 키를 '줄바꿈'으로 변경하여 키보드 내려감(깜빡임) 원천 차단
// 2. [PC] 엔터 키로 '전송' 유지 / Shift+Enter로 '줄바꿈' 완벽 지원 (한글 잔상 방어 100% 유지)
// 3. [Focus] 메시지 전송 후 포커스를 강제로 유지하여 연속 입력 보장
// 4. [🌟고도화] DB 요금 폭탄(무한 읽음 처리) 원천 차단
// 5. [🌟고도화] 같은 시간, 같은 사람의 연속 메시지 말풍선 묶음(프사, 시간 생략) UI 적용
// 6. [🌟고도화] 스크롤 시 '최신 메시지(↓)' 플로팅 버튼 등장

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
// 🌟 [수정 1] defaultTargetPlatform 에러 해결을 위해 import 항목 추가
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'dart:convert';
import 'dart:async';
import 'dart:io';

import '../../services/sales_service.dart';
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
    // 🌟 [최적화 유지] 채팅방 처음 열 때 딱 한 번만 읽음 처리
    if (widget.isVisible) _salesService.updateLastReadTime();
    _deleteOldMessages();
  }

  @override
  void didUpdateWidget(covariant ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 🌟 [최적화 유지] 다른 탭에 있다가 채팅방 탭으로 돌아왔을 때 한 번만 읽음 처리
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
            // 🌟 [고도화 반영] Stateful로 변경된 _MessageList 호출
            child: _MessageList(
              salesService: _salesService,
              scrollController: _scrollController,
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

// --- 1. 헤더 위젯 (기존 기능 100% 보존) ---
class _ChatHeader extends StatelessWidget {
  const _ChatHeader({super.key});

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
    final user = FirebaseAuth.instance.currentUser;
    final bool isAdmin = user?.email == 'yuseok8052@gmail.com';
    final bool isCompact = MediaQuery.of(context).size.width < 600;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              "💬 업무 톡톡",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
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
                    child: isCompact
                        ? const Icon(Icons.delete_forever, size: 20)
                        : const Row(children: [Icon(Icons.delete_forever, size: 16), SizedBox(width: 8), Text("전체삭제")]),
                  ),
                ),
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
                    : const Row(children: [Icon(Icons.download_rounded, size: 16), SizedBox(width: 8), Text("대화 백업")]),
              )
            ],
          )
        ],
      ),
    );
  }
}

// --- 2. 메시지 목록 위젯 (🌟 고도화를 위해 Stateful로 변경) ---
class _MessageList extends StatefulWidget {
  final SalesService salesService;
  final ScrollController scrollController;

  const _MessageList({required this.salesService, required this.scrollController});

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  bool _showScrollFAB = false;

  // 🌟 [핵심 수술 1] 데이터를 받아오는 파이프라인을 저장할 전용 변수를 만듭니다.
  late Stream<QuerySnapshot> _chatStream;

  @override
  void initState() {
    super.initState();

    // 🌟 [핵심 수술 2] 화면이 처음 열릴 때 딱 한 번만 파이프라인을 단단히 연결합니다!
    _chatStream = widget.salesService.getChatMessagesStream();

    // 🌟 [스크롤 감지] 화면을 위로 200픽셀 이상 올리면 플로팅 버튼 등장
    widget.scrollController.addListener(() {
      if (widget.scrollController.offset > 200 && !_showScrollFAB) {
        setState(() => _showScrollFAB = true);
      } else if (widget.scrollController.offset <= 200 && _showScrollFAB) {
        setState(() => _showScrollFAB = false);
      }
    });
  }

  void _scrollToBottom() {
    widget.scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

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
                  await widget.salesService.deleteChatMessage(docId);
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
    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          // 🌟 [핵심 수술 3] 매번 새로 부르지 않고, initState에서 딱 한 번 연결해둔 고정 파이프라인을 씁니다!
          stream: _chatStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final List<QueryDocumentSnapshot> docs = snapshot.hasData ? snapshot.data!.docs : <QueryDocumentSnapshot>[];

            // 🚨 [핵심 버그 수정] 이곳에 있던 updateLastReadTime() 무한 호출을 삭제하여 파이어베이스 요금 폭탄을 완벽 방어했습니다!

            if (docs.isEmpty) return const Center(child: Text("첫 메시지를 남겨보세요!", style: TextStyle(color: Colors.black54)));

            return ListView.builder(
              reverse: true, // 최신 메시지가 맨 아래(인덱스 0)로 오도록 뒤집음
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              physics: const ClampingScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final String docId = docs[index].id;
                final bool isMe = data['uid'] == currentUser?.uid;

                final DateTime currentDate = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                final String currentAuthor = data['author'] ?? '알수없음';

                bool showDateSeparator = false;
                bool hideProfileAndName = false;
                bool hideTime = false;

                // 🌟 [UI 고도화: 카카오톡 빙의] 연속 메시지 묶음 로직
                // index + 1 은 과거(이전) 메시지입니다 (reverse 상태이므로)
                if (index < docs.length - 1) {
                  final prevData = docs[index + 1].data() as Map<String, dynamic>;
                  final DateTime prevDate = (prevData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final String prevAuthor = prevData['author'] ?? '';

                  // 1. 날짜가 다르면 구분선 표시
                  if (currentDate.day != prevDate.day || currentDate.month != prevDate.month) {
                    showDateSeparator = true;
                  }

                  // 2. 과거 메시지와 보낸 사람 & 분(minute)이 같으면 내 프사와 이름을 숨김 (위쪽으로 달라붙음)
                  if (currentAuthor == prevAuthor &&
                      currentDate.year == prevDate.year &&
                      currentDate.month == prevDate.month &&
                      currentDate.day == prevDate.day &&
                      currentDate.hour == prevDate.hour &&
                      currentDate.minute == prevDate.minute) {
                    hideProfileAndName = true;
                  }
                } else {
                  // 가장 오래된(맨 처음) 메시지는 무조건 날짜 구분선 표시
                  showDateSeparator = true;
                }

                // index - 1 은 미래(최신) 메시지입니다 (reverse 상태이므로)
                if (index > 0) {
                  final nextData = docs[index - 1].data() as Map<String, dynamic>;
                  final DateTime nextDate = (nextData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final String nextAuthor = nextData['author'] ?? '';

                  // 3. 미래 메시지와 보낸 사람 & 분(minute)이 같으면 내 시간 표시를 숨김 (아래 메시지에만 표시)
                  if (currentAuthor == nextAuthor &&
                      currentDate.year == nextDate.year &&
                      currentDate.month == nextDate.month &&
                      currentDate.day == nextDate.day &&
                      currentDate.hour == nextDate.hour &&
                      currentDate.minute == nextDate.minute) {
                    hideTime = true;
                  }
                }

                return Column(
                  children: [
                    if (showDateSeparator) _buildDateSeparator(currentDate),
                    _buildMessageBubble(
                      context: context,
                      isMe: isMe,
                      author: currentAuthor,
                      message: data['message'] ?? '',
                      imageUrl: data['imageUrl'],
                      date: currentDate,
                      hideProfileAndName: hideProfileAndName,
                      hideTime: hideTime,
                      onLongPress: isMe ? () => _showDeleteOption(context, docId) : null,
                    ),
                  ],
                );
              },
            );
          },
        ),

        // 🌟 [UX 고도화] 최신 메시지로 스크롤 이동 버튼 (우측 하단)
        if (_showScrollFAB)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white.withOpacity(0.9),
              elevation: 3,
              onPressed: _scrollToBottom,
              child: const Icon(Icons.keyboard_arrow_down, color: Colors.black87, size: 30),
            ),
          ),
      ],
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR').format(date), style: const TextStyle(fontSize: 12, color: Colors.white))
        )
    );
  }

  Widget _buildMessageBubble({
    required BuildContext context,
    required bool isMe,
    required String author,
    required String message,
    String? imageUrl,
    required DateTime date,
    required bool hideProfileAndName,
    required bool hideTime,
    VoidCallback? onLongPress
  }) {
    String timeStr = DateFormat('a h:mm', 'ko_KR').format(date);

    Widget bubble = Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: imageUrl != null ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: isMe ? const Color(0xFFFEE500) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 1, offset: const Offset(0, 1))]
        ),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? GestureDetector(onTap: () => _showZoomableImage(context, imageUrl), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, fit: BoxFit.cover)))
            : Text(message, style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black))
    );

    if (onLongPress != null) {
      bubble = GestureDetector(onLongPress: onLongPress, onDoubleTap: onLongPress, child: bubble);
    }

    return Padding(
      // 연속 메시지일 경우 위아래 간격을 확 줄여서 하나처럼 보이게 만듦
        padding: EdgeInsets.only(bottom: hideTime ? 4 : 12),
        child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 내 메시지가 아닐 때 프사 영역
              if (!isMe)
                hideProfileAndName
                    ? const SizedBox(width: 44) // 프사 숨길 때 빈 공간 확보 (정렬 유지)
                    : Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: CircleAvatar(radius: 18, backgroundColor: Colors.white, child: Text(author.isNotEmpty ? author[0] : '?', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)))
                ),

              Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // 내 메시지가 아닐 때 이름 영역
                    if (!isMe && !hideProfileAndName)
                      Padding(padding: const EdgeInsets.only(left: 2, bottom: 4), child: Text(author, style: const TextStyle(fontSize: 12, color: Colors.black54))),

                    Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // 내가 보낸 메시지일 때 좌측 시간
                          if (isMe && !hideTime) Padding(padding: const EdgeInsets.only(right: 6, bottom: 2), child: Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.black54))),
                          bubble,
                          // 남이 보낸 메시지일 때 우측 시간
                          if (!isMe && !hideTime) Padding(padding: const EdgeInsets.only(left: 6, bottom: 2), child: Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.black54)))
                        ]
                    )
                  ]
              )
            ]
        )
    );
  }

  void _showZoomableImage(BuildContext context, String imageUrl) {
    showDialog(context: context, builder: (context) => Dialog(backgroundColor: Colors.black, insetPadding: EdgeInsets.zero, child: Stack(children: [Center(child: InteractiveViewer(child: Image.network(imageUrl))), Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)))])));
  }
}

// --- 3. 메시지 입력창 위젯 (기존 로직 100% 유지) ---
class _ChatInput extends StatefulWidget {
  final SalesService salesService;
  final ScrollController scrollController;

  const _ChatInput({required this.salesService, required this.scrollController});

  @override
  State<_ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<_ChatInput> {
  final TextEditingController _msgController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isUploading = false;
  bool _isSending = false;

  // 🌟 [핵심 고도화] 웹(Web)으로 접속해도 PC인지 모바일/태블릿인지 완벽하게 스캔합니다!
  bool get _isMobile {
    if (kIsWeb) {
      return defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android;
    }
    return Platform.isAndroid || Platform.isIOS;
  }

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

    // 🌟 [핵심 보존] 한글 IME 잔상 버그 완벽 방어 로직 (절대 건드리지 않음)
    if (kIsWeb) {
      _focusNode.unfocus();
      Future.delayed(const Duration(milliseconds: 10), () {
        if (mounted) _focusNode.requestFocus();
      });
    } else {
      _focusNode.requestFocus();
    }

    try {
      await widget.salesService.addChatMessage(message: text);
      widget.salesService.updateLastReadTime();
      Future.delayed(const Duration(milliseconds: 100), () => _scrollToBottom());
    } catch (e) {
      debugPrint("전송 중 에러 발생: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendImage() async {
    final ImagePicker picker = ImagePicker();
    // 🌟 [핵심 보존] 웹 환경 HEIC 호환을 위한 원본 화질 유지 (imageQuality 옵션 없음)
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await image.readAsBytes();
        String fileName = "chat/${DateTime.now().millisecondsSinceEpoch}_${image.name}";

        String downloadUrl = await widget.salesService.uploadImage(bytes, fileName);
        await widget.salesService.addChatMessage(message: "(사진)", imageUrl: downloadUrl);
        widget.salesService.updateLastReadTime();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("사진 전송 실패")));
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

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
                    // 🌟 [UX 고도화] 모바일/태블릿 웹에서는 엔터키 가로채기를 해제하여 100% 줄바꿈만 되도록 설정!
                    bindings: _isMobile ? {} : {
                      const SingleActivator(LogicalKeyboardKey.enter): () {
                        if (!_isSending) _sendMessage();
                      },
                    },
                    child: TextField(
                      focusNode: _focusNode,
                      controller: _msgController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,

                      // 🌟 [수정 2] PC/모바일 상관없이 무조건 'newline'으로 설정하고, onSubmitted를 뺍니다.
                      // 브라우저가 강제로 엔터를 '전송'으로 처리하는 것을 막아주어 Shift+Enter가 완벽히 동작합니다!
                      textInputAction: TextInputAction.newline,
                      onSubmitted: null,

                      decoration: InputDecoration(
                        // 🌟 [UX 고도화] 줄바꿈 단축키(Shift+Enter) 힌트 안내 추가
                        hintText: _isMobile ? "메시지 입력 (엔터: 줄바꿈)" : "메시지 입력 (Enter: 전송, Shift+Enter: 줄바꿈)",
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