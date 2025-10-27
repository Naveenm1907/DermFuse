import '../models/disease_tracking.dart';

class PhotoPlanService {
  static PhotoPlan getPhotoPlan(DiseaseAnalysis analysis) {
    final riskScore = analysis.riskScore;
    
    if (riskScore >= 0.8) {
      return _getHighRiskPlan(analysis);
    } else if (riskScore >= 0.6) {
      return _getMediumRiskPlan(analysis);
    } else if (riskScore >= 0.4) {
      return _getLowRiskPlan(analysis);
    } else {
      return _getVeryLowRiskPlan(analysis);
    }
  }
  
  static PhotoPlan _getHighRiskPlan(DiseaseAnalysis analysis) {
    return PhotoPlan(
      riskLevel: 'HIGH RISK',
      priority: 'URGENT',
      color: 0xFFD32F2F, // Red
      icon: '🚨',
      title: 'Immediate Action Required',
      description: 'Your analysis shows high-risk indicators that require immediate medical attention.',
      
      immediateActions: [
        'Contact a dermatologist within 24-48 hours',
        'Schedule an urgent appointment',
        'Document the lesion with photos daily',
        'Monitor for any rapid changes',
        'Avoid sun exposure to the area',
      ],
      
      photoSchedule: [
        PhotoScheduleItem(
          timeframe: 'Daily',
          duration: 'Next 7 days',
          instructions: 'Take photos at the same time each day under consistent lighting',
          purpose: 'Monitor for rapid changes requiring immediate medical attention',
          priority: 'CRITICAL',
        ),
        PhotoScheduleItem(
          timeframe: 'Every 3 days',
          duration: 'Next 2 weeks',
          instructions: 'Continue monitoring if no immediate changes',
          purpose: 'Track progression before medical appointment',
          priority: 'HIGH',
        ),
      ],
      
      photoInstructions: [
        'Use consistent lighting (natural light preferred)',
        'Take photos from multiple angles',
        'Include a ruler or coin for scale reference',
        'Ensure sharp focus on the lesion',
        'Capture surrounding normal skin for comparison',
        'Take photos at the same time of day',
      ],
      
      nextSteps: [
        'Book dermatologist appointment immediately',
        'Prepare questions about the lesion',
        'Gather family history of skin cancer',
        'Prepare to discuss symptoms and timeline',
        'Consider second opinion if needed',
      ],
      
      warningSigns: [
        'Rapid size increase',
        'Color changes (darkening, multiple colors)',
        'Shape changes (irregular borders)',
        'Bleeding or oozing',
        'Itching or pain',
        'Elevation or thickness changes',
      ],
    );
  }
  
  static PhotoPlan _getMediumRiskPlan(DiseaseAnalysis analysis) {
    return PhotoPlan(
      riskLevel: 'MEDIUM RISK',
      priority: 'HIGH',
      color: 0xFFFF9800, // Orange
      icon: '⚠️',
      title: 'Close Monitoring Required',
      description: 'Your analysis shows concerning features that warrant close monitoring and medical consultation.',
      
      immediateActions: [
        'Schedule dermatologist appointment within 1-2 weeks',
        'Begin regular photo documentation',
        'Monitor for any changes',
        'Protect from sun exposure',
        'Consider mole mapping',
      ],
      
      photoSchedule: [
        PhotoScheduleItem(
          timeframe: 'Every 2-3 days',
          duration: 'Next 2 weeks',
          instructions: 'Take detailed photos with consistent lighting and angles',
          purpose: 'Monitor for changes before medical appointment',
          priority: 'HIGH',
        ),
        PhotoScheduleItem(
          timeframe: 'Weekly',
          duration: 'Next 2 months',
          instructions: 'Continue regular monitoring after initial period',
          purpose: 'Long-term tracking of lesion progression',
          priority: 'MEDIUM',
        ),
      ],
      
      photoInstructions: [
        'Use natural lighting when possible',
        'Maintain consistent distance and angle',
        'Include reference object for scale',
        'Capture clear, focused images',
        'Document any visible changes',
        'Keep consistent time of day',
      ],
      
      nextSteps: [
        'Schedule dermatologist consultation',
        'Prepare detailed history of the lesion',
        'Consider mole mapping services',
        'Learn about skin cancer warning signs',
        'Discuss family history with doctor',
      ],
      
      warningSigns: [
        'Size increase over time',
        'Color variations',
        'Border irregularity',
        'Surface texture changes',
        'New symptoms (itching, pain)',
        'Elevation changes',
      ],
    );
  }
  
  static PhotoPlan _getLowRiskPlan(DiseaseAnalysis analysis) {
    return PhotoPlan(
      riskLevel: 'LOW RISK',
      priority: 'MODERATE',
      color: 0xFFFFC107, // Yellow
      icon: '👀',
      title: 'Regular Monitoring Recommended',
      description: 'Your analysis shows some features of concern that benefit from regular monitoring.',
      
      immediateActions: [
        'Schedule routine dermatologist checkup',
        'Begin monthly photo documentation',
        'Practice sun protection',
        'Learn about skin self-examination',
        'Consider annual skin checks',
      ],
      
      photoSchedule: [
        PhotoScheduleItem(
          timeframe: 'Weekly',
          duration: 'Next month',
          instructions: 'Take photos weekly with consistent setup',
          purpose: 'Establish baseline and monitor for changes',
          priority: 'MEDIUM',
        ),
        PhotoScheduleItem(
          timeframe: 'Monthly',
          duration: 'Next 6 months',
          instructions: 'Continue monthly monitoring',
          purpose: 'Long-term tracking and early detection',
          priority: 'LOW',
        ),
      ],
      
      photoInstructions: [
        'Use good lighting conditions',
        'Maintain consistent positioning',
        'Include scale reference when possible',
        'Keep photos organized by date',
        'Note any visible changes',
        'Use same camera/device when possible',
      ],
      
      nextSteps: [
        'Schedule routine dermatology appointment',
        'Learn proper skin self-examination',
        'Establish regular monitoring routine',
        'Consider mole mapping for tracking',
        'Discuss family history with healthcare provider',
      ],
      
      warningSigns: [
        'Gradual size increase',
        'Color changes',
        'Shape modifications',
        'New symptoms',
        'Surface changes',
        'Border irregularities',
      ],
    );
  }
  
  static PhotoPlan _getVeryLowRiskPlan(DiseaseAnalysis analysis) {
    return PhotoPlan(
      riskLevel: 'VERY LOW RISK',
      priority: 'ROUTINE',
      color: 0xFF4CAF50, // Green
      icon: '✅',
      title: 'Routine Monitoring',
      description: 'Your analysis shows benign characteristics. Continue regular skin health monitoring.',
      
      immediateActions: [
        'Continue regular skin self-examination',
        'Maintain sun protection habits',
        'Schedule annual dermatology checkup',
        'Keep general skin health records',
        'Stay aware of any changes',
      ],
      
      photoSchedule: [
        PhotoScheduleItem(
          timeframe: 'Monthly',
          duration: 'Next 6 months',
          instructions: 'Take photos monthly for general monitoring',
          purpose: 'Maintain awareness and detect any future changes',
          priority: 'LOW',
        ),
        PhotoScheduleItem(
          timeframe: 'Every 3 months',
          duration: 'Ongoing',
          instructions: 'Continue quarterly monitoring',
          purpose: 'Long-term health tracking',
          priority: 'LOW',
        ),
      ],
      
      photoInstructions: [
        'Use adequate lighting',
        'Maintain consistent approach',
        'Keep photos organized',
        'Note any changes over time',
        'Use reliable camera/device',
        'Store photos securely',
      ],
      
      nextSteps: [
        'Schedule annual skin checkup',
        'Maintain sun protection routine',
        'Continue self-examination habits',
        'Stay informed about skin health',
        'Consider family history factors',
      ],
      
      warningSigns: [
        'Any size increase',
        'Color changes',
        'Shape modifications',
        'New symptoms',
        'Surface changes',
        'Any concerning features',
      ],
    );
  }
  
  static List<String> getGeneralPhotoTips() {
    return [
      'Use natural lighting when possible',
      'Avoid shadows and reflections',
      'Keep camera steady for sharp images',
      'Include some surrounding normal skin',
      'Use consistent distance and angle',
      'Take photos at the same time of day',
      'Include scale reference (coin, ruler)',
      'Ensure good focus on the lesion',
      'Avoid makeup or lotions on the area',
      'Keep photos organized by date',
    ];
  }
  
  static String getNextPhotoDate(PhotoScheduleItem schedule) {
    final now = DateTime.now();
    switch (schedule.timeframe) {
      case 'Daily':
        return 'Tomorrow (${now.add(const Duration(days: 1)).day}/${now.add(const Duration(days: 1)).month})';
      case 'Every 2-3 days':
        return 'In 2-3 days (${now.add(const Duration(days: 3)).day}/${now.add(const Duration(days: 3)).month})';
      case 'Weekly':
        return 'Next week (${now.add(const Duration(days: 7)).day}/${now.add(const Duration(days: 7)).month})';
      case 'Monthly':
        return 'Next month (${now.add(const Duration(days: 30)).day}/${now.add(const Duration(days: 30)).month})';
      case 'Every 3 months':
        return 'In 3 months (${now.add(const Duration(days: 90)).day}/${now.add(const Duration(days: 90)).month})';
      default:
        return 'As recommended by your plan';
    }
  }
}

class PhotoPlan {
  final String riskLevel;
  final String priority;
  final int color;
  final String icon;
  final String title;
  final String description;
  final List<String> immediateActions;
  final List<PhotoScheduleItem> photoSchedule;
  final List<String> photoInstructions;
  final List<String> nextSteps;
  final List<String> warningSigns;
  
  PhotoPlan({
    required this.riskLevel,
    required this.priority,
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
    required this.immediateActions,
    required this.photoSchedule,
    required this.photoInstructions,
    required this.nextSteps,
    required this.warningSigns,
  });
}

class PhotoScheduleItem {
  final String timeframe;
  final String duration;
  final String instructions;
  final String purpose;
  final String priority;
  
  PhotoScheduleItem({
    required this.timeframe,
    required this.duration,
    required this.instructions,
    required this.purpose,
    required this.priority,
  });
}
