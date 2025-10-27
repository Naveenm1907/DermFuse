import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/disease_tracking.dart';
import '../services/photo_plan_service.dart';
import 'photo_upload_screen.dart';

class PhotoPlanScreen extends StatefulWidget {
  final DiseaseAnalysis analysis;
  final User user;

  const PhotoPlanScreen({
    super.key,
    required this.analysis,
    required this.user,
  });

  @override
  State<PhotoPlanScreen> createState() => _PhotoPlanScreenState();
}

class _PhotoPlanScreenState extends State<PhotoPlanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PhotoPlan _photoPlan;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _photoPlan = PhotoPlanService.getPhotoPlan(widget.analysis);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Photo Plan'),
        backgroundColor: Color(_photoPlan.color),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.schedule), text: 'Schedule'),
            Tab(icon: Icon(Icons.camera_alt), text: 'Instructions'),
            Tab(icon: Icon(Icons.warning), text: 'Warning Signs'),
            Tab(icon: Icon(Icons.next_plan), text: 'Next Steps'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildRiskAlert(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildScheduleTab(),
                _buildInstructionsTab(),
                _buildWarningSignsTab(),
                _buildNextStepsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploadNextPhoto,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Upload Next Photo'),
        backgroundColor: Color(_photoPlan.color),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildRiskAlert() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(_photoPlan.color).withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Color(_photoPlan.color), width: 2),
        ),
      ),
      child: Row(
        children: [
          Text(
            _photoPlan.icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _photoPlan.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Color(_photoPlan.color),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _photoPlan.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photo Schedule',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ..._photoPlan.photoSchedule.map((schedule) => _buildScheduleCard(schedule)),
          const SizedBox(height: 24),
          _buildImmediateActionsCard(),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(PhotoScheduleItem schedule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(schedule.priority),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    schedule.priority,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  schedule.timeframe,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Duration: ${schedule.duration}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Next Photo: ${PhotoPlanService.getNextPhotoDate(schedule)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Color(_photoPlan.color),
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Instructions:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(schedule.instructions),
            const SizedBox(height: 8),
            Text(
              'Purpose:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(schedule.purpose),
          ],
        ),
      ),
    );
  }

  Widget _buildImmediateActionsCard() {
    return Card(
      color: Color(_photoPlan.color).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Immediate Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Color(_photoPlan.color),
                  ),
            ),
            const SizedBox(height: 12),
            ..._photoPlan.immediateActions.map((action) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Color(_photoPlan.color),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(action)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photo Instructions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'For Best Results:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ..._photoPlan.photoInstructions.map((instruction) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Color(_photoPlan.color),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(instruction)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'General Tips:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...PhotoPlanService.getGeneralPhotoTips().map((tip) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 14,
                              color: Colors.amber[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningSignsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Warning Signs to Watch For',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Seek Immediate Medical Attention If:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._photoPlan.warningSigns.map((sign) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.priority_high,
                              size: 16,
                              color: Colors.red[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(sign)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remember:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'If you notice any of these warning signs, contact your healthcare provider immediately. Early detection and treatment are crucial for the best outcomes.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next Steps',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended Actions:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ..._photoPlan.nextSteps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Color(_photoPlan.color),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(step)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Color(_photoPlan.color).withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stay Informed:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Continue using DermFuse to track your skin health. Regular monitoring helps catch changes early and provides valuable information for your healthcare provider.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'CRITICAL':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
        return Colors.blue;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _uploadNextPhoto() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoUploadScreen(user: widget.user),
      ),
    );
  }
}
