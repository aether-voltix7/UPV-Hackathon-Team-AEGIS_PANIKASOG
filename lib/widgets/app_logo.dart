import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
// import '../core/constants/text_styles.dart';

class AppLogo extends StatelessWidget {
  final double iconSize;
  final bool darkBackground;

  const AppLogo({
    super.key,
    this.iconSize = 100,
    this.darkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    // final color = darkBackground ? AppColors.white : AppColors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo
        SizedBox(
          width: iconSize,
          height: iconSize,
          child: Image.asset(
            'assets/images/panikasog-logo.png',
            fit: BoxFit.contain,
          ),
        )
      ],
    );
  }
}

/// Shared app bar used across all auth screens
class PanikasogAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final VoidCallback? onBack;

  const PanikasogAppBar({super.key, this.showBack = false, this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.primary, size: 20),
              onPressed: onBack ?? () => Navigator.pop(context),
            )
          : null,
      title: const AppLogo(),
      centerTitle: false,
    );
  }
}
