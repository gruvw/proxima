import "dart:async";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:proxima/models/database/comment/comment_data.dart";
import "package:proxima/models/database/post/post_id_firestore.dart";
import "package:proxima/models/ui/validation/new_comment_validation.dart";
import "package:proxima/services/database/comment/comment_repository_service.dart";
import "package:proxima/viewmodels/login_view_model.dart";

/// The view model for adding a new comment to a post whose
/// post id [PostIdFirestore] is provided as an argument.
class NewCommentViewModel
    extends FamilyAsyncNotifier<NewCommentValidation, PostIdFirestore> {
  static const contentEmptyError = "Please fill out your comment";

  @override
  Future<NewCommentValidation> build(PostIdFirestore arg) async {
    return NewCommentValidation.defaultValue;
  }

  /// Validates that the content is not empty.
  /// If it is empty, the state is updated with the appropriate error message.
  /// Returns true if the content is not empty, false otherwise.
  bool validate(String content) {
    if (content.isEmpty) {
      state = const AsyncData(
        NewCommentValidation(
          contentError: contentEmptyError,
          posted: false,
        ),
      );

      return false;
    }

    return true;
  }

  /// Resets the state to be ready for adding a new comment.
  Future<void> reset() async {
    ref.invalidateSelf();
    await future;
  }

  /// Verifies that the content is not empty, then adds a new comment to the database.
  /// If the content is empty, the state is updated with the appropriate error message.
  /// If the comment is successfully added, the state is updated with the posted flag set to true.
  /// Returns true if the comment was successfully added, false otherwise.
  Future<bool> tryAddComment(String content) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _tryAddComment(content));

    return state.value?.posted ?? false;
  }

  Future<NewCommentValidation> _tryAddComment(String content) async {
    final currentUserId = ref.read(loggedInUserIdProvider);
    final commentRepository = ref.read(commentRepositoryServiceProvider);

    if (currentUserId == null) {
      throw Exception("User must be logged in before creating a comment");
    }

    if (!validate(content)) {
      // not loading or error since validation failed and wrote to the state
      return state.value!;
    }

    // The parent post id is gotten from the family argument
    final postId = arg;

    final commentData = CommentData(
      content: content,
      ownerId: currentUserId,
      publicationTime: Timestamp.now(),
      voteScore: 0,
    );

    await commentRepository.addComment(postId, commentData);

    state = const AsyncData(
      NewCommentValidation(
        contentError: null,
        posted: true,
      ),
    );

    return state.value!;
  }
}

final newCommentViewModelProvider = AsyncNotifierProvider.family<
    NewCommentViewModel, NewCommentValidation, PostIdFirestore>(
  () => NewCommentViewModel(),
);
