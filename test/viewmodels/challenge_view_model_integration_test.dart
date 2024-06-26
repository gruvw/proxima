import "package:fake_cloud_firestore/fake_cloud_firestore.dart";
import "package:flutter_test/flutter_test.dart";
import "package:geoflutterfire_plus/geoflutterfire_plus.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:mockito/mockito.dart";
import "package:proxima/services/database/challenge_repository_service.dart";
import "package:proxima/services/database/firestore_service.dart";
import "package:proxima/services/database/user_repository_service.dart";
import "package:proxima/services/sensors/geolocation_service.dart";
import "package:proxima/viewmodels/challenge_view_model.dart";
import "package:proxima/viewmodels/login_view_model.dart";
import "package:proxima/views/components/async/circular_value.dart";

import "../mocks/data/firestore_challenge.dart";
import "../mocks/data/firestore_post.dart";
import "../mocks/data/firestore_user.dart";
import "../mocks/data/geopoint.dart";
import "../mocks/services/mock_geo_location_service.dart";

void main() {
  late MockGeolocationService geoLocationService;
  late FakeFirebaseFirestore fakeFireStore;
  late ProviderContainer container;

  const extraTime = Duration(hours: 2, minutes: 30);

  setUp(() {
    geoLocationService = MockGeolocationService();
    fakeFireStore = FakeFirebaseFirestore();
    when(geoLocationService.getCurrentPosition()).thenAnswer(
      (_) async => userPosition1,
    );
  });

  group("Normal use", () {
    late UserRepositoryService userRepo;
    late FirestoreChallengeGenerator challengeGenerator;
    late FirestorePostGenerator postGenerator;

    setUp(() async {
      container = ProviderContainer(
        overrides: [
          geolocationServiceProvider.overrideWithValue(geoLocationService),
          loggedInUserIdProvider.overrideWithValue(testingUserFirestoreId),
          firestoreProvider.overrideWithValue(fakeFireStore),
        ],
      );
      challengeGenerator = FirestoreChallengeGenerator();
      postGenerator = FirestorePostGenerator();
      userRepo = container.read(userRepositoryServiceProvider);
    });

    test("No challenges are returned when the database is empty", () async {
      final challenges =
          await container.read(challengeViewModelProvider.future);
      expect(challenges, isEmpty);
    });

    test(
        "`ChallengeFirestore` is transformed correctly into `ChallengeCardData`",
        () async {
      final post = postGenerator.generatePostAt(
        userPosition1,
      ); // the challenge is added by hand, so we can use the user position
      await setPostFirestore(post, fakeFireStore);

      final challenge = challengeGenerator.generateChallenge(false, extraTime);
      await setChallenge(fakeFireStore, challenge, testingUserFirestoreId);

      final challenges =
          await container.read(challengeViewModelProvider.future);
      expect(challenges.length, 1);

      final uiChallenge = challenges.first;
      expect(uiChallenge.distance, 0);
      expect(
        uiChallenge.timeLeft,
        2,
      );
      expect(uiChallenge.isFinished, false);
      expect(
        uiChallenge.reward,
        ChallengeRepositoryService.soloChallengeReward,
      );
      expect(uiChallenge.title, post.data.title);
    });

    test("Completed challenge is transformed correctly", () async {
      final post = postGenerator.generatePostAt(
        userPosition1,
      ); // the challenge is added by hand, so we can use the user position
      await setPostFirestore(post, fakeFireStore);

      final challenge = challengeGenerator.generateChallenge(true, extraTime);
      await setChallenge(fakeFireStore, challenge, testingUserFirestoreId);

      final challenges =
          await container.read(challengeViewModelProvider.future);
      expect(challenges.length, 1);

      final uiChallenge = challenges.first;
      expect(uiChallenge.distance, null);
      expect(
        uiChallenge.timeLeft,
        2,
      );
      expect(uiChallenge.isFinished, true);
      expect(
        uiChallenge.reward,
        ChallengeRepositoryService.soloChallengeReward,
      );
      expect(uiChallenge.title, post.data.title);
    });

    test("Challenges are sorted correctly", () async {
      final posts = postGenerator.generatePostsAt(userPosition1, 3);
      await setPostsFirestore(posts, fakeFireStore);

      final finishedChallenges =
          challengeGenerator.generateChallenges(2, true, extraTime);
      final activeChallenges =
          challengeGenerator.generateChallenges(1, false, extraTime);

      await setChallenges(
        fakeFireStore,
        finishedChallenges,
        testingUserFirestoreId,
      );
      await setChallenges(
        fakeFireStore,
        activeChallenges,
        testingUserFirestoreId,
      );

      final challenges =
          await container.read(challengeViewModelProvider.future);
      final areChallengesFinished =
          challenges.map((c) => c.isFinished).toList();

      expect(
        areChallengesFinished,
        List.filled(activeChallenges.length, false) +
            List.filled(finishedChallenges.length, true),
      );
    });

    test("Challenge can be completed", () async {
      await setUserFirestore(fakeFireStore, testingUserFirestore);

      final post = postGenerator.generatePostAt(
        userPosition1,
      ); // the challenge is added by hand, so we can use the user position
      await setPostFirestore(post, fakeFireStore);

      final challenge = challengeGenerator.generateChallenge(false, extraTime);
      await setChallenge(fakeFireStore, challenge, testingUserFirestoreId);

      await container
          .read(challengeViewModelProvider.notifier)
          .completeChallenge(challenge.postId);

      await Future.delayed(const Duration(milliseconds: 100));

      final challenges =
          await container.read(challengeViewModelProvider.future);
      expect(challenges.length, 1);

      final uiChallenge = challenges.first;
      expect(uiChallenge.distance, null);
      expect(
        uiChallenge.timeLeft,
        2,
      );
      expect(uiChallenge.isFinished, true);
      expect(
        uiChallenge.reward,
        ChallengeRepositoryService.soloChallengeReward,
      );
      expect(uiChallenge.title, post.data.title);

      // tests that points are added
      final updatedUser = await userRepo.getUser(testingUserFirestoreId);
      final points = updatedUser.data.centauriPoints;
      expect(points, ChallengeRepositoryService.soloChallengeReward);
    });

    test("Challenges position is updated on user position change and refresh",
        () async {
      const nbPosts = 3;
      await postGenerator.addPosts(fakeFireStore, userPosition1, nbPosts);

      final activeChallenges =
          challengeGenerator.generateChallenges(nbPosts, false, extraTime);

      await setChallenges(
        fakeFireStore,
        activeChallenges,
        testingUserFirestoreId,
      );

      final challengesBeforeRefresh =
          await container.read(challengeViewModelProvider.future);

      // Check initial distances are 0 since user is at userPosition1
      for (final challenge in challengesBeforeRefresh) {
        expect(challenge.distance, 0);
      }

      // Change user position to userPosition2
      when(geoLocationService.getCurrentPosition()).thenAnswer(
        (_) async => userPosition2,
      );

      // Refresh challenges
      await container.read(challengeViewModelProvider.notifier).refresh();
      final challengesAfterRefresh =
          await container.read(challengeViewModelProvider.future);

      // Compute the distance between userPosition1 and userPosition2
      final double distanceKm = const GeoFirePoint(userPosition1)
          .distanceBetweenInKm(geopoint: userPosition2);
      final int distanceM = (distanceKm * 1000).toInt();

      // Check that challenges distances are updated correctly
      for (final challenge in challengesAfterRefresh) {
        expect(challenge.distance, distanceM);
      }
    });
  });

  group("No logged in user", () {
    setUp(() async {
      container = ProviderContainer(
        overrides: [
          geolocationServiceProvider.overrideWithValue(geoLocationService),
          loggedInUserIdProvider.overrideWithValue(null),
          firestoreProvider.overrideWithValue(fakeFireStore),
        ],
      );
    });

    test("No user only throws debug error", () async {
      expect(
        () async {
          await container.read(challengeViewModelProvider.future);
        },
        throwsA(
          (exception) =>
              exception.toString().contains(CircularValue.debugErrorTag),
        ),
      );
    });
  });
}
