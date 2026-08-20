import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The Glide China mark: the swallow logo, loaded from the bundled image asset.
///
/// Keeps the same API as before (size / showBadge) so every screen that already
/// uses it needs no change. The real logo reads well on its own, so [showBadge]
/// now just adds an optional soft rounded tile behind it when you want extra
/// contrast (e.g. on a busy background).
class GlideLogo extends StatelessWidget {
  final double size;
  final bool showBadge;

  const GlideLogo({
    super.key,
    this.size = 40,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/images/glide_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (!showBadge) return SizedBox(width: size, height: size, child: logo);

    return Container(
      width: size * 1.4,
      height: size * 1.4,
      padding: EdgeInsets.all(size * 0.18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(size * 0.36),
        boxShadow: AppShadows.soft,
      ),
      child: logo,
    );
  }
}
