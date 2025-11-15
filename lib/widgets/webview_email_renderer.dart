import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import '../models/email_message.dart';
import '../utils/attachment_processor.dart';

/// WebView-based email renderer similar to Thunderbird's MessageWebView
class WebViewEmailRenderer extends StatefulWidget {
  final String? htmlContent;
  final String? textContent;
  final List<EmailAttachment>? attachments;
  final bool useDarkMode;
  final Function(String)? onLinkTap;

  const WebViewEmailRenderer({
    super.key,
    this.htmlContent,
    this.textContent,
    this.attachments,
    this.useDarkMode = false,
    this.onLinkTap,
  });

  @override
  State<WebViewEmailRenderer> createState() => _WebViewEmailRendererState();
}

class _WebViewEmailRendererState extends State<WebViewEmailRenderer> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Enable for scrolling support
      ..setUserAgent('QMail/1.0 (Flutter Email Client)')
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
            // Inject JavaScript to get content height for auto-sizing
            _updateWebViewHeight();
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

  void _updateWebViewHeight() async {
    try {
      // Enable natural scrolling without height constraints
      await _controller.runJavaScript('''
        (function() {
          // Remove any height constraints
          document.body.style.height = 'auto';
          document.body.style.minHeight = 'auto';
          document.body.style.maxHeight = 'none';
          document.body.style.overflow = 'visible';

          document.documentElement.style.height = 'auto';
          document.documentElement.style.minHeight = 'auto';
          document.documentElement.style.maxHeight = 'none';
          document.documentElement.style.overflow = 'visible';

          // Ensure content flows naturally
          var allElements = document.querySelectorAll('*');
          for (var i = 0; i < allElements.length; i++) {
            var element = allElements[i];
            if (element.style.height === '100%' || element.style.height === '100vh') {
              element.style.height = 'auto';
            }
            if (element.style.minHeight === '100%' || element.style.minHeight === '100vh') {
              element.style.minHeight = 'auto';
            }
          }

          return true;
        })();
      ''');

      debugPrint('WebView natural scrolling enabled');
    } catch (e) {
      debugPrint('Error enabling WebView scrolling: $e');
    }
  }

  void _loadEmailContent() {
    final htmlContent = _prepareHtmlContent();
    final dataUri = 'data:text/html;charset=utf-8,${Uri.encodeComponent(htmlContent)}';
    _controller.loadRequest(Uri.parse(dataUri));
  }

  String _prepareHtmlContent() {
    String content;

    if (widget.htmlContent != null && widget.htmlContent!.isNotEmpty) {
      content = widget.htmlContent!;
    } else if (widget.textContent != null && widget.textContent!.isNotEmpty) {
      // Convert plain text to HTML
      content = _convertTextToHtml(widget.textContent!);
    } else {
      content = '<p>No content available</p>';
    }

    // Process inline attachments
    if (widget.attachments != null && widget.attachments!.isNotEmpty) {
      content = AttachmentProcessor.processInlineAttachments(
        htmlContent: content,
        attachments: widget.attachments,
      );
    }

    // Sanitize and enhance HTML
    return _sanitizeAndEnhanceHtml(content);
  }

  String _convertTextToHtml(String textContent) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
  <pre style="white-space: pre-wrap; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size: 14px; line-height: 1.6;">${_escapeHtml(textContent)}</pre>
</body>
</html>
''';
  }

  String _sanitizeAndEnhanceHtml(String htmlContent) {
    try {
      final document = html_parser.parse(htmlContent);

      // Remove dangerous elements
      _removeDangerousElements(document);

      // Ensure we have proper HTML structure
      _ensureProperStructure(document);

      // Add responsive meta tag if missing
      _addViewportMeta(document);

      // Add custom CSS for email rendering
      _addCustomCSS(document);

      // Process images for better display
      _processImages(document);

      // Clean up links
      _processLinks(document);

      return document.outerHtml;
    } catch (e) {
      // Fallback for malformed HTML
      return _createFallbackHtml(htmlContent);
    }
  }

  void _removeDangerousElements(html_dom.Document document) {
    final dangerousTags = [
      'script',
      'iframe',
      'object',
      'embed',
      'form',
      'input',
      'button',
      'base',
    ];

    for (final tag in dangerousTags) {
      document.querySelectorAll(tag).forEach((element) => element.remove());
    }

    // Remove event handlers
    document.querySelectorAll('*').forEach((element) {
      final attributesToRemove = <String>[];
      element.attributes.forEach((name, value) {
        if (name.toString().startsWith('on')) {
          attributesToRemove.add(name.toString());
        }
      });
      for (final attr in attributesToRemove) {
        element.attributes.remove(attr);
      }
    });
  }

  void _ensureProperStructure(html_dom.Document document) {
    // Ensure we have html, head, and body elements
    if (document.documentElement == null) {
      document.append(html_dom.Element.tag('html'));
    }

    if (document.head == null) {
      document.documentElement!.insertBefore(
        html_dom.Element.tag('head'),
        document.body,
      );
    }

    if (document.body == null) {
      document.documentElement!.append(html_dom.Element.tag('body'));
    }
  }

  void _addViewportMeta(html_dom.Document document) {
    final head = document.head!;

    // Check if viewport meta already exists
    final existingViewport = head.querySelector('meta[name="viewport"]');
    if (existingViewport == null) {
      final viewportMeta = html_dom.Element.tag('meta');
      viewportMeta.attributes['name'] = 'viewport';
      viewportMeta.attributes['content'] = 'width=device-width, initial-scale=1.0';
      head.append(viewportMeta);
    }

    // Add charset meta if missing
    final existingCharset = head.querySelector('meta[charset]');
    if (existingCharset == null) {
      final charsetMeta = html_dom.Element.tag('meta');
      charsetMeta.attributes['charset'] = 'UTF-8';
      head.append(charsetMeta);
    }
  }

  void _addCustomCSS(html_dom.Document document) {
    final head = document.head!;
    final styleElement = html_dom.Element.tag('style');

    String css = '''
      /* QMail Email Renderer Styles */
      html, body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
        font-size: 14px;
        line-height: 1.6;
        margin: 16px;
        padding: 0;
        word-wrap: break-word;
        height: auto !important;
        min-height: auto !important;
        max-height: none !important;
        overflow: visible !important;
        -webkit-overflow-scrolling: touch;
        box-sizing: border-box;
      }

      /* Image handling */
      img {
        max-width: 100% !important;
        height: auto !important;
        display: block;
      }

      /* Table responsiveness */
      table {
        width: 100% !important;
        max-width: 100% !important;
        border-collapse: collapse;
      }

      td, th {
        padding: 8px;
        vertical-align: top;
      }

      /* Link styling */
      a {
        color: #007AFF;
        text-decoration: none;
      }

      a:hover {
        text-decoration: underline;
      }

      /* Responsive design */
      @media (max-width: 600px) {
        body {
          margin: 8px !important;
        }

        table, tbody, tr, td {
          display: block !important;
          width: 100% !important;
        }
      }

      /* Typography improvements */
      h1, h2, h3, h4, h5, h6 {
        margin: 16px 0 8px 0;
        line-height: 1.3;
      }

      p {
        margin: 0 0 12px 0;
      }

      /* Code and preformatted text */
      code, pre {
        font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;
        background-color: #f5f5f5;
        padding: 2px 4px;
        border-radius: 3px;
      }

      pre {
        padding: 12px;
        overflow-x: auto;
        white-space: pre-wrap;
      }

      /* Blockquote styling */
      blockquote {
        margin: 16px 0;
        padding: 8px 16px;
        border-left: 4px solid #007AFF;
        background-color: #f8f9fa;
        font-style: italic;
      }

      /* List improvements */
      ul, ol {
        padding-left: 20px;
      }

      li {
        margin-bottom: 4px;
      }
    ''';

    // Don't apply dark mode overrides for WebView rendering
    // This preserves the original email styling like Thunderbird does

    styleElement.text = css;
    head.append(styleElement);
  }

  void _processImages(html_dom.Document document) {
    document.querySelectorAll('img').forEach((img) {
      // Add responsive attributes
      img.attributes['style'] = '${img.attributes['style'] ?? ''} max-width: 100%; height: auto;';

      // Add loading optimization
      img.attributes['loading'] = 'lazy';

      // Handle missing src gracefully
      final src = img.attributes['src'];
      if (src == null || src.isEmpty) {
        img.attributes['alt'] = img.attributes['alt'] ?? 'Image';
      }
    });
  }

  void _processLinks(html_dom.Document document) {
    document.querySelectorAll('a').forEach((link) {
      // Add security attributes
      link.attributes['rel'] = 'noopener noreferrer';

      // Remove javascript: links
      final href = link.attributes['href'];
      if (href != null && href.toLowerCase().startsWith('javascript:')) {
        link.attributes.remove('href');
      }
    });
  }

  String _createFallbackHtml(String content) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      font-size: 14px;
      line-height: 1.6;
      margin: 16px;
      padding: 0;
      ${widget.useDarkMode ? 'background-color: #1c1c1e; color: #ffffff;' : ''}
    }
  </style>
</head>
<body>
  ${_escapeHtml(content)}
</body>
</html>
''';
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
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
          ],
        ),
      );
    }

    return Expanded(
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}