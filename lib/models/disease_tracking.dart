import 'package:hive/hive.dart';

part 'disease_tracking.g.dart';

@HiveType(typeId: 1)
enum DiseaseStage {
  @HiveField(0)
  early,
  @HiveField(1)
  developing,
  @HiveField(2)
  advanced,
  @HiveField(3)
  critical,
  @HiveField(4)
  benign,
  @HiveField(5)
  unknown,
}

@HiveType(typeId: 2)
enum DiseaseType {
  @HiveField(0)
  melanoma,
  @HiveField(1)
  basalCellCarcinoma,
  @HiveField(2)
  squamousCellCarcinoma,
  @HiveField(3)
  benignMole,
  @HiveField(4)
  other,
  @HiveField(5)
  unknown,
}


@HiveType(typeId: 3)
class DiseaseAnalysis extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final String imagePath;
  
  @HiveField(3)
  final DiseaseType diseaseType;
  
  @HiveField(4)
  final DiseaseStage stage;
  
  @HiveField(5)
  final double confidence;
  
  @HiveField(6)
  final double riskScore;
  
  @HiveField(7)
  final String description;
  
  @HiveField(8)
  final List<String> symptoms;
  
  @HiveField(9)
  final List<String> recommendations;
  
  @HiveField(10)
  final DateTime analyzedAt;
  
  @HiveField(11)
  final Map<String, dynamic> aiResponse;

  DiseaseAnalysis({
    required this.id,
    required this.userId,
    required this.imagePath,
    required this.diseaseType,
    required this.stage,
    required this.confidence,
    required this.riskScore,
    required this.description,
    required this.symptoms,
    required this.recommendations,
    required this.analyzedAt,
    required this.aiResponse,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'imagePath': imagePath,
      'diseaseType': diseaseType.name,
      'stage': stage.name,
      'confidence': confidence,
      'riskScore': riskScore,
      'description': description,
      'symptoms': symptoms,
      'recommendations': recommendations,
      'analyzedAt': analyzedAt.toIso8601String(),
      'aiResponse': aiResponse,
    };
  }

  factory DiseaseAnalysis.fromJson(Map<String, dynamic> json) {
    return DiseaseAnalysis(
      id: json['id'],
      userId: json['userId'],
      imagePath: json['imagePath'],
      diseaseType: DiseaseType.values.firstWhere(
        (e) => e.name == json['diseaseType'],
        orElse: () => DiseaseType.unknown,
      ),
      stage: DiseaseStage.values.firstWhere(
        (e) => e.name == json['stage'],
        orElse: () => DiseaseStage.unknown,
      ),
      confidence: json['confidence'].toDouble(),
      riskScore: json['riskScore'].toDouble(),
      description: json['description'],
      symptoms: List<String>.from(json['symptoms']),
      recommendations: List<String>.from(json['recommendations']),
      analyzedAt: DateTime.parse(json['analyzedAt']),
      aiResponse: Map<String, dynamic>.from(json['aiResponse']),
    );
  }
}

@HiveType(typeId: 4)
class DiseaseTimeline extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final List<DiseaseAnalysis> analyses;
  
  @HiveField(3)
  final DateTime createdAt;
  
  @HiveField(4)
  final DateTime? lastUpdated;

  DiseaseTimeline({
    required this.id,
    required this.userId,
    required this.analyses,
    required this.createdAt,
    this.lastUpdated,
  });

  DiseaseAnalysis? get latestAnalysis {
    if (analyses.isEmpty) return null;
    analyses.sort((a, b) => b.analyzedAt.compareTo(a.analyzedAt));
    return analyses.first;
  }

  List<DiseaseAnalysis> get sortedAnalyses {
    final sorted = List<DiseaseAnalysis>.from(analyses);
    sorted.sort((a, b) => a.analyzedAt.compareTo(b.analyzedAt));
    return sorted;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'analyses': analyses.map((a) => a.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory DiseaseTimeline.fromJson(Map<String, dynamic> json) {
    return DiseaseTimeline(
      id: json['id'],
      userId: json['userId'],
      analyses: (json['analyses'] as List)
          .map((a) => DiseaseAnalysis.fromJson(a))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : null,
    );
  }
}
