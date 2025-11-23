import 'package:flutter/material.dart';
import '../services/nudge_service.dart';
import '../models/email_message.dart';
import '../screens/email_detail_screen.dart';
import '../screens/compose_screen.dart';

/// Widget that displays email nudges in a card format
class NudgeWidget extends StatefulWidget {
  final List<EmailNudge> nudges;
  final VoidCallback? onNudgeActioned;

  const NudgeWidget({
    super.key,
    required this.nudges,
    this.onNudgeActioned,
  });

  @override
  State<NudgeWidget> createState() => _NudgeWidgetState();
}

class _NudgeWidgetState extends State<NudgeWidget> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  final Set<String> _dismissedNudges = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleNudges = widget.nudges
        .where((nudge) => !_dismissedNudges.contains(nudge.id))
        .toList();

    if (visibleNudges.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value * MediaQuery.of(context).size.width, 0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Suggested Actions',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        if (visibleNudges.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${visibleNudges.length}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Nudge cards
                  ...visibleNudges.take(3).map((nudge) => _buildNudgeCard(nudge)),

                  // Show more button if there are more nudges
                  if (visibleNudges.length > 3)
                    _buildShowMoreButton(visibleNudges.length - 3),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNudgeCard(EmailNudge nudge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _getPriorityColor(nudge.priority).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _onNudgeTapped(nudge),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Priority indicator
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(nudge.priority),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Type icon
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(nudge.priority).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getTypeIcon(nudge.type),
                        size: 16,
                        color: _getPriorityColor(nudge.priority),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Title
                    Expanded(
                      child: Text(
                        nudge.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),

                    // Dismiss button
                    IconButton(
                      onPressed: () => _dismissNudge(nudge.id),
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Message
                Text(
                  nudge.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),

                const SizedBox(height: 8),

                // Email preview
                _buildEmailPreview(nudge.email),

                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _performAction(nudge),
                      icon: Icon(_getActionIcon(nudge.type), size: 16),
                      label: Text(nudge.suggestedAction),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _getPriorityColor(nudge.priority),
                        side: BorderSide(color: _getPriorityColor(nudge.priority)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _viewEmail(nudge.email),
                      child: const Text('View Email'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailPreview(EmailMessage email) {
    final sender = _extractSenderName(email.from);
    final timeAgo = _getTimeAgo(email.date);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: _getAvatarColor(email.from),
                child: Text(
                  sender.isNotEmpty ? sender[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sender,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                timeAgo,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            email.subject.isNotEmpty ? email.subject : 'No Subject',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (email.previewText?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              email.previewText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShowMoreButton(int remainingCount) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => _showAllNudges(),
        icon: const Icon(Icons.expand_more, size: 16),
        label: Text('View $remainingCount more suggestion${remainingCount != 1 ? 's' : ''}'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods
  Color _getPriorityColor(NudgePriority priority) {
    switch (priority) {
      case NudgePriority.critical:
        return Colors.red;
      case NudgePriority.high:
        return Colors.orange;
      case NudgePriority.medium:
        return Colors.blue;
      case NudgePriority.low:
        return Colors.green;
    }
  }

  IconData _getTypeIcon(NudgeType type) {
    switch (type) {
      case NudgeType.followUpReminder:
        return Icons.reply_outlined;
      case NudgeType.replyReminder:
        return Icons.message_outlined;
      case NudgeType.deadlineReminder:
        return Icons.schedule_outlined;
      case NudgeType.importantUnread:
        return Icons.priority_high_outlined;
      case NudgeType.meetingFollowUp:
        return Icons.video_call_outlined;
      case NudgeType.weeklyDigest:
        return Icons.summarize_outlined;
    }
  }

  IconData _getActionIcon(NudgeType type) {
    switch (type) {
      case NudgeType.followUpReminder:
        return Icons.send_outlined;
      case NudgeType.replyReminder:
        return Icons.reply_outlined;
      case NudgeType.deadlineReminder:
        return Icons.task_alt_outlined;
      case NudgeType.importantUnread:
        return Icons.mark_email_read_outlined;
      case NudgeType.meetingFollowUp:
        return Icons.note_add_outlined;
      case NudgeType.weeklyDigest:
        return Icons.checklist_outlined;
    }
  }

  Color _getAvatarColor(String email) {
    final colors = [
      Colors.red.shade400,
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
    ];
    return colors[email.hashCode.abs() % colors.length];
  }

  String _extractSenderName(String fromField) {
    if (fromField.isEmpty) return 'Unknown';
    final match = RegExp(r'^(.*?)\s*<(.+?)>$').firstMatch(fromField.trim());
    if (match != null) {
      final name = match.group(1)?.trim().replaceAll('"', '') ?? '';
      if (name.isNotEmpty) return name;
      return match.group(2)?.split('@').first ?? 'Unknown';
    }
    return fromField.split('@').first;
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Event handlers
  void _dismissNudge(String nudgeId) {
    setState(() {
      _dismissedNudges.add(nudgeId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Suggestion dismissed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _dismissedNudges.remove(nudgeId);
            });
          },
        ),
      ),
    );
  }

  void _onNudgeTapped(EmailNudge nudge) {
    _viewEmail(nudge.email);
  }

  void _performAction(EmailNudge nudge) {
    switch (nudge.type) {
      case NudgeType.followUpReminder:
      case NudgeType.replyReminder:
      case NudgeType.meetingFollowUp:
        _composeReply(nudge.email);
        break;
      case NudgeType.deadlineReminder:
        _viewEmail(nudge.email);
        break;
      case NudgeType.importantUnread:
        _markAsRead(nudge.email);
        break;
      case NudgeType.weeklyDigest:
        _showWeeklyDigest();
        break;
    }

    widget.onNudgeActioned?.call();
  }

  void _viewEmail(EmailMessage email) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailDetailScreen(message: email),
      ),
    );
  }

  void _composeReply(EmailMessage email) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComposeScreen(
          replyTo: email.from,
          subject: email.subject.startsWith('Re:') ? email.subject : 'Re: ${email.subject}',
          replyToMessage: email,
          isReply: true,
        ),
      ),
    );
  }

  void _markAsRead(EmailMessage email) {
    // This would be handled by the email provider
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marked as read')),
    );
  }

  void _showWeeklyDigest() {
    // Show weekly digest dialog or navigate to digest screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Weekly digest feature coming soon')),
    );
  }

  void _showAllNudges() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All Suggestions',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // All nudges
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: widget.nudges.length,
                  itemBuilder: (context, index) => _buildNudgeCard(widget.nudges[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}