import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import '../models/score_model.dart';

class ScoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'scores';

  // Submit a score
  Future<ScoreModel> submitScore(ScoreModel score) async {
    try {
      final docRef =
          await _firestore.collection(_collection).add(score.toJson());
      return ScoreModel(
        id: docRef.id,
        eventId: score.eventId,
        judgeId: score.judgeId,
        contestantId: score.contestantId,
        scores: score.scores,
        comments: score.comments,
        timestamp: score.timestamp,
        isLocked: score.isLocked,
      );
    } catch (e) {
      throw Exception('Failed to submit score: $e');
    }
  }

  // Get a specific score
  Future<ScoreModel?> getScore(String scoreId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(scoreId).get();
      if (doc.exists) {
        return ScoreModel.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get score: $e');
    }
  }

  // Get all scores for an event
  Stream<List<ScoreModel>> getScoresForEvent(String eventId) {
    return _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScoreModel.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  // Get scores for a specific judge in an event
  Stream<List<ScoreModel>> getScoresForJudge(String eventId, String judgeId) {
    return _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .where('judgeId', isEqualTo: judgeId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScoreModel.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  // Get scores for a specific contestant in an event
  Stream<List<ScoreModel>> getScoresForContestant(
      String eventId, String contestantId) {
    return _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .where('contestantId', isEqualTo: contestantId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScoreModel.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  // Update a score
  Future<void> updateScore(ScoreModel score) async {
    await _firestore
        .collection(_collection)
        .doc(score.id)
        .update(score.toJson());
  }

  // Delete a score
  Future<void> deleteScore(String scoreId) async {
    await _firestore.collection(_collection).doc(scoreId).delete();
  }

  // Lock/unlock a score
  Future<void> setScoreLock(String scoreId, bool isLocked) async {
    try {
      await _firestore.collection(_collection).doc(scoreId).update({
        'isLocked': isLocked,
      });
    } catch (e) {
      throw Exception('Failed to update score lock status: $e');
    }
  }

  // Get average scores for all contestants in an event
  Future<Map<String, double>> getAverageScoresForEvent(String eventId) async {
    try {
      final scores = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
          .get();

      final Map<String, List<double>> contestantScores = {};

      for (var doc in scores.docs) {
        final score = ScoreModel.fromJson({...doc.data(), 'id': doc.id});
        if (!contestantScores.containsKey(score.contestantId)) {
          contestantScores[score.contestantId] = [];
        }
        contestantScores[score.contestantId]!.add(score.totalScore);
      }

      final Map<String, double> averages = {};
      contestantScores.forEach((contestantId, scores) {
        if (scores.isNotEmpty) {
          averages[contestantId] =
              scores.reduce((a, b) => a + b) / scores.length;
        }
      });

      return averages;
    } catch (e) {
      throw Exception('Failed to calculate average scores: $e');
    }
  }

  Future<void> createScore(ScoreModel score) async {
    final docRef = _firestore.collection(_collection).doc();
    await docRef.set(score.toJson());
  }

  Future<void> lockScores(String eventId) async {
    final scores = await getScoresForEvent(eventId).first;
    for (final score in scores) {
      await _firestore.collection(_collection).doc(score.id).update({
        'isLocked': true,
      });
    }
  }

  Future<Map<String, double>> getAverageScores(String eventId) async {
    final scores = await getScoresForEvent(eventId).first;
    final Map<String, List<double>> scoreSums = {};
    final Map<String, int> scoreCounts = {};

    for (final score in scores) {
      for (final entry in score.scores.entries) {
        final criterion = entry.key;
        final value = entry.value;

        scoreSums.putIfAbsent(criterion, () => []).add(value);
        scoreCounts[criterion] = (scoreCounts[criterion] ?? 0) + 1;
      }
    }

    final Map<String, double> averages = {};
    for (final entry in scoreSums.entries) {
      final criterion = entry.key;
      final values = entry.value;
      final count = scoreCounts[criterion] ?? 0;

      if (count > 0) {
        final sum = values.reduce((a, b) => a + b);
        averages[criterion] = sum / count;
      }
    }

    return averages;
  }
}
