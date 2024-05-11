import "package:proxima/models/database/post/post_id_firestore.dart";
import "package:proxima/models/ui/post_details.dart";

import "datetime.dart";

final List<PostDetails> testPosts = [
  PostDetails(
    postId: const PostIdFirestore(value: "post_1"),
    title: "First post",
    description: "Lorem ipsum dolor sit amet.",
    voteScore: 100,
    commentNumber: 5,
    ownerDisplayName: "Proxima",
    publicationDate: publicationDate1,
    distance: 20,
  ),
  PostDetails(
    postId: const PostIdFirestore(value: "post_2"),
    title: "Second post",
    description:
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut congue gravida justo, ut pharetra tortor sollicitudin sit amet. Etiam eu vulputate sapien.",
    voteScore: -10,
    commentNumber: 5,
    ownerDisplayName: "Proxima",
    publicationDate: publicationDate1,
    distance: 20,
    isChallenge: true,
  ),
  PostDetails(
    postId: const PostIdFirestore(value: "post_3"),
    title: "Third post",
    description: "Crazy post",
    voteScore: 93213,
    commentNumber: 829,
    ownerDisplayName: "Proxima",
    publicationDate: publicationDate1,
    distance: 20,
  ),
];

// Custom post for testing specific date and distances
final timeDistancePost = PostDetails(
  postId: const PostIdFirestore(value: "post_1"),
  title: "title",
  description: "description",
  voteScore: 1,
  commentNumber: 5,
  ownerDisplayName: "owner",
  publicationDate: DateTime.utc(1999),
  distance: 100,
);
