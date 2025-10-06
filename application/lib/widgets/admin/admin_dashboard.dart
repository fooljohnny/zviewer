import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/content_management_provider.dart';
import '../../providers/album_provider.dart';
import 'content_list.dart';
import 'category_management.dart';
import 'album_management.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadInitialData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final contentProvider = context.read<ContentManagementProvider>();
    final albumProvider = context.read<AlbumProvider>();
    await contentProvider.loadContent(refresh: true);
    await contentProvider.loadCategories();
    await albumProvider.loadAlbums(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ContentManagementProvider>(
      builder: (context, authProvider, contentProvider, child) {
        // Check if user is admin
        if (!authProvider.isAuthenticated || !authProvider.isAdmin) {
          return const _UnauthorizedView();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Content Management'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _loadInitialData(),
                tooltip: 'Refresh Data',
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'logout':
                      authProvider.logout();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Row(
            children: [
              // Sidebar Navigation
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Dashboard'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.photo_library),
                    selectedIcon: Icon(Icons.photo_library),
                    label: Text('Content'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.photo_album),
                    selectedIcon: Icon(Icons.photo_album),
                    label: Text('Albums'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.category),
                    selectedIcon: Icon(Icons.category),
                    label: Text('Categories'),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),
              // Main Content Area
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  children: [
                    _DashboardOverview(provider: contentProvider),
                    const ContentManagementView(),
                    const AlbumManagementView(),
                    const CategoryManagementView(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardOverview extends StatelessWidget {
  final ContentManagementProvider provider;

  const _DashboardOverview({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Content Management Overview',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          // Statistics Cards
          _buildStatisticsCards(context),
          const SizedBox(height: 24),
          // Recent Activity
          Expanded(
            child: _buildRecentActivity(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(BuildContext context) {
    return Consumer<ContentManagementProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Content',
                value: provider.totalContent.toString(),
                icon: Icons.photo_library,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Pending Review',
                value: provider.pendingContent.toString(),
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Approved',
                value: provider.approvedContent.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Rejected',
                value: provider.rejectedContent.toString(),
                icon: Icons.cancel,
                color: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<ContentManagementProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.recentActions.isEmpty) {
                    return const Center(
                      child: Text('No recent activity'),
                    );
                  }

                  return ListView.builder(
                    itemCount: provider.recentActions.length,
                    itemBuilder: (context, index) {
                      final action = provider.recentActions[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getActionColor(action.actionType),
                          child: Icon(
                            _getActionIcon(action.actionType),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(action.actionDisplayName),
                        subtitle: Text(
                          'Content ID: ${action.contentId}',
                        ),
                        trailing: Text(
                          _formatTimestamp(action.timestamp),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getActionColor(dynamic actionType) {
    switch (actionType.toString()) {
      case 'AdminActionType.approve':
        return Colors.green;
      case 'AdminActionType.reject':
        return Colors.red;
      case 'AdminActionType.delete':
        return Colors.red.shade800;
      case 'AdminActionType.categorize':
        return Colors.blue;
      case 'AdminActionType.flag':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(dynamic actionType) {
    switch (actionType.toString()) {
      case 'AdminActionType.approve':
        return Icons.check;
      case 'AdminActionType.reject':
        return Icons.close;
      case 'AdminActionType.delete':
        return Icons.delete;
      case 'AdminActionType.categorize':
        return Icons.category;
      case 'AdminActionType.flag':
        return Icons.flag;
      default:
        return Icons.info;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnauthorizedView extends StatelessWidget {
  const _UnauthorizedView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Access Denied',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'You do not have permission to access the admin dashboard.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
