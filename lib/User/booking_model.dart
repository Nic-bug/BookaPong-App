import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String? id;
  final String userId;
  final String facilityId;
  final String facilityName;
  final String table;
  final DateTime startTime;
  final DateTime endTime;
  final String accessCode;
  final double amountPaid;
  final String status;

  BookingModel({
    this.id,
    required this.userId,
    required this.facilityId,
    required this.facilityName,
    required this.table,
    required this.startTime,
    required this.endTime,
    required this.accessCode,
    required this.amountPaid,
    this.status = 'confirmed',
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'facilityId': facilityId,
    'facilityName': facilityName,
    'table': table,
    'startTime': Timestamp.fromDate(startTime),
    'endTime': Timestamp.fromDate(endTime),
    'accessCode': accessCode,
    'amountPaid': amountPaid,
    'status': status,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory BookingModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      facilityId: data['facilityId'] ?? '',
      facilityName: data['facilityName'] ?? '',
      table: data['table'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      accessCode: data['accessCode'] ?? '',
      amountPaid: (data['amountPaid'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'confirmed',
    );
  }
}
