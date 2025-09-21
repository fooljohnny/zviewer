import 'package:flutter_test/flutter_test.dart';
import 'package:zviewer/models/content_item.dart';
import 'package:zviewer/models/content_category.dart';
import 'package:zviewer/models/admin_action.dart';

void main() {
  group('ContentItem', () {
    test('should create ContentItem with required fields', () {
      final content = ContentItem(
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
      );

      expect(content.id, '1');
      expect(content.title, 'Test Content');
      expect(content.type, ContentType.image);
      expect(content.status, ContentStatus.pending);
      expect(content.isValid, true);
      expect(content.isPending, true);
      expect(content.isImage, true);
    });

    test('should validate required fields', () {
      final content = ContentItem(
        id: '',
        title: '',
        description: '',
        filePath: '',
        type: ContentType.image,
        userId: '',
        userName: '',
        status: ContentStatus.pending,
        categories: [],
        uploadedAt: DateTime(2024, 1, 1),
        metadata: {},
      );

      expect(content.isValid, false);
    });

    test('should create copy with updated fields', () {
      final original = ContentItem(
        id: '1',
        title: 'Original Title',
        description: 'Original Description',
        filePath: '/path/to/file.jpg',
        type: ContentType.image,
        userId: 'user1',
        userName: 'Test User',
        status: ContentStatus.pending,
        categories: ['category1'],
        uploadedAt: DateTime(2024, 1, 1),
        metadata: {'key': 'value'},
      );

      final updated = original.copyWith(
        title: 'Updated Title',
        status: ContentStatus.approved,
      );

      expect(updated.title, 'Updated Title');
      expect(updated.status, ContentStatus.approved);
      expect(updated.id, original.id);
      expect(updated.description, original.description);
    });

    test('should serialize to JSON', () {
      final content = ContentItem(
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
      );

      final json = content.toJson();
      expect(json['id'], '1');
      expect(json['title'], 'Test Content');
      expect(json['type'], 'image');
      expect(json['status'], 'pending');
    });

    test('should deserialize from JSON', () {
      final json = {
        'id': '1',
        'title': 'Test Content',
        'description': 'Test Description',
        'filePath': '/path/to/file.jpg',
        'type': 'image',
        'userId': 'user1',
        'userName': 'Test User',
        'status': 'pending',
        'categories': ['category1'],
        'uploadedAt': '2024-01-01T00:00:00.000Z',
        'metadata': {'key': 'value'},
      };

      final content = ContentItem.fromJson(json);
      expect(content.id, '1');
      expect(content.title, 'Test Content');
      expect(content.type, ContentType.image);
      expect(content.status, ContentStatus.pending);
    });
  });

  group('ContentCategory', () {
    test('should create ContentCategory with required fields', () {
      final category = ContentCategory(
        id: '1',
        name: 'Test Category',
        description: 'Test Description',
        color: '#FF0000',
        createdAt: DateTime(2024, 1, 1),
        isActive: true,
      );

      expect(category.id, '1');
      expect(category.name, 'Test Category');
      expect(category.isValid, true);
      expect(category.displayColor, '#FF0000');
    });

    test('should validate color format', () {
      final validCategory = ContentCategory(
        id: '1',
        name: 'Test Category',
        description: 'Test Description',
        color: '#FF0000',
        createdAt: DateTime(2024, 1, 1),
        isActive: true,
      );

      final invalidCategory = ContentCategory(
        id: '1',
        name: 'Test Category',
        description: 'Test Description',
        color: 'invalid',
        createdAt: DateTime(2024, 1, 1),
        isActive: true,
      );

      expect(validCategory.isValid, true);
      expect(invalidCategory.isValid, false);
    });

    test('should format display color correctly', () {
      final categoryWithHash = ContentCategory(
        id: '1',
        name: 'Test Category',
        description: 'Test Description',
        color: '#FF0000',
        createdAt: DateTime(2024, 1, 1),
        isActive: true,
      );

      final categoryWithoutHash = ContentCategory(
        id: '1',
        name: 'Test Category',
        description: 'Test Description',
        color: 'FF0000',
        createdAt: DateTime(2024, 1, 1),
        isActive: true,
      );

      expect(categoryWithHash.displayColor, '#FF0000');
      expect(categoryWithoutHash.displayColor, '#FF0000');
    });

    test('should truncate long descriptions', () {
      final longDescription = 'A' * 100;
      final category = ContentCategory(
        id: '1',
        name: 'Test Category',
        description: longDescription,
        color: '#FF0000',
        createdAt: DateTime(2024, 1, 1),
        isActive: true,
      );

      expect(category.shortDescription.length, 50);
      expect(category.shortDescription.endsWith('...'), true);
    });
  });

  group('AdminAction', () {
    test('should create AdminAction with required fields', () {
      final action = AdminAction(
        id: '1',
        adminId: 'admin1',
        actionType: AdminActionType.approve,
        contentId: 'content1',
        timestamp: DateTime(2024, 1, 1),
        metadata: {'key': 'value'},
      );

      expect(action.id, '1');
      expect(action.actionType, AdminActionType.approve);
      expect(action.isValid, true);
      expect(action.actionDisplayName, 'Approved');
      expect(action.requiresReason, false);
    });

    test('should identify actions that require reason', () {
      final rejectAction = AdminAction(
        id: '1',
        adminId: 'admin1',
        actionType: AdminActionType.reject,
        contentId: 'content1',
        timestamp: DateTime(2024, 1, 1),
        metadata: {},
      );

      final deleteAction = AdminAction(
        id: '2',
        adminId: 'admin1',
        actionType: AdminActionType.delete,
        contentId: 'content1',
        timestamp: DateTime(2024, 1, 1),
        metadata: {},
      );

      final approveAction = AdminAction(
        id: '3',
        adminId: 'admin1',
        actionType: AdminActionType.approve,
        contentId: 'content1',
        timestamp: DateTime(2024, 1, 1),
        metadata: {},
      );

      expect(rejectAction.requiresReason, true);
      expect(deleteAction.requiresReason, true);
      expect(approveAction.requiresReason, false);
    });

    test('should create factory methods for common actions', () {
      final approveAction = AdminAction.approve(
        id: '1',
        adminId: 'admin1',
        contentId: 'content1',
      );

      final rejectAction = AdminAction.reject(
        id: '2',
        adminId: 'admin1',
        contentId: 'content1',
        reason: 'Inappropriate content',
      );

      final deleteAction = AdminAction.delete(
        id: '3',
        adminId: 'admin1',
        contentId: 'content1',
        reason: 'Spam content',
      );

      final categorizeAction = AdminAction.categorize(
        id: '4',
        adminId: 'admin1',
        contentId: 'content1',
        categories: ['category1', 'category2'],
      );

      expect(approveAction.actionType, AdminActionType.approve);
      expect(rejectAction.actionType, AdminActionType.reject);
      expect(rejectAction.reason, 'Inappropriate content');
      expect(deleteAction.actionType, AdminActionType.delete);
      expect(categorizeAction.actionType, AdminActionType.categorize);
      expect(categorizeAction.metadata['categories'], ['category1', 'category2']);
    });

    test('should serialize to JSON', () {
      final action = AdminAction(
        id: '1',
        adminId: 'admin1',
        actionType: AdminActionType.approve,
        contentId: 'content1',
        reason: 'Good content',
        timestamp: DateTime(2024, 1, 1),
        metadata: {'key': 'value'},
      );

      final json = action.toJson();
      expect(json['id'], '1');
      expect(json['actionType'], 'approve');
      expect(json['reason'], 'Good content');
    });

    test('should deserialize from JSON', () {
      final json = {
        'id': '1',
        'adminId': 'admin1',
        'actionType': 'approve',
        'contentId': 'content1',
        'reason': 'Good content',
        'timestamp': '2024-01-01T00:00:00.000Z',
        'metadata': {'key': 'value'},
      };

      final action = AdminAction.fromJson(json);
      expect(action.id, '1');
      expect(action.actionType, AdminActionType.approve);
      expect(action.reason, 'Good content');
    });
  });
}
