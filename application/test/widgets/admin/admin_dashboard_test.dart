import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:zviewer/widgets/admin/admin_dashboard.dart';
import 'package:zviewer/providers/auth_provider.dart';
import 'package:zviewer/providers/content_management_provider.dart';
import 'package:zviewer/services/content_management_service.dart';
import 'package:zviewer/models/user.dart';

import 'admin_dashboard_test.mocks.dart';

@GenerateMocks([AuthProvider, ContentManagementProvider, ContentManagementService])
void main() {
  group('AdminDashboard', () {
    late MockAuthProvider mockAuthProvider;
    late MockContentManagementProvider mockContentProvider;
    late MockContentManagementService mockService;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockContentProvider = MockContentManagementProvider();
      mockService = MockContentManagementService();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<ContentManagementProvider>.value(value: mockContentProvider),
          ],
          child: const AdminDashboard(),
        ),
      );
    }

    group('authentication', () {
      testWidgets('should show unauthorized view for non-admin users', (WidgetTester tester) async {
        when(mockAuthProvider.isAuthenticated).thenReturn(true);
        when(mockAuthProvider.isAdmin).thenReturn(false);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Access Denied'), findsOneWidget);
        expect(find.text('You do not have permission to access the admin dashboard.'), findsOneWidget);
        expect(find.byIcon(Icons.lock), findsOneWidget);
      });

      testWidgets('should show unauthorized view for unauthenticated users', (WidgetTester tester) async {
        when(mockAuthProvider.isAuthenticated).thenReturn(false);
        when(mockAuthProvider.isAdmin).thenReturn(false);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Access Denied'), findsOneWidget);
        expect(find.text('You do not have permission to access the admin dashboard.'), findsOneWidget);
      });

      testWidgets('should show admin dashboard for admin users', (WidgetTester tester) async {
        when(mockAuthProvider.isAuthenticated).thenReturn(true);
        when(mockAuthProvider.isAdmin).thenReturn(true);
        when(mockContentProvider.isLoading).thenReturn(false);
        when(mockContentProvider.content).thenReturn([]);
        when(mockContentProvider.categories).thenReturn([]);
        when(mockContentProvider.recentActions).thenReturn([]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Content Management'), findsOneWidget);
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Content'), findsOneWidget);
        expect(find.text('Categories'), findsOneWidget);
      });
    });

    group('navigation', () {
      testWidgets('should navigate between sections', (WidgetTester tester) async {
        when(mockAuthProvider.isAuthenticated).thenReturn(true);
        when(mockAuthProvider.isAdmin).thenReturn(true);
        when(mockContentProvider.isLoading).thenReturn(false);
        when(mockContentProvider.content).thenReturn([]);
        when(mockContentProvider.categories).thenReturn([]);
        when(mockContentProvider.recentActions).thenReturn([]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Test navigation to Content section
        await tester.tap(find.text('Content'));
        await tester.pumpAndSettle();

        // Test navigation to Categories section
        await tester.tap(find.text('Categories'));
        await tester.pumpAndSettle();

        // Test navigation back to Dashboard
        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle();
      });
    });

    group('statistics', () {
      testWidgets('should display content statistics', (WidgetTester tester) async {
        when(mockAuthProvider.isAuthenticated).thenReturn(true);
        when(mockAuthProvider.isAdmin).thenReturn(true);
        when(mockContentProvider.isLoading).thenReturn(false);
        when(mockContentProvider.content).thenReturn([]);
        when(mockContentProvider.categories).thenReturn([]);
        when(mockContentProvider.recentActions).thenReturn([]);
        when(mockContentProvider.totalContent).thenReturn(10);
        when(mockContentProvider.pendingContent).thenReturn(3);
        when(mockContentProvider.approvedContent).thenReturn(5);
        when(mockContentProvider.rejectedContent).thenReturn(2);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('10'), findsOneWidget); // Total content
        expect(find.text('3'), findsOneWidget);  // Pending content
        expect(find.text('5'), findsOneWidget);  // Approved content
        expect(find.text('2'), findsOneWidget);  // Rejected content
      });
    });

    group('recent activity', () {
      testWidgets('should display recent activity when available', (WidgetTester tester) async {
        when(mockAuthProvider.isAuthenticated).thenReturn(true);
        when(mockAuthProvider.isAdmin).thenReturn(true);
        when(mockContentProvider.isLoading).thenReturn(false);
        when(mockContentProvider.content).thenReturn([]);
        when(mockContentProvider.categories).thenReturn([]);
        when(mockContentProvider.recentActions).thenReturn([]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Recent Activity'), findsOneWidget);
        expect(find.text('No recent activity'), findsOneWidget);
      });
    });

    group('loading states', () {
      testWidgets('should show loading indicator when loading', (WidgetTester tester) async {
        when(mockAuthProvider.isAuthenticated).thenReturn(true);
        when(mockAuthProvider.isAdmin).thenReturn(true);
        when(mockContentProvider.isLoading).thenReturn(true);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('refresh functionality', () {
      testWidgets('should refresh data when refresh button is tapped', (WidgetTester tester) async {
        when(mockAuthProvider.isAuthenticated).thenReturn(true);
        when(mockAuthProvider.isAdmin).thenReturn(true);
        when(mockContentProvider.isLoading).thenReturn(false);
        when(mockContentProvider.content).thenReturn([]);
        when(mockContentProvider.categories).thenReturn([]);
        when(mockContentProvider.recentActions).thenReturn([]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap refresh button
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pumpAndSettle();

        // Verify that loadContent and loadCategories were called
        verify(mockContentProvider.loadContent()).called(1);
        verify(mockContentProvider.loadCategories()).called(1);
      });
    });

    group('logout functionality', () {
      testWidgets('should logout when logout is selected from menu', (WidgetTester tester) async {
        when(mockAuthProvider.isAuthenticated).thenReturn(true);
        when(mockAuthProvider.isAdmin).thenReturn(true);
        when(mockContentProvider.isLoading).thenReturn(false);
        when(mockContentProvider.content).thenReturn([]);
        when(mockContentProvider.categories).thenReturn([]);
        when(mockContentProvider.recentActions).thenReturn([]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap menu button
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        // Tap logout
        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();

        verify(mockAuthProvider.logout()).called(1);
      });
    });
  });
}
