import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/email_provider.dart' as provider;

class ComposeScreen extends StatefulWidget {
  final String? replyTo;
  final String? subject;
  final String? initialBody;

  const ComposeScreen({
    super.key,
    this.replyTo,
    this.subject,
    this.initialBody,
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
  final _bodyController = TextEditingController();

  final List<String> _attachmentPaths = [];
  bool _showCcBcc = false;

  @override
  void initState() {
    super.initState();
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

                    // Body field
                    TextFormField(
                      controller: _bodyController,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 12,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your message';
                        }
                        return null;
                      },
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

    final success = await emailProvider.sendEmail(
      to: _toController.text,
      cc: _ccController.text.isNotEmpty ? _ccController.text : null,
      bcc: _bccController.text.isNotEmpty ? _bccController.text : null,
      subject: _subjectController.text,
      body: _bodyController.text,
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