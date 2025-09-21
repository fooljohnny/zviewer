import 'package:flutter/material.dart';

class CommentInput extends StatefulWidget {
  final String? mediaId;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final Function(String content)? onSubmit;
  final VoidCallback? onClearError;

  const CommentInput({
    super.key,
    this.mediaId,
    required this.isAuthenticated,
    required this.isLoading,
    this.error,
    this.onSubmit,
    this.onClearError,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && widget.error != null) {
      widget.onClearError?.call();
    }
  }

  void _submitComment() {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    widget.onSubmit?.call(content);
    
    // Clear the input after submission
    _controller.clear();
    _focusNode.unfocus();
    
    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                margin: const EdgeInsets.only(bottom: 8.0),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[300]!),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.error!,
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onClearError,
                      icon: Icon(Icons.close, color: Colors.red[600], size: 16),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.isAuthenticated && !widget.isLoading,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: widget.isAuthenticated 
                    ? 'Write a comment...'
                    : 'Please log in to comment',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(12.0),
                counterText: '${_controller.text.length}/500',
              ),
              onChanged: (value) {
                setState(() {}); // Update character count
              },
              onSubmitted: widget.isAuthenticated ? (_) => _submitComment() : null,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isAuthenticated 
                      ? 'Share your thoughts with the community'
                      : 'Sign in to join the conversation',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                ElevatedButton(
                  onPressed: widget.isAuthenticated && 
                             !widget.isLoading && 
                             _controller.text.trim().isNotEmpty
                      ? _submitComment
                      : null,
                  child: _isSubmitting || widget.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

