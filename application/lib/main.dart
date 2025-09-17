import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'widgets/multimedia_viewer/multimedia_viewer.dart';
import 'widgets/auth/auth_screen.dart';

void main() {
  runApp(const ZViewerApp());
}

class ZViewerApp extends StatelessWidget {
  const ZViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
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
        return const MultimediaViewerDemo();
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
              return PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'logout') {
                    await authProvider.logout();
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
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Icon(Icons.account_circle),
                ),
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
