import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/disease_tracking.dart';
import '../services/ai_service.dart';
import '../services/hive_storage_service.dart';
import 'photo_plan_screen.dart';

class AnalysisResultsScreen extends StatefulWidget {
  final DiseaseAnalysis analysis;
  final User user;

  const AnalysisResultsScreen({
    super.key,
    required this.analysis,
    required this.user,
  });

  @override
  State<AnalysisResultsScreen> createState() => _AnalysisResultsScreenState();
}

class _AnalysisResultsScreenState extends State<AnalysisResultsScreen> {
  final AIService _aiService = AIService();
  String? _explanation;
  bool _isLoadingExplanation = false;

  @override
  void initState() {
    super.initState();
    _loadExplanation();
  }

  Future<void> _loadExplanation() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingExplanation = true;
    });

    try {
      // Convert the AI response map to a JSON string
      final aiResponseString = jsonEncode(widget.analysis.aiResponse);
      final explanation = await _aiService.generateExplanation(aiResponseString);
      
      if (!mounted) return;
      
      setState(() {
        _explanation = explanation;
        _isLoadingExplanation = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoadingExplanation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareResults,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            const SizedBox(height: 20),
            _buildRiskAlert(),
            const SizedBox(height: 20),
            _buildAnalysisDetails(),
            const SizedBox(height: 20),
            _buildSymptomsSection(),
            const SizedBox(height: 20),
            _buildRecommendationsSection(),
            const SizedBox(height: 20),
            _buildExplanationSection(),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FutureBuilder<File?>(
          future: _getImageFile(widget.analysis.imagePath),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Image.file(
                snapshot.data!,
                fit: BoxFit.cover,
              );
            } else if (snapshot.hasError) {
              return Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.error, size: 64, color: Colors.red),
                ),
              );
            } else {
              return Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildRiskAlert() {
    final riskColor = _getRiskColor(widget.analysis.riskScore);
    final riskLevel = _getRiskLevel(widget.analysis.riskScore);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: riskColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(
            _getRiskIcon(widget.analysis.riskScore),
            color: riskColor,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Risk Level: $riskLevel',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: riskColor,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confidence: ${(widget.analysis.confidence * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
                if (widget.analysis.riskScore > 0.8) ...[
                  const SizedBox(height: 8),
                  Text(
                    '⚠️ Immediate medical attention recommended',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analysis Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Disease Type', widget.analysis.diseaseType.name.toUpperCase()),
            _buildDetailRow('Stage', widget.analysis.stage.name.toUpperCase()),
            _buildDetailRow('Risk Score', '${(widget.analysis.riskScore * 100).toStringAsFixed(0)}%'),
            _buildDetailRow('Confidence', '${(widget.analysis.confidence * 100).toStringAsFixed(0)}%'),
            _buildDetailRow('Analyzed', DateFormat('MMM dd, yyyy - HH:mm').format(widget.analysis.analyzedAt)),
            const SizedBox(height: 12),
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.analysis.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }

  Widget _buildSymptomsSection() {
    if (widget.analysis.symptoms.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Identified Symptoms',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...widget.analysis.symptoms.map((symptom) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      symptom,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommendations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...widget.analysis.recommendations.map((recommendation) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 20, color: Colors.green[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Explanation',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (_isLoadingExplanation)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_explanation != null)
              Text(
                _explanation!,
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Text(
                'Unable to generate explanation at this time.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _scheduleAppointment,
            icon: const Icon(Icons.calendar_today),
            label: const Text('Schedule Doctor Appointment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _viewPhotoPlan,
                icon: const Icon(Icons.schedule),
                label: const Text('Photo Plan'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _trackProgress,
                icon: const Icon(Icons.timeline),
                label: const Text('Track Progress'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _shareResults,
            icon: const Icon(Icons.share),
            label: const Text('Share Results'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
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

  String _getRiskLevel(double riskScore) {
    if (riskScore >= 0.8) return 'HIGH RISK';
    if (riskScore >= 0.6) return 'MEDIUM RISK';
    if (riskScore >= 0.4) return 'LOW RISK';
    return 'VERY LOW RISK';
  }

  IconData _getRiskIcon(double riskScore) {
    if (riskScore >= 0.8) return Icons.warning;
    if (riskScore >= 0.6) return Icons.info;
    if (riskScore >= 0.4) return Icons.check_circle_outline;
    return Icons.check_circle;
  }

  void _scheduleAppointment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Appointment'),
        content: const Text(
          'This feature will help you find and schedule an appointment with a dermatologist in your area.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _viewPhotoPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoPlanScreen(
          analysis: widget.analysis,
          user: widget.user,
        ),
      ),
    );
  }

  void _trackProgress() {
    Navigator.pop(context);
    // This would navigate to the timelapse screen
  }

  void _shareResults() {
    // This would implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing functionality coming soon')),
    );
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
