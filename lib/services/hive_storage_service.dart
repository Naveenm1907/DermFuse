import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';
import '../models/disease_tracking.dart';

class HiveStorageService {
  static const String _userBoxName = 'users';
  static const String _diseaseAnalysisBoxName = 'disease_analyses';
  static const String _diseaseTimelineBoxName = 'disease_timelines';
  static const String _imagesBoxName = 'images';

  late Box<User> _userBox;
  late Box<DiseaseAnalysis> _diseaseAnalysisBox;
  late Box<DiseaseTimeline> _diseaseTimelineBox;
  late Box<List<int>> _imagesBox;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize Hive
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(DiseaseAnalysisAdapter());
    Hive.registerAdapter(DiseaseTimelineAdapter());
    Hive.registerAdapter(DiseaseStageAdapter());
    Hive.registerAdapter(DiseaseTypeAdapter());

    // Open boxes
    _userBox = await Hive.openBox<User>(_userBoxName);
    _diseaseAnalysisBox = await Hive.openBox<DiseaseAnalysis>(_diseaseAnalysisBoxName);
    _diseaseTimelineBox = await Hive.openBox<DiseaseTimeline>(_diseaseTimelineBoxName);
    _imagesBox = await Hive.openBox<List<int>>(_imagesBoxName);

    _isInitialized = true;
  }

  // User operations
  Future<User?> getUser(String id) async {
    await _ensureInitialized();
    return _userBox.get(id);
  }

  Future<List<User>> getAllUsers() async {
    await _ensureInitialized();
    return _userBox.values.toList();
  }

  Future<void> saveUser(User user) async {
    await _ensureInitialized();
    await _userBox.put(user.id, user);
  }

  Future<void> updateUser(User user) async {
    await _ensureInitialized();
    await _userBox.put(user.id, user);
  }

  Future<void> deleteUser(String id) async {
    await _ensureInitialized();
    await _userBox.delete(id);
  }

  // Disease Analysis operations
  Future<DiseaseAnalysis?> getDiseaseAnalysis(String id) async {
    await _ensureInitialized();
    return _diseaseAnalysisBox.get(id);
  }

  Future<List<DiseaseAnalysis>> getAllDiseaseAnalyses() async {
    await _ensureInitialized();
    return _diseaseAnalysisBox.values.toList();
  }

  Future<List<DiseaseAnalysis>> getDiseaseAnalysesByUser(String userId) async {
    await _ensureInitialized();
    return _diseaseAnalysisBox.values
        .where((analysis) => analysis.userId == userId)
        .toList();
  }

  Future<String> createDiseaseAnalysis(DiseaseAnalysis analysis) async {
    await _ensureInitialized();
    await _diseaseAnalysisBox.put(analysis.id, analysis);
    
    // Update or create timeline
    await _updateTimeline(analysis);
    
    return analysis.id;
  }

  Future<void> updateDiseaseAnalysis(DiseaseAnalysis analysis) async {
    await _ensureInitialized();
    await _diseaseAnalysisBox.put(analysis.id, analysis);
    
    // Update timeline
    await _updateTimeline(analysis);
  }

  Future<void> deleteDiseaseAnalysis(String id) async {
    await _ensureInitialized();
    final analysis = await getDiseaseAnalysis(id);
    if (analysis != null) {
      await _diseaseAnalysisBox.delete(id);
      
      // Remove from timeline
      await _removeFromTimeline(analysis);
    }
  }

  // Disease Timeline operations
  Future<DiseaseTimeline?> getDiseaseTimeline(String userId) async {
    await _ensureInitialized();
    return _diseaseTimelineBox.get(userId);
  }

  Future<List<DiseaseTimeline>> getAllDiseaseTimelines() async {
    await _ensureInitialized();
    return _diseaseTimelineBox.values.toList();
  }

  // Image storage operations
  Future<String> saveImage(File imageFile) async {
    await _ensureInitialized();
    
    final bytes = await imageFile.readAsBytes();
    final imageId = DateTime.now().millisecondsSinceEpoch.toString();
    
    await _imagesBox.put(imageId, bytes);
    return imageId;
  }

  Future<File?> getImageFile(String imageId) async {
    await _ensureInitialized();
    
    final bytes = _imagesBox.get(imageId);
    if (bytes == null) return null;
    
    final directory = await getApplicationDocumentsDirectory();
    final imageFile = File('${directory.path}/$imageId.jpg');
    await imageFile.writeAsBytes(bytes);
    
    return imageFile;
  }

  Future<void> deleteImage(String imageId) async {
    await _ensureInitialized();
    await _imagesBox.delete(imageId);
  }

  // Helper methods
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  Future<void> _updateTimeline(DiseaseAnalysis analysis) async {
    final timeline = await getDiseaseTimeline(analysis.userId);
    
    if (timeline == null) {
      // Create new timeline
      final newTimeline = DiseaseTimeline(
        id: analysis.userId,
        userId: analysis.userId,
        analyses: [analysis],
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      await _diseaseTimelineBox.put(analysis.userId, newTimeline);
    } else {
      // Update existing timeline
      final existingAnalyses = List<DiseaseAnalysis>.from(timeline.analyses);
      
      // Remove existing analysis with same ID if it exists
      existingAnalyses.removeWhere((a) => a.id == analysis.id);
      
      // Add the new/updated analysis
      existingAnalyses.add(analysis);
      
      // Sort by analyzedAt
      existingAnalyses.sort((a, b) => a.analyzedAt.compareTo(b.analyzedAt));
      
      final updatedTimeline = DiseaseTimeline(
        id: timeline.id,
        userId: timeline.userId,
        analyses: existingAnalyses,
        createdAt: timeline.createdAt,
        lastUpdated: DateTime.now(),
      );
      
      await _diseaseTimelineBox.put(analysis.userId, updatedTimeline);
    }
  }

  Future<void> _removeFromTimeline(DiseaseAnalysis analysis) async {
    final timeline = await getDiseaseTimeline(analysis.userId);
    
    if (timeline != null) {
      final updatedAnalyses = timeline.analyses
          .where((a) => a.id != analysis.id)
          .toList();
      
      if (updatedAnalyses.isEmpty) {
        // Delete timeline if no analyses left
        await _diseaseTimelineBox.delete(analysis.userId);
      } else {
        // Update timeline
        final updatedTimeline = DiseaseTimeline(
          id: timeline.id,
          userId: timeline.userId,
          analyses: updatedAnalyses,
          createdAt: timeline.createdAt,
          lastUpdated: DateTime.now(),
        );
        
        await _diseaseTimelineBox.put(analysis.userId, updatedTimeline);
      }
    }
  }

  // Cleanup and maintenance
  Future<void> clearAllData() async {
    await _ensureInitialized();
    await _userBox.clear();
    await _diseaseAnalysisBox.clear();
    await _diseaseTimelineBox.clear();
    await _imagesBox.clear();
  }

  Future<void> close() async {
    if (_isInitialized) {
      await _userBox.close();
      await _diseaseAnalysisBox.close();
      await _diseaseTimelineBox.close();
      await _imagesBox.close();
      _isInitialized = false;
    }
  }

  // Get storage statistics
  Future<Map<String, int>> getStorageStats() async {
    await _ensureInitialized();
    return {
      'users': _userBox.length,
      'disease_analyses': _diseaseAnalysisBox.length,
      'disease_timelines': _diseaseTimelineBox.length,
      'images': _imagesBox.length,
    };
  }
}
