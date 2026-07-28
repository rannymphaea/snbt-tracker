// lib/widgets/app_card.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'animated_checkbox.dart';

/// Bold neobrutalism card — thick border, solid shadow, colorful fill
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final bool small;
  final Color? shadowColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.small = false,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.dark, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: shadowColor ?? AppColors.dark,
              offset: small ? const Offset(3, 3) : const Offset(5, 5),
              blurRadius: 0,
            ),
          ],
        ),
        padding: padding ?? const EdgeInsets.all(18),
        child: child,
      );
}

/// Pressable card with tap + scale animation
class TappableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Color? shadowColor;
  final EdgeInsets? padding;

  const TappableCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.shadowColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) => TapScale(
        onTap: onTap,
        child: AppCard(
          color: color,
          shadowColor: shadowColor,
          padding: padding,
          child: child,
        ),
      );
}

/// Bold primary button — blue bg, dark border, solid shadow
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool fullWidth;
  final IconData? icon;
  final Color? color;
  final Color? textColor;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.fullWidth = false,
    this.icon,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) => TapScale(
        onTap: onTap,
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: color ?? AppColors.blue,
            borderRadius: AppRadius.pill,
            border: Border.all(color: AppColors.dark, width: 2.5),
            boxShadow: AppShadows.solidSm,
          ),
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: textColor ?? AppColors.white),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: textColor ?? AppColors.white,
                ),
              ),
            ],
          ),
        ),
      );
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? color;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.borderColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) => TapScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            color: color ?? Colors.white,
            borderRadius: AppRadius.pill,
            border: Border.all(color: borderColor ?? AppColors.dark, width: 2.5),
            boxShadow: AppShadows.solidSm,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.dark,
            ),
          ),
        ),
      );
}

class AppChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const AppChip({
    super.key,
    required this.label,
    this.color = AppColors.amber,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => TapScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.dark : color.withValues(alpha: 0.15),
            borderRadius: AppRadius.pill,
            border: Border.all(color: AppColors.dark, width: 2),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: selected ? Colors.white : AppColors.dark,
            ),
          ),
        ),
      );
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.dark,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

/// "app by ran ft envy" — watermark pill with cat icon
class Watermark extends StatelessWidget {
  const Watermark({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.pill,
            border: Border.all(color: AppColors.dark.withValues(alpha: 0.15), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.dark.withValues(alpha: 0.08),
                offset: const Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/icon.png',
                  width: 22,
                  height: 22,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'app by ran ft envy',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark.withValues(alpha: 0.5),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
