import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String namaLengkap;
  final String kodeKkn;
  final String email;
  final int xp;
  final int level;
  final double totalBudget;
  final double usedBudget;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    required this.namaLengkap,
    required this.kodeKkn,
    required this.email,
    this.xp = 0,
    this.level = 1,
    this.totalBudget = 0.0,
    this.usedBudget = 0.0,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      namaLengkap: data['namaLengkap'] ?? '',
      kodeKkn: data['kodeKkn'] ?? '',
      email: data['email'] ?? '',
      xp: data['xp'] ?? 0,
      level: data['level'] ?? 1,
      totalBudget: (data['totalBudget'] ?? 0.0).toDouble(),
      usedBudget: (data['usedBudget'] ?? 0.0).toDouble(),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'namaLengkap': namaLengkap,
      'kodeKkn': kodeKkn,
      'email': email,
      'xp': xp,
      'level': level,
      'totalBudget': totalBudget,
      'usedBudget': usedBudget,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  UserProfile copyWith({
    String? namaLengkap,
    String? kodeKkn,
    String? email,
    int? xp,
    int? level,
    double? totalBudget,
    double? usedBudget,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      kodeKkn: kodeKkn ?? this.kodeKkn,
      email: email ?? this.email,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      totalBudget: totalBudget ?? this.totalBudget,
      usedBudget: usedBudget ?? this.usedBudget,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get xpForNextLevel => (level * 100);
  int get currentLevelXp => xp % xpForNextLevel;
  double get xpProgress => currentLevelXp / xpForNextLevel;
  double get remainingBudget => totalBudget - usedBudget;
  double get budgetUsagePercentage =>
      totalBudget > 0 ? usedBudget / totalBudget : 0.0;
}
