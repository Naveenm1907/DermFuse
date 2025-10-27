import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/disease_tracking.dart';
import '../services/ai_service.dart';
import '../services/hive_storage_service.dart';
import 'analysis_results_screen.dart';

class PhotoUploadScreen extends StatefulWidget {
  final User user;

  const PhotoUploadScreen({super.key, required this.user});

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final AIService _aiService = AIService();
  
  File? _selectedImage;
  bool _isAnalyzing = false;
  String? _userContext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyze Photo'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructions(),
            const SizedBox(height: 20),
            _buildImagePreview(),
            const SizedBox(height: 20),
            _buildContextInput(),
            const SizedBox(height: 20),
            _buildActionButtons(),
            if (_selectedImage != null) ...[
              const SizedBox(height: 20),
              _buildAnalyzeButton(),
            ],
            if (_isAnalyzing) ...[
              const SizedBox(height: 20),
              _buildAnalysisProgress(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                'Photo Analysis Instructions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'For best results, please ensure:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text('• Good lighting on the skin area'),
          const Text('• Clear, focused image of the lesion'),
          const Text('• Minimal shadows or reflections'),
          const Text('• Include some surrounding normal skin'),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedImage != null ? Colors.blue[300]! : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: _selectedImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_camera,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No image selected',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the camera button to take a photo',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ),
    );
  }

  Widget _buildContextInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Context (Optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'e.g., "This mole has been growing recently" or "Family history of skin cancer"',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          maxLines: 3,
          onChanged: (value) {
            setState(() {
              _userContext = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _takePicture,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isAnalyzing ? null : _analyzeImage,
        icon: _isAnalyzing 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.analytics),
        label: Text(
          _isAnalyzing ? 'Analyzing...' : 'Analyze Photo',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Analyzing your photo...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few moments',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _takePicture() async {
    try {
      // Check camera permission
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        _showErrorSnackBar('Camera permission is required');
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error taking picture: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      _showErrorSnackBar('Please select an image first');
      return;
    }

    if (!mounted) return;
    
    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Save image to Hive storage first
      final hiveService = Provider.of<HiveStorageService>(context, listen: false);
      final imageId = await hiveService.saveImage(_selectedImage!);
      print('Image saved to Hive storage with ID: $imageId');

      // Analyze image with AI
      final result = await _aiService.analyzeImage(
        _selectedImage!,
        userContext: _userContext,
      );

      // Convert AnalysisResult to DiseaseAnalysis with Hive image ID
      final analysis = DiseaseAnalysis(
        id: result.id,
        userId: widget.user.id,
        imagePath: imageId, // Use Hive image ID instead of file path
        diseaseType: result.diseaseType,
        stage: result.stage,
        confidence: result.confidence,
        riskScore: result.riskScore,
        description: result.description,
        symptoms: result.symptoms,
        recommendations: result.recommendations,
        analyzedAt: result.analyzedAt,
        aiResponse: result.rawResponse, // AI response data
      );

      // Save analysis to Hive storage
      try {
        final savedId = await hiveService.createDiseaseAnalysis(analysis);
        print('Analysis saved to Hive storage with ID: $savedId');
      } catch (dbError) {
        print('Hive storage error: $dbError');
        throw Exception('Failed to save analysis to storage: $dbError');
      }

      // Navigate to results screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AnalysisResultsScreen(
              analysis: analysis,
              user: widget.user,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isAnalyzing = false;
      });
      
      // Check if it's a non-skin image error
      if (e.toString().contains('does not appear to contain skin')) {
        _showNonSkinImageDialog();
      } else {
        _showErrorSnackBar('Analysis failed: $e');
      }
    }
  }

  void _showNonSkinImageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[600]),
            const SizedBox(width: 8),
            const Text('Invalid Image Type'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This image does not appear to contain skin or dermatological content.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please upload an image of:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Skin lesions or moles'),
            const Text('• Rashes or skin conditions'),
            const Text('• Dermatological abnormalities'),
            const Text('• Areas of concern on skin'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For best results, ensure good lighting and clear focus on the skin area.',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedImage = null;
              });
            },
            child: const Text('Upload Different Image'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
      ),
    );
  }

}
