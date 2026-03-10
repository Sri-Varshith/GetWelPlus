class Meeting {
  final String title;
  final String patientName;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final String notes;
  final String status; // 'pending', 'confirmed', 'rejected', 'completed'
  final String meetingType; // 'video' or 'chat'

  const Meeting({
    required this.title,
    required this.patientName,
    required this.scheduledAt,
    required this.createdAt,
    required this.notes,
    required this.status,
    this.meetingType = 'video',
  });

  bool get isAttended => scheduledAt.isBefore(DateTime.now());

  bool get isChat => meetingType == 'chat';

  String get displayStatus {
    if (isAttended && status == 'confirmed') return 'completed';
    return status;
  }
}