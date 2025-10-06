import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/album_provider.dart';
import '../../models/album.dart';

class AlbumFilters extends StatefulWidget {
  final AlbumProvider provider;

  const AlbumFilters({super.key, required this.provider});

  @override
  State<AlbumFilters> createState() => _AlbumFiltersState();
}

class _AlbumFiltersState extends State<AlbumFilters> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _userController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.provider.searchQuery;
    _userController.text = widget.provider.userFilter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _userController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // First row: Search and User filters
        Row(
          children: [
            // Search field
            Expanded(
              flex: 2,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search albums...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  widget.provider.setSearchQuery(value);
                },
                onSubmitted: (value) {
                  widget.provider.searchAlbums(value);
                },
              ),
            ),
            const SizedBox(width: 16),
            // User filter
            Expanded(
              child: TextField(
                controller: _userController,
                decoration: const InputDecoration(
                  hintText: 'Filter by user...',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  widget.provider.setUserFilter(value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second row: Status, Public filter, and buttons
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            // Status filter
            Consumer<AlbumProvider>(
              builder: (context, provider, child) {
                return DropdownButton<AlbumStatus?>(
                  value: provider.selectedStatus,
                  hint: const Text('All Status'),
                  onChanged: (value) {
                    provider.setStatusFilter(value);
                  },
                  items: const [
                    DropdownMenuItem<AlbumStatus?>(
                      value: null,
                      child: Text('All Status'),
                    ),
                    DropdownMenuItem<AlbumStatus?>(
                      value: AlbumStatus.draft,
                      child: Text('Draft'),
                    ),
                    DropdownMenuItem<AlbumStatus?>(
                      value: AlbumStatus.published,
                      child: Text('Published'),
                    ),
                    DropdownMenuItem<AlbumStatus?>(
                      value: AlbumStatus.archived,
                      child: Text('Archived'),
                    ),
                  ],
                );
              },
            ),
            // Public filter
            Consumer<AlbumProvider>(
              builder: (context, provider, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: provider.publicOnly,
                      onChanged: (value) {
                        provider.setPublicOnly(value ?? false);
                      },
                    ),
                    const Text('Public Only'),
                  ],
                );
              },
            ),
            // Apply filters button
            ElevatedButton(
              onPressed: () {
                widget.provider.applyFilters();
              },
              child: const Text('Apply'),
            ),
            // Clear filters button
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                _userController.clear();
                widget.provider.clearAllFilters();
                widget.provider.applyFilters();
              },
              child: const Text('Clear'),
            ),
          ],
        ),
      ],
    );
  }
}

