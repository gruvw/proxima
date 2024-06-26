import "package:cloud_firestore/cloud_firestore.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:proxima/models/database/post/post_data.dart";
import "package:proxima/models/ui/validation/new_post_validation.dart";
import "package:proxima/services/database/post_repository_service.dart";
import "package:proxima/services/sensors/geolocation_service.dart";
import "package:proxima/viewmodels/login_view_model.dart";
import "package:proxima/viewmodels/map/map_pin_view_model.dart";
import "package:proxima/viewmodels/posts_feed_view_model.dart";

/// View-model for adding a new post to the database. Handles validation and post creation.
class NewPostViewModel extends AutoDisposeAsyncNotifier<NewPostValidation> {
  static const _titleError = "Please enter a title";
  static const _bodyError = "Please enter a body";

  @override
  Future<NewPostValidation> build() async {
    return NewPostValidation(
      titleError: null,
      descriptionError: null,
      posted: false,
    );
  }

  /// Validates that the title and description are not empty.
  /// If either is empty, the state is updated with the appropriate error message.
  bool validate(String title, String description) {
    if (title.isEmpty || description.isEmpty) {
      state = AsyncData(
        NewPostValidation(
          titleError: title.isEmpty ? _titleError : null,
          descriptionError: description.isEmpty ? _bodyError : null,
          posted: false,
        ),
      );

      return false;
    }

    return true;
  }

  /// Verifies that the title and description are not empty, then adds a new post to the database.
  /// If the title or description is empty, the state is updated with the appropriate error message.
  /// If the post is successfully added, the state is updated with the posted flag set to true.
  Future<void> addPost(String title, String description) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _addPost(title, description));
  }

  Future<NewPostValidation> _addPost(String title, String description) async {
    final currentUser = ref.read(validLoggedInUserIdProvider);

    if (!validate(title, description)) {
      // not loading or error since validation failed and wrote to the state
      return state.value!;
    }

    final currPosition =
        await ref.read(geolocationServiceProvider).getCurrentPosition();
    final postRepository = ref.read(postRepositoryServiceProvider);

    final post = PostData(
      ownerId: currentUser,
      title: title,
      description: description,
      publicationTime: Timestamp.now(),
      voteScore: 0,
      commentCount: 0,
    );

    await postRepository.addPost(post, currPosition);

    // Refresh the home feed after post creation
    ref.read(postsFeedViewModelProvider.notifier).refresh();
    // Refresh the map pins after post creation
    ref.read(mapPinViewModelProvider.notifier).refresh();

    return NewPostValidation(
      titleError: null,
      descriptionError: null,
      posted: true,
    );
  }
}

final newPostViewModelProvider =
    AsyncNotifierProvider.autoDispose<NewPostViewModel, NewPostValidation>(
  () => NewPostViewModel(),
);
