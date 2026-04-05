import 'package:cloud_firestore/cloud_firestore.dart';

enum UrgencyLevel { urgent, high, medium }

class UrgentTaskModel {
  final String id;
  final String taskId;
  final String title;
  final String barangay;
  final String city;
  final String category; // e.g. 'Emergency Response'
  final List<String> tags; // e.g. ['Injured People', 'Rescue Needed']
  final int points;
  final int volunteersNeeded;
  final int volunteersAccepted;
  final DateTime scheduledAt;
  final UrgencyLevel urgency;
  final List<String> urgentReasons;
  final bool isVerifiedUrgent; // official tag from admin/CF

  const UrgentTaskModel({
    required this.id,
    required this.taskId,
    required this.title,
    required this.barangay,
    required this.city,
    required this.category,
    this.tags = const [],
    required this.points,
    this.volunteersNeeded = 10,
    this.volunteersAccepted = 0,
    required this.scheduledAt,
    this.urgency = UrgencyLevel.urgent,
    this.urgentReasons = const [],
    this.isVerifiedUrgent = false,
  });

  factory UrgentTaskModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UrgentTaskModel(
      id: doc.id,
      taskId: d['taskId'] ?? doc.id,
      title: d['title'] ?? '',
      barangay: d['barangay'] ?? '',
      city: d['city'] ?? '',
      category: d['category'] ?? 'General',
      tags: List<String>.from(d['tags'] ?? []),
      points: d['points'] ?? 0,
      volunteersNeeded: d['volunteersNeeded'] ?? 10,
      volunteersAccepted: d['volunteersAccepted'] ?? 0,
      scheduledAt: (d['scheduledStart'] as Timestamp?)?.toDate() ?? 
                   (d['scheduledAt'] as Timestamp?)?.toDate() ?? 
                   DateTime.now(), // ← reads scheduledStart, falls back to scheduledAt
      urgency: _urgencyFromString(d['urgency']),
      urgentReasons: List<String>.from(d['urgentReasons'] ?? []),
      isVerifiedUrgent: d['isVerifiedUrgent'] ?? false,
    );
  }

  static UrgencyLevel _urgencyFromString(String? s) {
    switch (s) {
      case 'high':
        return UrgencyLevel.high;
      case 'medium':
        return UrgencyLevel.medium;
      default:
        return UrgencyLevel.urgent;
    }
  }

  Map<String, dynamic> toFirestore() => {
        'taskId': taskId,
        'title': title,
        'barangay': barangay,
        'city': city,
        'category': category,
        'tags': tags,
        'points': points,
        'volunteersNeeded': volunteersNeeded,
        'volunteersAccepted': volunteersAccepted,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'urgency': urgency.name,
        'urgentReasons': urgentReasons,
        'isVerifiedUrgent': isVerifiedUrgent,
      };
}
