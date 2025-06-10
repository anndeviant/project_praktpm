import 'package:flutter/material.dart';

class QuestTheme {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF667eea);
  static const Color primaryPurple = Color(0xFF764ba2);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color accentOrange = Color(0xFFFF6B35);

  // Quest Type Colors
  static const Color dailyColor = Color(0xFFFF9500);
  static const Color weeklyColor = Color(0xFF007AFF);
  static const Color monthlyColor = Color(0xFF34C759);

  // Status Colors
  static const Color successColor = Color(0xFF34C759);
  static const Color warningColor = Color(0xFFFF9500);
  static const Color errorColor = Color(0xFFFF3B30);
  static const Color expiredColor = Color(0xFFFF3B30);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color cardBackground = Colors.white;
  static const Color surfaceColor = Color(0xFFF5F5F7);

  // Text Colors
  static const Color textPrimary = Color(0xFF1D1D1F);
  static const Color textSecondary = Color(0xFF86868B);
  static const Color textMuted = Color(0xFFA1A1A6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryPurple],
  );

  static const LinearGradient questGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
  );

  static const LinearGradient expGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGold, accentOrange],
  );
  // Shadow
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primaryBlue.withValues(alpha: 0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  // Border Radius - Reduced for compact design
  static const BorderRadius borderRadius = BorderRadius.all(
    Radius.circular(12),
  );
  static const BorderRadius smallBorderRadius = BorderRadius.all(
    Radius.circular(8),
  );
  static const BorderRadius largeBorderRadius = BorderRadius.all(
    Radius.circular(16),
  );

  // Compact spacing constants
  static const double compactPadding = 12.0;
  static const double compactMargin = 8.0;
  static const double compactIconSize = 20.0;
  static const double compactFontSize = 14.0;
}

class QuestCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final BorderRadius? borderRadius;

  const QuestCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.boxShadow,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? QuestTheme.cardBackground,
        borderRadius: borderRadius ?? QuestTheme.borderRadius,
        boxShadow: boxShadow ?? QuestTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius ?? QuestTheme.borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? QuestTheme.borderRadius,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

class QuestButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final IconData? icon;
  final bool isPrimary;

  const QuestButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.width,
    this.icon,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return Container(
        width: width,
        height: 48, // Reduced height for compact
        decoration: BoxDecoration(
          gradient: QuestTheme.primaryGradient,
          borderRadius: QuestTheme.borderRadius,
          boxShadow: onPressed != null ? QuestTheme.buttonShadow : null,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: QuestTheme.borderRadius,
            ),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
          ),
          child:
              isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18), // Reduced icon size
                        const SizedBox(width: 6),
                      ],
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 14, // Reduced font size
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: 48, // Reduced height for compact
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor ?? QuestTheme.primaryBlue,
          side: BorderSide(
            color: QuestTheme.primaryBlue.withValues(alpha: 0.3),
          ),
          shape: RoundedRectangleBorder(borderRadius: QuestTheme.borderRadius),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
        ),
        child:
            isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class QuestProgressIndicator extends StatelessWidget {
  final double progress;
  final Color? backgroundColor;
  final Color? valueColor;
  final double height;
  final String? label;

  const QuestProgressIndicator({
    super.key,
    required this.progress,
    this.backgroundColor,
    this.valueColor,
    this.height = 8,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 12,
              color: QuestTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? QuestTheme.surfaceColor,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(
                valueColor ?? QuestTheme.primaryBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class QuestChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const QuestChip({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? QuestTheme.surfaceColor,
        borderRadius: QuestTheme.smallBorderRadius,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: QuestTheme.smallBorderRadius,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: textColor ?? QuestTheme.textPrimary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor ?? QuestTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuestTypeHelper {
  static Color getQuestTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'daily':
        return QuestTheme.dailyColor;
      case 'weekly':
        return QuestTheme.weeklyColor;
      case 'monthly':
        return QuestTheme.monthlyColor;
      default:
        return QuestTheme.primaryBlue;
    }
  }

  static IconData getQuestTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'daily':
        return Icons.today;
      case 'weekly':
        return Icons.date_range;
      case 'monthly':
        return Icons.calendar_month;
      default:
        return Icons.assignment;
    }
  }
}
