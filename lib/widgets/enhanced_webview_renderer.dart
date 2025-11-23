import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/email_message.dart';
import '../utils/advanced_quote_processor.dart';
import '../utils/attachment_processor.dart';

/// Enhanced WebView email renderer with advanced quoted text handling
class EnhancedWebViewRenderer extends StatefulWidget {
  final String? htmlContent;
  final String? textContent;
  final List<EmailAttachment>? attachments;
  final bool useDarkMode;
  final Function(String)? onLinkTap;
  final Function(String, bool)? onQuoteToggled;

  const EnhancedWebViewRenderer({
    super.key,
    this.htmlContent,
    this.textContent,
    this.attachments,
    this.useDarkMode = false,
    this.onLinkTap,
    this.onQuoteToggled,
  });

  @override
  State<EnhancedWebViewRenderer> createState() => _EnhancedWebViewRendererState();
}

class _EnhancedWebViewRendererState extends State<EnhancedWebViewRenderer> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;
  ProcessedEmailContent? _processedContent;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('QMail/2.0 (Enhanced Email Renderer)')
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Handle link taps
            if (widget.onLinkTap != null) {
              widget.onLinkTap!(request.url);
            }
            return NavigationDecision.prevent; // Block navigation for security
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
            _setupJavaScriptHandlers();
          },
          onWebResourceError: (error) {
            setState(() {
              _error = error.description;
              _isLoading = false;
            });
          },
        ),
      );

    _loadEmailContent();
  }

  void _setupJavaScriptHandlers() async {
    // Set up quote toggle handler
    await _controller.addJavaScriptChannel(
      'QuoteHandler',
      onMessageReceived: (JavaScriptMessage message) {
        final data = message.message;
        debugPrint('Quote toggled: $data');

        // Parse the message to extract quote ID and state
        try {
          final parts = data.split('|');
          if (parts.length == 2) {
            final quoteId = parts[0];
            final isExpanded = parts[1] == 'true';
            widget.onQuoteToggled?.call(quoteId, isExpanded);
          }
        } catch (e) {
          debugPrint('Error parsing quote toggle message: $e');
        }
      },
    );
  }

  void _loadEmailContent() {
    final content = _prepareEmailContent();
    final dataUri = 'data:text/html;charset=utf-8,${Uri.encodeComponent(content)}';
    _controller.loadRequest(Uri.parse(dataUri));
  }

  String _prepareEmailContent() {
    String rawContent;

    // Determine content source and type
    if (widget.htmlContent != null && widget.htmlContent!.isNotEmpty) {
      rawContent = widget.htmlContent!;
    } else if (widget.textContent != null && widget.textContent!.isNotEmpty) {
      rawContent = widget.textContent!;
    } else {
      return _createFallbackHtml('No content available');
    }

    try {
      // Process inline attachments if needed
      if (widget.attachments != null && widget.attachments!.isNotEmpty) {
        rawContent = AttachmentProcessor.processInlineAttachments(
          htmlContent: rawContent,
          attachments: widget.attachments,
        );
      }

      // Process with advanced quote processor
      final isHtml = widget.htmlContent != null && widget.htmlContent!.isNotEmpty;
      _processedContent = AdvancedQuoteProcessor.processEmailContent(
        rawContent,
        isHtml: isHtml,
        useDarkMode: widget.useDarkMode,
      );

      return _enhanceHtmlWithInteractivity(_processedContent!.processedHtml);
    } catch (e) {
      debugPrint('Error processing email content: $e');
      return _createFallbackHtml(rawContent);
    }
  }

  /// Enhances HTML with additional interactivity and Flutter communication
  String _enhanceHtmlWithInteractivity(String html) {
    // Add enhanced JavaScript for Flutter communication
    final enhancedJavaScript = '''
      // Enhanced quote toggling with Flutter communication
      window.originalToggleQuote = window.toggleQuote;
      window.toggleQuote = function(elementId) {
        if (window.originalToggleQuote) {
          window.originalToggleQuote(elementId);
        }

        // Get the current state
        const quoteContent = document.getElementById(elementId);
        const isExpanded = quoteContent && quoteContent.style.display !== 'none';

        // Send to Flutter
        try {
          QuoteHandler.postMessage(elementId + '|' + isExpanded);
        } catch (e) {
          console.log('Failed to communicate with Flutter:', e);
        }
      };

      // Auto-scroll to show expanded content
      window.scrollToQuote = function(elementId) {
        const element = document.getElementById(elementId);
        if (element) {
          element.scrollIntoView({
            behavior: 'smooth',
            block: 'nearest',
            inline: 'start'
          });
        }
      };

      // Enhanced image handling
      document.addEventListener('DOMContentLoaded', function() {
        // Make images responsive and add loading states
        const images = document.querySelectorAll('img');
        images.forEach(function(img) {
          img.style.maxWidth = '100%';
          img.style.height = 'auto';

          img.addEventListener('load', function() {
            this.style.opacity = '1';
          });

          img.addEventListener('error', function() {
            this.style.display = 'none';
          });

          img.style.opacity = '0.7';
          img.style.transition = 'opacity 0.3s';
        });

        // Add click handlers for expandable content
        const expandableElements = document.querySelectorAll('[data-expandable]');
        expandableElements.forEach(function(element) {
          element.style.cursor = 'pointer';
          element.addEventListener('click', function() {
            const target = this.getAttribute('data-target');
            if (target) {
              toggleQuote(target);
            }
          });
        });
      });
    ''';

    // Inject the enhanced JavaScript
    return html.replaceFirst(
      '</script>',
      '\n$enhancedJavaScript\n</script>',
    );
  }

  String _createFallbackHtml(String content) {
    final escapedContent = content
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    html, body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      font-size: 14px;
      line-height: 1.6;
      margin: 0;
      padding: 16px;
      ${widget.useDarkMode ? 'background-color: #1c1c1e; color: #ffffff;' : 'background-color: #ffffff; color: #000000;'}
      word-wrap: break-word;
      overflow-x: hidden;
      box-sizing: border-box;
      -webkit-text-size-adjust: 100%;
      -webkit-font-smoothing: antialiased;
    }

    * {
      box-sizing: border-box;
      max-width: 100%;
    }

    img {
      max-width: 100% !important;
      height: auto !important;
      display: block;
      margin: 8px auto;
    }

    table {
      max-width: 100% !important;
      table-layout: fixed;
      border-collapse: collapse;
    }

    td, th {
      word-wrap: break-word;
      overflow-wrap: break-word;
      max-width: 0;
    }

    .fallback-content {
      white-space: pre-wrap;
      max-width: 100%;
      overflow-wrap: break-word;
    }
  </style>
</head>
<body>
  <div class="fallback-content">$escapedContent</div>
</body>
</html>
''';
  }

  /// Gets email statistics for UI display
  Map<String, dynamic> getEmailStats() {
    if (_processedContent == null) return {};

    return {
      'hasQuotedText': _processedContent!.hasQuotedText,
      'hasSignature': _processedContent!.hasSignature,
      'sectionCount': _processedContent!.sections.length,
      'previewText': _processedContent!.previewText,
      'originalLength': _processedContent!.originalContent.length,
      'processedLength': _processedContent!.processedHtml.length,
    };
  }

  /// Programmatically expand/collapse all quotes
  void toggleAllQuotes(bool expand) async {
    await _controller.runJavaScript('''
      (function() {
        const quotes = document.querySelectorAll('.quote-content');
        quotes.forEach(function(quote, index) {
          const isVisible = quote.style.display !== 'none';
          if (${expand ? '!isVisible' : 'isVisible'}) {
            toggleQuote(quote.id);
          }
        });
      })();
    ''');
  }

  /// Scrolls to a specific quote section
  void scrollToQuote(String quoteId) async {
    await _controller.runJavaScript('''
      scrollToQuote('$quoteId');
    ''');
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load email content',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoading = true;
                });
                _loadEmailContent();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Expanded(
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Processing email content...'),
                  ],
                ),
              ),
            ),

        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}