import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../services/auth_service.dart';
import '../services/score_service.dart';
import '../models/event_model.dart';
import '../models/score_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_widget.dart';
import '../widgets/confirm_dialog.dart';

class ScoreEventScreen extends StatefulWidget {
  final EventModel event;

  const ScoreEventScreen({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  State<ScoreEventScreen> createState() => _ScoreEventScreenState();
}

class _ScoreEventScreenState extends State<ScoreEventScreen> {
  final _scoreService = GetIt.instance<ScoreService>();
  final _authService = GetIt.instance<AuthService>();
  final Map<String, Map<String, TextEditingController>> _scoreControllers = {};
  final Map<String, TextEditingController> _commentControllers = {};

  bool _isLoading = false;
  String? _error;
  List<ScoreModel> _scores = [];
  Map<String, Map<String, double>> _scoreInputs = {};
  Map<String, String> _comments = {};
  Map<String, double> _averageScores = {};
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (final controllers in _scoreControllers.values) {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    for (final contestantId in widget.event.contestantIds) {
      _scoreControllers[contestantId] = {};
      for (final criterion in widget.event.criteria) {
        _scoreControllers[contestantId]![criterion] = TextEditingController(
          text: _scoreInputs[contestantId]?[criterion]?.toString() ?? '',
        );
      }
      _commentControllers[contestantId] = TextEditingController(
        text: _comments[contestantId] ?? '',
      );
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final scores = await _scoreService
          .getScoresForJudge(widget.event.id, user.uid)
          .first;
      final averageScores =
          await _scoreService.getAverageScores(widget.event.id);

      final scoreInputs = <String, Map<String, double>>{};
      final comments = <String, String>{};

      for (final contestantId in widget.event.contestantIds) {
        final existingScore = scores.firstWhere(
          (score) => score.contestantId == contestantId,
          orElse: () => ScoreModel(
            id: '',
            eventId: widget.event.id,
            judgeId: user.uid,
            contestantId: contestantId,
            scores: {},
            comments: '',
            timestamp: DateTime.now(),
            isLocked: false,
          ),
        );

        scoreInputs[contestantId] =
            Map<String, double>.from(existingScore.scores);
        comments[contestantId] = existingScore.comments;
      }

      if (!mounted) return;

      setState(() {
        _scores = scores;
        _scoreInputs = scoreInputs;
        _comments = comments;
        _averageScores = averageScores;
        _isLocked = scores.any((score) => score.isLocked);
        _isLoading = false;
      });

      _initializeControllers();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  bool _validateScore(double score) {
    return score >= 0 && score <= 100;
  }

  Future<void> _saveScore(String contestantId) async {
    if (_isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Scores are locked and cannot be modified')),
      );
      return;
    }

    final scoreInputs = _scoreInputs[contestantId] ?? {};
    for (final score in scoreInputs.values) {
      if (!_validateScore(score)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scores must be between 0 and 100')),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final existingScore = _scores.firstWhere(
        (score) => score.contestantId == contestantId,
        orElse: () => ScoreModel(
          id: '',
          eventId: widget.event.id,
          judgeId: user.uid,
          contestantId: contestantId,
          scores: {},
          comments: '',
          timestamp: DateTime.now(),
          isLocked: false,
        ),
      );

      final score = ScoreModel(
        id: existingScore.id,
        eventId: widget.event.id,
        judgeId: user.uid,
        contestantId: contestantId,
        scores: _scoreInputs[contestantId] ?? {},
        comments: _comments[contestantId] ?? '',
        timestamp: DateTime.now(),
        isLocked: existingScore.isLocked,
      );

      if (score.id.isEmpty) {
        await _scoreService.createScore(score);
      } else {
        await _scoreService.updateScore(score);
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Score saved successfully')),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _lockScores() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Lock Scores',
        message:
            'Are you sure you want to lock all scores for this event? This action cannot be undone.',
        confirmText: 'Lock',
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _scoreService.lockScores(widget.event.id);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to lock scores: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Score ${widget.event.name}'),
        actions: [
          if (!_isLocked)
            IconButton(
              icon: const Icon(Icons.lock),
              onPressed: _lockScores,
              tooltip: 'Lock Scores',
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _error != null
              ? CustomErrorWidget(
                  message: _error!,
                  onRetry: _loadData,
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_isLocked)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Scores are locked and cannot be modified',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        'Contestants',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ...widget.event.contestantIds.map((contestantId) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Contestant ID: $contestantId',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                ...widget.event.criteria.map((criterion) {
                                  final averageScore =
                                      _averageScores[criterion];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(criterion),
                                            ),
                                            if (averageScore != null) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                'Avg: ${averageScore.toStringAsFixed(1)}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: Colors.grey,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        TextField(
                                          controller:
                                              _scoreControllers[contestantId]
                                                  ?[criterion],
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'Score (0-100)',
                                            border: const OutlineInputBorder(),
                                            suffixText: '/100',
                                            enabled: !_isLocked,
                                          ),
                                          onChanged: (value) {
                                            final score =
                                                double.tryParse(value) ?? 0.0;
                                            setState(() {
                                              _scoreInputs[contestantId] ??= {};
                                              _scoreInputs[contestantId]![
                                                  criterion] = score;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _commentControllers[contestantId],
                                  decoration: InputDecoration(
                                    labelText: 'Comments',
                                    border: const OutlineInputBorder(),
                                    enabled: !_isLocked,
                                  ),
                                  maxLines: 3,
                                  onChanged: (value) {
                                    setState(() {
                                      _comments[contestantId] = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                if (!_isLocked)
                                  CustomButton(
                                    text: 'Save Score',
                                    onPressed: () => _saveScore(contestantId),
                                    isFullWidth: true,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
    );
  }
}
