import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService _service;

  TaskProvider(this._service) {
    loadTasks();
  }

  List<TaskModel> _tasks = [];
  TaskModel? _activeTask;
  bool _isLoading = false;
  String? _error;

  // Timer state
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  bool _timerRunning = false;

  // Getters
  List<TaskModel> get tasks => _tasks;
  TaskModel? get activeTask => _activeTask;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Duration get elapsed => _elapsed;
  bool get timerRunning => _timerRunning;

  List<TaskModel> get openTasks =>
      _tasks.where((t) => t.status == TaskStatus.open).toList();
  List<TaskModel> get myTasks =>
      _tasks.where((t) => t.status != TaskStatus.open).toList();

  // ─── Load ──────────────────────────────────────────────────────────────────
  Future<void> loadTasks({bool refresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final firestoreTasks = await _service.getTasks();
      _tasks = [...firestoreTasks, ...TaskModel.mockTasks];
    } catch (e) {
      _tasks = TaskModel.mockTasks; // fallback to mock if Firestore fails
      _error = 'Failed to load tasks.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Accept Task ───────────────────────────────────────────────────────────
  Future<bool> acceptTask(String taskId, String userId) async {
    if (_tasks.isEmpty) await loadTasks();

    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return false;

    try {
      await _service.acceptTask(taskId, userId);
    } catch (_) {}

    _tasks[idx] = _tasks[idx].copyWith(
      status: TaskStatus.accepted,
      acceptedBy: userId,
      acceptedAt: DateTime.now(),
    );
    _activeTask = _tasks[idx];
    notifyListeners();
    return true;
  }

  // ─── Start Timer ───────────────────────────────────────────────────────────
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

  // ─── Complete Task ─────────────────────────────────────────────────────────
  Future<void> completeTask(String taskId) async {
    pauseTimer();
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;

    try {
      await _service.completeTask(taskId);
    } catch (_) {}

    _tasks[idx] = _tasks[idx].copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
    );
    _activeTask = _tasks[idx];
    notifyListeners();
  }

  // ─── Submit Verification ───────────────────────────────────────────────────
  Future<bool> submitVerification({
    required String taskId,
    required String note,
    List<String> photos = const [],
  }) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return false;

    try {
      await _service.submitVerification(
          taskId: taskId, note: note, photos: photos);
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

  // ─── Create Task ───────────────────────────────────────────────────────────
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