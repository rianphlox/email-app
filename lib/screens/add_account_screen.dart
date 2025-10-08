import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/email_provider.dart' as provider;
import '../utils/constants.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({Key? key}) : super(key: key);

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _imapServerController = TextEditingController();
  final _imapPortController = TextEditingController(text: '993');
  final _smtpServerController = TextEditingController();
  final _smtpPortController = TextEditingController(text: '587');

  String _selectedProvider = 'custom';
  bool _isSSL = true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Email Account'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<provider.EmailProvider>(
        builder: (context, emailProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Provider selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Choose Email Provider',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.spaceEvenly,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildProviderButton('Gmail', 'gmail', Icons.email),
                              _buildProviderButton('Outlook', 'outlook', Icons.mail_outline),
                              _buildProviderButton('Yahoo', 'yahoo', Icons.alternate_email),
                              _buildProviderButton('Custom', 'custom', Icons.settings),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Account form
                  Expanded(
                    child: SingleChildScrollView(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              if (_selectedProvider == 'gmail') ...[
                                const Text(
                                  'Gmail Setup',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '🔐 Sign in with Google OAuth',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Tap "Sign in with Google" below to securely connect your Gmail account using Google\'s official authentication.',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Note: If sign-in fails, ensure you have a valid Google account and internet connection.',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: emailProvider.isLoading ? null : _signInWithGoogle,
                                  icon: const Icon(Icons.login),
                                  label: const Text('Sign in with Google'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 50),
                                  ),
                                ),
                              ] else if (_selectedProvider == 'outlook' || _selectedProvider == 'yahoo') ...[
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Please enter a valid email';
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
                              ] else ...[
                                // Custom email configuration
                                _buildTextField(
                                  controller: _nameController,
                                  label: 'Display Name',
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a display name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Please enter a valid email';
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
                                const SizedBox(height: 16),
                                const Text(
                                  'IMAP Settings',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
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
                                    const SizedBox(width: 8),
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
                                const Text(
                                  'SMTP Settings',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
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
                                    const SizedBox(width: 8),
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
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _isSSL,
                                      onChanged: (value) {
                                        setState(() {
                                          _isSSL = value ?? true;
                                        });
                                      },
                                    ),
                                    const Text('Use SSL/TLS'),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Action buttons (hide for Gmail since it uses OAuth button above)
                              if (_selectedProvider != 'gmail') ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: emailProvider.isLoading ? null : _addAccount,
                                        child: emailProvider.isLoading
                                            ? const CircularProgressIndicator()
                                            : const Text('Add Account'),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                // Just cancel button for Gmail
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                              ],

                              if (emailProvider.error != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Theme.of(context).colorScheme.onErrorContainer,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          emailProvider.error!,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onErrorContainer,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildProviderButton(String label, String value, IconData icon) {
    final isSelected = _selectedProvider == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProvider = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<bool> _signInWithGoogle() async {
    final emailProvider = context.read<provider.EmailProvider>();
    final success = await emailProvider.signInWithGoogle();
    if (success && mounted) {
      Navigator.pop(context);
      return true;
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailProvider.error ?? 'Failed to sign in with Google'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
    return success;
  }

  Future<void> _addAccount() async {
    final emailProvider = context.read<provider.EmailProvider>();
    bool success = false;

    if (_selectedProvider == 'gmail') {
      // Gmail uses OAuth, not manual form submission
      success = await _signInWithGoogle();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedProvider == 'outlook') {
      success = await emailProvider.signInWithOutlook(
        _emailController.text,
        _passwordController.text,
      );
    } else if (_selectedProvider == 'yahoo') {
      success = await emailProvider.signInWithYahoo(
        _emailController.text,
        _passwordController.text,
      );
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
}