import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/search_provider.dart';

/// 搜索建议组件
class SearchSuggestionsWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSuggestionSelected;
  final Function(String) onSearchSubmitted;
  final String hintText;
  final bool showHistory;

  const SearchSuggestionsWidget({
    super.key,
    required this.controller,
    required this.onSuggestionSelected,
    required this.onSearchSubmitted,
    this.hintText = '搜索...',
    this.showHistory = true,
  });

  @override
  State<SearchSuggestionsWidget> createState() => _SearchSuggestionsWidgetState();
}

class _SearchSuggestionsWidgetState extends State<SearchSuggestionsWidget> {
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus;
    });
  }

  void _onTextChanged() {
    final query = widget.controller.text;
    if (query.isNotEmpty) {
      context.read<SearchProvider>().debouncedSuggestions(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 搜索输入框
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      widget.controller.clear();
                      context.read<SearchProvider>().clearSearchResults();
                    },
                  )
                : null,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              widget.onSearchSubmitted(value);
              _focusNode.unfocus();
            }
          },
          onChanged: (value) {
            setState(() {});
          },
        ),
        
        // 搜索建议列表
        if (_showSuggestions && _shouldShowSuggestions())
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildSuggestionsList(),
          ),
      ],
    );
  }

  bool _shouldShowSuggestions() {
    final searchProvider = context.read<SearchProvider>();
    return searchProvider.suggestions.isNotEmpty || 
           (widget.showHistory && searchProvider.searchHistory.isNotEmpty);
  }

  Widget _buildSuggestionsList() {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        if (searchProvider.isLoadingSuggestions) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final suggestions = searchProvider.suggestions;
        final history = widget.showHistory ? searchProvider.searchHistory : <String>[];
        
        if (suggestions.isEmpty && history.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 搜索建议
            if (suggestions.isNotEmpty) ...[
              _buildSectionHeader('搜索建议'),
              ...suggestions.take(5).map((suggestion) => _buildSuggestionItem(
                suggestion,
                Icons.search,
                () => _selectSuggestion(suggestion),
              )),
            ],
            
            // 搜索历史
            if (widget.showHistory && history.isNotEmpty) ...[
              if (suggestions.isNotEmpty) const Divider(height: 1),
              _buildSectionHeader('搜索历史'),
              ...history.take(5).map((historyItem) => _buildSuggestionItem(
                historyItem,
                Icons.history,
                () => _selectSuggestion(historyItem),
                onDelete: () => _removeFromHistory(historyItem),
              )),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const Spacer(),
          if (title == '搜索历史')
            TextButton(
              onPressed: _clearHistory,
              child: const Text('清除'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(
    String text,
    IconData icon,
    VoidCallback onTap, {
    VoidCallback? onDelete,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.close, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _selectSuggestion(String suggestion) {
    widget.controller.text = suggestion;
    widget.onSuggestionSelected(suggestion);
    _focusNode.unfocus();
  }

  void _removeFromHistory(String historyItem) {
    context.read<SearchProvider>().removeFromSearchHistory(historyItem);
  }

  void _clearHistory() {
    context.read<SearchProvider>().clearSearchHistory();
  }
}
