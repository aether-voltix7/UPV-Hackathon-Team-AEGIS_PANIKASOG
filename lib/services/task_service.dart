import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import 'user_progress_service.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserProgressService _progressService = UserProgressService();

  // ─── Fetch Tasks ────────────────────────────────────────────────────────────

  Future<List<TaskModel>> getTasks(
      {TaskStatus? status, TaskCategory? category}) async {
    Query<Map<String, dynamic>> q = _db
        .collection('tasks')
        .orderBy('scheduledStart', descending: false);
    if (status != null) q = q.where('status', isEqualTo: status.name);
    if (category != null) q = q.where('category', isEqualTo: category.name);
    final snapshot = await q.get();
    return snapshot.docs.map((d) => TaskModel.fromFirestore(d)).toList();
  }

  Stream<List<TaskModel>> tasksStream({TaskStatus? status}) {
    Query<Map<String, dynamic>> q = _db
        .collection('tasks')
        .orderBy('scheduledStart', descending: false);
    if (status != null) q = q.where('status', isEqualTo: status.name);
    return q.snapshots().map(
        (snap) => snap.docs.map((d) => TaskModel.fromFirestore(d)).toList());
  }

  // ─── Create Task ────────────────────────────────────────────────────────────

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

  // ─── Accept Task ────────────────────────────────────────────────────────────
  // FIX: Use arrayUnion so multiple users can accept independently.
  //      Status stays 'open' until volunteersNeeded is filled so the task
  //      does NOT disappear from other users' open list prematurely.

  Future<void> acceptTask(String taskId, String userId) async {
    final taskRef = _db.collection('tasks').doc(taskId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(taskRef);
      if (!snap.exists) return;

      final data = snap.data()!;
      final accepted = (data['volunteersAccepted'] as int? ?? 0) + 1;
      final needed = data['volunteersNeeded'] as int? ?? 1;

      // Only flip to 'accepted' (fully booked) once quota is met.
      final newStatus =
          accepted >= needed ? TaskStatus.accepted.name : data['status'];

      tx.update(taskRef, {
        'acceptedByList': FieldValue.arrayUnion([userId]),
        'acceptedBy': userId, // keep for legacy reads
        'acceptedAt': FieldValue.serverTimestamp(),
        'volunteersAccepted': FieldValue.increment(1),
        'status': newStatus,
      });
    });

    // Track jobsTaken for the accepting user.
    await _progressService.incrementJobsTaken(userId);
  }

  // ─── Complete Task ──────────────────────────────────────────────────────────

  Future<void> completeTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).update({
      'status': TaskStatus.completed.name,
      'completedAt': FieldValue.serverTimestamp(),
    });
    // NOTE: Do NOT award points here — that is done in submitVerification
    // exclusively to avoid double-counting.
  }

  // ─── Submit Verification ────────────────────────────────────────────────────
  // FIX: Points are awarded ONCE here via UserProgressService (atomic
  //      Firestore transaction).  TaskProvider.completeTask() no longer
  //      increments points so there is no double-count.

  Future<void> submitVerification({
    required String taskId,
    required String userId,
    required String note,
    List<String> photos = const [],
  }) async {
    final taskRef = _db.collection('tasks').doc(taskId);
    final taskSnap = await taskRef.get();
    if (!taskSnap.exists) return;

    final taskData = taskSnap.data()!;
    final points = (taskData['points'] as int?) ?? 0;
    // EXP = same as points by default; adjust ratio here if needed.
    final exp = points;

    // 1. Update the task document.
    await taskRef.update({
      'status': TaskStatus.verified.name,
      'verificationNote': note,
      'verificationPhotos': photos,
    });

    // 2. Award points + EXP + level + badges — all in one atomic transaction.
    await _progressService.awardTaskCompletion(
      userId: userId,
      pointsEarned: points,
      expEarned: exp,
    );
  }

  // ─── Cancel Task ────────────────────────────────────────────────────────────

  Future<void> cancelTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).update({
      'status': TaskStatus.cancelled.name,
    });
  }
}