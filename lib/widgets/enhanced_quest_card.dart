import 'package:flutter/material.dart';
import '../models/quest_model.dart';
import '../widgets/quest_theme.dart';

class EnhancedQuestCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback? onTap;
  final VoidCallback? onProgress;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final bool showProgress;

  const EnhancedQuestCard({
    super.key,
    required this.quest,
    this.onTap,
    this.onProgress,
    this.onFavorite,
    this.isFavorite = false,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = QuestTypeHelper.getQuestTypeColor(quest.type.name);
    final typeIcon = QuestTypeHelper.getQuestTypeIcon(quest.type.name);

    return QuestCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and favorite button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: const TextStyle(
                        fontSize: 16, // Reduced font size
                        fontWeight: FontWeight.bold,
                        color: QuestTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2), // Reduced spacing
                    Text(
                      quest.description,
                      style: const TextStyle(
                        fontSize: 12, // Reduced font size
                        color: QuestTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onFavorite != null)
                Container(
                  width: 36, // Reduced size
                  height: 36,
                  decoration: BoxDecoration(
                    color:
                        isFavorite
                            ? Colors.red.shade50
                            : QuestTheme.surfaceColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: onFavorite,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : QuestTheme.textSecondary,
                      size: 18, // Reduced icon size
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12), // Reduced spacing
          // Quest info chips - more compact
          Wrap(
            spacing: 6, // Reduced spacing
            runSpacing: 6,
            children: [
              QuestChip(
                label: quest.type.name.toUpperCase(),
                icon: typeIcon,
                backgroundColor: typeColor.withValues(alpha: 0.1),
                textColor: typeColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ), // Compact padding
              ),
              if (quest.xpReward > 0)
                QuestChip(
                  label: '${quest.xpReward} XP',
                  icon: Icons.star,
                  backgroundColor: QuestTheme.accentGold.withValues(alpha: 0.1),
                  textColor: QuestTheme.accentGold,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              if (quest.cost > 0)
                QuestChip(
                  label: 'Rp${quest.cost.toStringAsFixed(0)}',
                  icon: Icons.attach_money,
                  backgroundColor: QuestTheme.accentOrange.withValues(
                    alpha: 0.1,
                  ),
                  textColor: QuestTheme.accentOrange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
            ],
          ),

          // Deadline info - more compact
          if (quest.deadline != null) ...[
            const SizedBox(height: 8), // Reduced spacing
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ), // Compact padding
              decoration: BoxDecoration(
                color:
                    quest.isExpired
                        ? QuestTheme.errorColor.withValues(alpha: 0.1)
                        : QuestTheme.warningColor.withValues(alpha: 0.1),
                borderRadius: QuestTheme.smallBorderRadius,
                border: Border.all(
                  color:
                      quest.isExpired
                          ? QuestTheme.errorColor.withValues(alpha: 0.3)
                          : QuestTheme.warningColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14, // Reduced icon size
                    color:
                        quest.isExpired
                            ? QuestTheme.errorColor
                            : QuestTheme.warningColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDeadline(quest.deadline!),
                    style: TextStyle(
                      fontSize: 11, // Reduced font size
                      fontWeight: FontWeight.w500,
                      color:
                          quest.isExpired
                              ? QuestTheme.errorColor
                              : QuestTheme.warningColor,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Progress section - more compact
          if (showProgress) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: const TextStyle(
                              fontSize: 11, // Reduced font size
                              color: QuestTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${quest.progress}/${quest.maxProgress}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: QuestTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4), // Reduced spacing
                      QuestProgressIndicator(
                        progress: quest.progressPercentage,
                        valueColor: typeColor,
                        height: 6, // Thinner progress bar
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          // Action buttons - more compact
          if (!quest.isCompleted && onProgress != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: QuestButton(
                    text:
                        quest.progress >= quest.maxProgress - 1
                            ? 'Complete Quest'
                            : 'Update Progress',
                    onPressed: onProgress,
                    icon:
                        quest.progress >= quest.maxProgress - 1
                            ? Icons.check_circle
                            : Icons.add_task,
                    isPrimary: quest.progress >= quest.maxProgress - 1,
                  ),
                ),
              ],
            ),
          ],

          // Completed indicator - more compact
          if (quest.isCompleted) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ), // Compact padding
              decoration: BoxDecoration(
                color: QuestTheme.successColor.withValues(alpha: 0.1),
                borderRadius: QuestTheme.smallBorderRadius,
                border: Border.all(
                  color: QuestTheme.successColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: QuestTheme.successColor,
                    size: 16, // Reduced icon size
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Quest Completed! 🎉',
                    style: TextStyle(
                      color: QuestTheme.successColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12, // Reduced font size
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    } else if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min left';
      } else {
        return '${difference.inHours}h ${difference.inMinutes % 60}m left';
      }
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else {
      return '${difference.inDays} days left';
    }
  }
}

class QuestStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final VoidCallback? onTap;

  const QuestStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? QuestTheme.primaryBlue;

    return QuestCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.1),
                  borderRadius: QuestTheme.smallBorderRadius,
                ),
                child: Icon(icon, color: cardColor, size: 24),
              ),
              const Spacer(),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: QuestTheme.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: cardColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: QuestTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: QuestTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class LevelProgressCard extends StatelessWidget {
  final int currentLevel;
  final int currentXP;
  final int xpForNextLevel;
  final double progress;

  const LevelProgressCard({
    super.key,
    required this.currentLevel,
    required this.currentXP,
    required this.xpForNextLevel,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return QuestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: QuestTheme.expGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: QuestTheme.accentGold.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level $currentLevel',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: QuestTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '$currentXP XP Total',
                      style: const TextStyle(
                        fontSize: 14,
                        color: QuestTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          QuestProgressIndicator(
            progress: progress,
            label: 'Progress to Level ${currentLevel + 1}',
            valueColor: QuestTheme.accentGold,
            height: 10,
          ),
          const SizedBox(height: 8),
          Text(
            '${(xpForNextLevel * progress).round()}/$xpForNextLevel XP to next level',
            style: const TextStyle(
              fontSize: 12,
              color: QuestTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
