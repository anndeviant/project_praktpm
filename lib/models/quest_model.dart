import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestType { daily, weekly, monthly }

enum QuestStatus { pending, inProgress, completed }

class Quest {
  final String id;
  final String title;
  final String description;
  final QuestType type;
  final QuestStatus status;
  final int xpReward;
  final double cost;
  final DateTime? deadline;
  final DateTime? startTime;
  final DateTime? endTime;
  final String kodeKkn;
  final List<String> childQuestIds;
  final String? parentQuestId;
  final int progress;
  final int maxProgress;
  final DateTime createdAt;
  final String createdBy;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.status = QuestStatus.pending,
    required this.xpReward,
    this.cost = 0.0,
    this.deadline,
    this.startTime,
    this.endTime,
    required this.kodeKkn,
    this.childQuestIds = const [],
    this.parentQuestId,
    this.progress = 0,
    this.maxProgress = 1,
    required this.createdAt,
    required this.createdBy,
  });

  factory Quest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Quest(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: QuestType.values[data['type'] ?? 0],
      status: QuestStatus.values[data['status'] ?? 0],
      xpReward: data['xpReward'] ?? 0,
      cost: (data['cost'] ?? 0.0).toDouble(),
      deadline: data['deadline']?.toDate(),
      startTime: data['startTime']?.toDate(),
      endTime: data['endTime']?.toDate(),
      kodeKkn: data['kodeKkn'] ?? '',
      childQuestIds: List<String>.from(data['childQuestIds'] ?? []),
      parentQuestId: data['parentQuestId'],
      progress: data['progress'] ?? 0,
      maxProgress: data['maxProgress'] ?? 1,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type.index,
      'status': status.index,
      'xpReward': xpReward,
      'cost': cost,
      'deadline': deadline,
      'startTime': startTime,
      'endTime': endTime,
      'kodeKkn': kodeKkn,
      'childQuestIds': childQuestIds,
      'parentQuestId': parentQuestId,
      'progress': progress,
      'maxProgress': maxProgress,
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }

  Quest copyWith({
    String? title,
    String? description,
    QuestType? type,
    QuestStatus? status,
    int? xpReward,
    double? cost,
    DateTime? deadline,
    DateTime? startTime,
    DateTime? endTime,
    String? kodeKkn,
    List<String>? childQuestIds,
    String? parentQuestId,
    int? progress,
    int? maxProgress,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Quest(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      xpReward: xpReward ?? this.xpReward,
      cost: cost ?? this.cost,
      deadline: deadline ?? this.deadline,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      kodeKkn: kodeKkn ?? this.kodeKkn,
      childQuestIds: childQuestIds ?? this.childQuestIds,
      parentQuestId: parentQuestId ?? this.parentQuestId,
      progress: progress ?? this.progress,
      maxProgress: maxProgress ?? this.maxProgress,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  double get progressPercentage =>
      maxProgress > 0 ? progress / maxProgress : 0.0;
  bool get isCompleted => status == QuestStatus.completed;
  bool get isExpired => deadline != null && DateTime.now().isAfter(deadline!);
}
