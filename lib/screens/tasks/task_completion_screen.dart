import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import 'task_rewards_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TASK COMPLETION SCREEN - Show completion steps and progress
// ═══════════════════════════════════════════════════════════════════════════════
class TaskCompletionScreen extends StatelessWidget {
  final TaskModel task;
  const TaskCompletionScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Progress Indicator
            Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      _buildProgressCircle(true, '1'),
                      _buildProgressLine(),
                      _buildProgressCircle(true, '2'),
                      _buildProgressLine(),
                      _buildProgressCircle(false, '3'),
                      _buildProgressLine(),
                      _buildProgressCircle(false, '4'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  'TASK COMPLETION',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                // Who else have helped
                if (task.acceptedByList.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Who else have helped?',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...task.acceptedByList.map((volunteerId) =>
                                _buildVolunteerBadge(
                                  _getInitials(volunteerId),
                                  _getColorForVolunteer(volunteerId),
                                )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                // Task Log
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Log',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildLogEntry(
                          'Check-in verified',
                          'GPS confirmed · Task location verified',
                          Icons.location_on,
                        ),
                        if (task.verificationPhotos.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildLogEntry(
                            'Photos added',
                            '${task.verificationPhotos.length} photo(s) uploaded · Evidence documented',
                            Icons.image,
                          ),
                        ],
                        if (task.completedAt != null) ...[
                          const SizedBox(height: 12),
                          _buildLogEntry(
                            'Task completed',
                            'Completed on ${_formatDate(task.completedAt!)}',
                            Icons.task_alt,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Submit Verification Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _submitVerification(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gradientStart,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        'Submit Verification',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Info text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Rewards will be given shortly after LGU verification',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFF353535),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
      ),
    );
  }

  Widget _buildProgressCircle(bool isCompleted, String label) {
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFF1A7815) : Colors.grey,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF1A7815)
              : const Color(0xFF353535),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressLine() {
    return Expanded(
      child: Container(
        height: 3,
        color: const Color(0xFF1A7815),
        margin: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildVolunteerBadge(
    String initials,
    Color color, {
    bool isDashed = false,
  }) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isDashed
            ? Border.all(
                color: Colors.black26,
                width: 1,
                style: BorderStyle.solid,
              )
            : null,
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.labelSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLogEntry(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 29,
          height: 29,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue),
          ),
          child: Icon(icon, size: 14, color: Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.labelSmall.copyWith(
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ],
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submitVerification(BuildContext context) async {
    final userId = context.read<AuthProvider>().user?.uid ?? '';
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to submit verification'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    try {
      await context.read<TaskProvider>().submitVerification(
            taskId: task.id,
            userId: userId,
            taskPoints: task.points,
            note: 'Task verification submitted',
            photos: task.verificationPhotos,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task verified! Enjoy your rewards!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to rewards screen immediately (no LGU waiting)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TaskRewardsScreen(task: task),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
