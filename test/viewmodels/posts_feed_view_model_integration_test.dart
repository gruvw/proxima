import "package:collection/collection.dart";
import "package:fake_cloud_firestore/fake_cloud_firestore.dart";
import "package:geoflutterfire_plus/geoflutterfire_plus.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:mockito/mockito.dart";
import "package:proxima/models/database/post/post_data.dart";
import "package:proxima/models/ui/post_details.dart";
import "package:proxima/services/database/firestore_service.dart";
import "package:proxima/services/database/post_repository_service.dart";
import "package:proxima/services/database/user_repository_service.dart";
import "package:proxima/services/sensors/geolocation_service.dart";
import "package:proxima/viewmodels/login_view_model.dart";
import "package:proxima/viewmodels/posts_feed_view_model.dart";
import "package:test/test.dart";

import "../mocks/data/firestore_user.dart";
import "../mocks/data/geopoint.dart";
import "../mocks/data/latlng.dart";
import "../mocks/data/post_data.dart";
import "../mocks/services/mock_geo_location_service.dart";

void main() {
  // This aims to test the [postsFeedViewModelProvider] with the real implementation
  // of the [UserRepositoryService] and [PostRepositoryService] on a fake
  // firestore instance
  group("Post Overview Provider integration testing with firestore", () {
    late MockGeolocationService geoLocationService;
    late FakeFirebaseFirestore fakeFireStore;

    late UserRepositoryService userRepo;
    late PostRepositoryService postRepo;

    late ProviderContainer container;

    // Base point used in the tests
    const userPosition = userPosition0;

    setUp(() async {
      fakeFireStore = FakeFirebaseFirestore();
      geoLocationService = MockGeolocationService();

      userRepo = UserRepositoryService(
        firestore: fakeFireStore,
      );
      postRepo = PostRepositoryService(
        firestore: fakeFireStore,
      );

      container = ProviderContainer(
        overrides: [
          geolocationServiceProvider.overrideWithValue(geoLocationService),
          firestoreProvider.overrideWithValue(fakeFireStore),
          loggedInUserIdProvider.overrideWithValue(testingUserFirestoreId),
        ],
      );

      when(geoLocationService.getCurrentPosition()).thenAnswer(
        (_) async => userPosition,
      );
    });

    test("No posts are returned when the database is empty", () async {
      final posts = await container.read(postsFeedViewModelProvider.future);

      expect(posts, isEmpty);
    });

    test("No posts are returned when they are far way from the user", () async {
      final postData = PostDataGenerator.generatePostData(1)[0];
      const userPosition = userPosition0;

      await postRepo.addPost(
        postData,
        GeoPointGenerator.createFarAwayPosition(
          userPosition,
          0.1,
        ), // This is >> 0.1 km away from the (0,0)
      );

      final actualPosts =
          await container.read(postsFeedViewModelProvider.future);

      expect(actualPosts, isEmpty);
    });

    test("Single near post returned correctly", () async {
      // Add the post owner to the database
      final owner = FirestoreUserGenerator.generateUserFirestore(1)[0];
      await userRepo.setUser(owner.uid, owner.data);

      // Add the post to the database
      final postData = PostDataGenerator.generatePostData(1).map((postData) {
        return PostData(
          ownerId: owner.uid,
          // Map to the owner
          title: postData.title,
          description: postData.description,
          publicationTime: postData.publicationTime,
          voteScore: postData.voteScore,
          commentCount: postData.commentCount,
        );
      }).first;

      const userPosition = userPosition0;
      final postPosition = GeoPointGenerator.createNearbyPosition(userPosition);
      // This is < 0.1 km away from the (0,0)

      final postId = await postRepo.addPost(
        postData,
        postPosition,
      );

      // Get the expected post overview
      final expectedPosts = [
        PostDetails(
          postId: postId,
          title: postData.title,
          description: postData.description,
          voteScore: postData.voteScore,
          ownerDisplayName: owner.data.displayName,
          ownerUsername: owner.data.username,
          ownerUserID: owner.uid,
          ownerCentauriPoints: owner.data.centauriPoints,
          commentNumber: postData.commentCount,
          publicationDate: postData.publicationTime.toDate(),
          distance: (const GeoFirePoint(userPosition)
                      .distanceBetweenInKm(geopoint: postPosition) *
                  1000)
              .round(),
          location: latLngLocation0,
        ),
      ];

      final actualPosts =
          await container.read(postsFeedViewModelProvider.future);

      expect(actualPosts, unorderedEquals(expectedPosts));
    });

    test("Throws an exception when the owner of a post is not found", () async {
      // Add the post to the database
      final postData = PostDataGenerator.generatePostData(1).first;

      await postRepo.addPost(
        postData,
        userPosition,
      );

      expect(
        container.read(postsFeedViewModelProvider.future),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            "message",
            "Exception: User document does not exist",
          ),
        ),
      );
    });

    test("Multiple near posts with multiple owners returned correctly",
        () async {
      const nbOwners = 3;
      const nbPosts = 10;

      // Add the post owners to the database
      final owners = FirestoreUserGenerator.generateUserFirestore(nbOwners);
      for (final owner in owners) {
        await userRepo.setUser(owner.uid, owner.data);
      }

      // Add the posts to the database
      final postDatas = PostDataGenerator.generatePostData(nbPosts)
          .mapIndexed(
            (index, element) => PostData(
              ownerId: owners[index % nbOwners].uid,
              // Map to an owner
              title: element.title,
              description: element.description,
              publicationTime: element.publicationTime,
              voteScore: element.voteScore,
              commentCount: element.commentCount,
            ),
          )
          .toList();

      // The 6 first posts are under 100m away from the user and are the ones expected
      const nbPostsInRange = 6;
      final postPositions = GeoPointGenerator.generatePositions(
        userPosition0,
        nbPostsInRange,
        nbPosts - nbPostsInRange,
      );

      final postIds = [];

      // Add the posts to the database
      for (var i = 0; i < postDatas.length; i++) {
        final postId = await postRepo.addPost(
          postDatas[i],
          postPositions[i],
        );

        postIds.add(postId);
      }

      // Get the expected post overviews
      final expectedPosts =
          postDatas.getRange(0, nbPostsInRange).mapIndexed((index, data) {
        final owner = owners.firstWhere(
          (user) => user.uid == data.ownerId,
          orElse: () => throw Exception("Owner not found"), // Should not happen
        );

        final postId = postIds[index];
        final postDetails = PostDetails(
          postId: postId,
          title: data.title,
          description: data.description,
          voteScore: data.voteScore,
          ownerDisplayName: owner.data.displayName,
          ownerUsername: owner.data.username,
          ownerUserID: owner.uid,
          ownerCentauriPoints: owner.data.centauriPoints,
          commentNumber: data.commentCount,
          publicationDate: data.publicationTime.toDate(),
          distance: (const GeoFirePoint(userPosition0)
                      .distanceBetweenInKm(geopoint: postPositions[index]) *
                  1000)
              .round(),
          location: latLngLocation0,
        );

        return postDetails;
      }).toList();

      final actualPosts =
          await container.read(postsFeedViewModelProvider.future);

      expect(actualPosts, unorderedEquals(expectedPosts));
    });
  });
}
