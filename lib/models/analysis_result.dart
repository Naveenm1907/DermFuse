import 'disease_tracking.dart';

class AnalysisResult {
  final String id;
  final String imagePath;
  final DiseaseType diseaseType;
  final DiseaseStage stage;
  final double confidence;
  final double riskScore;
  final String description;
  final List<String> symptoms;
  final List<String> recommendations;
  final String urgency;
  final bool needsImmediateAttention;
  final DateTime analyzedAt;
  final Map<String, dynamic> rawResponse;

  AnalysisResult({
    required this.id,
    required this.imagePath,
    required this.diseaseType,
    required this.stage,
    required this.confidence,
    required this.riskScore,
    required this.description,
    required this.symptoms,
    required this.recommendations,
    required this.urgency,
    required this.needsImmediateAttention,
    required this.analyzedAt,
    required this.rawResponse,
  });

  String get stageDescription {
    switch (stage) {
      case DiseaseStage.early:
        return 'Early stage - Monitor closely';
      case DiseaseStage.developing:
        return 'Developing - Consider consultation';
      case DiseaseStage.advanced:
        return 'Advanced - Seek medical attention';
      case DiseaseStage.critical:
        return 'Critical - Immediate medical attention required';
      case DiseaseStage.benign:
        return 'Benign - No immediate concern';
      case DiseaseStage.unknown:
        return 'Unknown - Further analysis needed';
    }
  }

  String get riskLevel {
    if (riskScore >= 0.8) return 'High Risk';
    if (riskScore >= 0.6) return 'Medium Risk';
    if (riskScore >= 0.4) return 'Low Risk';
    return 'Very Low Risk';
  }

  String get confidenceLevel {
    if (confidence >= 0.9) return 'Very High';
    if (confidence >= 0.7) return 'High';
    if (confidence >= 0.5) return 'Medium';
    return 'Low';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'diseaseType': diseaseType.name,
      'stage': stage.name,
      'confidence': confidence,
      'riskScore': riskScore,
      'description': description,
      'symptoms': symptoms,
      'recommendations': recommendations,
      'urgency': urgency,
      'needsImmediateAttention': needsImmediateAttention,
      'analyzedAt': analyzedAt.toIso8601String(),
      'rawResponse': rawResponse,
    };
  }

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      id: json['id'],
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
      urgency: json['urgency'],
      needsImmediateAttention: json['needsImmediateAttention'],
      analyzedAt: DateTime.parse(json['analyzedAt']),
      rawResponse: Map<String, dynamic>.from(json['rawResponse']),
    );
  }
}
