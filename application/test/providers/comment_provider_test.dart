import 'package:flutter_test/flutter_test.dart';
import 'package:zviewer/providers/comment_provider.dart';
import 'package:zviewer/models/comment.dart';
import 'package:zviewer/services/comment_service.dart';

void main() {
  group('CommentProvider', () {
    late CommentProvider commentProvider;
    late MockCommentService mockService;

    setUp(() {
      mockService = MockCommentService();
      commentProvider = CommentProvider(commentService: mockService);
    });

    tearDown(() {
      commentProvider.dispose();
    });

    group('Initial state', () {
      test('should have empty comments list', () {
        expect(commentProvider.comments, isEmpty);
        expect(commentProvider.isLoading, isFalse);
        expect(commentProvider.error, isNull);
        expect(commentProvider.currentMediaId, isNull);
        expect(commentProvider.hasComments, isFalse);
      });
    });

    group('loadComments', () {
      test('should load comments successfully', () async {
        // Arrange
        final mockComments = [
          Comment(
            id: '1',
            content: 'Test comment 1',
            authorId: 'user1',
            authorName: 'User 1',
            mediaId: 'media1',
            createdAt: DateTime(2024, 1, 1),
          ),
          Comment(
            id: '2',
            content: 'Test comment 2',
            authorId: 'user2',
            authorName: 'User 2',
            mediaId: 'media1',
            createdAt: DateTime(2024, 1, 2),
          ),
        ];
        mockService.mockGetComments = mockComments;

        // Act
        await commentProvider.loadComments('media1');

        // Assert
        expect(commentProvider.comments, hasLength(2));
        expect(commentProvider.comments[0].content, equals('Test comment 1'));
        expect(commentProvider.comments[1].content, equals('Test comment 2'));
        expect(commentProvider.currentMediaId, equals('media1'));
        expect(commentProvider.isLoading, isFalse);
        expect(commentProvider.error, isNull);
      });

      test('should handle loading error', () async {
        // Arrange
        mockService.mockGetCommentsError = 'Network error';

        // Act
        await commentProvider.loadComments('media1');

        // Assert
        expect(commentProvider.comments, isEmpty);
        expect(commentProvider.error, equals('Failed to load comments: CommentException: Network error'));
        expect(commentProvider.isLoading, isFalse);
      });
    });

    group('postComment', () {
      test('should post comment successfully', () async {
        // Arrange
        final newComment = Comment(
          id: '3',
          content: 'New comment',
          authorId: 'user3',
          authorName: 'User 3',
          mediaId: 'media1',
          createdAt: DateTime.now(),
        );
        mockService.mockPostComment = newComment;

        // Act
        final result = await commentProvider.postComment('New comment', 'media1');

        // Assert
        expect(result, isTrue);
        expect(commentProvider.comments, hasLength(1));
        expect(commentProvider.comments[0].content, equals('New comment'));
        expect(commentProvider.error, isNull);
      });

      test('should handle empty content', () async {
        // Act
        final result = await commentProvider.postComment('', 'media1');

        // Assert
        expect(result, isFalse);
        expect(commentProvider.error, equals('Comment cannot be empty'));
        expect(commentProvider.comments, isEmpty);
      });

      test('should handle posting error', () async {
        // Arrange
        mockService.mockPostCommentError = 'Posting failed';

        // Act
        final result = await commentProvider.postComment('Test comment', 'media1');

        // Assert
        expect(result, isFalse);
        expect(commentProvider.error, equals('Failed to post comment: CommentException: Posting failed'));
        expect(commentProvider.comments, isEmpty);
      });
    });

    group('clearComments', () {
      test('should clear comments and reset state', () {
        // Arrange
        commentProvider.comments; // Access to trigger loading

        // Act
        commentProvider.clearComments();

        // Assert
        expect(commentProvider.comments, isEmpty);
        expect(commentProvider.currentMediaId, isNull);
        expect(commentProvider.error, isNull);
      });
    });
  });
}

class MockCommentService extends CommentService {
  List<Comment>? mockGetComments;
  String? mockGetCommentsError;
  Comment? mockPostComment;
  String? mockPostCommentError;

  @override
  Future<List<Comment>> getComments(String mediaId) async {
    if (mockGetCommentsError != null) {
      throw CommentException(mockGetCommentsError!);
    }
    return mockGetComments ?? [];
  }

  @override
  Future<Comment> postComment({required String content, required String mediaId}) async {
    if (mockPostCommentError != null) {
      throw CommentException(mockPostCommentError!);
    }
    return mockPostComment ?? Comment(
      id: '1',
      content: content,
      authorId: 'user1',
      authorName: 'User 1',
      mediaId: mediaId,
      createdAt: DateTime.now(),
    );
  }
}
