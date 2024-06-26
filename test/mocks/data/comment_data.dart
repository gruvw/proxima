import "dart:math";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:proxima/models/database/comment/comment_data.dart";
import "package:proxima/models/database/user/user_id_firestore.dart";

class CommentDataGenerator {
  final Random _random;

  CommentDataGenerator({int seed = 0}) : _random = Random(seed);

  List<CommentData> generateCommentData(int count) {
    return List.generate(count, (i) {
      return CommentData(
        content: "content_$i",
        ownerId: UserIdFirestore(value: "owner_id_$i"),
        publicationTime: Timestamp.fromMillisecondsSinceEpoch(1000 * i),
        voteScore: i,
      );
    });
  }

  CommentData createMockCommentData({
    String? content,
    UserIdFirestore? ownerId,
    Timestamp? publicationTime,
    int? voteScore,
  }) {
    return CommentData(
      content: content ?? "content_${_random.nextInt(100)}",
      ownerId:
          ownerId ?? UserIdFirestore(value: "owner_id_${_random.nextInt(100)}"),
      publicationTime: publicationTime ??
          Timestamp.fromMicrosecondsSinceEpoch(_random.nextInt(1000000)),
      voteScore: voteScore ?? _random.nextInt(100),
    );
  }
}
