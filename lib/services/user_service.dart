import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  // Get a specific user
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Get all users
  Stream<List<UserModel>> getUsers() {
    return _firestore.collection(_collection).snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => UserModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Get users by role
  Stream<List<UserModel>> getUsersByRole(UserRole role) {
    return _firestore
        .collection(_collection)
        .where('role', isEqualTo: role.toString().split('.').last)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => UserModel.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  // Update user data
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(user.id)
          .update(user.toJson());
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // Get judges for an event
  Future<List<UserModel>> getJudgesForEvent(String eventId) async {
    try {
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      final event = eventDoc.data()!;
      final judgeIds = List<String>.from(event['judgeIds'] ?? []);

      if (judgeIds.isEmpty) {
        return [];
      }

      final judges = await _firestore
          .collection(_collection)
          .where(FieldPath.documentId, whereIn: judgeIds)
          .get();

      return judges.docs
          .map((doc) => UserModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to get judges for event: $e');
    }
  }

  // Get contestants for an event
  Future<List<UserModel>> getContestantsForEvent(String eventId) async {
    try {
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      final event = eventDoc.data()!;
      final contestantIds = List<String>.from(event['contestantIds'] ?? []);

      if (contestantIds.isEmpty) {
        return [];
      }

      final contestants = await _firestore
          .collection(_collection)
          .where(FieldPath.documentId, whereIn: contestantIds)
          .get();

      return contestants.docs
          .map((doc) => UserModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to get contestants for event: $e');
    }
  }

  Future<void> updateUserRole(String userId, UserRole role) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'role': role.name,
      });
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }
}
