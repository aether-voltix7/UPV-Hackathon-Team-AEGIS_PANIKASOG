import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../models/task_model.dart';
import 'task_completion_screen.dart';

class TaskInProgressScreen extends StatefulWidget {
  final TaskModel task;

  const TaskInProgressScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskInProgressScreen> createState() => _TaskInProgressScreenState();
}

class _TaskInProgressScreenState extends State<TaskInProgressScreen> {
  late Duration _elapsed;
  late Timer _timer;
  late DateTime _checkInTime;
  bool _hasBeforePhoto = false;
  bool _hasAfterPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkInTime = DateTime.now();
    _elapsed = Duration.zero;
    _startTimer();
    // Auto log before photo (simulated)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _hasBeforePhoto = true);
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(_checkInTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitHours = twoDigits(duration.inHours);
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds';
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null && mounted) {
        setState(() => _hasAfterPhoto = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Photo logged successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing photo: $e')),
        );
      }
    }
  }

  void _submitCompletion() {
    if (!_hasAfterPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add after photo first')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskCompletionScreen(task: widget.task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task status
            Text(
              'TASK IN PROGRESS',
              style: AppTextStyles.labelMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF520052),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            // Task title and time
            Text(
              widget.task.title,
              style: AppTextStyles.h2.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF520052),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Checked in · ${DateFormat('h:mm a').format(_checkInTime)}',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            // Timer card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFFFF5F7),
              ),
              child: Column(
                children: [
                  Text(
                    _formatDuration(_elapsed),
                    style: AppTextStyles.h1.copyWith(
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF520052),
                      fontFamily: 'Courier New',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Time Elapse',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Volunteers on-site card
            if (widget.task.acceptedByList.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Volunteers Near Task',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Volunteer avatars - all accepted volunteers
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...widget.task.acceptedByList.map((volunteerId) =>
                          _buildVolunteerAvatarWithStatus(
                            volunteerId,
                            _getInitials(volunteerId),
                            _getColorForVolunteer(volunteerId),
                            true, // Assuming checked in
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${widget.task.acceptedByList.length} volunteers checked in · ${widget.task.volunteersNeeded - widget.task.acceptedByList.length} have not yet arrived',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            // Progress log card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress Log',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProgressLogItem(
                    icon: Icons.check_circle,
                    title: 'Check-in verified',
                    subtitle: 'GPS confirmed · 32m from task point',
                    iconColor: const Color(0xFF0D47A1),
                  ),
                  const SizedBox(height: 16),
                  _buildProgressLogItem(
                    icon: Icons.camera_alt,
                    title: 'Photo added',
                    subtitle: 'Before photo logged · ${DateFormat('h:mm a').format(_checkInTime)}',
                    iconColor: Colors.orange,
                    isCompleted: _hasBeforePhoto,
                  ),
                  const SizedBox(height: 16),
                  _buildProgressLogItem(
                    icon: Icons.camera_alt,
                    title: 'After photo',
                    subtitle: _hasAfterPhoto 
                      ? 'After photo logged · ${DateFormat('h:mm a').format(DateTime.now())}'
                      : 'Not yet taken',
                    iconColor: Colors.grey,
                    isDisabled: !_hasAfterPhoto,
                    isCompleted: _hasAfterPhoto,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Log Progress Photo button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _capturePhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'Log Progress Photo',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Submit button - enabled only when after photo is added
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _hasAfterPhoto ? _submitCompletion : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasAfterPhoto ? AppColors.primary : Colors.grey[500],
                  disabledBackgroundColor: Colors.grey[500],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'Submit Completion',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteerAvatar(String initials, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressLogItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    bool isDisabled = false,
    bool isCompleted = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey[200] : iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check_circle : icon,
            size: 20,
            color: isDisabled ? Colors.grey : (isCompleted ? Colors.green : iconColor),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDisabled ? Colors.grey : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVolunteerAvatarWithStatus(
    String volunteerId,
    String initials,
    Color color,
    bool isCheckedIn,
  ) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCheckedIn ? Colors.green : Colors.grey,
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            initials,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isCheckedIn)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getInitials(String volunteerId) {
    if (volunteerId.isEmpty) return '?';
    final parts = volunteerId.split(RegExp(r'[_.-]'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return volunteerId.substring(0, 2).toUpperCase();
  }

  Color _getColorForVolunteer(String volunteerId) {
    final colors = [
      const Color(0xFF0B0198),
      const Color(0xFF1A7815),
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.green,
    ];
    return colors[volunteerId.hashCode % colors.length];
  }
}
