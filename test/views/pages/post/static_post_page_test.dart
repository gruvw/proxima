import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:intl/intl.dart";
import "package:proxima/utils/ui/centauri_snack_bar.dart";
import "package:proxima/views/components/user_avatar/user_avatar.dart";
import "package:proxima/views/home_content/feed/post_card/post_card.dart";
import "package:proxima/views/home_content/feed/post_card/post_header_widget.dart";
import "package:proxima/views/home_content/feed/post_feed.dart";
import "package:proxima/views/navigation/leading_back_button/leading_back_button.dart";
import "package:proxima/views/pages/post/components/comment/new_comment_button.dart";
import "package:proxima/views/pages/post/components/comment/new_comment_textfield.dart";
import "package:proxima/views/pages/post/components/comment/new_comment_user_avatar.dart";
import "package:proxima/views/pages/post/post_page.dart";
import "package:proxima/views/pages/post/post_page_widget/comment_post_widget.dart";
import "package:proxima/views/pages/post/post_page_widget/complete_post_widget.dart";
import "package:timeago/timeago.dart" as timeago;

import "../../../mocks/data/firebase_auth_user.dart";
import "../../../mocks/data/firestore_challenge.dart";
import "../../../mocks/data/firestore_user.dart";
import "../../../mocks/data/post_comment.dart";
import "../../../mocks/data/post_overview.dart";
import "../../../mocks/overrides/override_firestore.dart";
import "../../../mocks/providers/provider_homepage.dart";
import "../../../mocks/providers/provider_post_page.dart";
import "../../../mocks/services/setup_firebase_mocks.dart";

void main() {
  late ProviderScope nonEmptyHomePageWidget;
  late ProviderScope emptyPostPageWidget;
  late ProviderScope nonEmptyPostPageWidget;

  setUp(() async {
    setupFirebaseAuthMocks();

    nonEmptyHomePageWidget = nonEmptyHomePageProvider;
    emptyPostPageWidget = emptyPostPageProvider;
    nonEmptyPostPageWidget = nonEmptyPostPageProvider;
  });

  group("Navigation from feed to post page", () {
    testWidgets("Check navigation to post page and comeback to feed",
        (tester) async {
      await tester.pumpWidget(nonEmptyHomePageWidget);
      await tester.pumpAndSettle();

      // Tap of the first post
      await tester.tap(find.byKey(PostCard.postCardKey).first);
      await tester.pumpAndSettle();

      // Check if the post page is displayed, with the correct title
      expect(find.byType(CompletePostWidget), findsOneWidget);
      expect(find.text(testPosts.first.title), findsAtLeastNWidgets(1));

      // Tap on the back button
      await tester.tap(find.byKey(LeadingBackButton.leadingBackButtonKey));
      await tester.pumpAndSettle();

      // Check if the feed is displayed
      final postFeed = find.byType(PostFeed);
      expect(postFeed, findsOneWidget);
    });

    void testSnackbarNavigation(bool clickChallenge) {
      testWidgets(
        clickChallenge
            ? "Navigation to post page displays a snackbar when clicking a challenge"
            : "Navigation to post page displays no snackbar when clicking a non-challenge",
        (tester) async {
          await tester.pumpWidget(nonEmptyHomePageWidget);
          await tester.pumpAndSettle();

          final challenges = testPosts
              .where((post) => post.isChallenge)
              .map(
                (post) => FirestoreChallengeGenerator.generateFromPostId(
                  post.postId,
                ),
              )
              .toList();
          await setUserFirestore(fakeFireStore, testingUserFirestore);
          await setChallenges(
            fakeFireStore,
            challenges,
            testingUserFirestoreId,
          );

          // Find all the widgets we may want to click on, i.e. challenges
          // if we want to click on a challenge, and non-challenges otherwise
          final clickOnFinder = find.byWidgetPredicate(
            (widget) =>
                widget is PostCard &&
                (widget.postOverview.isChallenge == clickChallenge),
          );
          expect(clickOnFinder, findsAtLeast(1));
          await tester.tap(clickOnFinder.first);

          // Wait enough time for the snackbar to be displayed, but
          // not enough for it to disappear
          await tester.pump(centauriPointsSnackBarDuration * 0.75);

          // Check if the snackbar is displayed
          final snackBar = find.textContaining("You won");
          expect(snackBar, clickChallenge ? findsOneWidget : findsNothing);
        },
      );
    }

    testSnackbarNavigation(true);
    testSnackbarNavigation(false);
  });

  group("Widgets display", () {
    testWidgets("Check displayed post information", (tester) async {
      await tester.pumpWidget(emptyPostPageWidget);
      await tester.pumpAndSettle();

      final post = testPosts.first;

      //Check that the complete post widget is displayed
      final completePostWidget = find.byKey(PostPage.completePostWidgetKey);
      expect(completePostWidget, findsOneWidget);

      //Check that the post title is displayed
      final postTitle = find.byKey(CompletePostWidget.postTitleKey);
      expect(postTitle, findsOneWidget);
      final postTitleWidget = tester.widget(postTitle);
      expect(
        postTitleWidget is Text && postTitleWidget.data == post.title,
        true,
      );

      //Check that the post description is displayed
      final postDescription = find.byKey(CompletePostWidget.postDescriptionKey);
      expect(postDescription, findsOneWidget);
      final postDescriptionWidget = tester.widget(postDescription);
      expect(
        postDescriptionWidget is Text &&
            postDescriptionWidget.data == post.description,
        true,
      );

      //Check that the post vote widget is displayed
      final postVote = find.byKey(CompletePostWidget.postVoteWidgetKey);
      expect(postVote, findsOneWidget);

      //Check the userbar is displayed
      final postUserBar = find.byKey(CompletePostWidget.postUserBarKey);
      expect(postUserBar, findsOneWidget);

      //Check that the owner display name is displayed
      final postUserBarDisplayNameTextWidget = tester.widget(
        find.descendant(
          of: postUserBar,
          matching: find.byKey(PostHeaderWidget.displayNameTextKey),
        ),
      );

      expect(
        postUserBarDisplayNameTextWidget is Text &&
            postUserBarDisplayNameTextWidget.data == post.ownerDisplayName,
        true,
      );

      //Check that the publication time is displayed
      final postUserBarTimestampTextWidget = tester.widget(
        find.descendant(
          of: postUserBar,
          matching: find.byKey(PostHeaderWidget.publicationDateTextKey),
        ),
      );

      expect(
        postUserBarTimestampTextWidget is Text &&
            postUserBarTimestampTextWidget.data ==
                "${timeago.format(post.publicationDate, locale: "en_short")} ago",
        true,
      );

      // Check Tooltip message
      final tooltip = find.byType(Tooltip);
      expect(tooltip, findsOneWidget);

      final tooltipWidget = tester.widget(tooltip);
      expect(tooltipWidget is Tooltip, true);

      final tooltipMessage = (tooltipWidget as Tooltip).message;
      expect(
        tooltipMessage,
        DateFormat("EEEE, MMMM d, yyyy HH:mm").format(post.publicationDate),
      );
    });

    testWidgets("Check non-comment widgets are displayed", (tester) async {
      await tester.pumpWidget(emptyPostPageWidget);
      await tester.pumpAndSettle();

      // Check if the post is displayed
      final completePost = find.byType(PostPage);
      expect(completePost, findsOneWidget);

      //Check that the post distance is displayed
      final postDistance = find.byKey(PostPage.postDistanceKey);
      expect(postDistance, findsOneWidget);

      //Check that the complete post widget is displayed
      final completePostWidget = find.byKey(PostPage.completePostWidgetKey);
      expect(completePostWidget, findsOneWidget);

      //Check that the comment list widget is displayed
      final commentListWidget = find.byKey(PostPage.commentListWidgetKey);
      expect(commentListWidget, findsOneWidget);

      //Check that the bottom bar add comment widget is displayed
      final bottomBarAddComment = find.byKey(PostPage.bottomBarAddCommentKey);
      expect(bottomBarAddComment, findsOneWidget);

      //Check that the comment user avatar is displayed
      final commentUserAvatar =
          find.byKey(NewCommentUserAvatar.commentUserAvatarKey);
      expect(commentUserAvatar, findsOneWidget);

      //Check user initial is displayed in the user account bar
      final userInitial = find.descendant(
        of: commentUserAvatar,
        matching: find.byKey(UserAvatar.initialDisplayNameKey),
      );
      expect(userInitial, findsOneWidget);

      //Check that the first initial of the test user is displayed
      final Text textWidget = tester.widget(userInitial) as Text;
      expect(textWidget.data, equals(testingLoginUser.displayName![0]));

      //Check that the add comment text field is displayed
      final addCommentTextField =
          find.byKey(NewCommentTextField.addCommentTextFieldKey);
      expect(addCommentTextField, findsOneWidget);

      //Check that the post comment button is displayed
      final postCommentButton =
          find.byKey(NewCommentButton.postCommentButtonKey);
      expect(postCommentButton, findsOneWidget);
    });

    testWidgets("Check comments are displayed", (tester) async {
      await tester.pumpWidget(nonEmptyPostPageWidget);
      await tester.pumpAndSettle();

      // Check if the post is displayed
      final completePost = find.byType(PostPage);
      expect(completePost, findsOneWidget);

      //Check that comment list widget is displayed
      final commentListWidget = find.byKey(PostPage.commentListWidgetKey);
      expect(commentListWidget, findsOneWidget);

      //Check that we have the right number of comments
      final commentList = find.byKey(CommentPostWidget.commentWidgetKey);
      expect(commentList, findsNWidgets(testComments.length));

      //Check that the comment user widgets are displayed
      final commentUserAvatar =
          find.byKey(CommentPostWidget.commentUserWidgetKey);
      expect(commentUserAvatar, findsNWidgets(testComments.length));

      //Check that the username are displayed
      final Iterable<Text> displayNameWidgets = tester.widgetList<Text>(
        find.descendant(
          of: find.byKey(CommentPostWidget.commentUserWidgetKey),
          matching: find.byKey(PostHeaderWidget.displayNameTextKey),
        ),
      );

      expect(displayNameWidgets.length, testComments.length);

      //Check the displayed usernames are correct
      final expectedUsernames =
          testComments.map((comment) => comment.ownerDisplayName).toList();
      final actualUsernames =
          displayNameWidgets.map((textWidget) => textWidget.data).toList();

      expect(actualUsernames, expectedUsernames);

      //Check that the comment content are displayed
      final Iterable<Text> commentWidgets = tester
          .widgetList<Text>(find.byKey(CommentPostWidget.commentContentKey));
      expect(commentWidgets.length, testComments.length);

      //Check the comment content displayed information
      final expectedCommentContents =
          testComments.map((comment) => comment.content).toList();
      final actualCommentContents =
          commentWidgets.map((textWidget) => textWidget.data).toList();

      expect(actualCommentContents, expectedCommentContents);
    });
  });
}
