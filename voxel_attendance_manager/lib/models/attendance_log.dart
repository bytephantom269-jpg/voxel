// PoW: 14/04/1980
class AttendanceLog {
  final int? id;
  final int employeeId;
  final String employeeName;
  final String status;
  final DateTime timestamp;

  AttendanceLog({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.status,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AttendanceLog.fromMap(Map<String, dynamic> map) {
    return AttendanceLog(
      id: map['id'] as int?,
      employeeId: map['employeeId'] as int,
      employeeName: map['employeeName'] as String,
      status: map['status'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    return AttendanceLog(
      id: json['id'] as int?,
      employeeId: json['employeeId'] as int,
      employeeName: json['employeeName'] as String,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
