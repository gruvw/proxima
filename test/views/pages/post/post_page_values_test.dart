import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:proxima/models/database/post/post_id_firestore.dart";
import "package:proxima/models/ui/post_overview.dart";
import "package:proxima/views/pages/post/post_page_widget/complete_post_widget.dart";

import "../../../mocks/data/post_overview.dart";
import "../../../mocks/providers/provider_post_page.dart";
import "../../../mocks/services/setup_firebase_mocks.dart";

void main() {
  // Custom post for testing specific date and distances
  final customPost = PostOverview(
    postId: const PostIdFirestore(value: "post_1"),
    title: "title",
    description: "description",
    voteScore: 1,
    commentNumber: 5,
    ownerDisplayName: "owner",
    publicationDate: DateTime.utc(1999),
    distance: 100,
  );

  setUp(() async {
    setupFirebaseAuthMocks();
  });

  group("Post Distances and Timing values", () {
    testWidgets("Check correct distance on basic post", (tester) async {
      await tester.pumpWidget(emptyPostPageProvider);
      await tester.pumpAndSettle();

      final post = testPosts.first;
      final expectedDistanceText = "${post.distance}m away";

      // Find post distance value with expected human readable distance
      final distanceDisplay = find.text(expectedDistanceText);

      // Check that the distance is displayed with correct value
      expect(distanceDisplay, findsOneWidget);
    });

    testWidgets("Check correct distance on custom post", (tester) async {
      await tester.pumpWidget(customPostOverviewPage(customPost));
      await tester.pumpAndSettle();

      final expectedDistanceText = "${customPost.distance}m away";

      // Find the container for the distance
      final appBar = find.byType(AppBar);
      // Check that the container is correctly displayed
      expect(appBar, findsOneWidget);

      // Find the child widget of the appBar (containing the distance)
      final actualDistanceDisplayed = find.descendant(
        of: appBar,
        matching: find.text(expectedDistanceText),
      );

      // Check that the distance is correctly displayed and with the right value
      expect(actualDistanceDisplayed, findsOneWidget);
    });

    testWidgets("Check correct timing on basic post, special 'now' case",
        (tester) async {
      await tester.pumpWidget(customPostOverviewPage(testPosts.first));
      await tester.pumpAndSettle();

      const expectedTimeValue = "now";

      // Find the parent of the timing text
      final postUserBar = find.byKey(CompletePostWidget.postUserBarKey);
      expect(postUserBar, findsOneWidget);

      // Find if the parent contains a child with the expected timing text
      final actualTimeDisplayed = find.descendant(
        of: postUserBar,
        matching: find.text(expectedTimeValue),
      );

      // Check the special case 'now' is correctly handled in UI
      expect(actualTimeDisplayed, findsOneWidget);
    });

    testWidgets("Check correct timing on custom post", (tester) async {
      await tester.pumpWidget(customPostOverviewPage(customPost));
      await tester.pumpAndSettle();

      const expectedTimeValue = "~1y ago";

      // Find the parent of the timing text
      final postUserBar = find.byKey(CompletePostWidget.postUserBarKey);
      expect(postUserBar, findsOneWidget);

      // Find if the parent contains a child with the expected timing text
      final actualTimeDisplayed = find.descendant(
        of: postUserBar,
        matching: find.text(expectedTimeValue),
      );

      // Check the timing value is correct
      expect(actualTimeDisplayed, findsOneWidget);
    });
  });
}
