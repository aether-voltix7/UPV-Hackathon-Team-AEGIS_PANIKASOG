import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';

/// Step progress bar shown at the top of each signup screen.
class AuthStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String label;

  const AuthStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: currentStep / totalSteps,
            backgroundColor: AppColors.borderGrey,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

/// "— or —" divider used between form and social auth buttons.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.borderGrey)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '- or -',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.hintGrey),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.borderGrey)),
      ],
    );
  }
}

/// Google logo icon used in social auth buttons.
class GoogleSignInIcon extends StatelessWidget {
  const GoogleSignInIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.g_mobiledata, color: Color(0xFF4285F4), size: 22);
  }
}

/// Facebook logo icon used in social auth buttons.
class FacebookSignInIcon extends StatelessWidget {
  const FacebookSignInIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 22);
  }
}
