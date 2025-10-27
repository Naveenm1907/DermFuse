import 'database_service.dart';
import 'hive_storage_service.dart';

class MigrationService {
  static Future<void> migrateFromSQLiteToHive() async {
    print('Starting migration from SQLite to Hive...');
    
    try {
      // Initialize services
      final sqliteService = DatabaseService();
      final hiveService = HiveStorageService();
      await hiveService.init();
      
      // Migrate users
      print('Migrating users...');
      final users = await sqliteService.getAllUsers();
      for (final user in users) {
        await hiveService.saveUser(user);
        print('Migrated user: ${user.name}');
      }
      
      // Migrate disease analyses
      print('Migrating disease analyses...');
      final analyses = await sqliteService.getAllDiseaseAnalyses();
      for (final analysis in analyses) {
        await hiveService.createDiseaseAnalysis(analysis);
        print('Migrated analysis: ${analysis.id}');
      }
      
      // Disease timelines will be automatically created when analyses are added
      print('Disease timelines will be auto-created from analyses...');
      
      print('Migration completed successfully!');
      print('Migrated: ${users.length} users, ${analyses.length} analyses');
      
    } catch (e) {
      print('Migration failed: $e');
      rethrow;
    }
  }
  
  static Future<bool> hasSQLiteData() async {
    try {
      final sqliteService = DatabaseService();
      final users = await sqliteService.getAllUsers();
      return users.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  static Future<Map<String, int>> getMigrationStats() async {
    try {
      final sqliteService = DatabaseService();
      final users = await sqliteService.getAllUsers();
      final analyses = await sqliteService.getAllDiseaseAnalyses();
      
      return {
        'users': users.length,
        'analyses': analyses.length,
        'timelines': 0, // Will be auto-created
      };
    } catch (e) {
      return {
        'users': 0,
        'analyses': 0,
        'timelines': 0,
      };
    }
  }
}
