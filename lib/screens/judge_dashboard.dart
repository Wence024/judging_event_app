import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/score_service.dart';
import '../models/event_model.dart';
import '../models/score_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/event_card.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_widget.dart';
import 'score_event_screen.dart';

class JudgeDashboard extends StatefulWidget {
  const JudgeDashboard({Key? key}) : super(key: key);

  @override
  State<JudgeDashboard> createState() => _JudgeDashboardState();
}

class _JudgeDashboardState extends State<JudgeDashboard> {
  final _authService = GetIt.instance<AuthService>();
  final _eventService = GetIt.instance<EventService>();
  final _scoreService = GetIt.instance<ScoreService>();

  bool _isLoading = false;
  String? _error;
  List<EventModel> _events = [];
  Map<String, List<ScoreModel>> _scores = {};

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
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final events = await _eventService.getEvents().first;
      final judgeEvents =
          events.where((event) => event.judgeIds.contains(user.uid)).toList();

      final scores = <String, List<ScoreModel>>{};
      for (final event in judgeEvents) {
        try {
          final eventScores =
              await _scoreService.getScoresForJudge(event.id, user.uid).first;
          scores[event.id] = eventScores;
        } catch (e) {
          print('Error loading scores for event ${event.id}: $e');
          scores[event.id] = [];
        }
      }

      if (!mounted) return;

      setState(() {
        _events = judgeEvents;
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

  bool _hasScoredAllContestants(EventModel event) {
    final user = _authService.currentUser;
    if (user == null) return false;

    final eventScores = _scores[event.id] ?? [];
    final scoredContestantIds =
        eventScores.map((score) => score.contestantId).toSet();
    return scoredContestantIds.length == event.contestantIds.length;
  }

  void _navigateToScoreEvent(EventModel event) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ScoreEventScreen(event: event),
          ),
        )
        .then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Judge Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/login');
            },
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
                      Text(
                        'My Events',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      if (_events.isEmpty)
                        const Center(
                          child: Text('No events assigned to you yet.'),
                        )
                      else
                        ..._events.map((event) => EventCard(
                              event: event,
                              showActions: false,
                              onTap: () => _navigateToScoreEvent(event),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 16,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Contestants to score: ${event.contestantIds.length}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: _hasScoredAllContestants(event)
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _hasScoredAllContestants(event)
                                            ? 'All contestants scored'
                                            : 'Pending scores',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: _hasScoredAllContestants(
                                                      event)
                                                  ? Colors.green
                                                  : Colors.grey,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  CustomButton(
                                    text: 'Score Event',
                                    onPressed: () =>
                                        _navigateToScoreEvent(event),
                                    isFullWidth: true,
                                  ),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
    );
  }
}
