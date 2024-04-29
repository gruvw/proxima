import "package:cloud_firestore/cloud_firestore.dart";
import "package:fake_cloud_firestore/fake_cloud_firestore.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:proxima/models/database/user/user_firestore.dart";
import "package:proxima/views/pages/home/top_bar/app_top_bar.dart";
import "package:proxima/views/pages/profile/components/profile_badge.dart";
import "package:proxima/views/pages/profile/components/user_account.dart";
import "package:proxima/views/pages/profile/info_cards/profile_info_card.dart";
import "package:proxima/views/pages/profile/info_cards/profile_info_pop_up.dart";
import "package:proxima/views/pages/profile/info_cards/profile_info_row.dart";
import "package:proxima/views/pages/profile/profile_page.dart";

import "../../../mocks/data/firestore_user.dart";
import "../../../mocks/providers/provider_homepage.dart";
import "../../../mocks/providers/provider_profile_page.dart";
import "../../../mocks/services/setup_firebase_mocks.dart";

void main() {
  const delayNeededForAsyncFunctionExecution = Duration(seconds: 1);

  late FakeFirebaseFirestore fakeFireStore;
  late CollectionReference<Map<String, dynamic>> userCollection;
  late ProviderScope mockedProfilePage;

  final expectedUser = testingUserFirestore;

  setUp(() async {
    setupFirebaseAuthMocks();
    fakeFireStore = FakeFirebaseFirestore();
    userCollection = fakeFireStore.collection(UserFirestore.collectionName);

    await userCollection
        .doc(expectedUser.uid.value)
        .set(expectedUser.data.toDbData());

    mockedProfilePage = profilePageProvider(
      fakeFireStore,
    );
  });

  group("Widgets display", () {
    testWidgets("Display badges, posts comments and centauri", (tester) async {
      await tester.pumpWidget(mockedProfilePage);
      await tester.pumpAndSettle();

      // Check that badges are displayed
      final badgeCard = find.byKey(ProfileBadge.badgeKey);
      expect(badgeCard, findsWidgets);

      //Check that the post card is displayed
      final postCard = find.byKey(ProfileInfoCard.infoCardKey);
      expect(postCard, findsWidgets);

      // Check that the info column is displayed
      final infoColumn = find.byKey(ProfilePage.postColumnKey);
      expect(infoColumn, findsOneWidget);

      // Check that the info row is displayed
      final infoRowWidget = find.byKey(ProfileInfoRow.infoRowKey);
      expect(infoRowWidget, findsOneWidget);

      //Check that centauri points are displayed
      final centauriPoints = find.byKey(UserAccount.centauriPointsKey);
      expect(centauriPoints, findsOneWidget);

      //Check that the user account is displayed
      final userAccount = find.byKey(UserAccount.userInfoKey);
      expect(userAccount, findsOneWidget);

      //Check that the tab is displayed
      final tab = find.byKey(ProfilePage.tabKey);
      expect(tab, findsOneWidget);
    });
  });

  group("Functionality", () {
    testWidgets("Post popup working as expected", (tester) async {
      await tester.pumpWidget(mockedProfilePage);
      await tester.pumpAndSettle();

      //Check tab on the first post
      final infoCardPost = find.byKey(ProfileInfoCard.infoCardKey);
      expect(infoCardPost, findsWidgets);

      // Tap on the first post
      await tester.tap(infoCardPost.first);
      await tester.pumpAndSettle();

      // Check that the post popup is displayed
      final postPopup = find.byType(ProfileInfoPopUp);
      expect(postPopup, findsOneWidget);

      //Check that the title of the pop up is displayed
      final postPopupTitle = find.byKey(ProfileInfoPopUp.popUpTitleKey);
      expect(postPopupTitle, findsOneWidget);

      //Check that the description of the pop up is displayed
      final postPopupDescription =
          find.byKey(ProfileInfoPopUp.popUpDescriptionKey);
      expect(postPopupDescription, findsOneWidget);

      //Check that the delete button is displayed
      final postPopupDeleteButton =
          find.byKey(ProfileInfoPopUp.popUpDeleteButtonKey);
      expect(postPopupDeleteButton, findsOneWidget);

      //Check clicking on the delete button come back to the profile page
      await tester.tap(postPopupDeleteButton);
      await tester.pumpAndSettle();

      //Check that the profile page is displayed
      final profilePage = find.byType(ProfilePage);
      expect(profilePage, findsOneWidget);
    });

    testWidgets("Comment popup working as expected", (tester) async {
      await tester.pumpWidget(mockedProfilePage);
      await tester.pumpAndSettle();

      // Tap on the comment tab
      final commentTab = find.byKey(ProfilePage.commentTabKey);
      await tester.tap(commentTab);
      await tester.pumpAndSettle();

      //Check tab on the first comment
      final infoCardComment = find.byKey(ProfileInfoCard.infoCardKey);
      expect(infoCardComment, findsWidgets);

      // Tap on the first comment
      await tester.tap(infoCardComment.first);
      await tester.pumpAndSettle();

      // Check that the comment popup is displayed
      final commentPopup = find.byType(ProfileInfoPopUp);
      expect(commentPopup, findsOneWidget);

      //Check that the description of the pop up is displayed
      final commentPopupDescription =
          find.byKey(ProfileInfoPopUp.popUpDescriptionKey);
      expect(commentPopupDescription, findsOneWidget);

      //Check that the delete button is displayed
      final commentPopupDeleteButton =
          find.byKey(ProfileInfoPopUp.popUpDeleteButtonKey);
      expect(commentPopupDeleteButton, findsOneWidget);

      //Check clicking on the delete button come back to the profile page
      await tester.tap(commentPopupDeleteButton);
      await tester.pumpAndSettle(delayNeededForAsyncFunctionExecution);

      //Check that the profile page is displayed
      final profilePage = find.byType(ProfilePage);
      expect(profilePage, findsOneWidget);
    });

    testWidgets("Tab working as expected", (tester) async {
      await tester.pumpWidget(mockedProfilePage);
      await tester.pumpAndSettle();

      // Check that the post tab is displayed
      final postTab = find.byKey(ProfilePage.postTabKey);
      expect(postTab, findsOneWidget);

      // Check that the comment tab is displayed
      final commentTab = find.byKey(ProfilePage.commentTabKey);
      expect(commentTab, findsOneWidget);

      //Check that post column is displayed
      final postColumn = find.byKey(ProfilePage.postColumnKey);
      expect(postColumn, findsOneWidget);

      // Tap on the comment tab
      await tester.tap(commentTab);
      await tester.pumpAndSettle();

      // Check that the comment column is displayed
      final commentColumn = find.byKey(ProfilePage.commentColumnKey);
      expect(commentColumn, findsOneWidget);
    });

    testWidgets("Centauri points displayed correctly", (tester) async {
      await tester.pumpWidget(mockedProfilePage);
      await tester.pumpAndSettle();

      //Check that centauri points are displayed
      final centauriPoints = find.byKey(UserAccount.centauriPointsKey);
      expect(centauriPoints, findsOneWidget);

      // checking the text
      final centauriText = find.text("username_8456 · 0 Centauri");
      expect(centauriText, findsOneWidget);
    });
  });

  group("Navigation", () {
    testWidgets("Navigate from overview to profile page", (tester) async {
      final homePageWidget = emptyHomePageProvider;
      await tester.pumpWidget(homePageWidget);
      await tester.pumpAndSettle();

      // Check that the top bar is displayed
      final topBar = find.byKey(AppTopBar.homeTopBarKey);
      expect(topBar, findsOneWidget);

      //Check profile picture is displayed
      final profilePicture = find.byKey(AppTopBar.profilePictureKey);
      expect(profilePicture, findsOneWidget);

      // Tap on the profile picture
      await tester.tap(profilePicture);
      await tester.pumpAndSettle();

      // Check that the profile page is displayed
      final profilePage = find.byType(ProfilePage);
      expect(profilePage, findsOneWidget);
    });
  });
}