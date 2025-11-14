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

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _selectedEmails = <String>{};
  bool _isSelectionMode = false;

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

    // Auto-sync emails in background after showing cached emails
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBackgroundSync();
    });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode
        ? _buildSelectionAppBar()
        : AppBar(
            title: const Text('QMail'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            bottom: _buildTabBar(),
            actions: [
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
      body: Consumer<provider.EmailProvider>(
        builder: (context, emailProvider, child) {
          // PRIORITY 1: Always show cached emails immediately if available (even without accounts)
          if (emailProvider.messages.isNotEmpty) {
            return Stack(
            children: [
              _buildCategorizedInbox(emailProvider),
              // Show subtle loading indicator during background sync
              if (emailProvider.isLoading)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
            ],
          );
          }

          // PRIORITY 2: Show welcome screen only if no accounts AND no cached emails
          if (emailProvider.accounts.isEmpty) {
            return _buildWelcomeScreen();
          }

          // PRIORITY 3: Show loading when we have accounts but no cached emails yet
          if (emailProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // PRIORITY 4: Show error only if we have accounts but no cached emails and there's an error
          if (emailProvider.error != null) {
            return _buildErrorState(emailProvider.error!);
          }

          // PRIORITY 5: Empty state with quick action to sync
          return _buildEmptyInbox(emailProvider);
        },
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
              // Account header
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
                            Icons.person,
                            size: 30,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          emailProvider.currentAccount?.name ?? 'Offline Mode',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          emailProvider.currentAccount?.email ?? 'Viewing cached emails',
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

              // Folders
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
                      Icons.report,
                      EmailFolder.spam,
                      emailProvider,
                    ),
                    const Divider(),

                    // Accounts section
                    if (emailProvider.accounts.length > 1) ...[
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Accounts',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...emailProvider.accounts.map(
                        (account) => _buildAccountTile(account, emailProvider),
                      ),
                      const Divider(),
                    ],

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

  Widget _buildAccountTile(EmailAccount account, provider.EmailProvider emailProvider) {
    final isSelected = emailProvider.currentAccount?.id == account.id;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getProviderColor(account.provider),
        child: Text(
          account.name.isNotEmpty ? account.name[0].toUpperCase() : 'U',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(account.name),
      subtitle: Text(account.email),
      selected: isSelected,
      onTap: () {
        emailProvider.switchAccount(account);
        Navigator.pop(context);
      },
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          PopupMenuItem(
            child: const Text('Remove'),
            onTap: () {
              _showRemoveAccountDialog(account.id);
            },
          ),
        ],
      ),
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

  PreferredSizeWidget? _buildTabBar() {
    final emailProvider = context.watch<provider.EmailProvider>();
    // Show tab bar if we have accounts OR cached messages
    if (emailProvider.accounts.isEmpty && emailProvider.messages.isEmpty) return null;

    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabs: _categories.map((category) {
        final unreadCount = EmailCategorizer.getUnreadCount(
          emailProvider.messages,
          category,
        );
        return Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(EmailCategorizer.getCategoryIcon(category)),
              const SizedBox(width: 4),
              Text(EmailCategorizer.getCategoryDisplayName(category)),
              if (unreadCount > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onError,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
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
}