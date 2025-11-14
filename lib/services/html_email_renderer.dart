import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:url_launcher/url_launcher.dart';
import '../utils/quote_processor.dart';
import '../utils/attachment_processor.dart';
import '../models/email_message.dart';
import '../widgets/webview_email_renderer.dart';

class HtmlEmailRenderer {
  static final HtmlEmailRenderer _instance = HtmlEmailRenderer._internal();
  factory HtmlEmailRenderer() => _instance;
  HtmlEmailRenderer._internal();

  /// Renders HTML email content with proper styling and security
  Widget renderEmailContent({
    required String? htmlContent,
    required String? textContent,
    required BuildContext context,
    bool useDarkMode = false,
    List<EmailAttachment>? attachments,
  }) {
    if (htmlContent != null && htmlContent.isNotEmpty) {
      // Use WebView for complex HTML emails (like the AquaFunded example)
      if (_shouldUseWebView(htmlContent)) {
        return ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 200,
            maxHeight: 600,
          ),
          child: WebViewEmailRenderer(
            htmlContent: htmlContent,
            attachments: attachments,
            useDarkMode: useDarkMode,
            onLinkTap: _handleLinkTap,
          ),
        );
      } else {
        return _renderHtml(htmlContent, context, useDarkMode, attachments);
      }
    } else if (textContent != null && textContent.isNotEmpty) {
      return _renderPlainText(textContent, context, useDarkMode);
    } else {
      return _renderEmptyContent(context);
    }
  }

  /// Determines if WebView should be used for complex HTML rendering
  bool _shouldUseWebView(String htmlContent) {
    // Use WebView for emails with:
    // - Complex CSS styling
    // - Images
    // - Tables with complex layouts
    // - Background images/colors
    // - Advanced HTML structure

    final lowerContent = htmlContent.toLowerCase();

    return lowerContent.contains('<style') ||
           lowerContent.contains('background-image') ||
           lowerContent.contains('background-color') ||
           lowerContent.contains('<img') ||
           lowerContent.contains('<table') ||
           lowerContent.contains('css') ||
           lowerContent.contains('font-') ||
           lowerContent.contains('color:') ||
           lowerContent.contains('margin:') ||
           lowerContent.contains('padding:') ||
           lowerContent.contains('text-align') ||
           htmlContent.length > 1000; // Complex emails are usually longer
  }

  /// Renders HTML content using flutter_html with security and styling
  Widget _renderHtml(String htmlContent, BuildContext context, bool useDarkMode, List<EmailAttachment>? attachments) {
    // Process inline attachments
    String processedHtml = AttachmentProcessor.processInlineAttachments(
      htmlContent: htmlContent,
      attachments: attachments,
    );

    final sanitizedHtml = _sanitizeHtml(processedHtml, useDarkMode);

    return Html(
      data: sanitizedHtml,
      style: _getHtmlStyles(context, useDarkMode),
      onLinkTap: (url, _, __) => _handleLinkTap(url),
    );
  }

  /// Renders plain text content with proper formatting and quote processing
  Widget _renderPlainText(String textContent, BuildContext context, bool useDarkMode) {
    // Convert plain text with quote processing to HTML
    final processedHtml = QuoteProcessor.convertTextToHtml(textContent, useDarkMode: useDarkMode);

    return Html(
      data: processedHtml,
      style: _getHtmlStyles(context, useDarkMode),
      onLinkTap: (url, _, __) => _handleLinkTap(url),
    );
  }

  /// Renders empty content placeholder
  Widget _renderEmptyContent(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.email_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No content available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  /// Sanitizes HTML content for security
  String _sanitizeHtml(String htmlContent, bool useDarkMode) {
    final document = html_parser.parse(htmlContent);

    // Remove dangerous elements
    _removeDangerousElements(document);

    // Clean up CSS
    _sanitizeCss(document);

    // Process images
    _processImages(document);

    // Clean up links
    _processLinks(document);

    // Inject dark mode styles if needed
    if (useDarkMode) {
      _injectDarkModeStyles(document);
    }

    return document.outerHtml;
  }

  /// Removes potentially dangerous HTML elements
  void _removeDangerousElements(html_dom.Document document) {
    final dangerousTags = [
      'script',
      'iframe',
      'object',
      'embed',
      'form',
      'input',
      'button',
      'meta',
      'link',
      'base',
    ];

    for (final tag in dangerousTags) {
      document.querySelectorAll(tag).forEach((element) => element.remove());
    }

    // Remove event handlers
    document.querySelectorAll('*').forEach((element) {
      final attributesToRemove = <String>[];
      element.attributes.forEach((name, value) {
        if (name.toString().startsWith('on') || name.toString() == 'javascript:') {
          attributesToRemove.add(name.toString());
        }
      });
      for (final attr in attributesToRemove) {
        element.attributes.remove(attr);
      }
    });
  }

  /// Sanitizes CSS to prevent layout breaking and security issues
  void _sanitizeCss(html_dom.Document document) {
    // Remove style tags
    document.querySelectorAll('style').forEach((element) => element.remove());

    // Clean inline styles
    document.querySelectorAll('*').forEach((element) {
      final style = element.attributes['style'];
      if (style != null) {
        element.attributes['style'] = _cleanInlineStyle(style);
      }
    });
  }

  /// Cleans inline CSS styles
  String _cleanInlineStyle(String style) {
    final dangerousProperties = [
      'position',
      'z-index',
      'overflow',
      'display',
      'visibility',
      'opacity',
      'filter',
      'transform',
      'animation',
      'transition',
      'cursor',
      'pointer-events',
    ];

    String cleanStyle = style;
    for (final property in dangerousProperties) {
      cleanStyle = cleanStyle.replaceAll(RegExp('$property\s*:[^;]*;?', caseSensitive: false), '');
    }

    return cleanStyle;
  }

  /// Processes images for security and loading
  void _processImages(html_dom.Document document) {
    document.querySelectorAll('img').forEach((img) {
      final src = img.attributes['src'];
      if (src != null) {
        // Add loading="lazy" for performance
        img.attributes['loading'] = 'lazy';

        // Set reasonable max dimensions
        if (!img.attributes.containsKey('style')) {
          img.attributes['style'] = 'max-width: 100%; height: auto;';
        } else {
          String style = img.attributes['style'] ?? '';
          if (!style.contains('max-width')) {
            style += ' max-width: 100%;';
          }
          if (!style.contains('height')) {
            style += ' height: auto;';
          }
          img.attributes['style'] = style;
        }
      }
    });
  }

  /// Processes links for security
  void _processLinks(html_dom.Document document) {
    document.querySelectorAll('a').forEach((link) {
      // Add security attributes
      link.attributes['rel'] = 'noopener noreferrer';
      link.attributes['target'] = '_blank';

      // Remove javascript: links
      final href = link.attributes['href'];
      if (href != null && href.toLowerCase().startsWith('javascript:')) {
        link.attributes.remove('href');
      }
    });
  }

  /// Injects dark mode styles into HTML document
  void _injectDarkModeStyles(html_dom.Document document) {
    final head = document.head;
    if (head != null) {
      final styleElement = html_dom.Element.tag('style');
      styleElement.innerHtml = '''
        * {
          background: #121212 !important;
          color: #F3F3F3 !important;
        }
        :link, :link * {
          color: #CCFF33 !important;
        }
        :visited, :visited * {
          color: #BB86FC !important;
        }
      ''';
      head.append(styleElement);
    }
  }

  /// Defines HTML styles for proper email rendering
  Map<String, Style> _getHtmlStyles(BuildContext context, bool useDarkMode) {
    final theme = Theme.of(context);
    final textColor = useDarkMode ? Colors.white70 : theme.colorScheme.onSurface;

    return {
      'html': Style(
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
      ),
      'body': Style(
        margin: Margins.all(16),
        padding: HtmlPaddings.zero,
        fontSize: FontSize(theme.textTheme.bodyLarge?.fontSize ?? 16),
        color: textColor,
        lineHeight: LineHeight.number(1.6),
        fontFamily: theme.textTheme.bodyLarge?.fontFamily,
      ),
      'p': Style(
        margin: Margins.only(bottom: 12),
        lineHeight: LineHeight.number(1.6),
      ),
      'h1, h2, h3, h4, h5, h6': Style(
        margin: Margins.only(top: 16, bottom: 12),
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      'h1': Style(fontSize: FontSize(24)),
      'h2': Style(fontSize: FontSize(20)),
      'h3': Style(fontSize: FontSize(18)),
      'h4': Style(fontSize: FontSize(16)),
      'h5': Style(fontSize: FontSize(14)),
      'h6': Style(fontSize: FontSize(12)),
      'a': Style(
        color: theme.colorScheme.primary,
        textDecoration: TextDecoration.underline,
      ),
      'img': Style(
        width: Width(100, Unit.percent),
        height: Height.auto(),
        margin: Margins.only(top: 8, bottom: 8),
      ),
      'table': Style(
        width: Width(100, Unit.percent),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        margin: Margins.only(top: 12, bottom: 12),
      ),
      'th': Style(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        padding: HtmlPaddings.all(8),
        fontWeight: FontWeight.bold,
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      'td': Style(
        padding: HtmlPaddings.all(8),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      'blockquote': Style(
        margin: Margins.only(left: 16, top: 12, bottom: 12),
        padding: HtmlPaddings.only(left: 16),
        border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 4)),
        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      'ul, ol': Style(
        margin: Margins.only(top: 8, bottom: 8),
        padding: HtmlPaddings.only(left: 20),
      ),
      'li': Style(
        margin: Margins.only(bottom: 4),
      ),
      'code': Style(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        color: theme.colorScheme.onSurface,
        fontFamily: 'monospace',
        padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
      ),
      'pre': Style(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        color: theme.colorScheme.onSurface,
        fontFamily: 'monospace',
        padding: HtmlPaddings.all(12),
        margin: Margins.only(top: 12, bottom: 12),
        whiteSpace: WhiteSpace.pre,
      ),
      'hr': Style(
        margin: Margins.symmetric(vertical: 16),
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
      ),
    };
  }


  /// Handles link taps
  void _handleLinkTap(String? url) async {
    if (url == null || url.isEmpty) return;

    try {
      final uri = Uri.parse(url);
      if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      // Invalid URL, ignore
    }
  }

}