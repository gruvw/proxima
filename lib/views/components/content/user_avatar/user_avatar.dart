import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:proxima/models/ui/user_avatar_details.dart";
import "package:proxima/utils/user_avatar_color.dart";

/// A widget that displays the user's avatar.
/// It provides a [onTap] parameter to handle the user's tap,
/// which adds an InkWell response.
/// The [radius] parameter is the radius of the avatar.
class UserAvatar extends ConsumerWidget {
  static const initialDisplayNameKey = Key("initialDisplayName");

  const UserAvatar({
    super.key,
    required this.details,
    required this.radius,
    this.onTap,
  });

  final UserAvatarDetails details;
  final double radius;
  final VoidCallback? onTap;

  //TODO: Add a parameter to display the user's profile picture.
  // Note that the [backgroundImage] parameter on the [CircleAvatar] widget is
  // working and displays the user's profile picture behind the InkWell response.

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = Stack(
      children: [
        Center(
          child: Text(
            key: initialDisplayNameKey,
            // Display the first letter of the [displayName] parameter (user's initial).
            // If the display name is empty, display an empty string (because
            // it causes an error if it is empty).
            details.displayName.isEmpty
                ? ""
                : details.displayName.substring(0, 1),
          ),
        ),
        Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.hardEdge,
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
          ),
        ),
      ],
    );

    final backgroundColor = centauriToUserAvatarColor(
      details.centauriPoints,
      Theme.of(context).brightness,
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: content,
    );
  }
}
