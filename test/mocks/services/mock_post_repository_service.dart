import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mockito/mockito.dart";
import "package:proxima/models/database/post/post_data.dart";
import "package:proxima/models/database/post/post_firestore.dart";
import "package:proxima/models/database/post/post_id_firestore.dart";
import "package:proxima/models/database/post/post_location_firestore.dart";
import "package:proxima/models/database/user/user_id_firestore.dart";
import "package:proxima/services/database/post_repository_service.dart";

import "../data/geopoint.dart";

/// Not a coherent representation of a [PostFirestore]
/// This is just here as a placeholder value that will be overridden in the tests
final _emptyFirestorePost = PostFirestore(
  id: const PostIdFirestore(value: ""),
  location: const PostLocationFirestore(
    geoPoint: userPosition0,
    geohash: "",
  ),
  data: PostData(
    ownerId: const UserIdFirestore(value: ""),
    title: "",
    description: "",
    publicationTime: Timestamp.fromMillisecondsSinceEpoch(0),
    voteScore: 0,
    commentCount: 0,
  ),
);

class MockPostRepositoryService extends Mock implements PostRepositoryService {
  @override
  Future<PostIdFirestore> addPost(PostData? postData, GeoPoint? position) {
    return super.noSuchMethod(
      Invocation.method(#addPost, [postData, position]),
      returnValue: Future.value(const PostIdFirestore(value: "id")),
    );
  }

  @override
  Future<void> deletePost(PostIdFirestore? postId) {
    return super.noSuchMethod(
      Invocation.method(#deletePost, [postId]),
      returnValue: Future.value(),
    );
  }

  @override
  Future<PostFirestore> getPost(PostIdFirestore? postId) {
    return super.noSuchMethod(
      Invocation.method(#getPost, [postId]),
      returnValue: Future.value(_emptyFirestorePost),
    );
  }

  @override
  Future<List<PostFirestore>> getNearPosts(
    GeoPoint? point,
    double? maxRadius, [
    double? minRadius = 0.0,
  ]) {
    return super.noSuchMethod(
      Invocation.method(#getNearPosts, [point, maxRadius]),
      returnValue: Future.value(List<PostFirestore>.empty()),
    );
  }
}
