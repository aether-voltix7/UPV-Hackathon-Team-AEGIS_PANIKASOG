import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../models/task_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TASK ACCEPTED CONFIRMATION SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class TaskAcceptedScreen extends StatelessWidget {
  final TaskModel task;
  const TaskAcceptedScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 100),
                // Success Check Circle
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF1A7815),
                      width: 5,
                    ),
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A7815).withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Color(0xFF1A7815),
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  'TASK ACCEPTED!',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    "You've reserved a slot. Head to the location and complete the task to earn your rewards.",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Task Card
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
                          task.title,
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.gradientEnd,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${task.barangay}, ${task.city}',
                                style: AppTextStyles.labelSmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date and Time',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: const Color(0xFF353535),
                                  ),
                                ),
                                Text(
                                  task.scheduledStart.toString().split(' ')[0],
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.gradientEnd,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Slot',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                                Text(
                                  '#3 of 4',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.gradientEnd,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reward on Completion',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                                Text(
                                  '${task.points}pts + 200 EXP',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.gradientEnd,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Note section
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0x1A07A0FF),
                            border: Border.all(
                              color: const Color(0xFF07A0FF),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Note:',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: const Color(0xFF07A0FF),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Failure to be present before and on the said time and date will lead to a temporary ban from receiving any task or a reduction of experience points (EXP)',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: const Color(0xFF353535),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // View on Map Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to map
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gradientStart,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.gradientStart,
                              AppColors.gradientEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'View on Map',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),

      ),
    );
  }
}
