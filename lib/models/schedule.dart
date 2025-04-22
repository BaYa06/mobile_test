class Schedule {
  final int id;
  final String groupName;
  final String subject;
  final String timeSlot;
  final String room;
  final String teacher;
  final String? day;

  Schedule({
    required this.id,
    required this.groupName,
    required this.subject,
    required this.timeSlot,
    required this.room,
    required this.teacher,
    this.day,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      groupName: json['group_name'],
      subject: json['subject'],
      timeSlot: json['time_slot'],
      room: json['room'],
      teacher: json['teacher'],
      day: json['day'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'group_name': groupName,
        'subject': subject,
        'time_slot': timeSlot,
        'room': room,
        'teacher': teacher,
        'day': day,
      };
}