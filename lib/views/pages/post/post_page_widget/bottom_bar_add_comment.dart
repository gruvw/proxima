import "package:flutter/material.dart";
import "package:proxima/utils/ui/user_avatar.dart";

class BottomBarAddComment extends StatelessWidget {
  static const commentUserAvatarKey = Key("commentUserAvatar");
  static const addCommentTextFieldKey = Key("addCommentTextField");
  static const postCommentButtonKey = Key("postCommentButton");

  static const _textFieldHintAddComment = "Add a comment";

  final String currentDisplayName;

  const BottomBarAddComment({
    super.key,
    required this.currentDisplayName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment
          .start, // Align items to the start of the cross axis
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: UserAvatar(
            key: commentUserAvatarKey,
            displayName: currentDisplayName,
            radius: 22,
          ),
        ),
        const Expanded(
          child: TextField(
            key: addCommentTextFieldKey,
            minLines: 1,
            maxLines: 5,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(8),
              border: OutlineInputBorder(),
              hintText: _textFieldHintAddComment,
            ),
          ),
        ),
        Align(
          alignment: Alignment
              .center, // Keeps the IconButton centered in the cross axis
          child: IconButton(
            key: postCommentButtonKey,
            icon: const Icon(Icons.send),
            onPressed: () {
              //TODO: handle add comment
              FocusManager.instance.primaryFocus?.unfocus();
            },
          ),
        ),
      ],
    );
  }
}
