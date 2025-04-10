import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../services/score_service.dart';
import '../models/event_model.dart';
import '../models/score_model.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_widget.dart';

class DetailedSubmissionsScreen extends StatefulWidget {
  final EventModel event;

  const DetailedSubmissionsScreen({Key? key, required this.event})
      : super(key: key);

  @override
  State<DetailedSubmissionsScreen> createState() =>
      _DetailedSubmissionsScreenState();
}

class _DetailedSubmissionsScreenState extends State<DetailedSubmissionsScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submissions for ${widget.event.name}'),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _error != null
              ? CustomErrorWidget(
                  message: _error!,
                  onRetry: _loadData,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _scores.length,
                  itemBuilder: (context, index) {
                    final score = _scores[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(
                            'Judge: ${score.judgeId}'), // Replace with judge name
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Contestant: ${score.contestantId}'), // Replace with contestant name
                            Text(
                                'Score: ${score.scores.values.fold(0.0, (sum, score) => sum + score).toStringAsFixed(2)}'),
                            Text('Comments: ${score.comments}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
