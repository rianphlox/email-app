import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/email_provider.dart' as provider;
import '../models/email_message.dart';
import '../models/email_account.dart';
import '../screens/add_account_screen.dart';
import '../screens/email_detail_screen.dart';
import '../screens/compose_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({Key? key}) : super(key: key);

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<provider.EmailProvider>().fetchEmails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Readify'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
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
                      emailProvider.fetchEmails();
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
          if (emailProvider.accounts.isEmpty) {
            return _buildWelcomeScreen();
          }

          if (emailProvider.isLoading && emailProvider.messages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (emailProvider.error != null && emailProvider.messages.isEmpty) {
            return _buildErrorState(emailProvider.error!);
          }

          return _buildEmailList(emailProvider);
        },
      ),
      floatingActionButton: Consumer<provider.EmailProvider>(
        builder: (context, emailProvider, child) {
          if (emailProvider.accounts.isEmpty) return const SizedBox();
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
        if (emailProvider.accounts.isEmpty) return _buildEmptyDrawer();

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
                          emailProvider.currentAccount?.name ?? 'User',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          emailProvider.currentAccount?.email ?? '',
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
              'Welcome to Readify',
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
                context.read<provider.EmailProvider>().fetchEmails();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailList(provider.EmailProvider emailProvider) {
    return RefreshIndicator(
      onRefresh: () async {
        await emailProvider.fetchEmails();
      },
      child: Column(
        children: [
          // Folder header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(
                  _getFolderIcon(emailProvider.currentFolder),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  _getFolderName(emailProvider.currentFolder),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (emailProvider.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Email list
          Expanded(
            child: emailProvider.messages.isEmpty
                ? const Center(
                    child: Text('No emails found'),
                  )
                : ListView.builder(
                    itemCount: emailProvider.messages.length,
                    itemBuilder: (context, index) {
                      final message = emailProvider.messages[index];
                      return _buildEmailTile(message, emailProvider);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailTile(EmailMessage message, provider.EmailProvider emailProvider) {
    return Dismissible(
      key: Key(message.messageId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.red,
        child: const Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      onDismissed: (direction) {
        emailProvider.deleteEmail(message);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email deleted')),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: message.isRead
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Theme.of(context).colorScheme.primary,
            child: Text(
              message.from.isNotEmpty ? message.from[0].toUpperCase() : 'U',
              style: TextStyle(
                color: message.isRead
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            message.from,
            style: TextStyle(
              fontWeight: message.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.subject,
                style: TextStyle(
                  fontWeight: message.isRead ? FontWeight.normal : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                message.textBody,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDate(message.date),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (message.attachments?.isNotEmpty ?? false)
                const Icon(Icons.attach_file, size: 16),
              if (message.isImportant)
                const Icon(Icons.star, size: 16, color: Colors.orange),
            ],
          ),
          onTap: () {
            if (!message.isRead) {
              emailProvider.markAsRead(message);
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmailDetailScreen(message: message),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getFolderIcon(EmailFolder folder) {
    switch (folder) {
      case EmailFolder.inbox:
        return Icons.inbox;
      case EmailFolder.sent:
        return Icons.send;
      case EmailFolder.drafts:
        return Icons.drafts;
      case EmailFolder.trash:
        return Icons.delete;
      default:
        return Icons.folder;
    }
  }

  String _getFolderName(EmailFolder folder) {
    switch (folder) {
      case EmailFolder.inbox:
        return 'All Inboxes';
      case EmailFolder.sent:
        return 'Sent';
      case EmailFolder.drafts:
        return 'Drafts';
      case EmailFolder.trash:
        return 'Trash';
      default:
        return 'Folder';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}';
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
                      'Readify',
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Readify'),
        content: const Text(
          'Readify - Smart Email Reader\n\n'
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
}