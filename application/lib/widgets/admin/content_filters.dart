import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/content_management_provider.dart';
import '../../models/content_item.dart';

class ContentFilters extends StatefulWidget {
  const ContentFilters({super.key});

  @override
  State<ContentFilters> createState() => _ContentFiltersState();
}

class _ContentFiltersState extends State<ContentFilters> {
  final TextEditingController _searchController = TextEditingController();
  bool _isExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContentManagementProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search content...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                provider.setSearch(value);
              },
            ),
            const SizedBox(height: 16),
            // Filter controls
            Row(
              children: [
                Text(
                  'Filters:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 16),
                // Status filter
                _FilterChip(
                  label: 'All',
                  isSelected: provider.selectedStatus == null,
                  onSelected: () => provider.setStatusFilter(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pending',
                  isSelected: provider.selectedStatus == ContentStatus.pending,
                  onSelected: () => provider.setStatusFilter(ContentStatus.pending),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Approved',
                  isSelected: provider.selectedStatus == ContentStatus.approved,
                  onSelected: () => provider.setStatusFilter(ContentStatus.approved),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Rejected',
                  isSelected: provider.selectedStatus == ContentStatus.rejected,
                  onSelected: () => provider.setStatusFilter(ContentStatus.rejected),
                ),
                const Spacer(),
                // Advanced filters toggle
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  label: const Text('Advanced'),
                ),
              ],
            ),
            // Advanced filters
            if (_isExpanded) ...[
              const SizedBox(height: 16),
              _buildAdvancedFilters(context, provider),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAdvancedFilters(BuildContext context, ContentManagementProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Filters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Type filter
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Content Type',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ContentType?>(
                        initialValue: provider.selectedType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem<ContentType?>(
                            value: null,
                            child: Text('All Types'),
                          ),
                          DropdownMenuItem<ContentType?>(
                            value: ContentType.image,
                            child: Text('Images'),
                          ),
                          DropdownMenuItem<ContentType?>(
                            value: ContentType.video,
                            child: Text('Videos'),
                          ),
                        ],
                        onChanged: (value) => provider.setTypeFilter(value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // User filter
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Filter by user...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) => provider.setUserFilter(value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Date range filter
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date Range',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'From',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              readOnly: true,
                              onTap: () => _selectDate(
                                context,
                                provider,
                                isStartDate: true,
                              ),
                              controller: TextEditingController(
                                text: provider.startDate != null
                                    ? _formatDate(provider.startDate!)
                                    : '',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('to'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'To',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              readOnly: true,
                              onTap: () => _selectDate(
                                context,
                                provider,
                                isStartDate: false,
                              ),
                              controller: TextEditingController(
                                text: provider.endDate != null
                                    ? _formatDate(provider.endDate!)
                                    : '',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Category filter
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categories',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (provider.categories.isNotEmpty)
                      ...provider.categories.map((category) {
                        final isSelected = provider.selectedCategories.contains(category.id);
                        return FilterChip(
                          label: Text(category.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            provider.toggleCategoryFilter(category.id, selected);
                          },
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                              : null,
                        );
                      })
                    else
                      const Text('No categories available'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Clear filters button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => provider.clearAllFilters(),
                  child: const Text('Clear All Filters'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => provider.applyFilters(),
                  child: const Text('Apply Filters'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    ContentManagementProvider provider, {
    required bool isStartDate,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (provider.startDate ?? DateTime.now())
          : (provider.endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      if (isStartDate) {
        provider.setStartDate(picked);
      } else {
        provider.setEndDate(picked);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: isSelected
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : null,
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
    );
  }
}
