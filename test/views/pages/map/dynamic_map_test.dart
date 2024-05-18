import "package:cloud_firestore/cloud_firestore.dart";
import "package:fake_cloud_firestore/fake_cloud_firestore.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:mockito/mockito.dart";
import "package:proxima/models/database/post/post_firestore.dart";
import "package:proxima/models/ui/map_pin_details.dart";
import "package:proxima/viewmodels/map/map_pin_view_model.dart";
import "package:proxima/viewmodels/option_selection/map_selection_options_view_model.dart";
import "package:proxima/views/components/options/map/map_selection_option_chips.dart";
import "package:proxima/views/components/options/map/map_selection_options.dart";
import "package:proxima/views/navigation/bottom_navigation_bar/navigation_bar_routes.dart";
import "package:proxima/views/navigation/bottom_navigation_bar/navigation_bottom_bar.dart";
import "package:proxima/views/pages/home/home_page.dart";
import "package:proxima/views/pages/new_post/new_post_form.dart";

import "../../../mocks/data/firestore_post.dart";
import "../../../mocks/data/firestore_user.dart";
import "../../../mocks/data/geopoint.dart";
import "../../../mocks/overrides/override_posts_feed_view_model.dart";
import "../../../mocks/providers/provider_homepage.dart";
import "../../../mocks/services/mock_geo_location_service.dart";

void main() {
  late MockGeolocationService geoLocationService;
  late ProviderScope homePage;

  late FakeFirebaseFirestore fakeFirestore;
  late FirestorePostGenerator postGenerator;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    geoLocationService = MockGeolocationService();

    // We need the whole home page for navigation
    homePage = homePageFakeFirestoreProvider(
      fakeFirestore,
      geoLocationService,
      additionalOverrides: mockEmptyHomeViewModelOverride,
    );
    when(geoLocationService.getCurrentPosition()).thenAnswer(
      (_) => Future.value(userPosition0),
    );
    when(geoLocationService.getPositionStream()).thenAnswer(
      (_) => Stream.value(userPosition0),
    );

    postGenerator = FirestorePostGenerator();
  });

  /// Starts the test given by the [tester] by pumping the [mapPage] and
  /// getting the [ProviderContainer] of the [MapScreen] (which is returned).
  Future<ProviderContainer> beginTest(WidgetTester tester) async {
    await tester.pumpWidget(homePage);
    await tester.pumpAndSettle();

    final bottomBar = find.byKey(NavigationBottomBar.navigationBottomBarKey);
    await tester.tap(
      find.descendant(
        of: bottomBar,
        matching: find
            .byType(NavigationDestination)
            .at(NavigationbarRoutes.map.index),
      ),
    );
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(HomePage));
    return ProviderScope.containerOf(element);
  }

  /// Verifies that the [pins] and [posts] match.
  /// This means that they have the same id, and the same location. The order
  /// of the pins and posts does not matter.
  void expectPinsAndPostsMatch(
    List<MapPinDetails> pins,
    List<PostFirestore> posts,
  ) {
    // Compare the ids
    final pinsId = pins.map((pin) => pin.id.value);
    final postIds = posts.map((post) => post.id.value);
    expect(pinsId, unorderedEquals(postIds));

    // Compare the positions
    final pinsPosition = pins.map((pin) {
      final pos = pin.position;
      return GeoPoint(pos.latitude, pos.longitude);
    });
    final postPositions = posts.map((post) => post.location.geoPoint);
    expect(pinsPosition, unorderedEquals(postPositions));
  }

  group("Option selection", () {
    late List<PostFirestore> nearbyPosts;
    late List<PostFirestore> userPosts;

    late Map<MapSelectionOptions, List<PostFirestore>> expectedPostsForOption;

    setUp(() async {
      nearbyPosts = postGenerator.generatePostsAtDifferentLocations(
        GeoPointGenerator.generatePositions(userPosition0, 10, 0),
      );
      await setPostsFirestore(nearbyPosts, fakeFirestore);
      final farPosts = postGenerator.generatePostsAtDifferentLocations(
        GeoPointGenerator.generatePositions(userPosition0, 0, 10),
      );
      await setPostsFirestore(farPosts, fakeFirestore);

      userPosts = postGenerator.createUserPosts(
        testingUserFirestoreId,
        userPosition1,
        10,
      );
      await setPostsFirestore(userPosts, fakeFirestore);

      expectedPostsForOption = {
        MapSelectionOptions.nearby: nearbyPosts,
        MapSelectionOptions.myPosts: userPosts,
      };
    });

    testWidgets("Correct default option", (tester) async {
      final container = await beginTest(tester);

      final currentOption = container.read(
        mapSelectionOptionsViewModelProvider,
      );
      expect(
        currentOption,
        equals(MapSelectionOptionsViewModel.defaultMapOption),
      );
    });

    /// Verifies that the [option] is indeed the current option of the view-model
    /// (in the view of the [container]), and that the pins returned by the view-model
    /// are indeed the one expected in [expectedPostsForOption]. If [expectedPostForOption]
    /// does not contain the [option], then it is assumed that the expected posts
    /// are an empty list.
    Future<void> testOption(
      ProviderContainer container,
      MapSelectionOptions option,
    ) async {
      // Verify the option of the view-model is correct
      final currentOption = container.read(
        mapSelectionOptionsViewModelProvider,
      );
      expect(currentOption, equals(option));

      // Verify the pins are correct
      final expectedPosts = expectedPostsForOption[option] ?? List.empty();
      final pins = await container.read(mapPinViewModelProvider.future);
      expectPinsAndPostsMatch(pins, expectedPosts);
    }

    testWidgets("Post options work", (tester) async {
      final container = await beginTest(tester);

      // Verify the default option has a correct behaviour even before we click on any chip
      await testOption(
        container,
        MapSelectionOptionsViewModel.defaultMapOption,
      );

      // Run the tests twice, because the first time we click on a chip, we may
      // not refresh the posts (the first chip may be the default value)
      for (int i = 0; i < 2; ++i) {
        for (final option in MapSelectionOptions.values) {
          // Click on option chip
          final optionChip = find.byKey(
            MapSelectionOptionChips.optionChipKeys[option]!,
          );
          expect(optionChip, findsOneWidget);
          await tester.tap(optionChip);
          await tester.pumpAndSettle();

          // Verify the option
          await testOption(container, option);
        }
      }
    });

    testWidgets("Pins refresh after post creation", (tester) async {
      final container = await beginTest(tester);

      final nearbyChip = find.byKey(
        MapSelectionOptionChips.optionChipKeys[MapSelectionOptions.nearby]!,
      );
      expect(nearbyChip, findsOneWidget);
      await tester.tap(nearbyChip);

      await tester.tap(find.text("New post"));
      final addPostButton = find.text("New post");
      expect(addPostButton, findsOneWidget);
      await tester.tap(addPostButton);
      await tester.pumpAndSettle();

      final titleForm = find.byKey(NewPostForm.titleFieldKey);
      expect(titleForm, findsOneWidget);
      await tester.enterText(titleForm, "Title");
      final bodyForm = find.byKey(NewPostForm.bodyFieldKey);
      expect(bodyForm, findsOneWidget);
      await tester.enterText(bodyForm, "Body");
      final submitButton = find.byKey(NewPostForm.postButtonKey);
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // The option must not have change
      final currentOption = container.read(
        mapSelectionOptionsViewModelProvider,
      );
      expect(currentOption, equals(MapSelectionOptions.nearby));

      // There must be one more pin
      final pins = await container.read(mapPinViewModelProvider.future);
      expect(pins, hasLength(nearbyPosts.length + 1));
    });
  });
}
