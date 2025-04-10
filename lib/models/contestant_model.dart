class ContestantModel {
  final String id;
  final String name;
  final String number;
  final String eventId;

  ContestantModel({
    required this.id,
    required this.name,
    required this.number,
    required this.eventId,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'number': number, 'eventId': eventId};
  }

  factory ContestantModel.fromJson(Map<String, dynamic> json) {
    return ContestantModel(
      id: json['id'],
      name: json['name'],
      number: json['number'],
      eventId: json['eventId'],
    );
  }
}
