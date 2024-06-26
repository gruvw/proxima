import "dart:async";

import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:proxima/models/database/user/user_firestore.dart";
import "package:proxima/models/database/user/user_id_firestore.dart";
import "package:proxima/models/ui/user_avatar_details.dart";
import "package:proxima/services/database/user_repository_service.dart";
import "package:proxima/viewmodels/login_view_model.dart";

// TODO: Remove the fact that the current user is "null" and accept a non-nullable user id.
/// View model for the dynamic user avatar.
/// This view model is used to fetch the user's display name and centauri points
/// given its id. If the id is null, the current user's information is fetched.
class DynamicUserAvatarViewModel extends AutoDisposeFamilyAsyncNotifier<
    UserAvatarDetails, UserIdFirestore?> {
  DynamicUserAvatarViewModel();

  @override
  Future<UserAvatarDetails> build(UserIdFirestore? arg) async {
    final currentUID = ref.watch(loggedInUserIdProvider);
    final userDataBase = ref.watch(userRepositoryServiceProvider);

    late final UserFirestore user;
    late final UserIdFirestore userID;

    if (arg == null) {
      if (currentUID == null) {
        throw Exception("User is not logged in.");
      }
      userID = currentUID;
    } else {
      userID = arg;
    }

    user = await userDataBase.getUser(userID);

    return UserAvatarDetails.fromUser(user);
  }

  /// Refresh the user's information.
  Future<void> refresh() async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() => build(arg));
  }
}

//TODO: Extend to fetch the user's avatar image.
/// Flexible provider allowing to retrieve the user's display name and centauri points
/// given its id. If the id is null, the current user's information is fetched.
final dynamicUserAvatarViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<DynamicUserAvatarViewModel, UserAvatarDetails, UserIdFirestore?>(
  () => DynamicUserAvatarViewModel(),
);
