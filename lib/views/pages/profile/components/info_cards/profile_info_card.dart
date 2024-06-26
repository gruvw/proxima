import "package:flutter/material.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "package:proxima/views/components/async/loading_icon_button.dart";
import "package:proxima/views/helpers/types/future_void_callback.dart";
import "package:proxima/views/pages/profile/components/info_cards/profile_info_pop_up.dart";

/// Info card for the profile page (post or comment)
class ProfileInfoCard extends StatelessWidget {
  static const infoCardKey = Key("profileInfoCard");
  static const deleteButtonCardKey = Key("deleteButtonCard");

  const ProfileInfoCard({
    super.key,
    required this.content,
    required this.onDelete,
    this.title,
    this.location,
  });

  final String content;
  final FutureVoidCallback onDelete;
  final String? title;
  final LatLng? location;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    // Post have title, comments don't
    final potentialTitle = title != null
        ? Text(
            title!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: themeData.textTheme.titleSmall,
          )
        : null;

    final subtitle = Text(
      content,
      style: themeData.textTheme.bodySmall,
      maxLines: title == null ? 3 : 2,
      overflow: TextOverflow.ellipsis,
    );

    final cardContent = ListTile(
      title: potentialTitle ?? subtitle,
      subtitle: potentialTitle == null ? null : subtitle,
      trailing: DeleteButton(
        key: deleteButtonCardKey,
        onClick: onDelete,
      ),
    );

    // On click, show the full content
    final fullViewButton = InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (BuildContext context) {
          return ProfileInfoPopUp(
            title: title,
            content: content,
            onDelete: onDelete,
            location: location,
          );
        },
      ),
      child: Center(
        child: cardContent,
      ),
    );

    return Card(
      key: infoCardKey,
      clipBehavior: Clip.hardEdge,
      child: fullViewButton,
    );
  }
}
