import 'package:flutter/material.dart';
import '../models/email_message.dart';
import '../services/smart_reply_service.dart';
import '../screens/compose_screen.dart';

/// Widget that displays smart reply suggestions for an email
class SmartReplyWidget extends StatefulWidget {
  final EmailMessage email;
  final VoidCallback? onReplySent;

  const SmartReplyWidget({
    super.key,
    required this.email,
    this.onReplySent,
  });

  @override
  State<SmartReplyWidget> createState() => _SmartReplyWidgetState();
}

class _SmartReplyWidgetState extends State<SmartReplyWidget> with SingleTickerProviderStateMixin {
  List<SmartReply> _suggestions = [];
  bool _isLoading = true;
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _generateSuggestions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _generateSuggestions() async {
    try {
      setState(() => _isLoading = true);

      // Simulate slight delay for better UX (like Gmail)
      await Future.delayed(const Duration(milliseconds: 500));

      final suggestions = SmartReplyService.generateReplies(widget.email);

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
          _isExpanded = true;
        });
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('❌ SmartReplyWidget: Error generating suggestions: $e');
      if (mounted) {
        setState(() {
          _suggestions = SmartReplyService.getQuickActionReplies();
          _isLoading = false;
          _isExpanded = true;
        });
        _animationController.forward();
      }
    }
  }

  void _onReplyTapped(SmartReply reply) {
    // Track analytics
    SmartReplyAnalytics.trackUsage(reply);

    // Navigate to compose screen with pre-filled reply
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComposeScreen(
          replyTo: widget.email.from,
          subject: widget.email.subject.startsWith('Re:')
              ? widget.email.subject
              : 'Re: ${widget.email.subject}',
          initialBody: reply.text,
          replyToMessage: widget.email,
          isReply: true,
        ),
      ),
    ).then((sent) {
      if (sent == true) {
        widget.onReplySent?.call();

        // Show confirmation snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reply sent: "${reply.text}"'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    });
  }

  void _onCustomReplyTapped() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComposeScreen(
          replyTo: widget.email.from,
          subject: widget.email.subject.startsWith('Re:')
              ? widget.email.subject
              : 'Re: ${widget.email.subject}',
          replyToMessage: widget.email,
          isReply: true,
        ),
      ),
    ).then((sent) {
      if (sent == true) {
        widget.onReplySent?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded || _suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Opacity(
            opacity: _animation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Smart Reply',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      if (_isLoading)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Smart reply suggestions
                  if (!_isLoading) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._suggestions.map((suggestion) => _buildSuggestionChip(suggestion)),
                        _buildCustomReplyChip(),
                      ],
                    ),

                    // Confidence indicator for the top suggestion
                    if (_suggestions.isNotEmpty && _suggestions.first.confidence > 0.8) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.thumb_up_outlined,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'High confidence suggestion',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionChip(SmartReply suggestion) {
    return InkWell(
      onTap: () => _onReplyTapped(suggestion),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                suggestion.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 4),
            _getTypeIcon(suggestion.type),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomReplyChip() {
    return InkWell(
      onTap: _onCustomReplyTapped,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              'Custom Reply',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getTypeIcon(SmartReplyType type) {
    IconData iconData;
    Color color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.7);

    switch (type) {
      case SmartReplyType.contextual:
        iconData = Icons.psychology_outlined;
        break;
      case SmartReplyType.timeBased:
        iconData = Icons.schedule_outlined;
        break;
      case SmartReplyType.urgencyBased:
        iconData = Icons.priority_high_outlined;
        color = Colors.orange;
        break;
      case SmartReplyType.quickAction:
        iconData = Icons.flash_on_outlined;
        color = Colors.green;
        break;
      case SmartReplyType.generic:
        iconData = Icons.auto_awesome_outlined;
        break;
    }

    return Icon(
      iconData,
      size: 16,
      color: color,
    );
  }
}

/// Floating action button for quick smart replies
class SmartReplyFAB extends StatelessWidget {
  final EmailMessage email;
  final VoidCallback? onReplySent;

  const SmartReplyFAB({
    super.key,
    required this.email,
    this.onReplySent,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showQuickReplies(context),
      icon: const Icon(Icons.auto_awesome),
      label: const Text('Quick Reply'),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  void _showQuickReplies(BuildContext context) {
    final suggestions = SmartReplyService.generateReplies(email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Replies',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick reply options
            ...suggestions.map((suggestion) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.reply,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              title: Text(suggestion.text),
              subtitle: Text('${(suggestion.confidence * 100).toInt()}% confidence'),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
              onTap: () {
                Navigator.pop(context);
                _sendQuickReply(context, suggestion);
              },
            )),

            const SizedBox(height: 8),

            // Custom reply option
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  size: 20,
                ),
              ),
              title: const Text('Write custom reply'),
              subtitle: const Text('Compose your own response'),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
              onTap: () {
                Navigator.pop(context);
                _openCompose(context);
              },
            ),

            // Safe area padding
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _sendQuickReply(BuildContext context, SmartReply suggestion) {
    SmartReplyAnalytics.trackUsage(suggestion);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComposeScreen(
          replyTo: email.from,
          subject: email.subject.startsWith('Re:') ? email.subject : 'Re: ${email.subject}',
          initialBody: suggestion.text,
          replyToMessage: email,
          isReply: true,
        ),
      ),
    ).then((sent) {
      if (sent == true) {
        onReplySent?.call();
      }
    });
  }

  void _openCompose(BuildContext context) {
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
    ).then((sent) {
      if (sent == true) {
        onReplySent?.call();
      }
    });
  }
}