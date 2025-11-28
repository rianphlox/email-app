
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/email_provider.dart' as provider;
import '../utils/constants.dart';

/// A screen that allows users to add a new email account.
///
/// This screen provides options for adding a Gmail, Outlook, Yahoo, or custom
/// email account. For Gmail, it uses the Google Sign-In flow. For other
/// providers, it presents a form for entering the account details.
class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  // --- Private Properties ---

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _imapServerController = TextEditingController();
  final _imapPortController = TextEditingController(text: '993');
  final _smtpServerController = TextEditingController();
  final _smtpPortController = TextEditingController(text: '587');

  String _selectedProvider = 'gmail';
  bool _isSSL = true;

  // --- Lifecycle Methods ---

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _imapServerController.dispose();
    _imapPortController.dispose();
    _smtpServerController.dispose();
    _smtpPortController.dispose();
    super.dispose();
  }

  // --- UI Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Email Account'),
      ),
      body: Consumer<provider.EmailProvider>(
        builder: (context, emailProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Provider selection buttons.
                  _buildProviderSelection(),

                  const SizedBox(height: 16),

                  // Form for entering account details.
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildAccountForm(emailProvider),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Private Helper Methods ---

  /// Automatically populates the server settings when the user enters their email address.
  void _onEmailChanged() {
    final email = _emailController.text.toLowerCase();
    if (email.contains('@')) {
      final domain = email.split('@').last;
      if (Constants.defaultEmailSettings.containsKey(domain)) {
        final settings = Constants.defaultEmailSettings[domain]!;
        _imapServerController.text = settings['imap']['server'];
        _imapPortController.text = settings['imap']['port'].toString();
        _smtpServerController.text = settings['smtp']['server'];
        _smtpPortController.text = settings['smtp']['port'].toString();
        _isSSL = settings['imap']['ssl'];
        setState(() {});
      }
    }
  }

  /// Builds the UI for selecting the email provider.
  Widget _buildProviderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your email provider:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildProviderCard(
                'gmail',
                'Gmail',
                Icons.email,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProviderCard(
                'outlook',
                'Outlook',
                Icons.mail_outline,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildProviderCard(
                'yahoo',
                'Yahoo',
                Icons.alternate_email,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProviderCard(
                'custom',
                'Other',
                Icons.settings,
                Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds a provider selection card
  Widget _buildProviderCard(String provider, String name, IconData icon, Color color) {
    final isSelected = _selectedProvider == provider;
    final isComingSoon = provider == 'yahoo' || provider == 'outlook';

    return InkWell(
      onTap: isComingSoon
        ? () {
            // Show coming soon message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$name integration coming soon! 🚀'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        : () {
            setState(() {
              _selectedProvider = provider;
            });
          },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isComingSoon
              ? Colors.grey.shade300
              : isSelected ? color : Colors.grey.shade300,
            width: isSelected && !isComingSoon ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isComingSoon
            ? Colors.grey.shade50
            : isSelected ? color.withValues(alpha: 0.1) : null,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: isComingSoon
                    ? Colors.grey.shade400
                    : isSelected ? color : Colors.grey.shade600,
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: isSelected && !isComingSoon ? FontWeight.w600 : FontWeight.w500,
                    color: isComingSoon
                      ? Colors.grey.shade500
                      : isSelected ? color : Colors.grey.shade700,
                  ),
                ),
                if (isComingSoon) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Text(
                      'Coming Soon',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the form for entering account details.
  Widget _buildAccountForm(provider.EmailProvider emailProvider) {
    if (_selectedProvider == 'gmail') {
      return _buildGmailForm(emailProvider);
    } else if (_selectedProvider == 'yahoo') {
      return _buildYahooForm(emailProvider);
    } else {
      return _buildManualForm(emailProvider);
    }
  }

  /// Builds Gmail sign-in form
  Widget _buildGmailForm(provider.EmailProvider emailProvider) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Icon(
          Icons.email,
          size: 64,
          color: Colors.red,
        ),
        const SizedBox(height: 16),
        Text(
          'Sign in with Gmail',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the button below to sign in with your Google account',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: emailProvider.isLoading ? null : _signInWithGoogle,
            icon: const Icon(Icons.login),
            label: emailProvider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign in with Google'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        if (emailProvider.error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    emailProvider.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Builds Yahoo OAuth sign-in form
  Widget _buildYahooForm(provider.EmailProvider emailProvider) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Icon(
          Icons.alternate_email,
          size: 64,
          color: Colors.purple,
        ),
        const SizedBox(height: 16),
        Text(
          'Sign in with Yahoo',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the button below to sign in with your Yahoo account',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: emailProvider.isLoading ? null : _signInWithYahoo,
            icon: const Icon(Icons.login),
            label: emailProvider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign in with Yahoo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        if (emailProvider.error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    emailProvider.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Builds manual configuration form
  Widget _buildManualForm(provider.EmailProvider emailProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildTextField(
          controller: _nameController,
          label: 'Display Name',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email address';
            }
            if (!value.contains('@') || !value.contains('.')) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Server Settings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                controller: _imapServerController,
                label: 'IMAP Server',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _imapPortController,
                label: 'Port',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                controller: _smtpServerController,
                label: 'SMTP Server',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _smtpPortController,
                label: 'Port',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('Use SSL/TLS'),
          value: _isSSL,
          onChanged: (value) {
            setState(() {
              _isSSL = value ?? true;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: emailProvider.isLoading ? null : _addAccount,
            child: emailProvider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add Account'),
          ),
        ),
        if (emailProvider.error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    emailProvider.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Builds a text field widget.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  /// Initiates the Google Sign-In flow.
  Future<void> _signInWithGoogle() async {
    debugPrint('🖱️ UI: User tapped Google Sign-In button');

    final emailProvider = context.read<provider.EmailProvider>();

    debugPrint('🖱️ UI: Calling emailProvider.signInWithGoogle()...');
    final success = await emailProvider.signInWithGoogle();

    debugPrint('🖱️ UI: signInWithGoogle returned: $success');
    debugPrint('🖱️ UI: EmailProvider error: ${emailProvider.error}');

    if (success && mounted) {
      debugPrint('✅ UI: Sign-in successful, navigating back');
      Navigator.pop(context);
    } else if (!success && mounted) {
      debugPrint('❌ UI: Sign-in failed, showing error snackbar');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailProvider.error ?? 'Failed to sign in with Google'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Initiates the Yahoo Sign-In flow.
  Future<void> _signInWithYahoo() async {
    final emailProvider = context.read<provider.EmailProvider>();
    final success = await emailProvider.signInWithYahoo();
    if (success && mounted) {
      Navigator.pop(context);
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailProvider.error ?? 'Failed to sign in with Yahoo'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Adds the new email account.
  Future<void> _addAccount() async {
    final emailProvider = context.read<provider.EmailProvider>();
    bool success = false;

    if (_selectedProvider == 'gmail') {
      // Gmail uses the OAuth flow, not a form submission.
      await _signInWithGoogle();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedProvider == 'outlook') {
      success = await emailProvider.signInWithOutlook(
        _emailController.text,
        _passwordController.text,
      );
    } else if (_selectedProvider == 'yahoo') {
      success = await emailProvider.signInWithYahoo();
    } else if (_selectedProvider == 'custom') {
      success = await emailProvider.addCustomEmailAccount(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        imapServer: _imapServerController.text,
        imapPort: int.parse(_imapPortController.text),
        smtpServer: _smtpServerController.text,
        smtpPort: int.parse(_smtpPortController.text),
        isSSL: _isSSL,
      );
    }

    if (success && mounted) {
      Navigator.pop(context);
    }
  }
}
