// 🏷️ [메뉴 이름: 건물 DB 관리]
// [파일 위치: lib/pages/building_info_page.dart]
// 수정 내용:
// 1. [에러 수정] CommonButton의 'height' 파라미터 제거 -> SizedBox로 감싸서 높이 조절
// 2. [반응형 UI] 모바일에서 헤더가 깨지지 않도록 레이아웃 조정 (Mobile: 2줄 / PC: 1줄)
// 3. 관리자 권한 삭제, 엑셀 업로드 등 기존 기능 100% 유지

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import '../utils/daum_postcode_stub.dart' if (dart.library.html) '../utils/daum_postcode_web.dart';

import '../services/sales_service.dart';

// ✅ 디자인 시스템 import
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class BuildingInfoPage extends StatefulWidget {
  const BuildingInfoPage({super.key});

  @override
  State<BuildingInfoPage> createState() => _BuildingInfoPageState();
}

class _BuildingInfoPageState extends State<BuildingInfoPage> {
  final SalesService _salesService = SalesService();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchText = "";
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  // ====================================================
  // 엑셀(.xlsx) 업로드 기능
  // ====================================================
  Future<void> _pickAndUploadExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null) {
        PlatformFile file = result.files.first;

        if (file.extension != 'xlsx' && !file.name.toLowerCase().endsWith('.xlsx')) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("엑셀(.xlsx) 파일만 선택해주세요."), backgroundColor: AppTheme.errorColor)
          );
          return;
        }

        if (!mounted) return;
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (c) => const Center(child: CircularProgressIndicator())
        );

        var bytes = file.bytes;
        if (bytes == null) throw Exception("파일 데이터를 읽을 수 없습니다.");

        var excel = Excel.decodeBytes(bytes);
        var table = excel.tables[excel.tables.keys.first];

        int addedCount = 0;
        int updatedCount = 0;

        if (table != null && table.rows.length > 3) {
          for (int i = 3; i < table.rows.length; i++) {
            var row = table.rows[i];
            if (row.length < 3) continue;

            String name = _getCellValue(row[1]);
            String address = _getCellValue(row[2]);

            if (name.isNotEmpty && address.isNotEmpty) {
              var snapshot = await FirebaseFirestore.instance
                  .collection('buildings')
                  .where('address', isEqualTo: address)
                  .get();

              if (snapshot.docs.isNotEmpty) {
                for (var doc in snapshot.docs) {
                  await _salesService.updateBuildingInfo(doc.id, name, address);
                }
                updatedCount++;
              } else {
                await _salesService.addBuildingInfo(name, address);
                addedCount++;
              }
            }
          }
        }

        if (mounted) {
          Navigator.pop(context);

          String message = "완료: 신규 $addedCount건, 덮어쓰기 $updatedCount건";
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: AppTheme.primaryColor,
              )
          );
          setState(() { _currentPage = 1; });
        }
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("오류 발생: $e"), backgroundColor: AppTheme.errorColor)
        );
      }
    }
  }

  String _getCellValue(var cell) {
    if (cell == null) return "";
    var val = cell.value;
    if (val == null) return "";
    return val.toString().trim();
  }

  void _showEditDialog({String? docId, String? currentName, String? currentAddress}) {
    bool isEdit = docId != null;
    _nameCtrl.text = currentName ?? "";
    _addressCtrl.text = currentAddress ?? "";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: CommonCard(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? "건물 정보 수정" : "새 건물 등록", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
              const SizedBox(height: 24),

              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "건물명", hintText: "예: 파크타운 1차"),
              ),
              const SizedBox(height: 16),
              // 🌟 [고도화] 다음(Daum) API 연동 주소 검색기
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addressCtrl,
                      readOnly: true, // 🚨 사용자가 임의로 타이핑하지 못하게 막음 (데이터 무결성 보장)
                      decoration: const InputDecoration(
                        labelText: "도로명 주소",
                        hintText: "우측 '주소 검색' 버튼을 이용해주세요",
                        filled: true,
                        fillColor: Color(0xFFF5F5F5), // 약간 회색 배경으로 변경
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text("주소 검색"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: () async {
                        // 🌟 우리가 만든 직통 터널을 통해 카카오 팝업 호출!
                        Map<String, String>? result = await searchAddress();

                        // 사용자가 주소를 선택하고 돌아왔다면?
                        if (result != null && context.mounted) {
                          setState(() {
                            // 1. 도로명 주소 텍스트칸에 삽입
                            _addressCtrl.text = result['address'] ?? '';

                            // 2. (보너스 마법) 건물명이 비어있으면 자동 완성
                            if (_nameCtrl.text.isEmpty && result['buildingName'] != null && result['buildingName']!.isNotEmpty) {
                              _nameCtrl.text = result['buildingName']!;
                            }
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (!isEdit)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text("※ 네이버 지도 검색용 정확한 주소를 입력해주세요.", style: TextStyle(fontSize: 12, color: AppTheme.primaryColor)),
                ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("취소", style: TextStyle(color: AppTheme.textSub))
                  ),
                  const SizedBox(width: 8),
                  CommonButton(
                    text: isEdit ? "수정완료" : "등록",
                    onPressed: () {
                      if (_nameCtrl.text.isNotEmpty && _addressCtrl.text.isNotEmpty) {
                        if (isEdit) {
                          _salesService.updateBuildingInfo(docId, _nameCtrl.text, _addressCtrl.text);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("수정되었습니다.")));
                        } else {
                          _salesService.addBuildingInfo(_nameCtrl.text, _addressCtrl.text);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("새 건물이 등록되었습니다.")));
                        }
                        Navigator.pop(context);
                      }
                    },
                    width: 100,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteItem(String docId) async {
    bool? confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("삭제", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("정말 삭제하시겠습니까?\n경로 관리 리스트에서도 사라집니다."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: AppTheme.errorColor))),
          ],
        )
    );
    if (confirm == true) {
      _salesService.deleteBuildingInfo(docId);
    }
  }
  // 🌟 [고도화 추가] 상단 헤더용 실시간 건물 개수 뱃지 위젯
  Widget _buildTotalCountBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: _salesService.getBuildingsStream(),
      builder: (context, snapshot) {
        // 로딩 중이거나 데이터가 없으면 0개로 표시
        int total = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "$total개",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
        );
      },
    );
  }

  List<Widget> _buildPaginationButtons(int totalPages) {
    List<Widget> buttons = [];

    Widget pageBtn(int pageNum) {
      bool isActive = pageNum == _currentPage;
      return InkWell(
        onTap: () => setState(() => _currentPage = pageNum),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: isActive ? null : Border.all(color: AppTheme.borderColor),
          ),
          child: Text(
            "$pageNum",
            style: TextStyle(
              color: isActive ? Colors.white : AppTheme.textMain,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    Widget dots = const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text("...", style: TextStyle(color: AppTheme.textSub)),
    );

    if (totalPages <= 7) {
      for (int i = 1; i <= totalPages; i++) {
        buttons.add(pageBtn(i));
      }
    } else {
      buttons.add(pageBtn(1));
      if (_currentPage <= 4) {
        for (int i = 2; i <= 5; i++) buttons.add(pageBtn(i));
        buttons.add(dots);
        buttons.add(pageBtn(totalPages));
      } else if (_currentPage >= totalPages - 3) {
        buttons.add(dots);
        for (int i = totalPages - 4; i <= totalPages; i++) buttons.add(pageBtn(i));
      } else {
        buttons.add(dots);
        buttons.add(pageBtn(_currentPage - 1));
        buttons.add(pageBtn(_currentPage));
        buttons.add(pageBtn(_currentPage + 1));
        buttons.add(dots);
        buttons.add(pageBtn(totalPages));
      }
    }
    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // ✅ 화면 폭이 600px 미만이면 모바일로 간주
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, userSnapshot) {
        bool isAdmin = false;
        if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          if (userData['rank'] == '관리자') {
            isAdmin = true;
          }
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // ✅ [수정됨] 반응형 헤더 (실시간 건물 수 뱃지 고도화 적용)
              Container(
                padding: const EdgeInsets.only(bottom: 24),
                child: isMobile
                    ? Column( // 📱 모바일: 세로 배치
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. 타이틀 영역
                    Row(
                      children: [
                        const Icon(Icons.domain, size: 28, color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text("건물 DB 관리", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                                const SizedBox(width: 8),
                                _buildTotalCountBadge(), // 🌟 뱃지 장착!
                              ],
                            ),
                            const Text("경로 탐색용 마스터 데이터", style: TextStyle(fontSize: 12, color: AppTheme.textSub)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 2. 버튼 영역 (2줄)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickAndUploadExcel,
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text("엑셀 업로드"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppTheme.primaryColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: CommonButton(
                              text: "건물 추가",
                              icon: Icons.add,
                              onPressed: () => _showEditDialog(),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                )
                    : Row( // 💻 PC/태블릿: 가로 배치 (기존 스타일)
                  children: [
                    const Icon(Icons.domain, size: 28, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text("건물 DB 관리", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                            const SizedBox(width: 8),
                            _buildTotalCountBadge(), // 🌟 뱃지 장착!
                          ],
                        ),
                        const Text("경로 탐색을 위한 마스터 데이터", style: TextStyle(fontSize: 12, color: AppTheme.textSub)),
                      ],
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _pickAndUploadExcel,
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text("엑셀 업로드"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        side: const BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CommonButton(
                      text: "건물 추가",
                      icon: Icons.add,
                      onPressed: () => _showEditDialog(),
                    ),
                  ],
                ),
              ),

              // 2. 검색창 영역
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) {
                    setState(() {
                      _searchText = val;
                      _currentPage = 1;
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSub),
                    hintText: "건물명 또는 주소로 검색...",
                    suffixIcon: _searchText.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, size: 20, color: AppTheme.textSub),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() { _searchText = ""; _currentPage = 1; });
                      },
                    )
                        : null,
                  ),
                ),
              ),

              // 3. 리스트 및 페이지네이션
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _salesService.getBuildingsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("등록된 데이터가 없습니다.", style: TextStyle(color: AppTheme.textSub)));
                    }

                    var allDocs = snapshot.data!.docs;

                    if (_searchText.isNotEmpty) {
                      allDocs = allDocs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        String name = (data['name'] ?? '').toString().toLowerCase();
                        String addr = (data['address'] ?? '').toString().toLowerCase();
                        String keyword = _searchText.toLowerCase();
                        return name.contains(keyword) || addr.contains(keyword);
                      }).toList();
                    }

                    if (allDocs.isEmpty) {
                      return const Center(child: Text("검색 결과가 없습니다.", style: TextStyle(color: AppTheme.textSub)));
                    }

                    int totalItems = allDocs.length;
                    int totalPages = (totalItems / _itemsPerPage).ceil();

                    if (_currentPage > totalPages) _currentPage = totalPages;
                    if (_currentPage < 1) _currentPage = 1;

                    int startIndex = (_currentPage - 1) * _itemsPerPage;
                    int endIndex = startIndex + _itemsPerPage;
                    if (endIndex > totalItems) endIndex = totalItems;

                    var currentDocs = allDocs.sublist(startIndex, endIndex);

                    return Column(
                      children: [
                        // 리스트 아이템
                        Expanded(
                          child: ListView.separated(
                            itemCount: currentDocs.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              var doc = currentDocs[index];
                              var data = doc.data() as Map<String, dynamic>;

                              return CommonCard(
                                padding: EdgeInsets.zero,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.location_city, color: AppTheme.primaryColor),
                                  ),
                                  title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textMain)),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(data['address'] ?? '', style: const TextStyle(color: AppTheme.textSub, fontSize: 13)),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // 수정 버튼
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20, color: AppTheme.textSub),
                                        onPressed: () => _showEditDialog(
                                          docId: doc.id,
                                          currentName: data['name'],
                                          currentAddress: data['address'],
                                        ),
                                      ),

                                      // ✅ [보안] 관리자만 삭제 버튼 보이기
                                      if (isAdmin)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.errorColor),
                                          onPressed: () => _deleteItem(doc.id),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // 하단 페이지네이션
                        if (totalPages > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _currentPage > 1
                                      ? () => setState(() => _currentPage--)
                                      : null,
                                ),
                                ..._buildPaginationButtons(totalPages),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: _currentPage < totalPages
                                      ? () => setState(() => _currentPage++)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}