class PickupRequest {
  final String id;
  final int studentId;
  final String studentName;
  final int parentId;
  final String parentName;
  final String reason;
  final DateTime timestamp;
  final String status; // PENDING, APPROVED, REJECTED
  final String? response;
  final String? conciergeName;
  final DateTime? responseTimestamp;

  PickupRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.parentId,
    required this.parentName,
    required this.reason,
    required this.timestamp,
    this.status = 'PENDING',
    this.response,
    this.conciergeName,
    this.responseTimestamp,
  });

  factory PickupRequest.fromJson(Map<String, dynamic> json) {
    return PickupRequest(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      studentId: json['studentId'] ?? 0,
      studentName: json['studentName'] ?? '',
      parentId: json['parentId'] ?? 0,
      parentName: json['parentName'] ?? '',
      reason: json['reason'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      status: json['status'] ?? 'PENDING',
      response: json['response'],
      conciergeName: json['conciergeName'],
      responseTimestamp: json['responseTimestamp'] != null 
          ? DateTime.parse(json['responseTimestamp']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'parentId': parentId,
      'parentName': parentName,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'response': response,
      'conciergeName': conciergeName,
      'responseTimestamp': responseTimestamp?.toIso8601String(),
    };
  }

  PickupRequest copyWith({
    String? id,
    int? studentId,
    String? studentName,
    int? parentId,
    String? parentName,
    String? reason,
    DateTime? timestamp,
    String? status,
    String? response,
    String? conciergeName,
    DateTime? responseTimestamp,
  }) {
    return PickupRequest(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      reason: reason ?? this.reason,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      response: response ?? this.response,
      conciergeName: conciergeName ?? this.conciergeName,
      responseTimestamp: responseTimestamp ?? this.responseTimestamp,
    );
  }
}
