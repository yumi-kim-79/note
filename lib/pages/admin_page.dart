// [파일 위치: lib/pages/admin_page.dart]
// 수정 내용:
// 1. 디자인 시스템(AppTheme, CommonCard, CommonButton) 적용하여 UI 통일
// 2. 슈퍼 관리자(대표님) 전용 비밀번호 확인 기능 및 로직 100% 유지

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ 디자인 시스템 import
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  // 직급 목록
  final List<String> _rankOptions = ['사원', '주임', '대리', '과장', '차장', '팀장', '부장', '이사', '상무', '전무', '대표'];

  // [중요] 슈퍼 관리자 이메일 (정확해야 함)
  final String _superAdminEmail = "yuseok8052@gmail.com";

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final String myEmail = currentUser?.email ?? "";

    // 슈퍼 관리자 여부 확인
    bool isSuperAdmin = myEmail.trim().toLowerCase() == _superAdminEmail.trim().toLowerCase();

    return Container(
      color: AppTheme.backgroundColor, // 배경색 통일
      child: Column(
        children: [
          // 1. 헤더 영역
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("직원 관리", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain)),

                    // 신규 직원 등록 버튼 (공통 버튼 사용)
                    CommonButton(
                      text: "신규 직원 등록",
                      icon: Icons.person_add,
                      onPressed: _showAddEmployeeDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // [확인용] 접속자 정보
                Text(
                  "현재 접속: $myEmail ${isSuperAdmin ? '(슈퍼관리자 인증됨)' : '(일반관리자 - 비번조회 불가)'}",
                  style: TextStyle(fontSize: 12, color: isSuperAdmin ? AppTheme.primaryColor : AppTheme.textSub),
                ),
              ],
            ),
          ),

          // 2. 직원 리스트 영역
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.hasData ? snapshot.data!.docs : [];
                if (docs.isEmpty) return const Center(child: Text("등록된 직원이 없습니다.", style: TextStyle(color: AppTheme.textSub)));

                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String docId = docs[index].id;
                    String name = data['name'] ?? '이름 없음';
                    String rank = data['rank'] ?? '사원';
                    String emailField = data['email'] ?? '';

                    // 화면 표시용 ID
                    String displayId = emailField.contains('@') ? emailField.split('@')[0] : emailField;

                    // DB에 저장된 비밀번호 가져오기
                    String? savedPw = data['password'];
                    String role = data['role'] == 'admin' ? '관리자모드' : '일반모드';
                    bool isAdminRole = data['role'] == 'admin';

                    // ✅ 디자인 시스템: 공통 카드 사용
                    return CommonCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        leading: CircleAvatar(
                          backgroundColor: isAdminRole ? AppTheme.textMain : AppTheme.primaryLight,
                          child: Icon(Icons.person, color: isAdminRole ? Colors.white : AppTheme.primaryColor),
                        ),
                        title: Row(
                          children: [
                            Text("$name $rank", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textMain)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: isAdminRole ? Colors.black12 : Colors.green[50],
                                  borderRadius: BorderRadius.circular(4)
                              ),
                              child: Text(role, style: TextStyle(fontSize: 11, color: isAdminRole ? Colors.black : Colors.green, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("ID: $displayId", style: const TextStyle(color: AppTheme.textMain)),

                              // [비밀번호 표시 로직 유지]
                              if (isSuperAdmin) ...[
                                if (savedPw != null && savedPw.isNotEmpty)
                                  Text("PW: $savedPw", style: const TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold))
                                else
                                  const Text("PW: (기록 없음 - 재등록 필요)", style: TextStyle(color: AppTheme.textSub, fontSize: 12))
                              ] else ...[
                                const Text("PW: ****", style: TextStyle(color: AppTheme.textSub))
                              ]
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                              onPressed: () => _showEditEmployeeDialog(docId, data),
                              tooltip: "정보 수정",
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.textSub),
                              onPressed: () => _deleteEmployee(docId, displayId, name),
                              tooltip: "삭제",
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------
  // [기능 1] 신규 직원 등록 (디자인 적용)
  // ----------------------------------------------------------------
  void _showAddEmployeeDialog() {
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    String selectedRank = _rankOptions[0];
    String selectedRole = 'user';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: CommonCard(
                width: 400,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("신규 직원 등록", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                    const SizedBox(height: 24),

                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "이름", hintText: "홍길동")),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: selectedRank,
                      decoration: const InputDecoration(labelText: "직급"),
                      items: _rankOptions.map((rank) => DropdownMenuItem(value: rank, child: Text(rank))).toList(),
                      onChanged: (val) => setStateDialog(() => selectedRank = val!),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: "아이디 (휴대폰 번호)", hintText: "01012345678"),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: passCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: const InputDecoration(labelText: "비밀번호 (숫자 4자리)", counterText: ""),
                    ),
                    const SizedBox(height: 24),

                    const Align(alignment: Alignment.centerLeft, child: Text("권한 설정", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain))),
                    RadioListTile(
                      title: const Text("일반모드", style: TextStyle(fontSize: 14)), subtitle: const Text("본인 글만 관리", style: TextStyle(fontSize: 12)),
                      value: 'user', groupValue: selectedRole,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) => setStateDialog(() => selectedRole = val.toString()),
                    ),
                    RadioListTile(
                      title: const Text("관리자모드", style: TextStyle(fontSize: 14)), subtitle: const Text("모든 권한 보유", style: TextStyle(fontSize: 12)),
                      value: 'admin', groupValue: selectedRole,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) => setStateDialog(() => selectedRole = val.toString()),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("취소", style: TextStyle(color: AppTheme.textSub))
                        ),
                        const SizedBox(width: 8),
                        CommonButton(
                          text: "등록하기",
                          onPressed: () async {
                            if (phoneCtrl.text.isEmpty || passCtrl.text.length != 4 || nameCtrl.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("정보를 올바르게 입력해주세요 (비번 4자리)")));
                              return;
                            }
                            String realEmailId = "${phoneCtrl.text}@sm.com";

                            await _registerEmployee(
                              email: realEmailId,
                              password: "${passCtrl.text}00",
                              displayPw: passCtrl.text,
                              name: nameCtrl.text.trim(),
                              rank: selectedRank,
                              role: selectedRole,
                            );
                            Navigator.pop(context);
                          },
                          width: 100,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------------------
  // [기능 2] 직원 수정 (디자인 적용)
  // ----------------------------------------------------------------
  void _showEditEmployeeDialog(String docId, Map<String, dynamic> data) {
    final nameCtrl = TextEditingController(text: data['name']);
    String selectedRank = data['rank'] ?? '사원';
    String selectedRole = data['role'] ?? 'user';

    if (!_rankOptions.contains(selectedRank)) selectedRank = _rankOptions[0];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: CommonCard(
                width: 400,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("직원 정보 수정", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                    const SizedBox(height: 24),

                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "이름")),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: selectedRank,
                      decoration: const InputDecoration(labelText: "직급"),
                      items: _rankOptions.map((rank) => DropdownMenuItem(value: rank, child: Text(rank))).toList(),
                      onChanged: (val) => setStateDialog(() => selectedRank = val!),
                    ),
                    const SizedBox(height: 24),

                    const Align(alignment: Alignment.centerLeft, child: Text("권한 설정", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain))),
                    RadioListTile(
                      title: const Text("일반모드", style: TextStyle(fontSize: 14)),
                      value: 'user', groupValue: selectedRole,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) => setStateDialog(() => selectedRole = val.toString()),
                    ),
                    RadioListTile(
                      title: const Text("관리자모드", style: TextStyle(fontSize: 14)),
                      value: 'admin', groupValue: selectedRole,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) => setStateDialog(() => selectedRole = val.toString()),
                    ),
                    const SizedBox(height: 10),
                    const Text("* 아이디와 비밀번호 변경은 삭제 후 재등록해주세요.", style: TextStyle(color: AppTheme.errorColor, fontSize: 12)),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소", style: TextStyle(color: AppTheme.textSub))),
                        const SizedBox(width: 8),
                        CommonButton(
                          text: "수정 완료",
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('users').doc(docId).update({
                              'name': nameCtrl.text,
                              'rank': selectedRank,
                              'role': selectedRole,
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("수정되었습니다.")));
                          },
                          width: 100,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------------------
  // [기능 3] 직원 등록 로직 (기능 100% 유지)
  // ----------------------------------------------------------------
  Future<void> _registerEmployee({required String email, required String password, required String displayPw, required String name, required String rank, required String role}) async {
    FirebaseApp? tempApp;
    try {
      tempApp = await Firebase.initializeApp(name: 'temporaryRegisterApp', options: Firebase.app().options);
      UserCredential userCredential = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'password': displayPw, // [중요] 관리자 확인용 비번 저장
          'name': name,
          'rank': rank,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name 님 등록 완료!")));
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = "등록 실패";
      if (e.code == 'email-already-in-use') errorMsg = "이미 등록된 휴대폰 번호입니다.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: AppTheme.errorColor));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("오류 발생: $e")));
    } finally {
      await tempApp?.delete();
    }
  }

  void _deleteEmployee(String docId, String email, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("직원 삭제", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("정말로 '$name' ($email) 님을 목록에서 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(docId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제되었습니다.")));
            },
            child: const Text("삭제", style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}