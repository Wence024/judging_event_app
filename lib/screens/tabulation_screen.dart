import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../services/score_service.dart';
import '../models/event_model.dart';
import '../models/score_model.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_widget.dart';

class TabulationScreen extends StatefulWidget {
  final EventModel event;

  const TabulationScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<TabulationScreen> createState() => _TabulationScreenState();
}

class _TabulationScreenState extends State<TabulationScreen> {
  final _scoreService = GetIt.instance<ScoreService>();

  bool _isLoading = false;
  String? _error;
  List<ScoreModel> _scores = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final scores =
          await _scoreService.getScoresForEvent(widget.event.id).first;

      if (!mounted) return;

      setState(() {
        _scores = scores;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Map<String, List<ScoreModel>> _groupScoresByContestant(
      List<ScoreModel> scores) {
    final Map<String, List<ScoreModel>> groupedScores = {};
    for (var score in scores) {
      if (!groupedScores.containsKey(score.contestantId)) {
        groupedScores[score.contestantId] = [];
      }
      groupedScores[score.contestantId]!.add(score);
    }
    return groupedScores;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tabulation for ${widget.event.name}'),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _error != null
              ? CustomErrorWidget(
                  message: _error!,
                  onRetry: _loadData,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Average Scores',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      DataTable(
                        columns: const [
                          DataColumn(label: Text('Contestant')),
                          DataColumn(label: Text('Average Score')),
                        ],
                        rows: _groupScoresByContestant(_scores)
                            .entries
                            .map((entry) {
                          final contestantId = entry.key;
                          final scores = entry.value;
                          final totalScore = scores
                              .map((score) =>
                                  score.scores.values
                                      .fold(0.0, (sum, score) => sum + score) /
                                  score.scores.length)
                              .reduce((a, b) => a + b);
                          final averageScore = totalScore / scores.length;
                          return DataRow(cells: [
                            DataCell(Text(
                                contestantId)), // Replace with contestant name
                            DataCell(Text(averageScore.toStringAsFixed(2))),
                          ]);
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Individual Submissions',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ..._scores.map((score) => Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(
                                  'Judge: ${score.judgeId}'), // Replace with judge name
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Contestant: ${score.contestantId}'), // Replace with contestant name
                                  ...score.scores.entries.map((entry) => Text(
                                      '${entry.key}: ${entry.value.toStringAsFixed(2)}')),
                                  Text('Comments: ${score.comments}'),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
    );
  }
}
