import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../models/task_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TASK REWARDS SCREEN - Final verification and rewards display
// ═══════════════════════════════════════════════════════════════════════════════
class TaskRewardsScreen extends StatelessWidget {
  final TaskModel task;
  const TaskRewardsScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Progress Indicator - All complete
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      _buildProgressCircle(true, '1'),
                      _buildProgressLine(),
                      _buildProgressCircle(true, '2'),
                      _buildProgressLine(),
                      _buildProgressCircle(true, '3'),
                      _buildProgressLine(),
                      _buildProgressCircle(true, '4'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Trophy Icon
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
                    Icons.emoji_events,
                    color: Color(0xFF1A7815),
                    size: 60,
                  ),
                ),
                const SizedBox(height: 12),
                // Title
                Text(
                  'TASK VERIFIED',
                  style: AppTextStyles.h1.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  'All attendants have verified your task completion',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF353535),
                  ),
                ),
                const SizedBox(height: 20),
                // Rewards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      _buildRewardBadge(
                        '+ ${task.points}',
                        'IMPACT POINTS',
                      ),
                      const SizedBox(height: 8),
                      _buildRewardBadge('+ 200', 'EXP'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Your Impact Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF07A0FF).withOpacity(0.1),
                      border: Border.all(
                        color: const Color(0xFF07A0FF),
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Impact',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: const Color(0xFF07A0FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You helped aid 10 affected patients from ${task.barangay}.\nTime on task: 2hrs and 1min.',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Achievement Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFF110D9E),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF110D9E).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Color(0xFF110D9E),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Life Saver',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'People assisted across all medical tasks',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: const Color(0xFF353535),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Progress bar
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: LinearProgressIndicator(
                                            value: 10 / 20,
                                            backgroundColor:
                                                Colors.grey[200],
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.blue[400]!,
                                            ),
                                            minHeight: 8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '10/20',
                                        style: AppTextStyles.labelSmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Back to Home Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gradientStart,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        'Back to Home',
                          style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // View Leaderboard Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/rankings');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        side: const BorderSide(
                          color: AppColors.gradientStart,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'View Leaderboard',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
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

  Widget _buildProgressCircle(bool isCompleted, String label) {
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: const Color(0xFF1A7815),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF1A7815),
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

  Widget _buildRewardBadge(String points, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ).createShader(bounds),
            child: Text(
              points,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ).createShader(bounds),
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
