import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/email_provider.dart' as provider;
import '../models/email_message.dart';
import '../widgets/rich_text_editor.dart';

class ComposeScreen extends StatefulWidget {
  final String? replyTo;
  final String? subject;
  final String? initialBody;
  final EmailMessage? replyToMessage;
  final EmailMessage? forwardMessage;
  final bool isReply;
  final bool isForward;

  const ComposeScreen({
    super.key,
    this.replyTo,
    this.subject,
    this.initialBody,
    this.replyToMessage,
    this.forwardMessage,
    this.isReply = false,
    this.isForward = false,
  });

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _toController = TextEditingController();
  final _ccController = TextEditingController();
  final _bccController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController(); // Keep for compatibility

  final List<String> _attachmentPaths = [];
  bool _showCcBcc = false;
  String _bodyText = '';

  void _onBodyTextChanged(String plainText, String html) {
    setState(() {
      _bodyText = plainText;
    });
  }

  @override
  void initState() {
    super.initState();

    // Handle reply functionality
    if (widget.isReply && widget.replyToMessage != null) {
      final message = widget.replyToMessage!;
      _toController.text = message.from;
      _subjectController.text = message.subject.startsWith('Re:')
          ? message.subject
          : 'Re: ${message.subject}';

      // Add original message to body
      final originalText = message.textBody.length > 500
          ? '${message.textBody.substring(0, 500)}...'
          : message.textBody;

      final replyText = '\n\n--- Original Message ---\n'
          'From: ${message.from}\n'
          'Date: ${_formatDate(message.date)}\n'
          'Subject: ${message.subject}\n\n'
          '$originalText';

      _bodyController.text = replyText;
      _bodyText = replyText;
    }

    // Handle forward functionality
    else if (widget.isForward && widget.forwardMessage != null) {
      final message = widget.forwardMessage!;
      _subjectController.text = message.subject.startsWith('Fwd:')
          ? message.subject
          : 'Fwd: ${message.subject}';

      // Add original message to body
      _bodyController.text = '\n\n--- Forwarded Message ---\n'
          'From: ${message.from}\n'
          'To: ${message.to.join(', ')}\n'
          'Date: ${_formatDate(message.date)}\n'
          'Subject: ${message.subject}\n\n'
          '${message.textBody}';
    }

    // Handle legacy parameters
    else {
      if (widget.replyTo != null) {
        _toController.text = widget.replyTo!;
      }
      if (widget.subject != null) {
        _subjectController.text = widget.subject!;
      }
      if (widget.initialBody != null) {
        _bodyController.text = widget.initialBody!;
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '${months[date.month - 1]} ${date.day}, ${date.year}, $time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<provider.EmailProvider>(
            builder: (context, emailProvider, child) {
              return TextButton(
                onPressed: emailProvider.isLoading ? null : _sendEmail,
                child: emailProvider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send'),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // To field
                    TextFormField(
                      controller: _toController,
                      decoration: InputDecoration(
                        labelText: 'To',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showCcBcc ? Icons.remove : Icons.add,
                          ),
                          onPressed: () {
                            setState(() {
                              _showCcBcc = !_showCcBcc;
                            });
                          },
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter recipient email';
                        }
                        if (!_isValidEmail(value)) {
                          return 'Please enter valid email addresses';
                        }
                        return null;
                      },
                    ),

                    // CC and BCC fields (if shown)
                    if (_showCcBcc) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ccController,
                        decoration: const InputDecoration(
                          labelText: 'CC',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty && !_isValidEmail(value)) {
                            return 'Please enter valid email addresses';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bccController,
                        decoration: const InputDecoration(
                          labelText: 'BCC',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty && !_isValidEmail(value)) {
                            return 'Please enter valid email addresses';
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Subject field
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a subject';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Attachments section
                    if (_attachmentPaths.isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.attach_file),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Attachments (${_attachmentPaths.length})',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _attachmentPaths
                                    .map((path) => _buildAttachmentChip(path))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Body field with rich text editor
                    Container(
                      height: 300, // Fixed height for the rich text editor
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: RichTextEditor(
                        initialText: widget.initialBody,
                        hintText: 'Compose your message...',
                        onTextChanged: _onBodyTextChanged,
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom action bar
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Attach file button
                  IconButton(
                    onPressed: _pickAttachment,
                    icon: const Icon(Icons.attach_file),
                    tooltip: 'Attach files',
                  ),
                  const Spacer(),
                  // Send button
                  ElevatedButton.icon(
                    onPressed: _sendEmail,
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                  ),
                ],
              ),
            ),

            // Error display
            Consumer<provider.EmailProvider>(
              builder: (context, emailProvider, child) {
                if (emailProvider.error != null) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Text(
                      emailProvider.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentChip(String filePath) {
    final fileName = filePath.split('/').last;
    return Chip(
      label: Text(
        fileName,
        style: const TextStyle(fontSize: 12),
      ),
      avatar: const Icon(Icons.attach_file, size: 16),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: () {
        setState(() {
          _attachmentPaths.remove(filePath);
        });
      },
    );
  }

  bool _isValidEmail(String emails) {
    final emailList = emails.split(',').map((e) => e.trim());
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

    for (final email in emailList) {
      if (email.isNotEmpty && !emailRegExp.hasMatch(email)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _pickAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final file in result.files) {
            if (file.path != null && !_attachmentPaths.contains(file.path!)) {
              _attachmentPaths.add(file.path!);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final emailProvider = context.read<provider.EmailProvider>();

    // Use rich text content if available, otherwise fallback to plain text
    final bodyContent = _bodyText.isNotEmpty ? _bodyText : _bodyController.text;

    final success = await emailProvider.sendEmail(
      to: _toController.text,
      cc: _ccController.text.isNotEmpty ? _ccController.text : null,
      bcc: _bccController.text.isNotEmpty ? _bccController.text : null,
      subject: _subjectController.text,
      body: bodyContent,
      attachmentPaths: _attachmentPaths.isNotEmpty ? _attachmentPaths : null,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email sent successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(emailProvider.error ?? 'Failed to send email'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }


  @override
  void dispose() {
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}