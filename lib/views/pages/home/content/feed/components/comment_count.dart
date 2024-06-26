import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:proxima/models/database/post/post_id_firestore.dart";
import "package:proxima/models/ui/comment_count_details.dart";
import "package:proxima/viewmodels/post_comment_count_view_model.dart";

/// This widget is used to display the comment number in the post card.
/// It contains the comment icon and the number of comments.
class CommentCount extends ConsumerWidget {
  final PostIdFirestore postId;

  const CommentCount({
    super.key,
    required this.postId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCount = ref.watch(postCommentCountProvider(postId));
    final countDetails = asyncCount.value ?? CommentCountDetails.empty;

    final icon = Icon(
      Icons.comment,
      size: 20,
      color: countDetails.isIconBlue ? Colors.blue : null,
    );
    final countText = Text(countDetails.count.toString());

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.all(4),
          child: icon,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: countText,
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: content,
      ),
    );
  }
}
