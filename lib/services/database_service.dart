import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';
import '../models/disease_tracking.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'dermfuse.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        lastLogin TEXT
      )
    ''');

    // Disease analyses table
    await db.execute('''
      CREATE TABLE disease_analyses(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        diseaseType TEXT NOT NULL,
        stage TEXT NOT NULL,
        confidence REAL NOT NULL,
        riskScore REAL NOT NULL,
        description TEXT NOT NULL,
        symptoms TEXT NOT NULL,
        recommendations TEXT NOT NULL,
        analyzedAt TEXT NOT NULL,
        aiResponse TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Disease timelines table
    await db.execute('''
      CREATE TABLE disease_timelines(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        lastUpdated TEXT,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');
  }

  // User operations
  Future<String> createUser(User user) async {
    final db = await database;
    await db.insert('users', user.toJson());
    return user.id;
  }

  Future<User?> getUser(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return maps.map((map) => User.fromJson(map)).toList();
  }

  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update(
      'users',
      user.toJson(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> deleteUser(String id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // Disease analysis operations
  Future<String> createDiseaseAnalysis(DiseaseAnalysis analysis) async {
    final db = await database;
    
    // Create a new mutable map instead of modifying the original
    final analysisJson = <String, dynamic>{
      'id': analysis.id,
      'userId': analysis.userId,
      'imagePath': analysis.imagePath,
      'diseaseType': analysis.diseaseType.name,
      'stage': analysis.stage.name,
      'confidence': analysis.confidence,
      'riskScore': analysis.riskScore,
      'description': analysis.description,
      'symptoms': analysis.symptoms.join('|'),
      'recommendations': analysis.recommendations.join('|'),
      'analyzedAt': analysis.analyzedAt.toIso8601String(),
      'aiResponse': analysis.aiResponse.toString(),
    };
    
    await db.insert('disease_analyses', analysisJson);
    return analysis.id;
  }

  Future<DiseaseAnalysis?> getDiseaseAnalysis(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'disease_analyses',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final map = maps.first;
      map['symptoms'] = (map['symptoms'] as String).split('|');
      map['recommendations'] = (map['recommendations'] as String).split('|');
      map['aiResponse'] = <String, dynamic>{}; // Simplified for now
      return DiseaseAnalysis.fromJson(map);
    }
    return null;
  }

  Future<List<DiseaseAnalysis>> getDiseaseAnalysesByUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'disease_analyses',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'analyzedAt DESC',
    );

    return maps.map((map) {
      map['symptoms'] = (map['symptoms'] as String).split('|');
      map['recommendations'] = (map['recommendations'] as String).split('|');
      map['aiResponse'] = <String, dynamic>{}; // Simplified for now
      return DiseaseAnalysis.fromJson(map);
    }).toList();
  }

  Future<List<DiseaseAnalysis>> getAllDiseaseAnalyses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'disease_analyses',
      orderBy: 'analyzedAt DESC',
    );

    return maps.map((map) {
      map['symptoms'] = (map['symptoms'] as String).split('|');
      map['recommendations'] = (map['recommendations'] as String).split('|');
      map['aiResponse'] = <String, dynamic>{}; // Simplified for now
      return DiseaseAnalysis.fromJson(map);
    }).toList();
  }

  Future<void> updateDiseaseAnalysis(DiseaseAnalysis analysis) async {
    final db = await database;
    
    // Create a new mutable map instead of modifying the original
    final analysisJson = <String, dynamic>{
      'id': analysis.id,
      'userId': analysis.userId,
      'imagePath': analysis.imagePath,
      'diseaseType': analysis.diseaseType.name,
      'stage': analysis.stage.name,
      'confidence': analysis.confidence,
      'riskScore': analysis.riskScore,
      'description': analysis.description,
      'symptoms': analysis.symptoms.join('|'),
      'recommendations': analysis.recommendations.join('|'),
      'analyzedAt': analysis.analyzedAt.toIso8601String(),
      'aiResponse': analysis.aiResponse.toString(),
    };
    
    await db.update(
      'disease_analyses',
      analysisJson,
      where: 'id = ?',
      whereArgs: [analysis.id],
    );
  }

  Future<void> deleteDiseaseAnalysis(String id) async {
    final db = await database;
    await db.delete('disease_analyses', where: 'id = ?', whereArgs: [id]);
  }

  // Disease timeline operations
  Future<String> createDiseaseTimeline(DiseaseTimeline timeline) async {
    final db = await database;
    await db.insert('disease_timelines', timeline.toJson());
    return timeline.id;
  }

  Future<DiseaseTimeline?> getDiseaseTimeline(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'disease_timelines',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final timeline = DiseaseTimeline.fromJson(maps.first);
      final analyses = await getDiseaseAnalysesByUser(timeline.userId);
      return DiseaseTimeline(
        id: timeline.id,
        userId: timeline.userId,
        analyses: analyses,
        createdAt: timeline.createdAt,
        lastUpdated: timeline.lastUpdated,
      );
    }
    return null;
  }

  Future<List<DiseaseTimeline>> getDiseaseTimelinesByUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'disease_timelines',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    final timelines = <DiseaseTimeline>[];
    for (final map in maps) {
      final timeline = DiseaseTimeline.fromJson(map);
      final analyses = await getDiseaseAnalysesByUser(timeline.userId);
      timelines.add(DiseaseTimeline(
        id: timeline.id,
        userId: timeline.userId,
        analyses: analyses,
        createdAt: timeline.createdAt,
        lastUpdated: timeline.lastUpdated,
      ));
    }
    return timelines;
  }


  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
