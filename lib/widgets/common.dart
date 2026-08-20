import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A translucent floating back button with a soft shadow.
class FloatingBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const FloatingBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
        color: AppColors.ink,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
        onPressed: onPressed ?? () => Navigator.maybePop(context),
      ),
    );
  }
}

/// The signature app background: a soft blue→cyan→green gradient wash.
/// Wrap a screen body in this and set the Scaffold's backgroundColor to
/// transparent so the gradient shows through.
class GlideBackground extends StatelessWidget {
  final Widget child;
  const GlideBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.canvasGradient),
      child: child,
    );
  }
}

/// A rounded white card with a soft shadow — the app's primary surface.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
    this.radius = AppRadii.card,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.soft,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// A pill button filled with the brand gradient.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient? gradient;
  final bool expand;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final btn = Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              gradient: gradient ?? AppColors.brandGradient,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              boxShadow: disabled ? null : AppShadows.soft,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return btn;
  }
}

/// A small labelled section title used across pages.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(action!,
                  style: const TextStyle(
                      color: AppColors.teal, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

/// A rounded rectangular "app icon" tile.
/// Shows an asset image if [imageAsset] is provided, otherwise a MaterialIcon.
class AppIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final String? imageAsset;

  const AppIconTile(
      {super.key, required this.icon, required this.color, this.size = 52, this.imageAsset});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: imageAsset != null ? Colors.white : color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(size * 0.30),
        border: imageAsset != null ? Border.all(color: AppColors.line, width: 0.5) : null,
      ),
      child: imageAsset != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.30 - 1),
              child: Image.asset(imageAsset!, fit: BoxFit.cover),
            )
          : Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// A soft pill chip for tags/interests.
class TagChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  const TagChip(this.label, {super.key, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: TextStyle(
                  color: c, fontWeight: FontWeight.w600, fontSize: 12.5)),
        ],
      ),
    );
  }
}

/// A small toast-like confirmation.
void showGlideSnack(BuildContext context, String message, {IconData? icon}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.chip)),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.lime, size: 20),
              const SizedBox(width: 10),
            ],
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
