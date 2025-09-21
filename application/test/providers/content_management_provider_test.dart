import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:zviewer/providers/content_management_provider.dart';
import 'package:zviewer/providers/auth_provider.dart';
import 'package:zviewer/services/content_management_service.dart';
import 'package:zviewer/models/content_item.dart';
import 'package:zviewer/models/content_category.dart';
import 'package:zviewer/models/admin_action.dart';

import 'content_management_provider_test.mocks.dart';

@GenerateMocks([ContentManagementService, AuthProvider])
void main() {
  group('ContentManagementProvider', () {
    late ContentManagementProvider provider;
    late MockContentManagementService mockService;
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      mockService = MockContentManagementService();
      mockAuthProvider = MockAuthProvider();
      provider = ContentManagementProvider(
        service: mockService,
        authProvider: mockAuthProvider,
      );
    });

    group('initial state', () {
      test('should have empty initial state', () {
        expect(provider.content, isEmpty);
        expect(provider.categories, isEmpty);
        expect(provider.selectedContentIds, isEmpty);
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
      });
    });

    group('content management', () {
      test('should load content successfully', () async {
        // Mock service response
        final mockResponse = ContentListResponse(
          content: [
            ContentItem(
              id: '1',
              title: 'Test Content',
              description: 'Test Description',
              filePath: '/path/to/file.jpg',
              type: ContentType.image,
              userId: 'user1',
              userName: 'Test User',
              status: ContentStatus.pending,
              categories: ['category1'],
              uploadedAt: DateTime(2024, 1, 1),
              metadata: {'key': 'value'},
            ),
          ],
          total: 1,
          page: 1,
          limit: 20,
          totalPages: 1,
        );

        when(mockService.getContentList(
          page: anyNamed('page'),
          limit: anyNamed('limit'),
          status: anyNamed('status'),
          type: anyNamed('type'),
          search: anyNamed('search'),
          userId: anyNamed('userId'),
          categories: anyNamed('categories'),
          sortBy: anyNamed('sortBy'),
          sortOrder: anyNamed('sortOrder'),
        )).thenAnswer((_) async => mockResponse);

        await provider.loadContent();

        expect(provider.content.length, 1);
        expect(provider.content.first.title, 'Test Content');
        expect(provider.totalContent, 1);
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
      });

      test('should handle content loading errors', () async {
        when(mockService.getContentList(
          page: anyNamed('page'),
          limit: anyNamed('limit'),
          status: anyNamed('status'),
          type: anyNamed('type'),
          search: anyNamed('search'),
          userId: anyNamed('userId'),
          categories: anyNamed('categories'),
          sortBy: anyNamed('sortBy'),
          sortOrder: anyNamed('sortOrder'),
        )).thenThrow(Exception('Network error'));

        await provider.loadContent();

        expect(provider.content, isEmpty);
        expect(provider.isLoading, false);
        expect(provider.error, isNotNull);
      });

      test('should approve content successfully', () async {
        final mockResponse = ContentActionResponse(
          success: true,
          message: 'Content approved successfully',
        );

        when(mockService.approveContent('content1'))
            .thenAnswer((_) async => mockResponse);

        await provider.approveContent('content1');

        verify(mockService.approveContent('content1')).called(1);
      });

      test('should reject content with reason', () async {
        final mockResponse = ContentActionResponse(
          success: true,
          message: 'Content rejected successfully',
        );

        when(mockService.rejectContent('content1', 'Inappropriate content'))
            .thenAnswer((_) async => mockResponse);

        await provider.rejectContent('content1', 'Inappropriate content');

        verify(mockService.rejectContent('content1', 'Inappropriate content')).called(1);
      });

      test('should delete content with reason', () async {
        final mockResponse = ContentActionResponse(
          success: true,
          message: 'Content deleted successfully',
        );

        when(mockService.deleteContent('content1', 'Spam content'))
            .thenAnswer((_) async => mockResponse);

        await provider.deleteContent('content1', 'Spam content');

        verify(mockService.deleteContent('content1', 'Spam content')).called(1);
      });
    });

    group('category management', () {
      test('should load categories successfully', () async {
        final mockCategories = [
          ContentCategory(
            id: '1',
            name: 'Test Category',
            description: 'Test Description',
            color: '#FF0000',
            createdAt: DateTime(2024, 1, 1),
            isActive: true,
          ),
        ];

        when(mockService.getCategories())
            .thenAnswer((_) async => mockCategories);

        await provider.loadCategories();

        expect(provider.categories.length, 1);
        expect(provider.categories.first.name, 'Test Category');
      });

      test('should create category successfully', () async {
        final category = ContentCategory(
          id: '1',
          name: 'New Category',
          description: 'New Description',
          color: '#00FF00',
          createdAt: DateTime(2024, 1, 1),
          isActive: true,
        );

        when(mockService.createCategory(any))
            .thenAnswer((_) async => category);

        await provider.createCategory(category);

        expect(provider.categories.length, 1);
        expect(provider.categories.first.name, 'New Category');
      });

      test('should update category successfully', () async {
        final existingCategory = ContentCategory(
          id: '1',
          name: 'Original Category',
          description: 'Original Description',
          color: '#FF0000',
          createdAt: DateTime(2024, 1, 1),
          isActive: true,
        );

        final updatedCategory = existingCategory.copyWith(
          name: 'Updated Category',
        );

        provider.categories.add(existingCategory);

        when(mockService.updateCategory(any))
            .thenAnswer((_) async => updatedCategory);

        await provider.updateCategory(updatedCategory);

        expect(provider.categories.first.name, 'Updated Category');
      });

      test('should delete category successfully', () async {
        final category = ContentCategory(
          id: '1',
          name: 'Test Category',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: DateTime(2024, 1, 1),
          isActive: true,
        );

        provider.categories.add(category);

        when(mockService.deleteCategory('1'))
            .thenAnswer((_) async => true);

        await provider.deleteCategory('1');

        expect(provider.categories, isEmpty);
      });
    });

    group('filtering and search', () {
      test('should set search query', () {
        provider.setSearch('test query');
        expect(provider.searchQuery, 'test query');
      });

      test('should set status filter', () {
        provider.setStatusFilter(ContentStatus.pending);
        expect(provider.selectedStatus, ContentStatus.pending);
      });

      test('should set type filter', () {
        provider.setTypeFilter(ContentType.image);
        expect(provider.selectedType, ContentType.image);
      });

      test('should set user filter', () {
        provider.setUserFilter('user1');
        expect(provider.userFilter, 'user1');
      });

      test('should set date filters', () {
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);

        provider.setStartDate(startDate);
        provider.setEndDate(endDate);

        expect(provider.startDate, startDate);
        expect(provider.endDate, endDate);
      });

      test('should toggle category filter', () {
        provider.toggleCategoryFilter('category1', true);
        expect(provider.selectedCategories.contains('category1'), true);

        provider.toggleCategoryFilter('category1', false);
        expect(provider.selectedCategories.contains('category1'), false);
      });

      test('should clear all filters', () {
        provider.setSearch('test');
        provider.setStatusFilter(ContentStatus.pending);
        provider.setTypeFilter(ContentType.image);
        provider.toggleCategoryFilter('category1', true);

        provider.clearAllFilters();

        expect(provider.searchQuery, '');
        expect(provider.selectedStatus, isNull);
        expect(provider.selectedType, isNull);
        expect(provider.selectedCategories, isEmpty);
      });
    });

    group('selection management', () {
      test('should toggle content selection', () {
        provider.toggleContentSelection('content1', true);
        expect(provider.selectedContentIds.contains('content1'), true);

        provider.toggleContentSelection('content1', false);
        expect(provider.selectedContentIds.contains('content1'), false);
      });

      test('should clear selection', () {
        provider.toggleContentSelection('content1', true);
        provider.toggleContentSelection('content2', true);

        provider.clearSelection();

        expect(provider.selectedContentIds, isEmpty);
      });
    });

    group('computed properties', () {
      test('should calculate content statistics', () {
        provider.content.addAll([
          ContentItem(
            id: '1',
            title: 'Pending Content',
            description: 'Description',
            filePath: '/path1.jpg',
            type: ContentType.image,
            userId: 'user1',
            userName: 'User 1',
            status: ContentStatus.pending,
            categories: [],
            uploadedAt: DateTime.now(),
            metadata: {},
          ),
          ContentItem(
            id: '2',
            title: 'Approved Content',
            description: 'Description',
            filePath: '/path2.jpg',
            type: ContentType.image,
            userId: 'user2',
            userName: 'User 2',
            status: ContentStatus.approved,
            categories: [],
            uploadedAt: DateTime.now(),
            metadata: {},
          ),
          ContentItem(
            id: '3',
            title: 'Rejected Content',
            description: 'Description',
            filePath: '/path3.jpg',
            type: ContentType.image,
            userId: 'user3',
            userName: 'User 3',
            status: ContentStatus.rejected,
            categories: [],
            uploadedAt: DateTime.now(),
            metadata: {},
          ),
        ]);

        expect(provider.pendingContent, 1);
        expect(provider.approvedContent, 1);
        expect(provider.rejectedContent, 1);
      });
    });

    group('error handling', () {
      test('should clear error', () {
        provider.clearError();
        expect(provider.error, isNull);
      });
    });
  });
}
