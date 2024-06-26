import "package:fake_cloud_firestore/fake_cloud_firestore.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:proxima/models/database/post/post_firestore.dart";
import "package:proxima/models/database/post/post_id_firestore.dart";
import "package:proxima/models/database/user/user_id_firestore.dart";
import "package:proxima/models/database/vote/vote_state.dart";
import "package:proxima/models/ui/votes_details.dart";
import "package:proxima/services/database/firestore_service.dart";
import "package:proxima/services/database/post_repository_service.dart";
import "package:proxima/services/database/post_upvote_repository_service.dart";
import "package:proxima/services/database/upvote_repository_service.dart";
import "package:proxima/viewmodels/login_view_model.dart";
import "package:proxima/viewmodels/post_votes_view_model.dart";

import "../mocks/data/firestore_post.dart";
import "../mocks/data/firestore_user.dart";
import "../mocks/data/geopoint.dart";

void main() {
  group("UpVote ViewModel integration testing", () {
    late FakeFirebaseFirestore fakeFireStore;

    late UpvoteRepositoryService<PostIdFirestore> voteRepository;
    late PostRepositoryService postRepository;
    late PostFirestore testingPost;
    late UserIdFirestore userId;

    late AutoDisposeFamilyAsyncNotifierProvider<PostVotesViewModel,
        VotesDetails, PostIdFirestore> voteViewModelProvider;

    late ProviderContainer container;

    setUp(() async {
      fakeFireStore = FakeFirebaseFirestore();
      postRepository = PostRepositoryService(firestore: fakeFireStore);

      // Add a post to the database
      final testingPostData = FirestorePostGenerator()
          .createUserPost(
            testingUserFirestoreId,
            userPosition0,
          )
          .data;

      userId = testingUserFirestoreId;

      final postId =
          await postRepository.addPost(testingPostData, userPosition0);
      testingPost = await postRepository.getPost(postId);

      container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFireStore),
          postRepositoryServiceProvider.overrideWithValue(postRepository),
          loggedInUserIdProvider.overrideWithValue(userId),
        ],
      );

      voteRepository = container.read(postUpvoteRepositoryServiceProvider);

      voteViewModelProvider = postVotesProvider(testingPost.id);
    });

    test("Upvote correctly updates the state and vote count on the database",
        () async {
      await container.read(voteViewModelProvider.notifier).triggerUpVote();

      final updatedPost = await postRepository.getPost(testingPost.id);
      final updatedVoteState =
          await voteRepository.getUpvoteState(userId, testingPost.id);

      expect(updatedPost.data.voteScore, testingPost.data.voteScore + 1);
      expect(updatedVoteState, VoteState.upvoted);
    });

    test("Downvote correctly updates the state and vote count on the database",
        () async {
      await container.read(voteViewModelProvider.notifier).triggerDownVote();

      final updatedPost = await postRepository.getPost(testingPost.id);
      final updatedVoteState =
          await voteRepository.getUpvoteState(userId, testingPost.id);

      expect(updatedPost.data.voteScore, testingPost.data.voteScore - 1);
      expect(updatedVoteState, VoteState.downvoted);
    });

    test("Upvoting twice correctly add then removes the upvote on the database",
        () async {
      // Perform first upvote
      await container.read(voteViewModelProvider.notifier).triggerUpVote();

      final updatedPostFirstUpvote =
          await postRepository.getPost(testingPost.id);
      final updatedVoteStateFirstUpvote =
          await voteRepository.getUpvoteState(userId, testingPost.id);

      expect(
        updatedPostFirstUpvote.data.voteScore,
        testingPost.data.voteScore + 1,
      );
      expect(updatedVoteStateFirstUpvote, VoteState.upvoted);

      // Perform second upvote
      await container.read(voteViewModelProvider.notifier).triggerUpVote();

      final updatedPostSecondUpvote =
          await postRepository.getPost(testingPost.id);
      final updatedVoteStateSecondUpvote =
          await voteRepository.getUpvoteState(userId, testingPost.id);

      expect(
        updatedPostSecondUpvote.data.voteScore,
        testingPost.data.voteScore,
      );
      expect(updatedVoteStateSecondUpvote, VoteState.none);
    });

    test("Upvoting then downvoting correctly removes 2 votes on the database",
        () async {
      // Perform upvote
      await container.read(voteViewModelProvider.notifier).triggerUpVote();

      final updatedPostFirstUpvote =
          await postRepository.getPost(testingPost.id);
      final updatedVoteStateFirstUpvote =
          await voteRepository.getUpvoteState(userId, testingPost.id);

      expect(
        updatedPostFirstUpvote.data.voteScore,
        testingPost.data.voteScore + 1,
      );
      expect(updatedVoteStateFirstUpvote, VoteState.upvoted);

      // Perform downvote
      await container.read(voteViewModelProvider.notifier).triggerDownVote();

      final updatedPostSecondUpvote =
          await postRepository.getPost(testingPost.id);
      final updatedVoteStateSecondUpvote =
          await voteRepository.getUpvoteState(userId, testingPost.id);

      expect(
        updatedPostSecondUpvote.data.voteScore,
        testingPost.data.voteScore - 1,
      );
      expect(updatedVoteStateSecondUpvote, VoteState.downvoted);
    });
  });
}
