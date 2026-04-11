import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus { open, accepted, inProgress, completed, verified, cancelled }

enum TaskCategory {
  emergencyResponse,
  cleanupRecovery,
  reliefDistribution,
  medicalAssistance,
  preparedness,
  other
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String barangay;
  final String city;
  final TaskCategory category;
  final List<String> tags;
  final int points;
  final int volunteersNeeded;
  final int volunteersAccepted;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final TaskStatus status;
  final String createdBy;
  // ── FIX: was String? (single user) → now List<String> ─────────────────────
  // Old single-string field caused every user to see the SAME task as
  // "accepted by them" once any user accepted it.
  final List<String> acceptedByList;
  // Keep acceptedBy for Firestore backward-compat reads only.
  final String? acceptedBy;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final String? imageUrl;
  final bool isUrgent;
  final double? latitude;
  final double? longitude;
  final String? verificationNote;
  final List<String> verificationPhotos;
  final String? completionSummary;
  final String? issues;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.barangay,
    required this.city,
    required this.category,
    this.tags = const [],
    required this.points,
    this.volunteersNeeded = 1,
    this.volunteersAccepted = 0,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.status = TaskStatus.open,
    required this.createdBy,
    this.acceptedByList = const [],
    this.acceptedBy,
    this.acceptedAt,
    this.completedAt,
    this.imageUrl,
    this.isUrgent = false,
    this.latitude,
    this.longitude,
    this.verificationNote,
    this.verificationPhotos = const [],
    this.completionSummary,
    this.issues,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    // Support both old string field and new list field.
    List<String> resolvedList =
        List<String>.from(d['acceptedByList'] ?? []);
    final legacyAcceptedBy = d['acceptedBy'] as String?;
    if (resolvedList.isEmpty && legacyAcceptedBy != null) {
      resolvedList = [legacyAcceptedBy];
    }

    return TaskModel(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      barangay: d['barangay'] ?? '',
      city: d['city'] ?? '',
      category: _categoryFromString(d['category']),
      tags: List<String>.from(d['tags'] ?? []),
      points: d['points'] ?? 0,
      volunteersNeeded: d['volunteersNeeded'] ?? 1,
      volunteersAccepted: d['volunteersAccepted'] ?? 0,
      scheduledStart: (d['scheduledStart'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      scheduledEnd: (d['scheduledEnd'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(hours: 2)),
      status: _statusFromString(d['status']),
      createdBy: d['createdBy'] ?? '',
      acceptedByList: resolvedList,
      acceptedBy: legacyAcceptedBy,
      acceptedAt: (d['acceptedAt'] as Timestamp?)?.toDate(),
      completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
      imageUrl: d['imageUrl'],
      isUrgent: d['isUrgent'] ?? false,
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
      verificationNote: d['verificationNote'],
      verificationPhotos:
          List<String>.from(d['verificationPhotos'] ?? []),
      completionSummary: d['completionSummary'],
      issues: d['issues'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'barangay': barangay,
        'city': city,
        'category': category.name,
        'tags': tags,
        'points': points,
        'volunteersNeeded': volunteersNeeded,
        'volunteersAccepted': volunteersAccepted,
        'scheduledStart': Timestamp.fromDate(scheduledStart),
        'scheduledEnd': Timestamp.fromDate(scheduledEnd),
        'status': status.name,
        'createdBy': createdBy,
        'acceptedByList': acceptedByList,
        'acceptedBy': acceptedByList.isNotEmpty ? acceptedByList.last : null,
        'acceptedAt':
            acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'imageUrl': imageUrl,
        'isUrgent': isUrgent,
        'latitude': latitude,
        'longitude': longitude,
        'verificationNote': verificationNote,
        'verificationPhotos': verificationPhotos,
        'completionSummary': completionSummary,
        'issues': issues,
      };

  /// Whether a specific user has accepted this task.
  bool isAcceptedBy(String userId) =>
      acceptedByList.contains(userId) || acceptedBy == userId;

  static TaskStatus _statusFromString(String? s) {
    switch (s) {
      case 'accepted':
        return TaskStatus.accepted;
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'verified':
        return TaskStatus.verified;
      case 'cancelled':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.open;
    }
  }

  static TaskCategory _categoryFromString(String? s) {
    switch (s) {
      case 'cleanupRecovery':
        return TaskCategory.cleanupRecovery;
      case 'reliefDistribution':
        return TaskCategory.reliefDistribution;
      case 'medicalAssistance':
        return TaskCategory.medicalAssistance;
      case 'preparedness':
        return TaskCategory.preparedness;
      case 'other':
        return TaskCategory.other;
      default:
        return TaskCategory.emergencyResponse;
    }
  }

  String get categoryLabel {
    switch (category) {
      case TaskCategory.emergencyResponse:
        return 'Emergency Response';
      case TaskCategory.cleanupRecovery:
        return 'Cleanup & Recovery';
      case TaskCategory.reliefDistribution:
        return 'Relief Distribution';
      case TaskCategory.medicalAssistance:
        return 'Medical Assistance';
      case TaskCategory.preparedness:
        return 'Preparedness';
      case TaskCategory.other:
        return 'Other';
    }
  }

  TaskModel copyWith({
    TaskStatus? status,
    List<String>? acceptedByList,
    String? acceptedBy,
    DateTime? acceptedAt,
    DateTime? completedAt,
    String? verificationNote,
    List<String>? verificationPhotos,
    int? volunteersAccepted,
    String? completionSummary,
    String? issues,
  }) {
    return TaskModel(
      id: id,
      title: title,
      description: description,
      barangay: barangay,
      city: city,
      category: category,
      tags: tags,
      points: points,
      volunteersNeeded: volunteersNeeded,
      volunteersAccepted: volunteersAccepted ?? this.volunteersAccepted,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      status: status ?? this.status,
      createdBy: createdBy,
      acceptedByList: acceptedByList ?? this.acceptedByList,
      acceptedBy: acceptedBy ?? this.acceptedBy,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      imageUrl: imageUrl,
      isUrgent: isUrgent,
      latitude: latitude,
      longitude: longitude,
      verificationNote: verificationNote ?? this.verificationNote,
      verificationPhotos: verificationPhotos ?? this.verificationPhotos,
      completionSummary: completionSummary ?? this.completionSummary,
      issues: issues ?? this.issues,
    );
  }

  // ─── Mock data ──────────────────────────────────────────────────────────────
  static List<TaskModel> get mockTasks => [
        TaskModel(
          id: 'task_1',
          title: 'Medical Assistance for Injured Individuals',
          description:
              'Provide first aid and medical support to flood victims in Brgy. Rizal. Set up a triage station to assess and prioritize patients. Coordinate with nurses and doctors to treat minor wounds, sprains, and dehydration. Ensure all patients are recorded and directed to appropriate facilities if needed.',
          barangay: 'Brgy. Rizal',
          city: 'Iloilo City',
          category: TaskCategory.medicalAssistance,
          tags: const ['Injured People', 'Urgent', 'Medical'],
          points: 250,
          volunteersNeeded: 10,
          volunteersAccepted: 4,
          scheduledStart: DateTime(2026, 3, 21, 14, 0),
          scheduledEnd: DateTime(2026, 3, 21, 18, 0),
          createdBy: 'uid_admin',
          isUrgent: true,
          latitude: 10.7202,
          longitude: 122.5621,
        ),
        TaskModel(
          id: 'task_2',
          title: 'Debris Clearing – Brgy. San Pedro',
          description:
              'Clear flood debris from main road and drainage canals. Remove fallen branches, mud, and displaced materials blocking traffic. Organize volunteers to sweep and rake debris into collection points. Ensure proper drainage by clearing canal entries to prevent water stagnation.',
          barangay: 'Brgy. San Pedro',
          city: 'Iloilo City',
          category: TaskCategory.cleanupRecovery,
          tags: const ['Cleanup', 'Physical Work'],
          points: 150,
          volunteersNeeded: 20,
          volunteersAccepted: 12,
          scheduledStart: DateTime(2026, 3, 22, 8, 0),
          scheduledEnd: DateTime(2026, 3, 22, 12, 0),
          createdBy: 'uid_admin',
          latitude: 10.7180,
          longitude: 122.5600,
        ),
        TaskModel(
          id: 'task_3',
          title: 'Relief Pack Distribution – Evacuation Center',
          description:
              'Sort and distribute food packs, hygiene kits, and clothing to displaced families. Organize supplies by category on tables for easy access. Check family lists against inventory to match needs. Distribute with compassion and document recipients for tracking.',
          barangay: 'Brgy. Molo',
          city: 'Iloilo City',
          category: TaskCategory.reliefDistribution,
          tags: const ['Relief', 'Food', 'Families'],
          points: 120,
          volunteersNeeded: 15,
          volunteersAccepted: 8,
          scheduledStart: DateTime(2026, 3, 23, 9, 0),
          scheduledEnd: DateTime(2026, 3, 23, 15, 0),
          createdBy: 'uid_admin',
        ),
      ];
}