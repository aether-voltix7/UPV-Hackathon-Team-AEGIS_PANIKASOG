import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService _service;
  String? _currentUserId;

  TaskProvider(this._service) {
    loadTasks();
  }

  List<TaskModel> _tasks = [];
  TaskModel? _activeTask;
  bool _isLoading = false;
  String? _error;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  bool _timerRunning = false;

  List<TaskModel> get tasks => _tasks;
  TaskModel? get activeTask => _activeTask;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Duration get elapsed => _elapsed;
  bool get timerRunning => _timerRunning;

  List<TaskModel> get openTasks =>
      _tasks.where((t) => t.status == TaskStatus.open).toList();

  // FIX: Use acceptedByList (array) instead of single acceptedBy string.
  //      Previously, any task where acceptedBy == userId showed for EVERY
  //      user, because the field was overwritten per acceptance, not appended.
  List<TaskModel> get myTasks => _currentUserId == null
      ? []
      : _tasks
          .where((t) => t.isAcceptedBy(_currentUserId!))
          .toList();

  void setCurrentUser(String userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    notifyListeners();
  }

  Future<void> loadTasks({bool refresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final firestoreTasks = await _service.getTasks();
      // Only add mock tasks that don't already exist in Firestore results
      // (prevents duplicate IDs causing wrong status display).
      final firestoreIds = firestoreTasks.map((t) => t.id).toSet();
      final uniqueMocks = TaskModel.mockTasks
          .where((t) => !firestoreIds.contains(t.id))
          .toList();
      _tasks = [...firestoreTasks, ...uniqueMocks];
    } catch (e) {
      _tasks = TaskModel.mockTasks;
      _error = 'Failed to load tasks.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptTask(String taskId, String userId) async {
    if (_tasks.isEmpty) await loadTasks();
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return false;

    // Prevent double-accepting.
    if (_tasks[idx].isAcceptedBy(userId)) return true;

    try {
      await _service.acceptTask(taskId, userId);
    } catch (e) {
      _error = 'Failed to accept task. Please try again.';
      notifyListeners();
      return false;
    }

    final updated = _tasks[idx].copyWith(
      acceptedByList: [..._tasks[idx].acceptedByList, userId],
      acceptedAt: DateTime.now(),
      volunteersAccepted: _tasks[idx].volunteersAccepted + 1,
    );
    _tasks[idx] = updated;
    _activeTask = updated;
    notifyListeners();
    return true;
  }

  void startTimer() {
    if (_timerRunning) return;
    _timerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      notifyListeners();
    });
    notifyListeners();
  }

  void pauseTimer() {
    _timer?.cancel();
    _timerRunning = false;
    notifyListeners();
  }

  // FIX: completeTask no longer touches user points.
  //      Points are awarded ONLY in submitVerification (via TaskService →
  //      UserProgressService) to prevent double-counting.
  Future<void> completeTask(String taskId) async {
    pauseTimer();
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    try {
      await _service.completeTask(taskId);
    } catch (_) {}
    _tasks[idx] =
        _tasks[idx].copyWith(status: TaskStatus.completed, completedAt: DateTime.now());
    _activeTask = _tasks[idx];
    notifyListeners();
  }

  Future<bool> submitVerification({
    required String taskId,
    required String userId,
    required int taskPoints,
    required String note,
    List<String> photos = const [],
  }) async {
    pauseTimer();
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return false;
    try {
      // Points awarded atomically inside TaskService.submitVerification()
      await _service.submitVerification(
        taskId: taskId,
        userId: userId,
        note: note,
        photos: photos,
      );
    } catch (_) {}

    _tasks[idx] = _tasks[idx].copyWith(
      status: TaskStatus.verified,
      verificationNote: note,
      verificationPhotos: photos,
    );
    _activeTask = _tasks[idx];
    _elapsed = Duration.zero;
    notifyListeners();
    return true;
  }

  Future<TaskModel?> createTask({
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
    try {
      final task = await _service.createTask(
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
      _tasks.insert(0, task);
      notifyListeners();
      return task;
    } catch (e) {
      _error = 'Failed to create task.';
      notifyListeners();
      return null;
    }
  }

  String formatElapsed() {
    final h = _elapsed.inHours.toString().padLeft(2, '0');
    final m = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}