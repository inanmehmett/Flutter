import 'package:flutter/material.dart';
import 'dart:async';

class VocabularySearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const VocabularySearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<VocabularySearchBar> createState() => _VocabularySearchBarState();
}

class _VocabularySearchBarState extends State<VocabularySearchBar> {
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final isSearching = widget.controller.text.isNotEmpty;
    if (isSearching != _isSearching) {
      setState(() {
        _isSearching = isSearching;
      });
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      widget.onChanged(widget.controller.text.trim());
    });
  }

  void _clearSearch() {
    widget.controller.clear();
    _debounce?.cancel();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: 'Kelime ara...',
          hintStyle: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
