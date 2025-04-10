import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/event_service.dart';
import '../services/auth_service.dart';
import '../models/event_model.dart';
import '../models/score_model.dart';

class ScoreParticipantScreen extends StatefulWidget {
  final EventModel event;
  final String contestantId;

  const ScoreParticipantScreen({
    super.key,
    required this.event,
    required this.contestantId,
  });

  @override
  State<ScoreParticipantScreen> createState() => _ScoreParticipantScreenState();
}

class _ScoreParticipantScreenState extends State<ScoreParticipantScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, double> _scores = {};
  final _commentsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize scores with 0 for each criterion
    for (final criterion in widget.event.criteria) {
      _scores[criterion] = 0.0;
    }
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submitScore() async {
    if (!_formKey.currentState!.validate()) return;

    final eventService = Provider.of<EventService>(context, listen: false);
    final score = ScoreModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      eventId: widget.event.id,
      judgeId:
          Provider.of<AuthService>(context, listen: false).currentUser!.uid,
      contestantId: widget.contestantId,
      scores: _scores,
      comments: _commentsController.text.trim(),
      timestamp: DateTime.now(),
    );

    try {
      await eventService.submitScore(score);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting score: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Score Contestant')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scoring Criteria',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...widget.event.criteria.map((criterion) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(criterion),
                    Slider(
                      value: _scores[criterion]!,
                      min: 0,
                      max: 10,
                      divisions: 20,
                      label: _scores[criterion]!.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          _scores[criterion] = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commentsController,
                decoration: const InputDecoration(
                  labelText: 'Comments',
                  hintText: 'Enter any additional comments...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _submitScore,
                  child: const Text('Submit Score'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
