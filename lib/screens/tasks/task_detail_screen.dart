import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import 'task_map_screen.dart';
import 'task_in_progress_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TASK DETAIL SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class TaskDetailScreen extends StatelessWidget {
  final TaskModel task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final isOpen = task.status == TaskStatus.open;
    final userId = context.watch<AuthProvider>().user?.uid ?? '';
    final alreadyAccepted = task.isAcceptedBy(userId);
    final totalVolunteers = task.volunteersNeeded == 0 ? 1 : task.volunteersNeeded;
    final volunteerProgress =
        (task.volunteersAccepted / totalVolunteers).clamp(0.0, 1.0);
    final taskMinutes =
        task.scheduledEnd.difference(task.scheduledStart).inMinutes.abs();
    final elapsedMinutes = DateTime.now().difference(task.scheduledStart).inMinutes;
    final timeProgress = taskMinutes == 0
        ? 0.0
        : (elapsedMinutes / taskMinutes).clamp(0.0, 1.0);
    final detailSteps = _buildTaskSteps(task.description);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Task Detail',
          style: AppTextStyles.h1.copyWith(color: const Color(0xFF520052)),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDF0B33), width: 1.6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 46,
                    height: 61,
                    alignment: Alignment.center,
                    child: Icon(_categoryIcon(task.category),
                        size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      task.title,
                      style: AppTextStyles.h2.copyWith(
                        color: const Color(0xFF520052),
                        fontSize: 34 / 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ]),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _DetailMetaChip(
                      icon: Icons.location_on,
                      text: '${task.barangay}, ${task.city}',
                    ),
                    _DetailMetaChip(
                      icon: Icons.access_time_filled,
                      text: 'Posted ${_postedAgo(task.scheduledStart)}',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _TagChip(label: task.categoryLabel),
                    ...task.tags.take(2).map((t) => _TagChip(label: t)),
                    if (task.tags.length > 2)
                      _TagChip(label: '+${task.tags.length - 2}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.workspace_premium,
                      color: AppColors.primary, size: 24),
                  const SizedBox(width: 4),
                  Text(
                    '${task.points} points',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: const Color(0xFF947FFF),
                    child: Text(
                      _initials(task.createdBy),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    task.createdBy.isEmpty ? 'Task Organizer' : task.createdBy,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(
                  task.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textDark,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(children: [
                    const Expanded(
                      child: Text('Community Boost',
                          style: TextStyle(fontSize: 12)),
                    ),
                    const Icon(Icons.north, size: 14, color: AppColors.primary),
                    const SizedBox(width: 2),
                    Text('${1000 + (task.points * 2)}',
                        style: const TextStyle(fontSize: 12)),
                  ]),
                ),
                const SizedBox(height: 12),
                Text(
                  'What needs to be done:',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                ...List.generate(
                  detailSteps.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '${index + 1}. ${detailSteps[index]}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textDark,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _TaskMetricProgress(
                  label: 'Volunteers',
                  valueLabel: '${task.volunteersAccepted}/${task.volunteersNeeded}',
                  hint:
                      'Only ${task.volunteersNeeded - task.volunteersAccepted > 0 ? task.volunteersNeeded - task.volunteersAccepted : 0} volunteers left!',
                  progress: volunteerProgress,
                  icon: Icons.person,
                ),
                const SizedBox(height: 8),
                _TaskMetricProgress(
                  label: DateFormat('MMMM d, yyyy - h:mma').format(task.scheduledStart),
                  valueLabel: _remainingDuration(task.scheduledEnd),
                  hint: 'Only ${_remainingDuration(task.scheduledEnd)} left!',
                  progress: timeProgress,
                  icon: Icons.calendar_month,
                ),
              ]),
            ),
            const SizedBox(height: 20),
            if (alreadyAccepted || !isOpen)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDF0B33), Color(0xFFAB0857)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TaskInProgressScreen(task: task)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      alreadyAccepted ? 'Continue Task' : 'View Progress',
                      style: AppTextStyles.labelLarge.copyWith(fontSize: 16),
                    ),
                  ),
                ),
              )
            else
              Column(children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDF0B33), Color(0xFFAB0857)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton(
                      onPressed: () => _acceptTask(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Accept Task',
                          style: AppTextStyles.labelLarge),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => _navigateToMap(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'View on Map',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
              ]),
          ]),
        ),
      ),
    );
  }

  List<String> _buildTaskSteps(String description) {
    final parts = description
        .split(RegExp(r'[.!?]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isNotEmpty) {
      return parts.take(3).toList();
    }
    return const [
      'Coordinate with volunteers in the assigned area.',
      'Complete the task objectives safely and responsibly.',
      'Report outcomes and submit required proof of work.',
    ];
  }

  String _initials(String value) {
    if (value.trim().isEmpty) return 'TG';
    final words = value.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words.first.substring(0, words.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    final first = words.first.isNotEmpty ? words.first[0] : 'T';
    final last = words.last.isNotEmpty ? words.last[0] : 'G';
    return '$first$last'.toUpperCase();
  }

  Future<void> _acceptTask(BuildContext context) async {
    final userId = context.read<AuthProvider>().user?.uid ?? '';
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please login to accept tasks'),
          backgroundColor: AppColors.primary));
      return;
    }
    final success =
        await context.read<TaskProvider>().acceptTask(task.id, userId);
    // StatelessWidget – use context.mounted
    if (!context.mounted) return;
    if (success) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => TaskAcceptedScreen(task: task)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to accept task. Please try again.'),
          backgroundColor: Colors.red));
    }
  }

  void _navigateToMap(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => TaskMapScreen(task: task)));

  IconData _categoryIcon(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.medicalAssistance:
        return Icons.medical_services_outlined;
      case TaskCategory.cleanupRecovery:
        return Icons.cleaning_services_outlined;
      case TaskCategory.reliefDistribution:
        return Icons.volunteer_activism;
      case TaskCategory.preparedness:
        return Icons.shield_outlined;
      default:
        return Icons.assignment_outlined;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TASK ACCEPTED SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class TaskAcceptedScreen extends StatelessWidget {
  final TaskModel task;
  const TaskAcceptedScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.primary, size: 20),
              onPressed: () => Navigator.pop(context))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
                color: AppColors.chipBg, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle,
                color: AppColors.primary, size: 56),
          ),
          const SizedBox(height: 20),
          const Text('TASK ACCEPTED!',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text(
              'The task will be marked complete when you\narrive and log your progress.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(16)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.title, style: AppTextStyles.h3),
              const SizedBox(height: 8),
              _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: '${task.barangay}, ${task.city}'),
              const SizedBox(height: 4),
              _InfoRow(
                  icon: Icons.star_outline,
                  text: '${task.points} pts reward'),
            ]),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TaskNavigateScreen(task: task))),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28))),
              child:
                  const Text('View on Map', style: AppTextStyles.labelLarge),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TASK NAVIGATE / MAP SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class TaskNavigateScreen extends StatelessWidget {
  final TaskModel task;
  const TaskNavigateScreen({super.key, required this.task});

  Future<void> _checkIn(BuildContext context) async {
    if (task.latitude == null || task.longitude == null) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => TaskInProgressScreen(task: task)));
      return;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please enable location services to check in.')));
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Location permission required. Please enable in settings.')));
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        task.latitude!,
        task.longitude!,
      );

      if (!context.mounted) return;

      if (distance <= 50) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => TaskInProgressScreen(task: task)));
      } else {
        final metres = distance.toStringAsFixed(0);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'You are ${metres}m away. You must be within 50m to check in.'),
          backgroundColor: Colors.orange,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        if (kDebugMode) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => TaskInProgressScreen(task: task)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.primary, size: 20),
            onPressed: () => Navigator.pop(context)),
        title: Text(task.title,
            style: AppTextStyles.h3, overflow: TextOverflow.ellipsis),
      ),
      body: Column(children: [
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: task.latitude != null && task.longitude != null
                  ? LatLng(task.latitude!, task.longitude!)
                  : const LatLng(10.7202, 122.5621),
              zoom: 15,
            ),
            markers: task.latitude != null && task.longitude != null
                ? {
                    Marker(
                      markerId: const MarkerId('task_location'),
                      position: LatLng(task.latitude!, task.longitude!),
                      infoWindow: InfoWindow(
                          title: task.title,
                          snippet: '${task.barangay}, ${task.city}'),
                    ),
                  }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.white, boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -4))
          ]),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.location_on,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('${task.barangay}, ${task.city}',
                      style: AppTextStyles.bodyMedium)),
            ]),
            const SizedBox(height: 4),
            Text('Must be within 50m to check in',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.hintGrey)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _checkIn(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28))),
                child:
                    const Text('Check In', style: AppTextStyles.labelLarge),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TASK PROGRESS / TIMER SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class TaskProgressScreen extends StatefulWidget {
  final TaskModel task;
  const TaskProgressScreen({super.key, required this.task});
  @override
  State<TaskProgressScreen> createState() => _TaskProgressScreenState();
}

class _TaskProgressScreenState extends State<TaskProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().startTimer();
    });
  }

  Future<void> _submitCompletion() async {
    final userId = context.read<AuthProvider>().user?.uid ?? '';
    if (userId.isEmpty) return;

    await context.read<TaskProvider>().submitVerification(
          taskId: widget.task.id,
          userId: userId,
          taskPoints: widget.task.points,
          note: 'Task completed',
          photos: const [],
        );
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => TaskCompletionScreen(task: widget.task)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.primary, size: 20),
            onPressed: () => Navigator.pop(context)),
        title: const Text('IN PROGRESS',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 1)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const _StepRow(currentStep: 3),
          const SizedBox(height: 32),
          Text(widget.task.title,
              style: AppTextStyles.h2, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('${widget.task.barangay}, ${widget.task.city}',
              style: AppTextStyles.bodySmall),
          const SizedBox(height: 40),
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 28, horizontal: 40),
            decoration: BoxDecoration(
              color: AppColors.chipBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Text(
              provider.formatElapsed(),
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 4),
            ),
          ),
          const SizedBox(height: 12),
          const Text('TIME ELAPSED', style: AppTextStyles.labelSmall),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitCompletion,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28))),
              child: const Text('Submit Completion',
                  style: AppTextStyles.labelLarge),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TASK COMPLETION SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class TaskCompletionScreen extends StatelessWidget {
  final TaskModel task;
  const TaskCompletionScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          title: const Text('TASK COMPLETION',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const _StepRow(currentStep: 4),
          const SizedBox(height: 32),
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
                color: AppColors.chipBg, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle,
                color: AppColors.primary, size: 52),
          ),
          const SizedBox(height: 16),
          const Text('TASK VERIFIED',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          const SizedBox(height: 8),
          const Text('All your activities are verified to comply.',
              style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          const _VerificationChecklist(),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TaskVerificationScreen(task: task))),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28))),
              child: const Text('Submit Verification',
                  style: AppTextStyles.labelLarge),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () =>
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28))),
              child: Text('Back to Home',
                  style:
                      AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TASK VERIFICATION SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class TaskVerificationScreen extends StatefulWidget {
  final TaskModel task;
  const TaskVerificationScreen({super.key, required this.task});
  @override
  State<TaskVerificationScreen> createState() => _TaskVerificationScreenState();
}

class _TaskVerificationScreenState extends State<TaskVerificationScreen> {
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  static const _verifiers = [
    ('Nathaniel Loresto', true),
    ('Darla Albarido', true),
    ('Carla Comawas', true),
    ('Marjorie Ong', false),
    ('Ken Sison', false),
  ];

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.primary, size: 20),
              onPressed: () => Navigator.pop(context)),
          title: const Text('Task Verification', style: AppTextStyles.h2)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _StepRow(currentStep: 5),
          const SizedBox(height: 20),
          const Text('Are your activities complete?', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          const Text('Looking for: volunteers are willing',
              style: AppTextStyles.bodySmall),
          const SizedBox(height: 20),
          ...List.generate(_verifiers.length, (i) {
            final (name, verified) = _verifiers[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.chipBg,
                  child: Text(name[0],
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(name, style: AppTextStyles.bodyMedium)),
                Icon(
                    verified
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color:
                        verified ? AppColors.success : AppColors.borderGrey,
                    size: 22),
              ]),
            );
          }),
          const SizedBox(height: 20),
          TextFormField(
            controller: _noteCtrl,
            maxLines: 3,
            style: AppTextStyles.inputText,
            decoration: const InputDecoration(
                hintText: 'Add a verification note (optional)...'),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : () => _submit(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28))),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: AppColors.white, strokeWidth: 2.5))
                  : const Text('Submit Verification',
                      style: AppTextStyles.labelLarge),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    setState(() => _submitting = true);
    final userId = context.read<AuthProvider>().user?.uid ?? '';
    await context.read<TaskProvider>().submitVerification(
          taskId: widget.task.id,
          userId: userId,
          taskPoints: widget.task.points,
          note: _noteCtrl.text.trim(),
        );
    setState(() => _submitting = false);
    if (!mounted) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => TaskRewardsScreen(task: widget.task)));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TASK REWARDS SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class TaskRewardsScreen extends StatelessWidget {
  final TaskModel task;
  const TaskRewardsScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child:
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                  color: Color(0xFFFFF8E1), shape: BoxShape.circle),
              child: const Icon(Icons.emoji_events,
                  color: Color(0xFFFFB300), size: 64),
            ),
            const SizedBox(height: 24),
            const Text('🎉 Task Complete!',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text('You earned',
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.textGrey)),
            const SizedBox(height: 4),
            Text(
              '+${task.points} pts',
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppColors.chipBg,
                  borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                Text(task.title,
                    style: AppTextStyles.h3, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          color: AppColors.success, size: 18),
                      SizedBox(width: 6),
                      Text('Verified & Added to your Impact Score',
                          style: AppTextStyles.bodySmall),
                    ]),
              ]),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28))),
                child: const Text('Back to Home',
                    style: AppTextStyles.labelLarge),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamedAndRemoveUntil(context, '/rankings', (_) => false),
              child: Text('View Leaderboard >',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.primary)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CREATE TASK SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});
  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _locationCtrl = TextEditingController(text: 'La Paz, Iloilo City');
  TaskCategory _category = TaskCategory.emergencyResponse;
  final List<String> _tags = [];
  final FocusNode _locationFocus = FocusNode();
  bool _showMap = false;
  GoogleMapController? _mapController;
  Marker? _pickedMarker;
  static const LatLng _iloiloDefaultLoc = LatLng(10.7202, 122.5621);
  int _points = 100;
  int _volunteers = 5;
  bool _isUrgent = false;
  bool _submitting = false;
  DateTime _startDate = DateTime.now().add(const Duration(hours: 2));
  DateTime _endDate = DateTime.now().add(const Duration(hours: 6));

  Future<void> _updateMarker(LatLng position) async {
    setState(() {
      _pickedMarker = Marker(
        markerId: const MarkerId('picked_location'),
        position: position,
      );
    });

    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        geo.Placemark place = placemarks.first;
        String barangay = place.subLocality ?? place.name ?? "Unknown Brgy";
        String city = place.locality ?? "Iloilo City";
        if (mounted) {
          setState(() {
            _locationCtrl.text = "$barangay, $city";
          });
        }
      }
    } catch (e) {
      debugPrint("Reverse Geocoding failed: $e");
      if (mounted) {
        setState(() {
          _locationCtrl.text =
              "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        });
      }
    }
  }

  Future<void> _handleLocationDetection() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please enable location services in settings.')),
          );
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      if (mounted) setState(() => _locationCtrl.text = "Detecting address...");

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      LatLng detectedLatLng = LatLng(position.latitude, position.longitude);

      if (_mapController != null) {
        try {
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(detectedLatLng, 16),
          );
        } catch (e) {
          debugPrint("GPS Camera move failed: $e");
        }
      }

      await _updateMarker(detectedLatLng);
    } catch (e) {
      debugPrint("GPS Error: $e");
      if (mounted) {
        setState(() => _locationCtrl.text = "Error detecting location");
      }
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    try {
      String fullQuery = "$query, Iloilo City, Philippines";
      debugPrint("Searching for: $fullQuery");

      List<geo.Location> locations = await geo.locationFromAddress(fullQuery);
      if (!mounted) return;

      if (locations.isNotEmpty) {
        final target =
            LatLng(locations.first.latitude, locations.first.longitude);
        debugPrint("Location found: ${target.latitude}, ${target.longitude}");

        if (_mapController != null) {
          try {
            await _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(target, 16),
            );
          } catch (e) {
            debugPrint("Map animation failed (probably disposed): $e");
          }
        }

        await _updateMarker(target);
      } else {
        _showError("No results found for '$query'");
      }
    } catch (e) {
      debugPrint("Geocoding Error: $e");
      if (mounted) _showError("Location search failed. Check internet.");
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _locationFocus
        .addListener(() => setState(() => _showMap = _locationFocus.hasFocus));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _tagCtrl.dispose();
    _locationCtrl.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.primary, size: 20),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Create a Task', style: AppTextStyles.h2),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 4),
            const _FieldLabel(label: 'Title'),
            TextFormField(
                controller: _titleCtrl,
                style: AppTextStyles.inputText,
                decoration: const InputDecoration(
                    hintText: 'e.g. Medical Assistance for Injured...'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null),
            const SizedBox(height: 16),
            const _FieldLabel(label: 'Description'),
            TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: AppTextStyles.inputText,
                decoration: const InputDecoration(
                    hintText: 'Describe the task in detail...'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null),
            const SizedBox(height: 16),
            const _FieldLabel(label: 'Category'),
            DropdownButtonFormField<TaskCategory>(
              initialValue: _category,
              style: AppTextStyles.inputText,
              decoration: const InputDecoration(),
              items: TaskCategory.values.map((c) {
                final label = TaskModel(
                        id: '',
                        title: '',
                        description: '',
                        barangay: '',
                        city: '',
                        category: c,
                        points: 0,
                        scheduledStart: DateTime.now(),
                        scheduledEnd: DateTime.now(),
                        createdBy: '')
                    .categoryLabel;
                return DropdownMenuItem(value: c, child: Text(label));
              }).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            const _FieldLabel(label: 'Tags'),
            TextFormField(
              controller: _tagCtrl,
              style: AppTextStyles.inputText,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (v) {
                if (v.trim().isNotEmpty) {
                  setState(() {
                    _tags.add(v.trim());
                    _tagCtrl.clear();
                  });
                }
              },
              decoration: InputDecoration(
                hintText: 'Add a tag and press Enter',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.primary),
                  onPressed: () {
                    if (_tagCtrl.text.trim().isNotEmpty) {
                      setState(() {
                        _tags.add(_tagCtrl.text.trim());
                        _tagCtrl.clear();
                      });
                    }
                  },
                ),
              ),
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _tags
                      .map((t) => _TagChip(
                          label: t,
                          onRemove: () => setState(() => _tags.remove(t))))
                      .toList()),
            ],
            const SizedBox(height: 16),
            const _FieldLabel(label: 'Location (Auto-detected)'),
            TextFormField(
              controller: _locationCtrl,
              focusNode: _locationFocus,
              textInputAction: TextInputAction.search,
              onFieldSubmitted: (v) {
                if (v.isNotEmpty) _searchLocation(v);
              },
              style: AppTextStyles.inputText,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.gps_fixed,
                      color: AppColors.primary, size: 18),
                  onPressed: _handleLocationDetection,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_showMap)
              Container(
                height: 200,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: _iloiloDefaultLoc,
                      zoom: 14,
                    ),
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer()),
                    },
                    myLocationEnabled: true,
                    onMapCreated: (controller) {
                      if (!mounted) return;
                      _mapController = controller;
                    },
                    markers: _pickedMarker != null ? {_pickedMarker!} : {},
                    onCameraMove: (p) => _updateMarker(p.target),
                  ),
                ),
              ),
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const _FieldLabel(label: 'Volunteers'),
                    TextFormField(
                      initialValue: _volunteers.toString(),
                      style: AppTextStyles.inputText,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _volunteers = int.tryParse(v) ?? 1,
                      decoration: const InputDecoration(),
                    ),
                  ])),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const _FieldLabel(label: 'Points'),
                    TextFormField(
                      initialValue: _points.toString(),
                      style: AppTextStyles.inputText,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _points = int.tryParse(v) ?? 100,
                      decoration: const InputDecoration(),
                    ),
                  ])),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: _DateField(
                      label: 'Start Date/Time',
                      date: _startDate,
                      onTap: () => _pickDate(context, true))),
              const SizedBox(width: 12),
              Expanded(
                  child: _DateField(
                      label: 'End Date/Time',
                      date: _endDate,
                      onTap: () => _pickDate(context, false))),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Switch(
                value: _isUrgent,
                onChanged: (v) => setState(() => _isUrgent = v),
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primaryLight,
              ),
              const SizedBox(width: 8),
              const Text('Mark as Urgent', style: AppTextStyles.bodyMedium),
            ]),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : () => _submit(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28))),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: AppColors.white, strokeWidth: 2.5))
                    : const Text('Create Task',
                        style: AppTextStyles.labelLarge),
              ),
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final picked =
        await _showDateTimePicker(context, isStart ? _startDate : _endDate);
    if (picked != null) {
      setState(() => isStart ? _startDate = picked : _endDate = picked);
    }
  }

  Future<DateTime?> _showDateTimePicker(
      BuildContext context, DateTime initial) async {
    final date = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final user = context.read<AuthProvider>().user;
    final locationParts = _locationCtrl.text.split(',');
    await context.read<TaskProvider>().createTask(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          barangay: locationParts.first.trim(),
          city: locationParts.length > 1
              ? locationParts.last.trim()
              : 'Iloilo City',
          category: _category,
          tags: _tags,
          points: _points,
          volunteersNeeded: _volunteers,
          scheduledStart: _startDate,
          scheduledEnd: _endDate,
          createdBy: user?.uid ?? '',
          isUrgent: _isUrgent,
        );
    setState(() => _submitting = false);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Task created! 🎉'),
        backgroundColor: AppColors.success));
  }
}

// ─── Shared helpers ────────────────────────────────────────────────────────────
class _StepRow extends StatelessWidget {
  final int currentStep;
  const _StepRow({required this.currentStep});
  static const _steps = ['Accepted', 'Navigate', 'Check In', 'Complete', 'Verify'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
              child: Container(
                  height: 2,
                  color: i < (currentStep - 1) * 2
                      ? AppColors.primary
                      : AppColors.borderGrey));
        }
        final stepIdx = i ~/ 2;
        final done = stepIdx < currentStep - 1;
        final active = stepIdx == currentStep - 1;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: (done || active) ? AppColors.primary : AppColors.borderGrey,
              shape: BoxShape.circle,
            ),
            child: Icon(done ? Icons.check : Icons.circle,
                color: AppColors.white, size: 14),
          ),
          const SizedBox(height: 4),
          Text(_steps[stepIdx],
              style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 9,
                  color: active ? AppColors.primary : AppColors.hintGrey)),
        ]);
      }),
    );
  }
}

class _VerificationChecklist extends StatelessWidget {
  const _VerificationChecklist();
  static const _items = [
    'Task title verified',
    'Location confirmed',
    'Volunteer photos submitted',
    'Supervisor notified',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
        children: _items
            .map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 10),
                    Text(item, style: AppTextStyles.bodyMedium),
                  ]),
                ))
            .toList());
  }
}

class _DetailMetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailMetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.bodySmall.copyWith(
      fontSize: 9,
      color: AppColors.primary,
      fontWeight: FontWeight.w500,
    );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: AppColors.primary),
      const SizedBox(width: 2),
      Text(text, style: style),
    ]);
  }
}

class _TaskMetricProgress extends StatelessWidget {
  final String label;
  final String valueLabel;
  final String hint;
  final double progress;
  final IconData icon;
  const _TaskMetricProgress({
    required this.label,
    required this.valueLabel,
    required this.hint,
    required this.progress,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyles.bodySmall.copyWith(
      fontSize: 9,
      color: AppColors.primary,
      fontWeight: FontWeight.w500,
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 11, color: AppColors.primary),
        const SizedBox(width: 3),
        Expanded(child: Text(label, style: labelStyle)),
        Text(valueLabel, style: labelStyle),
      ]),
      const SizedBox(height: 4),
      Container(
        height: 15,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (_, constraints) => Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: constraints.maxWidth * progress,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF510152), Color(0xFFA6029E)],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 2),
      Text(hint, style: labelStyle.copyWith(fontSize: 8)),
    ]);
  }
}

String _postedAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes} mins. ago';
  if (diff.inDays < 1) return '${diff.inHours} hours ago';
  return '${diff.inDays} days ago';
}

String _remainingDuration(DateTime end) {
  final diff = end.difference(DateTime.now());
  if (diff.isNegative) return 'Ended';
  if (diff.inHours >= 1) return '${diff.inHours} hours';
  return '${diff.inMinutes} mins';
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 16, color: AppColors.hintGrey),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
      ]);
}

class _TagChip extends StatelessWidget {
  final String label;
  final VoidCallback? onRemove;
  const _TagChip({required this.label, this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFDF0B33), Color(0xFFAB0857)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFECF3),
            borderRadius: BorderRadius.circular(19),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label,
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.primary, fontSize: 12)),
            if (onRemove != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.close,
                      size: 13, color: AppColors.primary)),
            ],
          ]),
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(label, style: AppTextStyles.inputLabel),
      );
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateField(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _FieldLabel(label: label),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderGrey),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Expanded(
                  child: Text(DateFormat('MMM d, yyyy\nh:mma').format(date),
                      style: AppTextStyles.bodySmall)),
              const Icon(Icons.calendar_today_outlined,
                  size: 16, color: AppColors.hintGrey),
            ]),
          ),
        ]),
      );
}