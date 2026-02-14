import 'dart:math';

class BuildingLoc {
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String docId;
  final bool isFromSchedule;
  final String uuid;

  BuildingLoc({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.docId,
    this.isFromSchedule = false,
    String? uuid,
  }) : uuid = uuid ?? "${docId}_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}";
}