import "dart:math";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:geoflutterfire_plus/geoflutterfire_plus.dart";
import "package:proxima/models/database/post/post_data.dart";
import "package:proxima/models/database/post/post_firestore.dart";
import "package:proxima/models/database/post/post_id_firestore.dart";
import "package:proxima/models/database/post/post_location_firestore.dart";
import "package:proxima/models/database/user/user_id_firestore.dart";

/// Helper class to create mock post data to be used in tests
class PostFirestoreGenerator {
  /// Create a [PostFirestore] with given data
  static PostFirestore createPostAt(
    PostData data,
    GeoPoint location, {
    id = "post_id",
  }) {
    final point = GeoFirePoint(location);
    return PostFirestore(
      id: PostIdFirestore(value: id),
      location: PostLocationFirestore(
        geoPoint: location,
        geohash: point.geohash,
      ),
      data: data,
    );
  }

  /// Generate a [PostFirestore] at position [location], generating the post data
  static PostFirestore generatePostAt(GeoPoint location) {
    return createPostAt(
      PostFirestoreGenerator.generatePostData(1).first,
      location,
    );
  }

  /// Create a [PostFirestore] with random data
  static PostFirestore createUserPost(
    UserIdFirestore userId,
    GeoPoint location,
  ) {
    final point = GeoPoint(location.latitude, location.longitude);

    return PostFirestore(
      id: PostIdFirestore(
        value: DateTime.now().microsecondsSinceEpoch.toString(),
      ),
      location: PostLocationFirestore(
        geoPoint: location,
        geohash: point.toString(),
      ),
      data: PostData(
        ownerId: userId,
        title: "title",
        description: "desciption",
        publicationTime: Timestamp.fromMicrosecondsSinceEpoch(1000000),
        voteScore: Random().nextInt(100),
      ),
    );
  }

  /// Generate a list of [PostData]
  static List<PostData> generatePostData(int count) {
    return List.generate(count, (i) {
      return PostData(
        description: "description_$i",
        title: "title_$i",
        ownerId: UserIdFirestore(value: "owner_id_$i"),
        publicationTime: Timestamp.fromMillisecondsSinceEpoch(1000 * i),
        voteScore: i,
      );
    });
  }
}
