import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/user_service.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../models/contestant_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/event_card.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_widget.dart';
import '../widgets/confirm_dialog.dart';
import 'create_event_screen.dart';
import 'manage_users_screen.dart';
import 'tabulation_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _authService = GetIt.instance<AuthService>();
  final _eventService = GetIt.instance<EventService>();
  final _userService = GetIt.instance<UserService>();

  bool _isLoading = false;
  String? _error;
  List<EventModel> _events = [];
  List<UserModel> _users = [];

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
      final eventsStream = _eventService.getEvents();
      final usersStream = _userService.getUsers();

      final events = await eventsStream.first;
      final users = await usersStream.first;

      if (!mounted) return;

      setState(() {
        _events = events;
        _users = users;
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

  Future<void> _deleteEvent(EventModel event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Delete Event',
        message: 'Are you sure you want to delete ${event.name}?',
        confirmText: 'Delete',
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _eventService.deleteEvent(event.id);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete event: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToCreateEvent() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => const CreateEventScreen()),
        )
        .then((_) => _loadData());
  }

  void _navigateToManageUsers() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
    );
  }

  void _assignJudges(EventModel event) async {
    final selectedJudges = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        final selected = <String>{};
        return AlertDialog(
          title: const Text('Assign Judges'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              children: _users
                  .where((user) => user.role == UserRole.judge)
                  .map((user) {
                return CheckboxListTile(
                  title: Text(user.name),
                  value: selected.contains(user.id),
                  onChanged: (isChecked) {
                    setState(() {
                      if (isChecked == true) {
                        selected.add(user.id);
                      } else {
                        selected.remove(user.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selected.toList()),
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );

    if (selectedJudges != null) {
      final updatedEvent = event.copyWith(judgeIds: selectedJudges);
      await _eventService.updateEvent(updatedEvent);
      await _loadData();
    }
  }

  void _assignContestants(EventModel event) async {
    final contestants = await _fetchContestants();
    final selectedContestants = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        final selected = <String>{};
        return AlertDialog(
          title: const Text('Assign Contestants'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              children: contestants.map((contestant) {
                return CheckboxListTile(
                  title: Text(contestant.name),
                  value: selected.contains(contestant.id),
                  onChanged: (isChecked) {
                    setState(() {
                      if (isChecked == true) {
                        selected.add(contestant.id);
                      } else {
                        selected.remove(contestant.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selected.toList()),
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );

    if (selectedContestants != null) {
      final updatedEvent = event.copyWith(contestantIds: selectedContestants);
      await _eventService.updateEvent(updatedEvent);
      await _loadData();
    }
  }

  Future<List<ContestantModel>> _fetchContestants() async {
    // Implement fetching logic here
    return [];
  }

  void _createParticipant() async {
    final participantName = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Create Participant'),
          content: TextField(
            controller: controller,
            decoration:
                const InputDecoration(hintText: 'Enter participant name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (participantName != null && participantName.isNotEmpty) {
      // Add logic to save the participant
      print('Participant created: $participantName');
    }
  }

  void _createJudge() async {
    final judgeName = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Create Judge'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter judge name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (judgeName != null && judgeName.isNotEmpty) {
      // Add logic to save the judge
      print('Judge created: $judgeName');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Events',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          CustomButton(
                            text: 'Create Event',
                            onPressed: _navigateToCreateEvent,
                            icon: Icons.add,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._events.map((event) => EventCard(
                            event: event,
                            onDelete: () => _deleteEvent(event),
                            onEdit: () {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) => CreateEventScreen(
                                          initialEvent: event),
                                    ),
                                  )
                                  .then((_) => _loadData());
                            },
                            actions: [
                              IconButton(
                                icon: const Icon(Icons.person_add),
                                onPressed: () => _assignJudges(event),
                                tooltip: 'Assign Judges',
                              ),
                              IconButton(
                                icon: const Icon(Icons.group_add),
                                onPressed: () => _assignContestants(event),
                                tooltip: 'Assign Contestants',
                              ),
                              IconButton(
                                icon: const Icon(Icons.bar_chart),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          TabulationScreen(event: event),
                                    ),
                                  );
                                },
                                tooltip: 'View Results',
                              ),
                            ],
                          )),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Users',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          CustomButton(
                            text: 'Manage Users',
                            onPressed: _navigateToManageUsers,
                            icon: Icons.people,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Create Participant',
                        onPressed: _createParticipant,
                        icon: Icons.person_add,
                      ),
                      const SizedBox(height: 8),
                      CustomButton(
                        text: 'Create Judge',
                        onPressed: _createJudge,
                        icon: Icons.person_add,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          title: const Text('Total Users'),
                          subtitle: Text('${_users.length} users'),
                          trailing: const Icon(Icons.people_outline),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
