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

class TimelapseScreen extends StatefulWidget {
  final User user;

  const TimelapseScreen({super.key, required this.user});

  @override
  State<TimelapseScreen> createState() => _TimelapseScreenState();
}

class _TimelapseScreenState extends State<TimelapseScreen> {
  List<DiseaseAnalysis> _analyses = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalyses();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analyses: $e')),
      );
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analyses.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildTimelineHeader(),
                    Expanded(
                      child: Row(
                        children: [
                          _buildImageTimeline(),
                          _buildAnalysisDetails(),
                        ],
                      ),
                    ),
                    _buildProgressChart(),
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
            Icon(
              Icons.timeline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Analysis History',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload photos to start tracking your skin health over time',
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

  Widget _buildTimelineHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.blue[200]!),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.timeline, color: Colors.blue[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Disease Progression Timeline',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                ),
                Text(
                  '${_analyses.length} analyses over time',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue[600],
                      ),
                ),
              ],
            ),
          ),
          if (_analyses.isNotEmpty)
            Text(
              '${_getDaysBetween()}+ days',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageTimeline() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          right: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              border: Border(
                bottom: BorderSide(color: Colors.blue[200]!),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.photo_library, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Images',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _analyses.length,
              itemBuilder: (context, index) {
                final analysis = _analyses[index];
                final isSelected = index == _selectedIndex;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          child: FutureBuilder<File?>(
                            future: _getImageFile(analysis.imagePath),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                return Image.file(
                                  snapshot.data!,
                                  height: 80,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              } else if (snapshot.hasError) {
                                return Container(
                                  height: 80,
                                  width: double.infinity,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.error),
                                );
                              } else {
                                return Container(
                                  height: 80,
                                  width: double.infinity,
                                  color: Colors.grey[300],
                                  child: const CircularProgressIndicator(),
                                );
                              }
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              Text(
                                DateFormat('MMM dd').format(analysis.analyzedAt),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getRiskColor(analysis.riskScore),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getRiskLevel(analysis.riskScore),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisDetails() {
    if (_analyses.isEmpty) return const SizedBox.shrink();

    final analysis = _analyses[_selectedIndex];
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Analysis Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
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
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('View Full Report'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailCard('Disease Type', analysis.diseaseType.name.toUpperCase()),
                    _buildDetailCard('Stage', analysis.stage.name.toUpperCase()),
                    _buildDetailCard('Risk Score', '${(analysis.riskScore * 100).toStringAsFixed(0)}%'),
                    _buildDetailCard('Confidence', '${(analysis.confidence * 100).toStringAsFixed(0)}%'),
                    _buildDetailCard('Date', DateFormat('MMM dd, yyyy - HH:mm').format(analysis.analyzedAt)),
                    const SizedBox(height: 16),
                    _buildDescriptionCard(analysis.description),
                    const SizedBox(height: 16),
                    _buildSymptomsCard(analysis.symptoms),
                    const SizedBox(height: 16),
                    _buildRecommendationsCard(analysis.recommendations),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                '$label:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(String description) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(description),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomsCard(List<String> symptoms) {
    if (symptoms.isEmpty) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Symptoms',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...symptoms.map((symptom) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Expanded(child: Text(symptom)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard(List<String> recommendations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommendations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...recommendations.map((recommendation) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  Expanded(child: Text(recommendation)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
    if (_analyses.length < 2) return const SizedBox.shrink();

    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Risk Progression Over Time',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnalysisChart(analyses: _analyses),
          ),
        ],
      ),
    );
  }

  int _getDaysBetween() {
    if (_analyses.length < 2) return 0;
    
    final first = _analyses.last.analyzedAt;
    final last = _analyses.first.analyzedAt;
    return last.difference(first).inDays;
  }

  Color _getRiskColor(double riskScore) {
    if (riskScore >= 0.8) return Colors.red;
    if (riskScore >= 0.6) return Colors.orange;
    if (riskScore >= 0.4) return Colors.yellow[700]!;
    return Colors.green;
  }

  String _getRiskLevel(double riskScore) {
    if (riskScore >= 0.8) return 'HIGH';
    if (riskScore >= 0.6) return 'MED';
    if (riskScore >= 0.4) return 'LOW';
    return 'SAFE';
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
