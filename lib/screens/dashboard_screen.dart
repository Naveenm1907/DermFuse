import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/disease_tracking.dart';
import '../services/hive_storage_service.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/analysis_chart.dart';
import 'photo_upload_screen.dart';
import 'timelapse_screen.dart';
import 'disease_progression_screen.dart';
import 'analysis_results_screen.dart';

class DashboardScreen extends StatefulWidget {
  final User user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<DiseaseAnalysis> _recentAnalyses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentAnalyses();
  }

  Future<void> _loadRecentAnalyses() async {
    try {
      final hiveService = Provider.of<HiveStorageService>(context, listen: false);
      final analyses = await hiveService.getDiseaseAnalysesByUser(widget.user.id);
      setState(() {
        _recentAnalyses = analyses.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analyses: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Welcome, ${widget.user.name}'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecentAnalyses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRecentAnalyses,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    _buildRecentAnalyses(),
                    const SizedBox(height: 20),
                    _buildHealthOverview(),
                    const SizedBox(height: 20),
                    _buildRiskTrends(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PhotoUploadScreen(user: widget.user),
            ),
          ).then((_) => _loadRecentAnalyses());
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text('Analyze Photo'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DermFuse Dashboard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your skin health with AI-powered analysis',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.health_and_safety, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_recentAnalyses.length} analyses completed',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DashboardCard(
                title: 'New Analysis',
                subtitle: 'Upload a photo',
                icon: Icons.camera_alt,
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhotoUploadScreen(user: widget.user),
                    ),
                  ).then((_) => _loadRecentAnalyses());
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardCard(
                title: 'Track Progress',
                subtitle: 'See progression',
                icon: Icons.timeline,
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DiseaseProgressionScreen(user: widget.user),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentAnalyses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Analyses',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (_recentAnalyses.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TimelapseScreen(user: widget.user),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentAnalyses.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(Icons.photo_camera, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No analyses yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload your first photo to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ),
          )
        else
          ..._recentAnalyses.map((analysis) => _buildAnalysisCard(analysis)),
      ],
    );
  }

  Widget _buildAnalysisCard(DiseaseAnalysis analysis) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRiskColor(analysis.riskScore),
          child: Icon(
            _getDiseaseIcon(analysis.diseaseType),
            color: Colors.white,
          ),
        ),
        title: Text(analysis.diseaseType.name.toUpperCase()),
        subtitle: Text(
          '${analysis.stage.name} • ${(analysis.confidence * 100).toStringAsFixed(0)}% confidence',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateFormat('MMM dd').format(analysis.analyzedAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              _getRiskLevel(analysis.riskScore),
              style: TextStyle(
                color: _getRiskColor(analysis.riskScore),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnalysisResultsScreen(
                analysis: analysis,
                user: widget.user,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHealthOverview() {
    if (_recentAnalyses.isEmpty) return const SizedBox.shrink();

    final highRiskCount = _recentAnalyses.where((a) => a.riskScore > 0.7).length;
    final totalCount = _recentAnalyses.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DashboardCard(
                title: 'Total Analyses',
                subtitle: '$totalCount completed',
                icon: Icons.analytics,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardCard(
                title: 'High Risk',
                subtitle: '$highRiskCount detected',
                icon: Icons.warning,
                color: highRiskCount > 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRiskTrends() {
    if (_recentAnalyses.length < 2) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Risk Trends',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AnalysisChart(analyses: _recentAnalyses),
        ),
      ],
    );
  }

  Color _getRiskColor(double riskScore) {
    if (riskScore >= 0.8) return Colors.red;
    if (riskScore >= 0.6) return Colors.orange;
    if (riskScore >= 0.4) return Colors.yellow[700]!;
    return Colors.green;
  }

  IconData _getDiseaseIcon(DiseaseType type) {
    switch (type) {
      case DiseaseType.melanoma:
        return Icons.warning;
      case DiseaseType.basalCellCarcinoma:
        return Icons.medical_services;
      case DiseaseType.squamousCellCarcinoma:
        return Icons.medical_services;
      case DiseaseType.benignMole:
        return Icons.check_circle;
      case DiseaseType.other:
        return Icons.help;
      case DiseaseType.unknown:
        return Icons.help_outline;
    }
  }

  String _getRiskLevel(double riskScore) {
    if (riskScore >= 0.8) return 'HIGH';
    if (riskScore >= 0.6) return 'MED';
    if (riskScore >= 0.4) return 'LOW';
    return 'SAFE';
  }
}
