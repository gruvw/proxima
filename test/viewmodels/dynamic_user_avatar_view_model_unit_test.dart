import "package:fake_cloud_firestore/fake_cloud_firestore.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:proxima/models/database/user/user_firestore.dart";
import "package:proxima/services/database/firestore_service.dart";
import "package:proxima/services/database/user_repository_service.dart";
import "package:proxima/viewmodels/dynamic_user_avatar_view_model.dart";
import "package:proxima/viewmodels/login_view_model.dart";

import "../mocks/data/firestore_user.dart";

void main() {
  group("Dynamic User Avatar ViewModel unit testing", () {
    late FakeFirebaseFirestore fakeFireStore;
    late UserRepositoryService userRepo;

    late ProviderContainer container;
    late List<Override> overrideList;

    setUp(() async {
      fakeFireStore = FakeFirebaseFirestore();

      userRepo = UserRepositoryService(
        firestore: fakeFireStore,
      );

      //Prepare the list of providers to override.
      overrideList = [
        firestoreProvider.overrideWithValue(fakeFireStore),
        userRepositoryServiceProvider.overrideWithValue(userRepo),
      ];
    });

    group(
        "Dynamic User Avatar display name provider unit testing without current user",
        () {
      setUp(() async {
        container = ProviderContainer(
          overrides: overrideList,
        );
      });

      test("Find non existent current user display name", () async {
        expect(
          () async => await container
              .read(dynamicUserAvatarViewModelProvider(null).future),
          throwsA(isA<Exception>()),
        );
      });
    });
    group("Dynamic User Avatar display name provider unit testing", () {
      late List<UserFirestore> availableUsers;

      setUp(() async {
        //Define the available users
        availableUsers = FirestoreUserGenerator.generateUserFirestore(10);
        await setUsersFirestore(fakeFireStore, availableUsers);

        container = ProviderContainer(
          overrides: [
            ...overrideList,
            //Set current user id.
            loggedInUserIdProvider.overrideWithValue(availableUsers[0].uid),
          ],
        );
      });

      test("Find current user display name", () async {
        final details = await container
            .read(dynamicUserAvatarViewModelProvider(null).future);

        expect(
          details.displayName,
          availableUsers[0].data.displayName,
        );
      });

      test("Find user display name by userId", () async {
        for (final user in availableUsers) {
          final details = await container
              .read(dynamicUserAvatarViewModelProvider(user.uid).future);

          expect(
            details.displayName,
            user.data.displayName,
          );
        }
      });

      group("User Centauri points unit testing", () {
        test("Find centauri points given null user id", () async {
          final userAvatarDetails = await container.read(
            dynamicUserAvatarViewModelProvider(null).future,
          );
          expect(
            userAvatarDetails.centauriPoints,
            availableUsers[0].data.centauriPoints,
          );
        });

        test("Find centauri points given user id in available users", () async {
          for (final user in availableUsers) {
            final userAvatarDetails = await container.read(
              dynamicUserAvatarViewModelProvider(user.uid).future,
            );
            expect(
              userAvatarDetails.centauriPoints,
              user.data.centauriPoints,
            );
          }
        });
      });
    });
  });
}
