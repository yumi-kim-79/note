//반상회 안건 db 업로드 페이지
//언제든 새로운 안건을 정리해서 파이어 베이스에 업로드 시킬수 있다,

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AgendaDbUploadPage extends StatefulWidget {
  const AgendaDbUploadPage({super.key});

  @override
  State<AgendaDbUploadPage> createState() => _AgendaDbUploadPageState();
}

class _AgendaDbUploadPageState extends State<AgendaDbUploadPage> {
  bool _isUploading = false; // 업로드 중 로딩 상태 표시

  // ---------------------------------------------------------
  // 🚀 [STEP 1] 핵심 10개 안건 데이터 리스트
  // ---------------------------------------------------------
  Future<void> _bulkUploadAgendas() async {
    setState(() {
      _isUploading = true;
    });

    // 1. 법무팀 검토 완료된 프리미엄 안건 데이터 세트 (우선 10개)
    List<Map<String, dynamic>> initialAgendas = [
      {
        "category": "집합건물/인사",
        "title": "[비의무관리] 관리위원(동대표) 임기 만료에 따른 연임 의결의 건",
        "reason": "현재 건물의 관리 업무를 심의하는 관리위원의 임기가 만료됨에 따라, 업무의 연속성을 유지하고 안정적인 운영을 위해 기존 위원의 연임 여부를 관리단 집회(또는 위원회)에서 결정하고자 함.",
        "content": "1. 대상 위원의 그간 활동 평가 및 연임 의사 확인\n2. 규약이 정하는 바에 따라 연임 찬반 투표 진행 및 결과 공고",
        "legal": "집합건물의 소유 및 관리에 관한 법률 제26조의2 및 관리단 규약",
        "keywords": ["연임", "임기만료", "관리위원", "동대표", "비의무", "집합건물"]
      },
      {
        "category": "집합건물/인사",
        "title": "[비의무관리] 관리인(대표자) 중임 제한 예외 적용 및 재선출의 건",
        "reason": "우리 건물 규약상 중임 제한 규정이 있으나, 차기 후보자 부재로 인한 관리 공백을 방지하기 위해 집합건물법 취지에 따라 한시적으로 중임 제한 예외를 적용하여 후보 등록을 허용하고자 함.",
        "content": "1. 중임 제한 예외 적용 사유(후보자 미등록 등) 보고\n2. 예외적 후보 자격 부여 및 관리단 집회 선출 절차 의결",
        "legal": "집합건물의 소유 및 관리에 관한 법률 제24조 및 관리단 규약",
        "keywords": ["중임제한", "재선출", "관리인", "비의무", "집합건물", "예외"]
      },
      {
        "category": "집합건물/인사",
        "title": "[비의무관리] 관리위원(동대표) 해임(안) 상정 및 징계의 건",
        "reason": "특정 관리위원이 집합건물법 및 규약을 위반하거나 관리단의 명예를 실추시키는 등 선량한 관리자의 주의 의무를 위반함에 따라, 적법한 절차를 거쳐 해임하고자 함.",
        "content": "1. 해임 사유(횡령, 배임, 직권남용 등) 소명 및 검토\n2. 관리단 집회 또는 위원회 결의를 통한 해임 확정 및 통보",
        "legal": "집합건물의 소유 및 관리에 관한 법률 제24조 제5항(해임 청구) 준용",
        "keywords": ["해임", "직무정지", "징계", "관리위원", "비의무", "분쟁"]
      },
      {
        "category": "집합건물/인사",
        "title": "[비의무관리] 관리위원(동대표) 사의 표명에 따른 궐위 위원 보궐 선거의 건",
        "reason": "일부 관리위원이 일신상의 사유로 사퇴서를 제출함에 따라, 원활한 의사결정 정족수 확보를 위해 결원된 자리를 채울 보궐 선거를 실시하고자 함.",
        "content": "1. 사퇴서 수리 및 궐위 사실 공고\n2. 잔여 임기를 수행할 보궐 위원 모집 및 선출 일정 확정",
        "legal": "집합건물의 소유 및 관리에 관한 법률 및 관리단 규약",
        "keywords": ["사의", "사퇴", "보궐선거", "결원충원", "관리위원", "비의무"]
      },
      {
        "category": "집합건물/인사",
        "title": "[비의무관리] 임시 관리인 선임 및 직무대행자 지정의 건",
        "reason": "관리인의 해임, 사퇴 또는 법적 분쟁으로 인해 정상적인 직무 수행이 불가능한 경우, 법원의 결정 전까지 건물의 필수 행정 업무를 처리할 임시 직무대행자를 지정하고자 함.",
        "content": "1. 직무대행자 선정 기준(최고령 위원 또는 관리소장 등) 및 권한 범위 설정\n2. 정식 관리인 선출 시까지의 한시적 운영 지침 의결",
        "legal": "집합건물의 소유 및 관리에 관한 법률 제24조 및 민법 제52조의2 준용",
        "keywords": ["직무대행", "임시관리인", "관리부재", "비의무", "집합건물"]
      }
    ];

    // 2. Firestore 'agenda_templates' 컬렉션에 일괄 업로드
    try {
      final collection = FirebaseFirestore.instance.collection('agenda_templates');

      for (var agenda in initialAgendas) {
        await collection.add(agenda);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ 성공적으로 10개의 핵심 안건이 DB에 업로드 되었습니다!"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("🚨 업로드 실패: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("⚙️ [관리자] 안건 DB 자동 업로더", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_upload_outlined, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 24),
              const Text(
                "SM 프리미엄 표준 안건 100선\n(현재 업로드 대기 중)",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text(
                "아래 버튼을 누르면 Firebase Firestore의\n'agenda_templates' 컬렉션에 데이터가 자동으로 삽입됩니다.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // 🚀 업로드 실행 버튼
              SizedBox(
                height: 56,
                width: 300,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _bulkUploadAgendas,
                  icon: _isUploading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.rocket_launch, color: Colors.white),
                  label: Text(
                    _isUploading ? "업로드 진행 중..." : "🔥 데이터 업로드 실행",
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}