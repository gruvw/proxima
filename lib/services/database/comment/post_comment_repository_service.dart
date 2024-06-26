import "package:cloud_firestore/cloud_firestore.dart";
import "package:proxima/models/database/comment/comment_data.dart";
import "package:proxima/models/database/comment/comment_firestore.dart";
import "package:proxima/models/database/comment/comment_id_firestore.dart";
import "package:proxima/models/database/post/post_data.dart";
import "package:proxima/models/database/post/post_firestore.dart";
import "package:proxima/models/database/post/post_id_firestore.dart";
import "package:proxima/services/database/upvote_repository_service.dart";

/// This class is a service that allows to interact with the comments
/// of the posts in the firestore database.
class PostCommentRepositoryService {
  final FirebaseFirestore _firestore;

  PostCommentRepositoryService({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  /// Returns the document reference of the post with id [postId]
  DocumentReference<Map<String, dynamic>> _postDocument(
    PostIdFirestore postId,
  ) {
    return _firestore
        .collection(PostFirestore.collectionName)
        .doc(postId.value);
  }

  /// Returns the collection reference of the subcollection of comments of
  /// the post with id [parentPostId]
  CollectionReference<Map<String, dynamic>> _commentsSubCollection(
    PostIdFirestore parentPostId,
  ) {
    return _postDocument(parentPostId)
        .collection(CommentFirestore.subCollectionName);
  }

  /// This method returns the comments of the post with id [parentPostId]
  Future<List<CommentFirestore>> getComments(
    PostIdFirestore parentPostId,
  ) async {
    final commentsQuery = await _commentsSubCollection(parentPostId).get();

    final comments = commentsQuery.docs
        .map((docSnap) => CommentFirestore.fromDb(docSnap))
        .toList();

    return comments;
  }

  /// This method will add the comment with data [commentData] to the
  /// post with id [parentPostId].
  /// It will also update the number of comments of the post.
  /// This is done atomically.
  ///
  /// The method returns the id of the comment that was added.
  Future<CommentIdFirestore> addComment(
    PostIdFirestore parentPostId,
    CommentData commentData,
  ) async {
    // Generate a new reference for the comment
    // Although generated locally, the new id can be considered unique
    // https://stackoverflow.com/questions/54268257/what-are-the-chances-for-firestore-to-generate-two-identical-random-keys
    final newCommentRef = _commentsSubCollection(parentPostId).doc();

    // Create a batch write to perform the operations atomically
    final batch = _firestore.batch();

    batch.set(newCommentRef, commentData.toDbData());

    final postDocRef = _postDocument(parentPostId);
    batch.update(
      postDocRef,
      {PostData.commentCountField: FieldValue.increment(1)},
    );

    await batch.commit();

    return CommentIdFirestore(value: newCommentRef.id);
  }

  /// This method will delete the comment with id [commentId] from the
  /// post with id [parentPostId].
  /// It will also update the number of comments of the post.
  /// This is done atomically.
  /// If the comment does not exist, the method will do nothing and
  /// throw an error.
  Future<void> deleteComment(
    PostIdFirestore parentPostId,
    CommentIdFirestore commentId,
  ) async {
    final batch = _firestore.batch();

    final commentUpvoteRepository =
        UpvoteRepositoryService.commentUpvoteRepositoryService(
      _firestore,
      parentPostId,
    );

    await _deleteCommentNoCountUpdate(
      parentPostId,
      commentId,
      batch,
      commentUpvoteRepository,
    );

    batch.update(
      _postDocument(parentPostId),
      {PostData.commentCountField: FieldValue.increment(-1)},
    );

    await batch.commit();
  }

  /// This method will delete all the comments of the post with id [parentPostId].
  /// Helper method to delete a post. Adds all the deletions to the batch [batch].
  Future<void> deleteAllComments(
    PostIdFirestore parentPostId,
    WriteBatch batch,
  ) async {
    final commentsRef = _commentsSubCollection(parentPostId);
    final comments = await commentsRef.get();
    final commentUpvoteRepository =
        UpvoteRepositoryService.commentUpvoteRepositoryService(
      _firestore,
      parentPostId,
    );

    for (final comment in comments.docs) {
      await _deleteCommentNoCountUpdate(
        parentPostId,
        CommentIdFirestore(value: comment.id),
        batch,
        commentUpvoteRepository,
        checkExists: false,
      );
    }

    batch.update(_postDocument(parentPostId), {PostData.commentCountField: 0});
  }

  /// Helper method to delete a comment. Adds all the deletions to the batch [batch].
  /// Does not update the comment count of the post. That should be done separately.
  /// If [checkExists] is true, the method will check if the comment exists before
  /// deleting it. If it does not exist, the method will throw an error.
  Future<void> _deleteCommentNoCountUpdate(
    PostIdFirestore parentPostId,
    CommentIdFirestore commentId,
    WriteBatch batch,
    UpvoteRepositoryService<CommentIdFirestore> commentUpvoteRepository, {
    bool checkExists = true,
  }) async {
    final commentRef =
        _commentsSubCollection(parentPostId).doc(commentId.value);

    if (checkExists) {
      final comment = await commentRef.get();
      if (!comment.exists) {
        throw Exception("Comment does not exist");
      }
    }

    await commentUpvoteRepository.deleteAllUpvotes(
      commentId,
      batch,
    );
    batch.delete(commentRef);
  }
}
