import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/comment_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/content_management_provider.dart';
import 'providers/danmaku_provider.dart';
import 'services/content_management_service.dart';
import 'widgets/multimedia_viewer/multimedia_viewer.dart';
import 'widgets/navigation/main_navigation.dart';
import 'widgets/gallery/main_gallery_page.dart';
import 'widgets/gallery/gallery_with_drawer.dart';
import 'widgets/gallery/responsive_demo_page.dart';
import 'widgets/gallery/layout_test_tool.dart';
import 'widgets/auth/auth_screen.dart';
import 'widgets/payments/payment_screen.dart';
import 'widgets/admin/admin_dashboard.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize configuration
  await AppConfig.initialize();
  
  // Print configuration for debugging
  AppConfig.printConfig();
  
  runApp(const ZViewerApp());
}

class ZViewerApp extends StatelessWidget {
  const ZViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => CommentProvider()),
        ChangeNotifierProvider(create: (context) => PaymentProvider()),
        ChangeNotifierProvider(create: (context) => DanmakuProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ContentManagementProvider>(
          create: (context) => ContentManagementProvider(
            service: ContentManagementService(
              authToken: context.read<AuthProvider>().user?.id,
            ),
            authProvider: context.read<AuthProvider>(),
          ),
          update: (context, authProvider, previous) => previous ?? ContentManagementProvider(
            service: ContentManagementService(
              authToken: authProvider.user?.id,
            ),
            authProvider: authProvider,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'ZViewer',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize authentication state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while initializing
        if (!authProvider.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show auth screen if not authenticated
        if (!authProvider.isAuthenticated) {
          return const AuthScreen();
        }

                // Show main app if authenticated
                return const GalleryWithDrawer();
      },
    );
  }
}

class MultimediaViewerDemo extends StatefulWidget {
  const MultimediaViewerDemo({super.key});

  @override
  State<MultimediaViewerDemo> createState() => _MultimediaViewerDemoState();
}

class _MultimediaViewerDemoState extends State<MultimediaViewerDemo> {
  final List<String> _mediaFiles = [
    'assets/sample_image.jpg',
    'assets/sample_video.mp4',
  ];
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZViewer - Multimedia Viewer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.payment),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PaymentScreen(),
                        ),
                      );
                    },
                    tooltip: 'Payments',
                  ),
                  if (authProvider.isAdmin)
                    IconButton(
                      icon: const Icon(Icons.admin_panel_settings),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AdminDashboard(),
                          ),
                        );
                      },
                      tooltip: 'Admin Dashboard',
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'admin') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AdminDashboard(),
                          ),
                        );
                      } else if (value == 'logout') {
                        await authProvider.logout();
                      }
                    },
                    itemBuilder: (context) => [
                      if (authProvider.isAdmin)
                        const PopupMenuItem(
                          value: 'admin',
                          child: Row(
                            children: [
                              Icon(Icons.admin_panel_settings),
                              SizedBox(width: 8),
                              Text('Admin Dashboard'),
                            ],
                          ),
                        ),
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
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Icon(Icons.account_circle),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Center(
        child: _mediaFiles.isNotEmpty
            ? MultimediaViewer(
                mediaPath: _mediaFiles[_currentIndex],
                onPrevious: _currentIndex > 0 ? () {
                  setState(() {
                    _currentIndex--;
                  });
                } : null,
                onNext: _currentIndex < _mediaFiles.length - 1 ? () {
                  setState(() {
                    _currentIndex++;
                  });
                } : null,
              )
            : const Text('No media files available'),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_currentIndex > 0)
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  _currentIndex--;
                });
              },
              child: const Icon(Icons.arrow_back),
            ),
          if (_currentIndex < _mediaFiles.length - 1)
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  _currentIndex++;
                });
              },
              child: const Icon(Icons.arrow_forward),
            ),
        ],
      ),
    );
  }
}
