import 'package:flutter/material.dart';
import '../models/event_model.dart';
import 'custom_button.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final Widget? child;

  const EventCard({
    Key? key,
    required this.event,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Start: ${event.startDate.toLocal().toString().split(' ')[0]}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'End: ${event.endDate.toLocal().toString().split(' ')[0]}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Judges: ${event.judgeIds.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Contestants: ${event.contestantIds.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: event.criteria
                    .map((criterion) => Chip(
                          label: Text(criterion),
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                        ))
                    .toList(),
              ),
              if (child != null) ...[
                const SizedBox(height: 8),
                child!,
              ],
              if (showActions) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      CustomButton(
                        text: 'Edit',
                        onPressed: onEdit!,
                        variant: ButtonVariant.secondary,
                      ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      CustomButton(
                        text: 'Delete',
                        onPressed: onDelete!,
                        variant: ButtonVariant.error,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
