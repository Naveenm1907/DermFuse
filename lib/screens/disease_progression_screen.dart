import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/disease_tracking.dart';
import '../services/hive_storage_service.dart';
import '../widgets/analysis_chart.dart';
import 'analysis_results_screen.dart';
import 'photo_upload_screen.dart';

class DiseaseProgressionScreen extends StatefulWidget {
  final User user;

  const DiseaseProgressionScreen({super.key, required this.user});

  @override
  State<DiseaseProgressionScreen> createState() => _DiseaseProgressionScreenState();
}

class _DiseaseProgressionScreenState extends State<DiseaseProgressionScreen> with SingleTickerProviderStateMixin {
  List<DiseaseAnalysis> _analyses = [];
  bool _isLoading = true;
  late TabController _tabController;
  
  DiseaseAnalysis? _comparisonAnalysis1;
  DiseaseAnalysis? _comparisonAnalysis2;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalyses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyses() async {
    try {
      final hiveService = Provider.of<HiveStorageService>(context, listen: false);
      final analyses = await hiveService.getDiseaseAnalysesByUser(widget.user.id);
      setState(() {
        _analyses = analyses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analyses: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Progression'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PhotoUploadScreen(user: widget.user),
                ),
              ).then((_) {
                // Refresh data when returning from photo upload
                _loadAnalyses();
              });
            },
            tooltip: 'Upload New Photo',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
            Tab(icon: Icon(Icons.compare_arrows), text: 'Compare'),
            Tab(icon: Icon(Icons.show_chart), text: 'Trends'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analyses.isEmpty
              ? _buildEmptyState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTimelineView(),
                    _buildComparisonView(),
                    _buildTrendsView(),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Disease History',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload and analyze photos to track disease progression over time',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhotoUploadScreen(user: widget.user),
                  ),
                ).then((_) {
                  // Refresh data when returning from photo upload
                  _loadAnalyses();
                });
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Upload First Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineView() {
    final sortedAnalyses = List<DiseaseAnalysis>.from(_analyses);
    sortedAnalyses.sort((a, b) => b.analyzedAt.compareTo(a.analyzedAt));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedAnalyses.length,
      itemBuilder: (context, index) {
        final analysis = sortedAnalyses[index];
        final isFirst = index == 0;
        final isLast = index == sortedAnalyses.length - 1;

        return _buildTimelineItem(analysis, isFirst, isLast, index);
      },
    );
  }

  Widget _buildTimelineItem(DiseaseAnalysis analysis, bool isFirst, bool isLast, int index) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          SizedBox(
            width: 60,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.blue[300],
                    ),
                  ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getRiskColor(analysis.riskScore),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.blue[300],
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(left: 8, bottom: 16),
              child: InkWell(
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
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FutureBuilder<File?>(
                              future: _getImageFile(analysis.imagePath),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  return Image.file(
                                    snapshot.data!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  );
                                } else if (snapshot.hasError) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.error),
                                  );
                                } else {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child: const CircularProgressIndicator(),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  analysis.diseaseType.name.toUpperCase(),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Stage: ${analysis.stage.name}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getRiskColor(analysis.riskScore),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Risk: ${(analysis.riskScore * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${(analysis.confidence * 100).toStringAsFixed(0)}% confidence',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('MMM dd, yyyy - HH:mm').format(analysis.analyzedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonView() {
    if (_analyses.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.compare_arrows, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Need More Analyses',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload at least 2 analyses to compare disease progression',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[500],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Select two analyses to compare',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildComparisonSelector(1),
              ),
              Expanded(
                child: _buildComparisonSelector(2),
              ),
            ],
          ),
        ),
        if (_comparisonAnalysis1 != null && _comparisonAnalysis2 != null)
          _buildComparisonResults(),
      ],
    );
  }

  Widget _buildComparisonSelector(int selectorNumber) {
    final selectedAnalysis = selectorNumber == 1 ? _comparisonAnalysis1 : _comparisonAnalysis2;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            'Analysis $selectorNumber',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _analyses.length,
            itemBuilder: (context, index) {
              final analysis = _analyses[index];
              final isSelected = selectedAnalysis?.id == analysis.id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: isSelected ? Colors.blue[50] : null,
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: FutureBuilder<File?>(
                      future: _getImageFile(analysis.imagePath),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Image.file(
                            snapshot.data!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          );
                        } else {
                          return Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 20),
                          );
                        }
                      },
                    ),
                  ),
                  title: Text(
                    DateFormat('MMM dd').format(analysis.analyzedAt),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                  subtitle: Text('Risk: ${(analysis.riskScore * 100).toStringAsFixed(0)}%'),
                  selected: isSelected,
                  onTap: () {
                    setState(() {
                      if (selectorNumber == 1) {
                        _comparisonAnalysis1 = analysis;
                      } else {
                        _comparisonAnalysis2 = analysis;
                      }
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonResults() {
    final analysis1 = _comparisonAnalysis1!;
    final analysis2 = _comparisonAnalysis2!;
    
    final riskChange = analysis2.riskScore - analysis1.riskScore;
    final confidenceChange = analysis2.confidence - analysis1.confidence;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Text(
            'Comparison Results',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildComparisonMetric(
                'Risk Change',
                '${riskChange > 0 ? '+' : ''}${(riskChange * 100).toStringAsFixed(1)}%',
                riskChange > 0 ? Colors.red : Colors.green,
                riskChange > 0 ? Icons.trending_up : Icons.trending_down,
              ),
              _buildComparisonMetric(
                'Confidence Change',
                '${confidenceChange > 0 ? '+' : ''}${(confidenceChange * 100).toStringAsFixed(1)}%',
                confidenceChange > 0 ? Colors.green : Colors.orange,
                confidenceChange > 0 ? Icons.trending_up : Icons.trending_down,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonMetric(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildTrendsView() {
    if (_analyses.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Need More Data',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload at least 2 analyses to see trends',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[500],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final sortedAnalyses = List<DiseaseAnalysis>.from(_analyses);
    sortedAnalyses.sort((a, b) => a.analyzedAt.compareTo(b.analyzedAt));

    final avgRisk = _analyses.map((a) => a.riskScore).reduce((a, b) => a + b) / _analyses.length;
    final avgConfidence = _analyses.map((a) => a.confidence).reduce((a, b) => a + b) / _analyses.length;
    final trend = sortedAnalyses.last.riskScore - sortedAnalyses.first.riskScore;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrendCard('Overall Trend', trend),
          const SizedBox(height: 16),
          _buildStatCard('Average Risk', '${(avgRisk * 100).toStringAsFixed(1)}%', _getRiskColor(avgRisk)),
          const SizedBox(height: 16),
          _buildStatCard('Average Confidence', '${(avgConfidence * 100).toStringAsFixed(1)}%', Colors.blue),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Risk Progression Chart',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: AnalysisChart(analyses: sortedAnalyses),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(String title, double trend) {
    final isIncreasing = trend > 0;
    final color = isIncreasing ? Colors.red : Colors.green;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isIncreasing ? Icons.trending_up : Icons.trending_down,
              size: 48,
              color: color,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isIncreasing ? '+' : ''}${(trend * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    isIncreasing ? 'Risk increasing over time' : 'Risk decreasing over time',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.analytics, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(double riskScore) {
    if (riskScore >= 0.8) return Colors.red;
    if (riskScore >= 0.6) return Colors.orange;
    if (riskScore >= 0.4) return Colors.yellow[700]!;
    return Colors.green;
  }

  Future<File?> _getImageFile(String imagePath) async {
    try {
      final hiveService = Provider.of<HiveStorageService>(context, listen: false);
      return await hiveService.getImageFile(imagePath);
    } catch (e) {
      print('Error loading image: $e');
      return null;
    }
  }
}

