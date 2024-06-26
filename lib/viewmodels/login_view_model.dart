import "package:flutter/widgets.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:proxima/models/auth/auth_logged_in_user.dart";
import "package:proxima/models/database/user/user_id_firestore.dart";
import "package:proxima/services/authentication/auth_login_service.dart";
import "package:proxima/views/components/async/circular_value.dart";
import "package:proxima/views/navigation/routes.dart";

/// Firebase authentication change provider
final authLoggedInUserProvider = StreamProvider<AuthLoggedInUser?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges().map((user) {
    if (user == null) {
      return null;
    }

    return AuthLoggedInUser(id: user.uid, email: user.email);
  });
});

/// Firebase authentication change provider to boolean
final isUserLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authLoggedInUserProvider).valueOrNull != null;
});

/// Firebase logged in user id provider, returns null if the user is not logged
/// in. [validLoggedInUserIdProvider] should almost always be used: its
/// error does not cause a pop-up to be shown by the circular
/// value, which is typically what one want since the user will
/// get navigated back to the log-in page anyway.
final loggedInUserIdProvider = Provider<UserIdFirestore?>((ref) {
  final user = ref.watch(authLoggedInUserProvider).valueOrNull;

  return user == null ? null : UserIdFirestore(value: user.id);
});

/// Firebase logged in user id provider, throws an exception if the user is
/// not logged in. This error contains the [CircularValue.debugErrorTag],
/// so it will not create a pop-up (which is useful to avoid errors
/// where the user is logged out before page navigation).
/// This prover should not be overriden, override [loggedInUserIdProvider].
final validLoggedInUserIdProvider = Provider<UserIdFirestore>((ref) {
  final user = ref.watch(loggedInUserIdProvider);

  if (user == null) {
    throw Exception(
      "${CircularValue.debugErrorTag} User must be logged in.",
    );
  }

  return user;
});

/// Registers the widget to navigate to the login page on logout.
/// This only needs to be called once in the navigation stack,
/// typically in the home page.
void navigateToLoginPageOnLogout(BuildContext context, WidgetRef ref) {
  ref.listen(isUserLoggedInProvider, (_, isLoggedIn) {
    if (!isLoggedIn) {
      // Go to login page when the user is logged out
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.login.name,
        (route) => false,
      );
    }
  });
}
