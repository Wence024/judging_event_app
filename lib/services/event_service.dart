import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/score_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'events';

  // Create a new event
  Future<EventModel> createEvent(EventModel event) async {
    try {
      final docRef =
          await _firestore.collection(_collection).add(event.toJson());
      return EventModel(
        id: docRef.id,
        name: event.name,
        description: event.description,
        criteria: event.criteria,
        judgeIds: event.judgeIds,
        contestantIds: event.contestantIds,
        startDate: event.startDate,
        endDate: event.endDate,
        createdAt: event.createdAt,
        updatedAt: event.updatedAt,
      );
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  // Get an event by ID
  Future<EventModel?> getEvent(String eventId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(eventId).get();
      if (doc.exists) {
        return EventModel.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get event: $e');
    }
  }

  // Get all events
  Stream<List<EventModel>> getEvents() {
    return _firestore
        .collection(_collection)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => EventModel.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  // Update an event
  Future<void> updateEvent(EventModel event) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(event.id)
          .update(event.toJson());
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  // Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection(_collection).doc(eventId).delete();
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  // Add a judge to an event
  Future<void> addJudge(String eventId, String judgeId) async {
    try {
      await _firestore.collection(_collection).doc(eventId).update({
        'judgeIds': FieldValue.arrayUnion([judgeId]),
      });
    } catch (e) {
      throw Exception('Failed to add judge: $e');
    }
  }

  // Remove a judge from an event
  Future<void> removeJudge(String eventId, String judgeId) async {
    try {
      await _firestore.collection(_collection).doc(eventId).update({
        'judgeIds': FieldValue.arrayRemove([judgeId]),
      });
    } catch (e) {
      throw Exception('Failed to remove judge: $e');
    }
  }

  // Add a contestant to an event
  Future<void> addContestant(String eventId, String contestantId) async {
    try {
      await _firestore.collection(_collection).doc(eventId).update({
        'contestantIds': FieldValue.arrayUnion([contestantId]),
      });
    } catch (e) {
      throw Exception('Failed to add contestant: $e');
    }
  }

  // Remove a contestant from an event
  Future<void> removeContestant(String eventId, String contestantId) async {
    try {
      await _firestore.collection(_collection).doc(eventId).update({
        'contestantIds': FieldValue.arrayRemove([contestantId]),
      });
    } catch (e) {
      throw Exception('Failed to remove contestant: $e');
    }
  }

  // Get events for a specific judge
  Stream<List<EventModel>> getEventsForJudge(String judgeId) {
    return _firestore
        .collection('events')
        .where('judgeIds', arrayContains: judgeId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  // Submit a score
  Future<bool> submitScore(ScoreModel score) async {
    try {
      await _firestore
          .collection('events')
          .doc(score.eventId)
          .collection('scores')
          .doc(score.id)
          .set(score.toJson());
      return true;
    } catch (e) {
      print('Error submitting score: $e');
      return false;
    }
  }

  // Get scores for an event
  Stream<List<ScoreModel>> getScoresForEvent(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('scores')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ScoreModel.fromJson(doc.data()))
              .toList(),
        );
  }

  // Get scores for a contestant in an event
  Stream<List<ScoreModel>> getScoresForContestant(
    String eventId,
    String contestantId,
  ) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('scores')
        .where('contestantId', isEqualTo: contestantId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ScoreModel.fromJson(doc.data()))
              .toList(),
        );
  }
}
