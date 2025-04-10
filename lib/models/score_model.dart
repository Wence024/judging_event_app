import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreModel {
  final String id;
  final String eventId;
  final String judgeId;
  final String contestantId;
  final Map<String, double> scores; // criteria name -> score
  final String comments;
  final DateTime timestamp;
  final bool isLocked;

  ScoreModel({
    required this.id,
    required this.eventId,
    required this.judgeId,
    required this.contestantId,
    required this.scores,
    this.comments = '',
    required this.timestamp,
    this.isLocked = false,
  });

  double get totalScore => scores.values.fold(0, (sum, score) => sum + score);

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'judgeId': judgeId,
      'contestantId': contestantId,
      'scores': scores,
      'comments': comments,
      'timestamp': timestamp.toIso8601String(),
      'isLocked': isLocked,
    };
  }

  factory ScoreModel.fromJson(Map<String, dynamic> json) {
    final scoresMap = json['scores'] as Map<String, dynamic>;
    final convertedScores = scoresMap.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    return ScoreModel(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      judgeId: json['judgeId'] as String,
      contestantId: json['contestantId'] as String,
      scores: convertedScores,
      comments: json['comments'] as String? ?? '',
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'] as String)
          : (json['timestamp'] as Timestamp).toDate(),
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }
}
