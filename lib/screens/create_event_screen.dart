import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../services/event_service.dart';
import '../models/event_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_widget.dart';

class CreateEventScreen extends StatefulWidget {
  final EventModel? initialEvent;

  const CreateEventScreen({
    Key? key,
    this.initialEvent,
  }) : super(key: key);

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _eventService = GetIt.instance<EventService>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _criteriaController = TextEditingController();
  final _contestantIdsController = TextEditingController();
  final _judgeIdsController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  List<String> _criteria = [];
  List<String> _contestantIds = [];
  List<String> _judgeIds = [];
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    if (widget.initialEvent != null) {
      _nameController.text = widget.initialEvent!.name;
      _descriptionController.text = widget.initialEvent!.description;
      _criteria = List<String>.from(widget.initialEvent!.criteria);
      _contestantIds = List<String>.from(widget.initialEvent!.contestantIds);
      _judgeIds = List<String>.from(widget.initialEvent!.judgeIds);
      _startDate = widget.initialEvent!.startDate;
      _endDate = widget.initialEvent!.endDate;
      _updateControllers();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _criteriaController.dispose();
    _contestantIdsController.dispose();
    _judgeIdsController.dispose();
    super.dispose();
  }

  void _updateControllers() {
    _criteriaController.text = _criteria.join(', ');
    _contestantIdsController.text = _contestantIds.join(', ');
    _judgeIdsController.text = _judgeIds.join(', ');
  }

  void _addCriterion() {
    final criterion = _criteriaController.text.trim();
    if (criterion.isNotEmpty && !_criteria.contains(criterion)) {
      setState(() {
        _criteria.add(criterion);
        _criteriaController.clear();
        _updateControllers();
      });
    }
  }

  void _removeCriterion(String criterion) {
    setState(() {
      _criteria.remove(criterion);
      _updateControllers();
    });
  }

  void _addContestantId() {
    final contestantId = _contestantIdsController.text.trim();
    if (contestantId.isNotEmpty && !_contestantIds.contains(contestantId)) {
      setState(() {
        _contestantIds.add(contestantId);
        _contestantIdsController.clear();
        _updateControllers();
      });
    }
  }

  void _removeContestantId(String contestantId) {
    setState(() {
      _contestantIds.remove(contestantId);
      _updateControllers();
    });
  }

  void _addJudgeId() {
    final judgeId = _judgeIdsController.text.trim();
    if (judgeId.isNotEmpty && !_judgeIds.contains(judgeId)) {
      setState(() {
        _judgeIds.add(judgeId);
        _judgeIdsController.clear();
        _updateControllers();
      });
    }
  }

  void _removeJudgeId(String judgeId) {
    setState(() {
      _judgeIds.remove(judgeId);
      _updateControllers();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final event = EventModel(
        id: widget.initialEvent?.id ?? '',
        name: _nameController.text,
        description: _descriptionController.text,
        criteria: _criteria,
        contestantIds: _contestantIds,
        judgeIds: _judgeIds,
        startDate: _startDate,
        endDate: _endDate,
        createdAt: widget.initialEvent?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.initialEvent == null) {
        await _eventService.createEvent(event);
      } else {
        await _eventService.updateEvent(event);
      }

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.initialEvent == null ? 'Create Event' : 'Edit Event'),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _error != null
              ? CustomErrorWidget(
                  message: _error!,
                  onRetry: _saveEvent,
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Event Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an event name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _criteriaController,
                              decoration: const InputDecoration(
                                labelText: 'Add Criterion',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addCriterion,
                            tooltip: 'Add Criterion',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _criteria
                            .map((criterion) => Chip(
                                  label: Text(criterion),
                                  onDeleted: () => _removeCriterion(criterion),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _contestantIdsController,
                              decoration: const InputDecoration(
                                labelText: 'Add Contestant ID',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addContestantId,
                            tooltip: 'Add Contestant',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _contestantIds
                            .map((id) => Chip(
                                  label: Text(id),
                                  onDeleted: () => _removeContestantId(id),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _judgeIdsController,
                              decoration: const InputDecoration(
                                labelText: 'Add Judge ID',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addJudgeId,
                            tooltip: 'Add Judge',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _judgeIds
                            .map((id) => Chip(
                                  label: Text(id),
                                  onDeleted: () => _removeJudgeId(id),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: const Text('Start Date'),
                              subtitle: Text(
                                '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                              ),
                              onTap: () => _selectDate(context, true),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: const Text('End Date'),
                              subtitle: Text(
                                '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}',
                              ),
                              onTap: () => _selectDate(context, false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: widget.initialEvent == null
                            ? 'Create Event'
                            : 'Update Event',
                        onPressed: _saveEvent,
                        isFullWidth: true,
                      ),
                    ],
                  ),
                ),
    );
  }
}
