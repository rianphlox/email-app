import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/email_provider.dart' as provider;
import '../models/email_message.dart';
import '../models/email_account.dart';
import '../screens/add_account_screen.dart';
import '../screens/email_detail_screen.dart';
import '../screens/compose_screen.dart';
import '../services/email_categorizer.dart';
import '../widgets/conversation_item.dart';
import '../widgets/shimmer_loading.dart';
import '../utils/date_utils.dart';
import '../utils/preview_extractor.dart';
import '../widgets/snooze_dialog.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _selectedEmails = <String>{};
  bool _isSelectionMode = false;
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  final List<EmailCategory> _categories = [
    EmailCategory.primary,
    EmailCategory.promotions,
    EmailCategory.social,
    EmailCategory.updates,
  ];
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _scrollController.addListener(_scrollListener);
  }

  /// Listens to scroll events and triggers loading more emails at 80% scroll
  void _scrollListener() {
    if (_scrollController.hasClients) {
      final threshold = 0.8; // Trigger at 80% scroll
      final position = _scrollController.position;

      if (position.pixels / position.maxScrollExtent >= threshold) {
        final emailProvider = context.read<provider.EmailProvider>();
        if (emailProvider.hasMoreEmails && !emailProvider.isLoadingMore) {
          emailProvider.loadMoreEmails();
        }
      }
    }
  }

  /// Starts background sync after cached emails are shown
  void _startBackgroundSync() {
    final emailProvider = context.read<provider.EmailProvider>();

    // Only sync if we have accounts
    if (emailProvider.accounts.isNotEmpty) {
      // Small delay to let the UI render cached emails first
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          emailProvider.syncEmails();
        }
      });
    }
  }

  /// Handles pull-to-refresh with Gmail-like UX
  Future<void> _handleRefresh() async {
    if (!mounted) return;

    // Get all context-dependent values before async operations
    final emailProvider = context.read<provider.EmailProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    try {
      // Provide haptic feedback like Gmail
      await HapticFeedback.lightImpact();

      // Show a brief loading state
      messenger.hideCurrentSnackBar();

      // Sync emails
      await emailProvider.syncEmails();

      // Show success feedback
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Emails refreshed'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      // Show error feedback
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode
        ? _buildSelectionAppBar()
        : _isSearchMode
            ? _buildSearchAppBar()
            : AppBar(
                title: const Text('QMail'),
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                bottom: _buildTabBar(),
                actions: [
                  // Search icon
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _enterSearchMode,
                    tooltip: 'Search emails',
                  ),

                  // Conversation mode toggle
                  Consumer<provider.EmailProvider>(
                    builder: (context, emailProvider, child) {
                      return IconButton(
                        icon: Icon(
                          emailProvider.conversationMode
                              ? Icons.chat_bubble_outline
                              : Icons.list,
                        ),
                        onPressed: () => emailProvider.toggleConversationMode(),
                        tooltip: emailProvider.conversationMode
                            ? 'Switch to message list'
                            : 'Switch to conversations',
                      );
                    },
                  ),
              // Connectivity status indicator
              Consumer<provider.EmailProvider>(
                builder: (context, emailProvider, child) {
                  if (emailProvider.isOffline) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.cloud_off,
                          color: Colors.orange,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Offline - ${emailProvider.connectivityStatus}'),
                              action: emailProvider.hasPendingOperations
                                  ? SnackBarAction(
                                      label: '${emailProvider.pendingOperationsCount} pending',
                                      onPressed: () {},
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    );
                  } else if (emailProvider.hasPendingOperations) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        icon: Stack(
                          children: [
                            Icon(Icons.cloud_sync, color: Colors.blue),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '${emailProvider.pendingOperationsCount}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Syncing ${emailProvider.pendingOperationsCount} operations...'),
                            ),
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              Consumer<provider.EmailProvider>(
                builder: (context, emailProvider, child) {
                  if (emailProvider.accounts.isNotEmpty) {
                    return PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'add_account') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddAccountScreen(),
                            ),
                          );
                        } else if (value == 'refresh') {
                          emailProvider.syncEmails();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'refresh',
                          child: Row(
                            children: [
                              Icon(Icons.refresh),
                              SizedBox(width: 8),
                              Text('Refresh'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'add_account',
                          child: Row(
                            children: [
                              Icon(Icons.add),
                              SizedBox(width: 8),
                              Text('Add Account'),
                            ],
                          ),
                        ),
                      ],
                    );
              }
              return IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddAccountScreen(),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Consumer<provider.EmailProvider>(
          builder: (context, emailProvider, child) {
          // Show search results info if searching
          if (emailProvider.isSearching) {
            return RefreshIndicator(
              onRefresh: _handleRefresh,
              displacement: 50.0,
              backgroundColor: Theme.of(context).colorScheme.surface,
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 2.5,
              triggerMode: RefreshIndicatorTriggerMode.onEdge,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Text(
                        'Found ${emailProvider.messages.length} result${emailProvider.messages.length != 1 ? 's' : ''} for "${emailProvider.searchQuery}"',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  emailProvider.messages.isNotEmpty
                      ? _buildSimpleEmailListSliver(emailProvider.messages)
                      : SliverToBoxAdapter(child: _buildNoSearchResults()),
                ],
              ),
            );
          }

          // PRIORITY 1: Always show cached content immediately if available (conversations or messages)
          debugPrint('📱 UI: conversation mode: ${emailProvider.conversationMode}');
          debugPrint('📱 UI: conversations count: ${emailProvider.conversations.length}');
          debugPrint('📱 UI: messages count: ${emailProvider.messages.length}');
          debugPrint('📱 UI: isSearching: ${emailProvider.isSearching}');
          debugPrint('📱 UI: isLoading: ${emailProvider.isLoading}');

          // Debug the condition parts
          bool conversationModeAndHasContent = emailProvider.conversationMode && (emailProvider.conversations.isNotEmpty || emailProvider.messages.isNotEmpty);
          bool messageModeAndHasMessages = !emailProvider.conversationMode && emailProvider.messages.isNotEmpty;
          debugPrint('🔍 UI: conversationModeAndHasContent: $conversationModeAndHasContent');
          debugPrint('🔍 UI: messageModeAndHasMessages: $messageModeAndHasMessages');
          debugPrint('🔍 UI: conversations.isNotEmpty: ${emailProvider.conversations.isNotEmpty}');
          debugPrint('🔍 UI: messages.isNotEmpty: ${emailProvider.messages.isNotEmpty}');

          if (conversationModeAndHasContent || messageModeAndHasMessages) {
            debugPrint('✅ UI: Showing emails/conversations');
            return RefreshIndicator(
              onRefresh: _handleRefresh,
              displacement: 50.0,
              backgroundColor: Theme.of(context).colorScheme.surface,
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 2.5,
              triggerMode: RefreshIndicatorTriggerMode.onEdge,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // Nudge suggestions temporarily disabled to fix overflow
                  // if (emailProvider.currentAccount != null)
                  //   SliverToBoxAdapter(
                  //     child: ConstrainedBox(
                  //       constraints: const BoxConstraints(maxHeight: 200),
                  //       child: FutureBuilder<List<EmailNudge>>(
                  //         future: Future.value(NudgeService.generateNudges(
                  //           emailProvider.messages,
                  //           emailProvider.currentAccount!,
                  //         )),
                  //         builder: (context, snapshot) {
                  //           if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  //             return SingleChildScrollView(
                  //               child: NudgeWidget(
                  //                 nudges: snapshot.data!,
                  //                 onNudgeActioned: () {
                  //                   // Refresh emails after nudge action
                  //                   emailProvider.syncEmails();
                  //                 },
                  //               ),
                  //             );
                  //           }
                  //           return const SizedBox.shrink();
                  //         },
                  //       ),
                  //     ),
                  //   ),

                  // Main email content
                  if (emailProvider.conversationMode && emailProvider.conversations.isNotEmpty)
                    _buildConversationViewSliver(emailProvider)
                  else
                    _buildSimpleEmailListSliver(emailProvider.messages),

                  // Show subtle loading indicator during background sync
                  if (emailProvider.isLoading)
                    SliverToBoxAdapter(
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          // PRIORITY 2: Show welcome screen only if no accounts AND no cached emails
          if (emailProvider.accounts.isEmpty) {
            debugPrint('❌ UI: Showing welcome screen (no accounts)');
            return _buildWelcomeScreen();
          }

          // PRIORITY 3: Show loading when we have accounts but no cached emails yet
          if (emailProvider.isLoading) {
            debugPrint('⏳ UI: Showing loading shimmer');
            return RefreshIndicator(
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ShimmerLoading.conversationList(
                  itemCount: 7,
                  isDarkMode: Theme.of(context).brightness == Brightness.dark,
                ),
              ),
            );
          }

          // PRIORITY 4: Show error only if we have accounts but no cached emails and there's an error
          if (emailProvider.error != null) {
            debugPrint('❌ UI: Showing error state: ${emailProvider.error}');
            return _buildErrorState(emailProvider.error!);
          }

          // PRIORITY 5: Empty state with quick action to sync
          debugPrint('📭 UI: Showing empty inbox (fallback)');
          return _buildEmptyInbox(emailProvider);
          },
        ),
      ),
      floatingActionButton: Consumer<provider.EmailProvider>(
        builder: (context, emailProvider, child) {
          // Show compose button if we have accounts OR cached emails (offline mode)
          if (emailProvider.accounts.isEmpty && emailProvider.messages.isEmpty) {
            return const SizedBox();
          }
          return FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ComposeScreen(),
                ),
              );
            },
            child: const Icon(Icons.edit),
          );
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Consumer<provider.EmailProvider>(
      builder: (context, emailProvider, child) {
        // Show empty drawer only if no accounts AND no cached emails
        if (emailProvider.accounts.isEmpty && emailProvider.messages.isEmpty) {
          return _buildEmptyDrawer();
        }

        return Drawer(
          child: Column(
            children: [
              // Account header with user info
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.inversePrimary,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            emailProvider.currentAccount?.name.isNotEmpty == true
                                ? emailProvider.currentAccount!.name[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          emailProvider.currentAccount?.name ?? 'Offline Mode',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onInverseSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          emailProvider.currentAccount?.email ?? 'Viewing cached emails',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onInverseSurface.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Folders section
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildFolderTile(
                      'Inbox',
                      Icons.inbox,
                      EmailFolder.inbox,
                      emailProvider,
                    ),
                    _buildFolderTile(
                      'Sent',
                      Icons.send,
                      EmailFolder.sent,
                      emailProvider,
                    ),
                    _buildFolderTile(
                      'Drafts',
                      Icons.drafts,
                      EmailFolder.drafts,
                      emailProvider,
                    ),
                    _buildFolderTile(
                      'Trash',
                      Icons.delete,
                      EmailFolder.trash,
                      emailProvider,
                    ),
                    _buildFolderTile(
                      'Spam',
                      Icons.warning,
                      EmailFolder.spam,
                      emailProvider,
                    ),

                    // Accounts section at the bottom
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        'Accounts',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Current account (always show)
                    if (emailProvider.currentAccount != null)
                      _buildAccountTile(emailProvider.currentAccount!, emailProvider, isSelected: true),

                    // Other accounts
                    ...emailProvider.accounts
                        .where((account) => account.id != emailProvider.currentAccount?.id)
                        .map((account) => _buildAccountTile(account, emailProvider, isSelected: false)),

                    ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text('Add Account'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddAccountScreen(),
                          ),
                        );
                      },
                    ),

                    const Divider(),

                    // Debug option for fixing cache issues
                    ListTile(
                      leading: const Icon(Icons.refresh, color: Colors.orange),
                      title: const Text('Fix Cache (Debug)'),
                      subtitle: const Text('Force refresh all accounts'),
                      onTap: () {
                        Navigator.pop(context);
                        _forceRefreshCache();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFolderTile(
    String title,
    IconData icon,
    EmailFolder folder,
    provider.EmailProvider emailProvider,
  ) {
    final isSelected = emailProvider.currentFolder == folder;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: isSelected,
      onTap: () {
        emailProvider.switchFolder(folder);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildAccountTile(EmailAccount account, provider.EmailProvider emailProvider, {bool isSelected = false}) {
    return ListTile(
      leading: CircleAvatar(
        radius: 15,
        backgroundColor: _getProviderColor(account.provider),
        child: Text(
          account.name.isNotEmpty ? account.name[0].toUpperCase() : 'U',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
      title: Text(
        account.name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        account.email,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      selected: isSelected,
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary, size: 18)
          : PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Remove'),
                  onTap: () {
                    _showRemoveAccountDialog(account.id);
                  },
                ),
              ],
            ),
      onTap: isSelected ? null : () {
        emailProvider.switchAccount(account);
        Navigator.pop(context);
      },
    );
  }

  Color _getProviderColor(EmailProvider provider) {
    switch (provider) {
      case EmailProvider.gmail:
        return Colors.red;
      case EmailProvider.outlook:
        return Colors.blue;
      case EmailProvider.yahoo:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to QMail',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Smart Email Reader\nStay organized and read your emails effortlessly.\nMaking it faster and more efficient. Say goodbye to clutter and hello to seamless reading!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddAccountScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Email Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<provider.EmailProvider>().syncEmails();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }



  String _formatDate(DateTime date) {
    // Convert dates to West African Time (UTC+1) for Lagos timezone
    final lagosOffset = const Duration(hours: 1);
    final lagosDate = date.toUtc().add(lagosOffset);
    final now = DateTime.now().toUtc().add(lagosOffset);
    final difference = now.difference(lagosDate);

    if (difference.inDays == 0) {
      // Today: Show time only (Gmail style)
      final hour = lagosDate.hour > 12 ? lagosDate.hour - 12 : (lagosDate.hour == 0 ? 12 : lagosDate.hour);
      final amPm = lagosDate.hour >= 12 ? 'AM' : 'PM';
      return '$hour:${lagosDate.minute.toString().padLeft(2, '0')} $amPm';
    } else if (lagosDate.year == now.year) {
      // This year: Show month and day (Gmail style: "Nov 1")
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[lagosDate.month - 1]} ${lagosDate.day}';
    } else {
      // Previous years: Show month, day, and year (Gmail style: "Nov 1, 2023")
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[lagosDate.month - 1]} ${lagosDate.day}, ${lagosDate.year}';
    }
  }

  // Helper methods for Gmail-style email list
  String _extractSenderName(String fromField) {
    if (fromField.isEmpty) return 'Unknown';

    // Extract name from "Name <email>" or just use the email
    final match = RegExp(r'^(.*?)\s*<(.+?)>$').firstMatch(fromField.trim());
    if (match != null) {
      final name = match.group(1)?.trim().replaceAll('"', '') ?? '';
      if (name.isNotEmpty) {
        return name;
      }
      return match.group(2)?.split('@').first ?? 'Unknown';
    }

    // Just email, extract the part before @
    return fromField.split('@').first;
  }

  String _getSenderInitial(String fromField) {
    final name = _extractSenderName(fromField);
    if (name.isEmpty) return '?';

    return name[0].toUpperCase();
  }

  Color _getAvatarColor(String fromField) {
    // Generate consistent colors based on sender name
    final name = _extractSenderName(fromField);
    final colors = [
      Colors.red.shade400,
      Colors.pink.shade400,
      Colors.purple.shade400,
      Colors.deepPurple.shade400,
      Colors.indigo.shade400,
      Colors.blue.shade400,
      Colors.lightBlue.shade400,
      Colors.cyan.shade400,
      Colors.teal.shade400,
      Colors.green.shade400,
      Colors.lightGreen.shade400,
      Colors.orange.shade400,
      Colors.deepOrange.shade400,
      Colors.brown.shade400,
      Colors.blueGrey.shade400,
    ];

    final hash = name.hashCode;
    return colors[hash.abs() % colors.length];
  }

  Widget _buildEmptyDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Empty header
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.primary,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).colorScheme.onPrimary,
                      child: Icon(
                        Icons.email,
                        size: 30,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'QMail',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Smart Email Reader',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Add Email Account'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddAccountScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInbox(provider.EmailProvider emailProvider) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      // Gmail-style refresh indicator styling
      displacement: 50.0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      color: Theme.of(context).colorScheme.primary,
      strokeWidth: 2.5,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No emails found',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pull down to refresh or sync your emails',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await emailProvider.syncEmails();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Sync Emails'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About QMail'),
        content: const Text(
          'QMail - Smart Email Reader\n\n'
          'A modern, secure email client built with Flutter.\n\n'
          'Features:\n'
          '• Multiple email providers\n'
          '• Secure OAuth authentication\n'
          '• Real-time email sync\n'
          '• Attachment support\n'
          '• Modern Material Design',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRemoveAccountDialog(String accountId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Account'),
        content: const Text('Are you sure you want to remove this account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<provider.EmailProvider>().removeAccount(accountId);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // Tab bar removed for simple Gmail-style view
  PreferredSizeWidget? _buildTabBar() {
    return null; // No more category tabs
  }

  Widget _buildCategorizedInbox(provider.EmailProvider emailProvider) {
    return TabBarView(
      controller: _tabController,
      children: _categories.map((category) {
        final categoryEmails = EmailCategorizer.getEmailsByCategory(
          emailProvider.messages,
          category,
        );

        if (categoryEmails.isEmpty) {
          return _buildEmptyCategory(category);
        }

        return _buildCategoryEmailList(categoryEmails);
      }).toList(),
    );
  }

  Widget _buildEmptyCategory(EmailCategory category) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      // Gmail-style refresh indicator styling
      displacement: 50.0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      color: Theme.of(context).colorScheme.primary,
      strokeWidth: 2.5,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    EmailCategorizer.getCategoryIcon(category),
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ${EmailCategorizer.getCategoryDisplayName(category).toLowerCase()} emails',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pull down to refresh',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Simple Gmail-style email list as a Sliver for CustomScrollView
  Widget _buildSimpleEmailListSliver(List<EmailMessage> emails) {
    final emailProvider = context.watch<provider.EmailProvider>();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Show loading indicator at the bottom
          if (index == emails.length) {
            if (emailProvider.isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (emailProvider.hasMoreEmails) {
              // Trigger loading more emails when this item becomes visible
              WidgetsBinding.instance.addPostFrameCallback((_) {
                emailProvider.loadMoreEmails();
              });
              return const SizedBox();
            }
          }

          if (index >= emails.length) {
            return const SizedBox();
          }
          final message = emails[index];
          final isSelected = _selectedEmails.contains(message.messageId);

          return Dismissible(
            key: ValueKey(message.messageId),
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              color: Colors.green,
              child: const Row(
                children: [
                  Icon(Icons.archive, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text('Archive', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            secondaryBackground: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.orange,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Snooze', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  SizedBox(width: 8),
                  Icon(Icons.snooze, color: Colors.white, size: 24),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                // Archive email
                if (mounted) {
                  final emailProvider = context.read<provider.EmailProvider>();
                  emailProvider.archiveEmail(message);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email archived')),
                  );
                  return true;
                }
                return false;
              } else if (direction == DismissDirection.endToStart) {
                // Snooze email
                final snoozeTime = await showSnoozeDialog(context);
                if (snoozeTime != null) {
                  final emailProvider = context.read<provider.EmailProvider>();
                  await emailProvider.snoozeEmail(message, snoozeTime);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Email snoozed until ${_formatSnoozeTime(snoozeTime)}')),
                    );
                  }
                  return true;
                }
                return false;
              }
              return false;
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : null,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: InkWell(
              onTap: () {
                if (_isSelectionMode) {
                  _toggleEmailSelection(message.messageId);
                } else {
                  final emailProvider = context.read<provider.EmailProvider>();
                  if (!message.isRead) {
                    emailProvider.markAsRead(message);
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmailDetailScreen(message: message),
                    ),
                  );
                }
              },
              onLongPress: () {
                if (!_isSelectionMode) {
                  _enterSelectionMode(message.messageId);
                } else {
                  _toggleEmailSelection(message.messageId);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gmail-style sender avatar
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 12.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : _getAvatarColor(message.from),
                      ),
                      child: Center(
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 20,
                              )
                            : Text(
                                _getSenderInitial(message.from),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),

                    // Email content - Gmail layout
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // First row: Sender name and date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _extractSenderName(message.from),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: message.isRead ? FontWeight.normal : FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                DateFormatUtils.formatRelativeDate(message.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontWeight: message.isRead ? FontWeight.normal : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 2),

                          // Second row: Subject line
                          Text(
                            message.subject.isNotEmpty ? message.subject : 'No subject',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: message.isRead ? FontWeight.normal : FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 2),

                          // Third row: Preview text
                          Text(
                            (message.previewText?.isNotEmpty == true)
                                ? message.previewText!
                                : (message.textBody.isNotEmpty
                                    ? PreviewExtractor.extractPreview(
                                        textContent: message.textBody,
                                        htmlContent: message.htmlBody,
                                        maxLength: 100
                                      )
                                    : 'No preview available'),
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Star button (Gmail-style)
                    IconButton(
                      onPressed: () {
                        final emailProvider = context.read<provider.EmailProvider>();
                        emailProvider.toggleImportant(message);
                      },
                      icon: Icon(
                        message.isImportant ? Icons.star : Icons.star_border,
                        color: message.isImportant
                            ? Colors.amber
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        size: 20,
                      ),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        },
        childCount: emails.length + (emailProvider.hasMoreEmails ? 1 : 0),
      ),
    );
  }

  // Simple Gmail-style email list without categories
  Widget _buildSimpleEmailList(List<EmailMessage> emails) {
    final emailProvider = context.watch<provider.EmailProvider>();

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      displacement: 50.0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      color: Theme.of(context).colorScheme.primary,
      strokeWidth: 2.5,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: ListView.builder(
        itemCount: emails.length + (emailProvider.hasMoreEmails ? 1 : 0), // Add 1 for loading indicator
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemBuilder: (context, index) {
          // Show loading indicator at the bottom
          if (index == emails.length) {
            if (emailProvider.isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (emailProvider.hasMoreEmails) {
              // Trigger loading more emails when this item becomes visible
              WidgetsBinding.instance.addPostFrameCallback((_) {
                emailProvider.loadMoreEmails();
              });
              return const SizedBox();
            }
          }

          if (index >= emails.length) {
            return const SizedBox();
          }
          final message = emails[index];
          final isSelected = _selectedEmails.contains(message.messageId);

          return Dismissible(
            key: ValueKey(message.messageId),
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              color: Colors.green,
              child: const Row(
                children: [
                  Icon(Icons.archive, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text('Archive', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            secondaryBackground: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.orange,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Snooze', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  SizedBox(width: 8),
                  Icon(Icons.snooze, color: Colors.white, size: 24),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                // Archive email
                if (mounted) {
                  final emailProvider = context.read<provider.EmailProvider>();
                  emailProvider.archiveEmail(message);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email archived')),
                  );
                  return true;
                }
                return false;
              } else if (direction == DismissDirection.endToStart) {
                // Snooze email
                final snoozeTime = await showSnoozeDialog(context);
                if (snoozeTime != null) {
                  final emailProvider = context.read<provider.EmailProvider>();
                  await emailProvider.snoozeEmail(message, snoozeTime);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Email snoozed until ${_formatSnoozeTime(snoozeTime)}')),
                    );
                  }
                  return true;
                }
                return false;
              }
              return false;
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : null,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: InkWell(
              onTap: () {
                if (_isSelectionMode) {
                  _toggleEmailSelection(message.messageId);
                } else {
                  final emailProvider = context.read<provider.EmailProvider>();
                  if (!message.isRead) {
                    emailProvider.markAsRead(message);
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmailDetailScreen(message: message),
                    ),
                  );
                }
              },
              onLongPress: () {
                if (!_isSelectionMode) {
                  _enterSelectionMode(message.messageId);
                } else {
                  _toggleEmailSelection(message.messageId);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gmail-style sender avatar
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 12.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : _getAvatarColor(message.from),
                      ),
                      child: Center(
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 20,
                              )
                            : Text(
                                _getSenderInitial(message.from),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),

                    // Email content - Gmail layout
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // First row: Sender name and date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _extractSenderName(message.from),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: message.isRead ? FontWeight.normal : FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                DateFormatUtils.formatRelativeDate(message.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontWeight: message.isRead ? FontWeight.normal : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 2),

                          // Second row: Subject line
                          Text(
                            message.subject.isNotEmpty ? message.subject : 'No subject',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: message.isRead ? FontWeight.normal : FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 2),

                          // Third row: Preview text
                          Text(
                            (message.previewText?.isNotEmpty == true)
                                ? message.previewText!
                                : (message.textBody.isNotEmpty
                                    ? PreviewExtractor.extractPreview(
                                        textContent: message.textBody,
                                        htmlContent: message.htmlBody,
                                        maxLength: 100
                                      )
                                    : 'No preview available'),
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Star button (Gmail-style)
                    IconButton(
                      onPressed: () {
                        final emailProvider = context.read<provider.EmailProvider>();
                        emailProvider.toggleImportant(message);
                      },
                      icon: Icon(
                        message.isImportant ? Icons.star : Icons.star_border,
                        color: message.isImportant
                            ? Colors.amber
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        size: 20,
                      ),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        },
      ),
    );
  }

  Widget _buildCategoryEmailList(List<EmailMessage> emails) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      // Gmail-style refresh indicator styling
      displacement: 50.0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      color: Theme.of(context).colorScheme.primary,
      strokeWidth: 2.5,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: ListView.builder(
        itemCount: emails.length,
        // Add physics for better scroll experience like Gmail
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemBuilder: (context, index) {
          final message = emails[index];
          final isSelected = _selectedEmails.contains(message.messageId);

          return Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : null,
            ),
            child: InkWell(
              onTap: () {
                if (_isSelectionMode) {
                  _toggleEmailSelection(message.messageId);
                } else {
                  final emailProvider = context.read<provider.EmailProvider>();
                  if (!message.isRead) {
                    emailProvider.markAsRead(message);
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmailDetailScreen(message: message),
                    ),
                  );
                }
              },
              onLongPress: () {
                if (!_isSelectionMode) {
                  _enterSelectionMode(message.messageId);
                } else {
                  _toggleEmailSelection(message.messageId);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selection indicator or sender avatar
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 12.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : message.isRead
                                ? Theme.of(context).colorScheme.surfaceContainerHighest
                                : Theme.of(context).colorScheme.primary,
                      ),
                      child: Center(
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 20,
                              )
                            : Text(
                                message.from.isNotEmpty ? message.from[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  color: message.isRead
                                      ? Theme.of(context).colorScheme.onSurfaceVariant
                                      : Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),

                    // Email content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sender name and time row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  message.from,
                                  style: TextStyle(
                                    fontWeight: message.isRead ? FontWeight.w500 : FontWeight.w600,
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  // Category chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(message.category).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      EmailCategorizer.getCategoryDisplayName(message.category),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: _getCategoryColor(message.category),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(message.date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Subject line
                          Text(
                            message.subject,
                            style: TextStyle(
                              fontWeight: message.isRead ? FontWeight.normal : FontWeight.w500,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 2),

                          // Email preview - use optimized preview text
                          Text(
                            message.previewText ?? message.textBody,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the selection mode AppBar with Gmail-style actions
  AppBar _buildSelectionAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitSelectionMode,
      ),
      title: Text('${_selectedEmails.length}'),
      actions: [
        IconButton(
          icon: const Icon(Icons.archive),
          onPressed: _selectedEmails.isNotEmpty ? _archiveSelected : null,
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: _selectedEmails.isNotEmpty ? _deleteSelected : null,
        ),
        IconButton(
          icon: const Icon(Icons.mark_email_read),
          onPressed: _selectedEmails.isNotEmpty ? _markSelectedAsRead : null,
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'select_all':
                _selectAll();
                break;
              case 'mark_unread':
                _markSelectedAsUnread();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'select_all',
              child: Row(
                children: [
                  Icon(Icons.select_all),
                  SizedBox(width: 8),
                  Text('Select all'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'mark_unread',
              child: Row(
                children: [
                  Icon(Icons.mark_email_unread),
                  SizedBox(width: 8),
                  Text('Mark as unread'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Enters selection mode
  void _enterSelectionMode(String messageId) {
    setState(() {
      _isSelectionMode = true;
      _selectedEmails.add(messageId);
    });
  }

  /// Exits selection mode
  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedEmails.clear();
    });
  }

  /// Toggles selection of an email
  void _toggleEmailSelection(String messageId) {
    setState(() {
      if (_selectedEmails.contains(messageId)) {
        _selectedEmails.remove(messageId);
        if (_selectedEmails.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedEmails.add(messageId);
      }
    });
  }

  /// Selects all emails in the current category
  void _selectAll() {
    final emailProvider = context.read<provider.EmailProvider>();
    final currentCategory = _categories[_tabController.index];
    final categoryEmails = EmailCategorizer.getEmailsByCategory(
      emailProvider.messages,
      currentCategory,
    );

    setState(() {
      _selectedEmails.addAll(categoryEmails.map((e) => e.messageId));
    });
  }

  /// Archives selected emails
  void _archiveSelected() async {
    final emailProvider = context.read<provider.EmailProvider>();
    for (final messageId in _selectedEmails) {
      // Archive functionality - for now just remove from UI
      final message = emailProvider.messages.firstWhere(
        (m) => m.messageId == messageId,
        orElse: () => EmailMessage(
          messageId: '',
          accountId: '',
          subject: '',
          from: '',
          to: [],
          date: DateTime.now(),
          textBody: '',
          folder: EmailFolder.inbox,
          uid: 0,
        ),
      );
      if (message.messageId.isNotEmpty) {
        await emailProvider.deleteEmail(message);
      }
    }
    _exitSelectionMode();
  }

  /// Deletes selected emails
  void _deleteSelected() async {
    final emailProvider = context.read<provider.EmailProvider>();
    for (final messageId in _selectedEmails) {
      final message = emailProvider.messages.firstWhere(
        (m) => m.messageId == messageId,
        orElse: () => EmailMessage(
          messageId: '',
          accountId: '',
          subject: '',
          from: '',
          to: [],
          date: DateTime.now(),
          textBody: '',
          folder: EmailFolder.inbox,
          uid: 0,
        ),
      );
      if (message.messageId.isNotEmpty) {
        await emailProvider.deleteEmail(message);
      }
    }
    _exitSelectionMode();
  }

  /// Marks selected emails as read
  void _markSelectedAsRead() async {
    final emailProvider = context.read<provider.EmailProvider>();
    for (final messageId in _selectedEmails) {
      final message = emailProvider.messages.firstWhere(
        (m) => m.messageId == messageId,
        orElse: () => EmailMessage(
          messageId: '',
          accountId: '',
          subject: '',
          from: '',
          to: [],
          date: DateTime.now(),
          textBody: '',
          folder: EmailFolder.inbox,
          uid: 0,
        ),
      );
      if (message.messageId.isNotEmpty) {
        await emailProvider.markAsRead(message);
      }
    }
    _exitSelectionMode();
  }

  /// Marks selected emails as unread
  void _markSelectedAsUnread() async {
    final emailProvider = context.read<provider.EmailProvider>();
    for (final messageId in _selectedEmails) {
      final message = emailProvider.messages.firstWhere(
        (m) => m.messageId == messageId,
        orElse: () => EmailMessage(
          messageId: '',
          accountId: '',
          subject: '',
          from: '',
          to: [],
          date: DateTime.now(),
          textBody: '',
          folder: EmailFolder.inbox,
          uid: 0,
        ),
      );
      if (message.messageId.isNotEmpty) {
        // Set as unread
        message.isRead = false;
        await emailProvider.markAsRead(message); // This will sync the change
      }
    }
    _exitSelectionMode();
  }

  /// Gets the color for a category
  Color _getCategoryColor(EmailCategory category) {
    switch (category) {
      case EmailCategory.primary:
        return Colors.blue;
      case EmailCategory.promotions:
        return Colors.orange;
      case EmailCategory.social:
        return Colors.green;
      case EmailCategory.updates:
        return Colors.purple;
    }
  }

  /// Enters search mode
  void _enterSearchMode() {
    setState(() {
      _isSearchMode = true;
    });
    // Focus the search field after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  /// Exits search mode
  void _exitSearchMode() {
    setState(() {
      _isSearchMode = false;
      _searchQuery = '';
    });
    _searchController.clear();
    _searchFocusNode.unfocus();
    // Trigger search with empty query to show all emails
    _performSearch('');
  }

  /// Builds the search AppBar similar to Gmail
  AppBar _buildSearchAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _exitSearchMode,
      ),
      title: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search in mail',
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
        ),
        textInputAction: TextInputAction.search,
        onChanged: _performSearch,
        onSubmitted: _performSearch,
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              _performSearch('');
            },
            tooltip: 'Clear search',
          ),
      ],
    );
  }

  /// Performs the email search
  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.trim();
    });

    // TODO: Implement search logic in EmailProvider
    final emailProvider = context.read<provider.EmailProvider>();
    if (query.trim().isEmpty) {
      // Show all emails when search is cleared
      emailProvider.clearSearch();
    } else {
      // Perform search
      emailProvider.searchEmails(query.trim());
    }
  }

  /// Builds the no search results view
  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No emails found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or check your spelling',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Forces a refresh of all cached emails for troubleshooting
  void _forceRefreshCache() async {
    final emailProvider = context.read<provider.EmailProvider>();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fix Cache'),
        content: const Text(
          'This will force refresh all emails for all accounts. This may take a few minutes.\n\nContinue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await emailProvider.forceRefreshAllAccounts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cache refresh completed!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cache refresh failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Builds the conversation view as a Sliver for CustomScrollView
  Widget _buildConversationViewSliver(provider.EmailProvider emailProvider) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final conversation = emailProvider.conversations[index];
          final messages = emailProvider.getMessagesForConversation(conversation);

          return ConversationItem(
            conversation: conversation,
            messages: messages,
            isSelected: _selectedEmails.contains(conversation.id),
            onMessageTap: (message) => _openEmailDetail(message),
            onConversationTap: (conversation) {
              // Handle conversation tap (expand/collapse)
              setState(() {
                // The conversation item handles its own expansion state
              });
            },
            onAvatarTap: (senderEmail) {
              // Handle avatar tap (e.g., show sender details)
              _showSenderDetails(senderEmail);
            },
            onLongPress: () => _toggleEmailSelection(conversation.id),
          );
        },
        childCount: emailProvider.conversations.length,
      ),
    );
  }

  /// Builds the conversation view for threaded email display
  Widget _buildConversationView(provider.EmailProvider emailProvider) {
    return ListView.builder(
      itemCount: emailProvider.conversations.length,
      itemBuilder: (context, index) {
        final conversation = emailProvider.conversations[index];
        final messages = emailProvider.getMessagesForConversation(conversation);

        return ConversationItem(
          conversation: conversation,
          messages: messages,
          isSelected: _selectedEmails.contains(conversation.id),
          onMessageTap: (message) => _openEmailDetail(message),
          onConversationTap: (conversation) {
            // Handle conversation tap (expand/collapse)
            setState(() {
              // The conversation item handles its own expansion state
            });
          },
          onAvatarTap: (senderEmail) {
            // Handle avatar tap (e.g., show sender details)
            _showSenderDetails(senderEmail);
          },
          onLongPress: () => _toggleEmailSelection(conversation.id),
        );
      },
    );
  }

  /// Shows details for a sender
  void _showSenderDetails(String senderEmail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sender Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: $senderEmail'),
            const SizedBox(height: 16),
            Text('Actions:'),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Compose Email'),
              dense: true,
              onTap: () {
                Navigator.pop(context);
                _composeEmailToSender(senderEmail);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block Sender'),
              dense: true,
              onTap: () {
                Navigator.pop(context);
                _blockSender(senderEmail);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Composes an email to a specific sender
  void _composeEmailToSender(String senderEmail) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComposeScreen(
          replyTo: senderEmail,
        ),
      ),
    );
  }

  /// Blocks a sender
  void _blockSender(String senderEmail) {
    // TODO: Implement block sender functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Blocked $senderEmail'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Opens the email detail screen
  void _openEmailDetail(EmailMessage message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailDetailScreen(message: message),
      ),
    );
  }

  /// Shows a snackbar with a message
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Shows a confirmation dialog for deleting emails
  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Email'),
          content: const Text('Are you sure you want to delete this email?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  String _formatSnoozeTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (messageDate == today) {
      return 'today at $timeStr';
    } else if (messageDate == tomorrow) {
      return 'tomorrow at $timeStr';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

      return '${weekdays[dateTime.weekday - 1]}, ${months[dateTime.month - 1]} ${dateTime.day} at $timeStr';
    }
  }
}