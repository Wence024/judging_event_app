import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/event_service.dart';
import '../models/event_model.dart';
import '../models/score_model.dart';
import 'score_participant_screen.dart';

class EventDetailsScreen extends StatelessWidget {
  final EventModel event;
  final bool isAdmin;

  const EventDetailsScreen({
    super.key,
    required this.event,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final eventService = Provider.of<EventService>(context);

    return DefaultTabController(
      length: isAdmin ? 3 : 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(event.name),
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Details'),
              const Tab(text: 'Participants'),
              if (isAdmin) const Tab(text: 'Judges'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Details Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(event.description),
                  const SizedBox(height: 16),
                  Text(
                    'Event Dates',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start: ${event.startDate.toLocal().toString().split(' ')[0]}',
                  ),
                  Text(
                    'End: ${event.endDate.toLocal().toString().split(' ')[0]}',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Scoring Criteria',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ...event.criteria.map(
                    (criterion) => ListTile(
                      title: Text(criterion),
                    ),
                  ),
                ],
              ),
            ),
            // Participants Tab
            StreamBuilder<List<ScoreModel>>(
              stream: eventService.getScoresForEvent(event.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final scores = snapshot.data ?? [];

                return ListView.builder(
                  itemCount: event.contestantIds.length,
                  itemBuilder: (context, index) {
                    final contestantId = event.contestantIds[index];
                    final contestantScores = scores
                        .where((score) => score.contestantId == contestantId)
                        .toList();

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text('Contestant ${index + 1}'),
                        subtitle: Text(
                          'Scores submitted: ${contestantScores.length}',
                        ),
                        trailing: isAdmin
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.score),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ScoreParticipantScreen(
                                        event: event,
                                        contestantId: contestantId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    );
                  },
                );
              },
            ),
            // Judges Tab (Admin only)
            if (isAdmin)
              ListView.builder(
                itemCount: event.judgeIds.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text('Judge ${index + 1}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Remove Judge'),
                              content: const Text(
                                  'Are you sure you want to remove this judge?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final updatedJudges =
                                        List<String>.from(event.judgeIds)
                                          ..removeAt(index);
                                    final updatedEvent = EventModel(
                                      id: event.id,
                                      name: event.name,
                                      description: event.description,
                                      startDate: event.startDate,
                                      endDate: event.endDate,
                                      judgeIds: updatedJudges,
                                      contestantIds: event.contestantIds,
                                      criteria: event.criteria,
                                      createdAt: event.createdAt,
                                      updatedAt: DateTime.now(),
                                    );
                                    await eventService
                                        .updateEvent(updatedEvent);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
