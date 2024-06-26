import "dart:async";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:proxima/models/database/user/user_data.dart";
import "package:proxima/models/database/user/user_firestore.dart";
import "package:proxima/models/database/user/user_id_firestore.dart";
import "package:proxima/services/database/firestore_service.dart";

/// This repository service is responsible for managing the users in the database
class UserRepositoryService {
  final CollectionReference _collectionRef;
  final FirebaseFirestore _firestore;

  UserRepositoryService({
    required FirebaseFirestore firestore,
  })  : _collectionRef = firestore.collection(UserFirestore.collectionName),
        _firestore = firestore;

  /// This method will retrieve the user with id [uid] from the database
  Future<UserFirestore> getUser(UserIdFirestore uid) async {
    final docSnap = await _collectionRef.doc(uid.value).get();

    return UserFirestore.fromDb(docSnap);
  }

  /// This method will set the user with id [uid] to have the data [userData]
  /// If the user does not exist yet, it will be created
  Future<void> setUser(UserIdFirestore uid, UserData userData) async {
    await _collectionRef.doc(uid.value).set(userData.toDbData());
  }

  /// This method will check if the user with id [uid] exists in the database
  Future<bool> doesUserExist(UserIdFirestore uid) async {
    final docSnap = await _collectionRef.doc(uid.value).get();

    return docSnap.exists;
  }

  /// This method will check if the unique username [username] is already taken
  /// by some user
  Future<bool> isUsernameTaken(String username) async {
    final query = await _collectionRef
        .where(UserData.usernameField, isEqualTo: username)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// This method will add [points] to the user with id [uid]
  Future<void> addPoints(UserIdFirestore uid, int points) async {
    return _firestore.runTransaction((transaction) async {
      final userDocRef = _collectionRef.doc(uid.value);

      final userDocSnap = await transaction.get(userDocRef);

      final userData =
          UserData.fromDbData(userDocSnap.data() as Map<String, dynamic>);

      final updatedUserData = userData.withPointsAddition(points).toDbData();

      transaction.update(userDocRef, updatedUserData);
    });
  }

  /// This method will return the top [limit] users that have
  /// the most centauri points.
  Future<List<UserFirestore>> getTopUsers(int limit) async {
    final centauriSorted = _collectionRef.orderBy(
      UserData.centauriPointsField,
      descending: true,
    );

    final query = await centauriSorted.limit(limit).get();
    final result = query.docs.map((doc) => UserFirestore.fromDb(doc));

    return result.toList();
  }
}

final userRepositoryServiceProvider = Provider<UserRepositoryService>(
  (ref) => UserRepositoryService(
    firestore: ref.watch(firestoreProvider),
  ),
);
