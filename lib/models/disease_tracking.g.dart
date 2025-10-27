// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disease_tracking.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DiseaseAnalysisAdapter extends TypeAdapter<DiseaseAnalysis> {
  @override
  final int typeId = 3;

  @override
  DiseaseAnalysis read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiseaseAnalysis(
      id: fields[0] as String,
      userId: fields[1] as String,
      imagePath: fields[2] as String,
      diseaseType: fields[3] as DiseaseType,
      stage: fields[4] as DiseaseStage,
      confidence: fields[5] as double,
      riskScore: fields[6] as double,
      description: fields[7] as String,
      symptoms: (fields[8] as List).cast<String>(),
      recommendations: (fields[9] as List).cast<String>(),
      analyzedAt: fields[10] as DateTime,
      aiResponse: (fields[11] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, DiseaseAnalysis obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.diseaseType)
      ..writeByte(4)
      ..write(obj.stage)
      ..writeByte(5)
      ..write(obj.confidence)
      ..writeByte(6)
      ..write(obj.riskScore)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.symptoms)
      ..writeByte(9)
      ..write(obj.recommendations)
      ..writeByte(10)
      ..write(obj.analyzedAt)
      ..writeByte(11)
      ..write(obj.aiResponse);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiseaseAnalysisAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DiseaseTimelineAdapter extends TypeAdapter<DiseaseTimeline> {
  @override
  final int typeId = 4;

  @override
  DiseaseTimeline read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiseaseTimeline(
      id: fields[0] as String,
      userId: fields[1] as String,
      analyses: (fields[2] as List).cast<DiseaseAnalysis>(),
      createdAt: fields[3] as DateTime,
      lastUpdated: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DiseaseTimeline obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.analyses)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiseaseTimelineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DiseaseStageAdapter extends TypeAdapter<DiseaseStage> {
  @override
  final int typeId = 1;

  @override
  DiseaseStage read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DiseaseStage.early;
      case 1:
        return DiseaseStage.developing;
      case 2:
        return DiseaseStage.advanced;
      case 3:
        return DiseaseStage.critical;
      case 4:
        return DiseaseStage.benign;
      case 5:
        return DiseaseStage.unknown;
      default:
        return DiseaseStage.early;
    }
  }

  @override
  void write(BinaryWriter writer, DiseaseStage obj) {
    switch (obj) {
      case DiseaseStage.early:
        writer.writeByte(0);
        break;
      case DiseaseStage.developing:
        writer.writeByte(1);
        break;
      case DiseaseStage.advanced:
        writer.writeByte(2);
        break;
      case DiseaseStage.critical:
        writer.writeByte(3);
        break;
      case DiseaseStage.benign:
        writer.writeByte(4);
        break;
      case DiseaseStage.unknown:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiseaseStageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DiseaseTypeAdapter extends TypeAdapter<DiseaseType> {
  @override
  final int typeId = 2;

  @override
  DiseaseType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DiseaseType.melanoma;
      case 1:
        return DiseaseType.basalCellCarcinoma;
      case 2:
        return DiseaseType.squamousCellCarcinoma;
      case 3:
        return DiseaseType.benignMole;
      case 4:
        return DiseaseType.other;
      case 5:
        return DiseaseType.unknown;
      default:
        return DiseaseType.melanoma;
    }
  }

  @override
  void write(BinaryWriter writer, DiseaseType obj) {
    switch (obj) {
      case DiseaseType.melanoma:
        writer.writeByte(0);
        break;
      case DiseaseType.basalCellCarcinoma:
        writer.writeByte(1);
        break;
      case DiseaseType.squamousCellCarcinoma:
        writer.writeByte(2);
        break;
      case DiseaseType.benignMole:
        writer.writeByte(3);
        break;
      case DiseaseType.other:
        writer.writeByte(4);
        break;
      case DiseaseType.unknown:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiseaseTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
