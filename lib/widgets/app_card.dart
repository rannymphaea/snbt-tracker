// lib/widgets/app_card.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'animated_checkbox.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final bool small;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.dark, width: 2),
          boxShadow: small ? AppShadows.solidSm : AppShadows.solid,
        ),
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool fullWidth;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.fullWidth = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => TapScale(
        onTap: onTap,
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.yellow,
            borderRadius: AppRadius.pill,
            border: Border.all(color: AppColors.dark, width: 2),
            boxShadow: AppShadows.solidSm,
          ),
          child: Row(
            mainAxisSize:
                fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.dark),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.dark)),
            ],
          ),
        ),
      );
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? borderColor;

  const SecondaryButton(
      {super.key, required this.label, this.onTap, this.borderColor});

  @override
  Widget build(BuildContext context) => TapScale(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.pill,
            border: Border.all(
                color: borderColor ?? AppColors.dark, width: 2),
            boxShadow: AppShadows.solidSm,
          ),
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.dark)),
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
    this.color = AppColors.yellow,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => TapScale(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.dark : Colors.white,
            borderRadius: AppRadius.pill,
            border: Border.all(color: AppColors.dark, width: 2),
          ),
          child: Text(
            label,
            style: TextStyle(
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
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
                child: Text(title,
                    style: Theme.of(context).textTheme.headlineMedium)),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

/// "app by ran ft envy" — watermark with cat icon
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
            border: Border.all(color: AppColors.dark.withValues(alpha: 0.12), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.dark.withValues(alpha: 0.06),
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
                  color: AppColors.dark.withValues(alpha: 0.45),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
