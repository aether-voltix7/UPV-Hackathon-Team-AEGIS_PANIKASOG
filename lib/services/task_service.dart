import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Fetch Tasks ───────────────────────────────────────────────────────────

  Future<List<TaskModel>> getTasks({TaskStatus? status, TaskCategory? category}) async {
    Query<Map<String, dynamic>> q =
        _db.collection('tasks').orderBy('scheduledStart', descending: false);

    if (status != null) {
      q = q.where('status', isEqualTo: status.name);
    }
    if (category != null) {
      q = q.where('category', isEqualTo: category.name);
    }

    final snapshot = await q.get();
    return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
  }

  Stream<List<TaskModel>> tasksStream({TaskStatus? status}) {
    Query<Map<String, dynamic>> q =
        _db.collection('tasks').orderBy('scheduledStart', descending: false);

    if (status != null) {
      q = q.where('status', isEqualTo: status.name);
    }

    return q.snapshots().map(
          (snap) => snap.docs.map((d) => TaskModel.fromFirestore(d)).toList(),
        );
  }

  // ─── Create Task ───────────────────────────────────────────────────────────

  Future<TaskModel> createTask({
    required String title,
    required String description,
    required String barangay,
    required String city,
    required TaskCategory category,
    required List<String> tags,
    required int points,
    required int volunteersNeeded,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    required String createdBy,
    bool isUrgent = false,
    double? latitude,
    double? longitude,
  }) async {
    final docRef = _db.collection('tasks').doc();
    final task = TaskModel(
      id: docRef.id,
      title: title,
      description: description,
      barangay: barangay,
      city: city,
      category: category,
      tags: tags,
      points: points,
      volunteersNeeded: volunteersNeeded,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      createdBy: createdBy,
      isUrgent: isUrgent,
      latitude: latitude,
      longitude: longitude,
    );
    await docRef.set(task.toFirestore());
    return task;
  }

  // ─── Accept Task ───────────────────────────────────────────────────────────

  Future<void> acceptTask(String taskId, String userId) async {
    await _db.collection('tasks').doc(taskId).update({
      'status': TaskStatus.accepted.name,
      'acceptedBy': userId,
      'acceptedAt': FieldValue.serverTimestamp(),
      'volunteersAccepted': FieldValue.increment(1),
    });
  }

  // ─── Complete Task ─────────────────────────────────────────────────────────

  Future<void> completeTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).update({
      'status': TaskStatus.completed.name,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Submit Verification ───────────────────────────────────────────────────

  Future<void> submitVerification({
    required String taskId,
    required String note,
    List<String> photos = const [],
  }) async {
    await _db.collection('tasks').doc(taskId).update({
      'status': TaskStatus.verified.name,
      'verificationNote': note,
      'verificationPhotos': photos,
    });
  }

  // ─── Cancel Task ──────────────────────────────────────────────────────────

  Future<void> cancelTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).update({
      'status': TaskStatus.cancelled.name,
    });
  }
}