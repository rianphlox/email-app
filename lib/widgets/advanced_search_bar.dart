import 'package:flutter/material.dart';
import '../services/advanced_search_service.dart';
import '../models/email_message.dart';

/// Enhanced search bar with Gmail-style advanced operators
class AdvancedSearchBar extends StatefulWidget {
  final Function(String query) onSearch;
  final Function() onClear;
  final List<EmailMessage> emails;
  final String? initialQuery;

  const AdvancedSearchBar({
    super.key,
    required this.onSearch,
    required this.onClear,
    required this.emails,
    this.initialQuery,
  });

  @override
  State<AdvancedSearchBar> createState() => _AdvancedSearchBarState();
}

class _AdvancedSearchBarState extends State<AdvancedSearchBar> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final query = _controller.text;

    if (query.isNotEmpty) {
      setState(() {
        _suggestions = AdvancedSearchService.getSearchSuggestions(
          widget.emails,
          query,
        );
      });
      _showSuggestionsOverlay();
    } else {
      _hideSuggestions();
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      if (_controller.text.isNotEmpty) {
        _showSuggestionsOverlay();
      } else {
        _showQuickFilters();
      }
    } else {
      _hideSuggestions();
    }
  }

  void _showSuggestionsOverlay() {
    _removeOverlay();

    if (_suggestions.isEmpty) return;

    _overlayEntry = _createSuggestionsOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _showSuggestions = true);
  }

  void _showQuickFilters() {
    _removeOverlay();

    final quickFilters = [
      'is:unread',
      'is:important',
      'has:attachment',
      'in:inbox',
      'from:',
      'subject:',
    ];

    setState(() => _suggestions = quickFilters);
    _overlayEntry = _createSuggestionsOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _showSuggestions = true);
  }

  void _hideSuggestions() {
    _removeOverlay();
    setState(() => _showSuggestions = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createSuggestionsOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_controller.text.isEmpty) ...[
                  // Quick filters header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Quick Filters',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _showAdvancedSearchDialog(),
                          child: Text(
                            'Advanced',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          _getIconForSuggestion(suggestion),
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          suggestion,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: _getDescriptionForSuggestion(suggestion),
                        onTap: () => _applySuggestion(suggestion),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForSuggestion(String suggestion) {
    if (suggestion.startsWith('from:')) return Icons.person;
    if (suggestion.startsWith('to:')) return Icons.send;
    if (suggestion.startsWith('subject:')) return Icons.subject;
    if (suggestion.startsWith('has:')) return Icons.attach_file;
    if (suggestion.startsWith('is:unread')) return Icons.mark_as_unread;
    if (suggestion.startsWith('is:read')) return Icons.mark_chat_read;
    if (suggestion.startsWith('is:important')) return Icons.priority_high;
    if (suggestion.startsWith('in:')) return Icons.folder;
    return Icons.search;
  }

  Widget? _getDescriptionForSuggestion(String suggestion) {
    String? description;

    if (suggestion == 'is:unread') {
      description = 'Show unread emails';
    } else if (suggestion == 'is:important') {
      description = 'Show important emails';
    } else if (suggestion == 'has:attachment') {
      description = 'Show emails with attachments';
    } else if (suggestion == 'in:inbox') {
      description = 'Search in inbox';
    } else if (suggestion == 'from:') {
      description = 'Search by sender';
    } else if (suggestion == 'subject:') {
      description = 'Search by subject';
    }

    return description != null
        ? Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          )
        : null;
  }

  void _applySuggestion(String suggestion) {
    if (suggestion.endsWith(':')) {
      // For operators that need values, position cursor after the colon
      _controller.text = suggestion;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: suggestion.length),
      );
    } else {
      // For complete suggestions, trigger search
      _controller.text = suggestion;
      widget.onSearch(suggestion);
      _hideSuggestions();
      _focusNode.unfocus();
    }
  }

  void _showAdvancedSearchDialog() {
    _hideSuggestions();
    showDialog(
      context: context,
      builder: (context) => AdvancedSearchDialog(
        onSearch: (query) {
          _controller.text = query;
          widget.onSearch(query);
          Navigator.of(context).pop();
        },
        emails: widget.emails,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _focusNode.hasFocus
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: _focusNode.hasFocus ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Search icon
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              Icons.search,
              color: _focusNode.hasFocus
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
          ),

          // Search input
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Search emails (try: from:, is:unread, has:attachment)',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
              style: const TextStyle(fontSize: 14),
              onSubmitted: (query) {
                widget.onSearch(query);
                _hideSuggestions();
              },
            ),
          ),

          // Clear button
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                size: 20,
              ),
              onPressed: () {
                _controller.clear();
                widget.onClear();
                _hideSuggestions();
              },
            ),

          // Advanced search button
          IconButton(
            icon: Icon(
              Icons.tune,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            onPressed: _showAdvancedSearchDialog,
            tooltip: 'Advanced search',
          ),
        ],
      ),
    );
  }
}

/// Advanced search dialog with form fields for complex queries
class AdvancedSearchDialog extends StatefulWidget {
  final Function(String query) onSearch;
  final List<EmailMessage> emails;

  const AdvancedSearchDialog({
    super.key,
    required this.onSearch,
    required this.emails,
  });

  @override
  State<AdvancedSearchDialog> createState() => _AdvancedSearchDialogState();
}

class _AdvancedSearchDialogState extends State<AdvancedSearchDialog> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _wordsController = TextEditingController();
  final _excludeController = TextEditingController();

  bool _hasAttachment = false;
  bool _isUnread = false;
  bool _isImportant = false;
  EmailFolder? _selectedFolder;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _subjectController.dispose();
    _wordsController.dispose();
    _excludeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Advanced Search'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _fromController,
                decoration: const InputDecoration(
                  labelText: 'From',
                  hintText: 'sender@example.com',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _toController,
                decoration: const InputDecoration(
                  labelText: 'To',
                  hintText: 'recipient@example.com',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  hintText: 'Email subject keywords',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _wordsController,
                decoration: const InputDecoration(
                  labelText: 'Has the words',
                  hintText: 'Search terms',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _excludeController,
                decoration: const InputDecoration(
                  labelText: "Doesn't have",
                  hintText: 'Exclude these words',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Folder selection
              DropdownButtonFormField<EmailFolder>(
                initialValue: _selectedFolder,
                decoration: const InputDecoration(
                  labelText: 'Folder',
                  border: OutlineInputBorder(),
                ),
                items: EmailFolder.values.map((folder) {
                  return DropdownMenuItem(
                    value: folder,
                    child: Text(folder.toString().split('.').last.toUpperCase()),
                  );
                }).toList(),
                onChanged: (folder) => setState(() => _selectedFolder = folder),
              ),
              const SizedBox(height: 16),

              // Checkboxes
              CheckboxListTile(
                title: const Text('Has attachment'),
                value: _hasAttachment,
                onChanged: (value) => setState(() => _hasAttachment = value ?? false),
              ),

              CheckboxListTile(
                title: const Text('Is unread'),
                value: _isUnread,
                onChanged: (value) => setState(() => _isUnread = value ?? false),
              ),

              CheckboxListTile(
                title: const Text('Is important'),
                value: _isImportant,
                onChanged: (value) => setState(() => _isImportant = value ?? false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _buildQuery,
          child: const Text('Search'),
        ),
      ],
    );
  }

  void _buildQuery() {
    final parts = <String>[];

    if (_fromController.text.isNotEmpty) {
      parts.add('from:${_fromController.text}');
    }
    if (_toController.text.isNotEmpty) {
      parts.add('to:${_toController.text}');
    }
    if (_subjectController.text.isNotEmpty) {
      parts.add('subject:${_subjectController.text}');
    }
    if (_wordsController.text.isNotEmpty) {
      parts.add(_wordsController.text);
    }
    if (_excludeController.text.isNotEmpty) {
      final excludeWords = _excludeController.text.split(' ');
      parts.addAll(excludeWords.map((word) => '-$word'));
    }

    if (_selectedFolder != null) {
      parts.add('in:${_selectedFolder.toString().split('.').last}');
    }
    if (_hasAttachment) {
      parts.add('has:attachment');
    }
    if (_isUnread) {
      parts.add('is:unread');
    }
    if (_isImportant) {
      parts.add('is:important');
    }

    final query = parts.join(' ');
    widget.onSearch(query);
  }
}