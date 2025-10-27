import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/hive_storage_service.dart';
import 'screens/user_setup_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive storage
  final hiveService = HiveStorageService();
  await hiveService.init();
  
  runApp(DermFuseApp(hiveService: hiveService));
}

class DermFuseApp extends StatelessWidget {
  final HiveStorageService hiveService;
  
  const DermFuseApp({super.key, required this.hiveService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<HiveStorageService>(create: (_) => hiveService),
      ],
      child: MaterialApp(
        title: 'DermFuse - AI Skin Health Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
          ),
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserAndNavigate();
  }

  Future<void> _checkUserAndNavigate() async {
    // Wait for splash screen to be visible
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      final hiveService = Provider.of<HiveStorageService>(context, listen: false);
      final users = await hiveService.getAllUsers();
      
      if (mounted) {
        if (users.isNotEmpty) {
          // User exists, go to dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(user: users.first),
            ),
          );
        } else {
          // No user, go to setup
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const UserSetupScreen(),
            ),
          );
        }
      }
    } catch (e) {
      // Error loading users, go to setup
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const UserSetupScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[600],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.health_and_safety,
                size: 80,
                color: Colors.blue[600],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'DermFuse',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI-Powered Skin Health Tracker',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
