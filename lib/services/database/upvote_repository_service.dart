import "package:cloud_firestore/cloud_firestore.dart";
import "package:proxima/models/database/comment/comment_data.dart";
import "package:proxima/models/database/comment/comment_firestore.dart";
import "package:proxima/models/database/comment/comment_id_firestore.dart";
import "package:proxima/models/database/firestore/id_firestore.dart";
import "package:proxima/models/database/post/post_data.dart";
import "package:proxima/models/database/post/post_firestore.dart";
import "package:proxima/models/database/post/post_id_firestore.dart";
import "package:proxima/models/database/user/user_id_firestore.dart";
import "package:proxima/models/database/vote/vote_firestore.dart";
import "package:proxima/models/database/vote/vote_state.dart";

/// This repository service is responsible for handling the upvotes of an
/// arbitrary parent document.
class UpvoteRepositoryService<ParentIdFirestore extends IdFirestore> {
  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _parentCollection;
  final String _voteScoreField;

  UpvoteRepositoryService._({
    required FirebaseFirestore firestore,
    required CollectionReference<Map<String, dynamic>> parentCollection,
    required voteScoreField,
  })  : _firestore = firestore,
        _parentCollection = parentCollection,
        _voteScoreField = voteScoreField;

  /// Returns an instance of [UpvoteRepositoryService] for up-voting posts that
  /// are stored in the [firestore] database.
  static UpvoteRepositoryService<PostIdFirestore> postUpvoteRepositoryService(
    FirebaseFirestore firestore,
  ) {
    return UpvoteRepositoryService._(
      firestore: firestore,
      parentCollection: firestore.collection(PostFirestore.collectionName),
      voteScoreField: PostData.voteScoreField,
    );
  }

  /// Returns an instance of [UpvoteRepositoryService] for up-voting comments
  /// relating to the post with id [postId]. Everything is stored in the
  /// [firestore] database.
  static UpvoteRepositoryService<CommentIdFirestore>
      commentUpvoteRepositoryService(
    FirebaseFirestore firestore,
    PostIdFirestore postId,
  ) {
    final parentCollection = firestore
        .collection(PostFirestore.collectionName)
        .doc(postId.value)
        .collection(CommentFirestore.subCollectionName);

    return UpvoteRepositoryService._(
      firestore: firestore,
      parentCollection: parentCollection,
      voteScoreField: CommentData.voteScoreField,
    );
  }

  /// Returns the document reference of the parent with id [parentId]
  DocumentReference<Map<String, dynamic>> _parentDocument(
    ParentIdFirestore parentId,
  ) {
    return _parentCollection.doc(parentId.value);
  }

  /// Returns the collection reference of the subcollection that contains the
  /// list of users who voted the parent with id [parentId]
  CollectionReference<Map<String, dynamic>> _votersCollection(
    ParentIdFirestore parentId,
  ) {
    return _parentDocument(parentId)
        .collection(VoteFirestore.votersSubCollectionName);
  }

  /// Returns the upvote state of the user with id [userId] on the parent with id [parentId]
  /// This is done atomically, possibly as part of the transaction [transaction].
  /// This only reads and writes nothing to the transaction, so it must be run before any
  /// transaction write (see [FirebaseFirestore::runWithTransaction] documentation).
  Future<VoteState> getUpvoteState(
    UserIdFirestore userId,
    ParentIdFirestore parentId, {
    Transaction? transaction,
  }) async {
    final voteStateCollection = _votersCollection(parentId).doc(userId.value);

    final DocumentSnapshot<Map<String, dynamic>> voteState;
    try {
      // Exception `cloud_firestore/unavailable` (of type `FirebaseException`) is thrown here when voting offline
      voteState = transaction != null
          ? await transaction.get(voteStateCollection)
          : await voteStateCollection.get();
    } on FirebaseException {
      // Do not handle voting a post when being offline, see issue #160
      return VoteState.none;
    }

    if (!voteState.exists) {
      return VoteState.none;
    }

    return VoteFirestore.fromDbData(voteState.data()!).hasUpvoted
        ? VoteState.upvoted
        : VoteState.downvoted;
  }

  /// Sets the upvote state of the user with id [userId] on the parent with id [parentId]
  /// to [newState]. This is done atomically.
  Future<void> setUpvoteState(
    UserIdFirestore userId,
    ParentIdFirestore parentId,
    VoteState newState,
  ) async {
    return await _firestore.runTransaction((transaction) async {
      final currState = await getUpvoteState(
        userId,
        parentId,
        transaction: transaction,
      );
      if (currState == newState) return;

      int increment = 0;

      // Remove the current state, setting it to none.
      increment -= currState.increment;

      // Apply the wanted state.
      increment += newState.increment;

      if (newState == VoteState.none) {
        transaction.delete(_votersCollection(parentId).doc(userId.value));
      } else {
        transaction.set(
          _votersCollection(parentId).doc(userId.value),
          VoteFirestore(hasUpvoted: newState == VoteState.upvoted).toDbData(),
        );
      }

      // Update the vote count
      transaction.update(
        _parentDocument(parentId),
        {_voteScoreField: FieldValue.increment(increment)},
      );
    });
  }

  /// Deletes all the upvotes of the parent with id [parentId]. Should not be
  /// used on its own but rather as part of the deletion of the parent. Adds all
  /// the deletions to the batch [batch].
  Future<void> deleteAllUpvotes(
    ParentIdFirestore parentId,
    WriteBatch batch,
  ) async {
    final upvotes = await _votersCollection(parentId).get();
    for (final upvote in upvotes.docs) {
      batch.delete(upvote.reference);
    }
    batch.update(_parentDocument(parentId), {_voteScoreField: 0});
  }
}
