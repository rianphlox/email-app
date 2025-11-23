import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// A rich text editor widget for composing emails with formatting options
class RichTextEditor extends StatefulWidget {
  final String? initialText;
  final String? initialHtml;
  final Function(String plainText, String html)? onTextChanged;
  final String? hintText;

  const RichTextEditor({
    super.key,
    this.initialText,
    this.initialHtml,
    this.onTextChanged,
    this.hintText,
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();

    // Set initial content if provided
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _controller.document = Document()..insert(0, widget.initialText!);
    }

    // Listen for text changes
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.onTextChanged != null) {
      final plainText = _controller.document.toPlainText();
      // For now, we'll use plain text as HTML since toHtml might not be available
      final html = '<p>$plainText</p>';
      widget.onTextChanged!(plainText, html);
    }
  }

  /// Gets the plain text content
  String getPlainText() {
    return _controller.document.toPlainText();
  }

  /// Gets the HTML content (basic conversion)
  String getHtml() {
    final plainText = _controller.document.toPlainText();
    return '<p>$plainText</p>';
  }

  /// Sets the content from plain text
  void setPlainText(String text) {
    _controller.document = Document()..insert(0, text);
  }

  /// Clears all content
  void clear() {
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Formatting toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: QuillSimpleToolbar(
            controller: _controller,
            config: const QuillSimpleToolbarConfig(
              multiRowsDisplay: false,
              showFontFamily: false,
              showFontSize: false,
              showSubscript: false,
              showSuperscript: false,
              showStrikeThrough: false,
              showInlineCode: false,
              showColorButton: false,
              showBackgroundColorButton: false,
              showClearFormat: true,
              showAlignmentButtons: true,
              showLeftAlignment: true,
              showCenterAlignment: true,
              showRightAlignment: true,
              showJustifyAlignment: false,
              showHeaderStyle: false,
              showListNumbers: true,
              showListBullets: true,
              showCodeBlock: false,
              showQuote: true,
              showIndent: true,
              showLink: true,
              showUndo: true,
              showRedo: true,
              showSearchButton: false,
            ),
          ),
        ),

        // Editor area
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: QuillEditor.basic(
              controller: _controller,
              focusNode: _focusNode,
              config: QuillEditorConfig(
                placeholder: widget.hintText ?? 'Compose your message...',
                padding: EdgeInsets.zero,
                autoFocus: false,
                expands: true,
                scrollable: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}