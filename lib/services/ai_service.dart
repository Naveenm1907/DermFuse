import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/disease_tracking.dart';
import '../models/analysis_result.dart';

class AIService {
  static const String _apiKey = 'AIzaSyA8MUkO9ctoE-YLKE-m7OfCS-gl-DJlNjI';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent';
  
  // Fallback models to try if the primary one fails (free tier models)
  static const List<String> _fallbackModels = [
    'gemini-2.5-flash-preview-05-20',
    'gemini-2.5-pro-preview-03-25',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-1.5-pro',
  ];
  
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // Test method to verify API connection
  Future<bool> testConnection() async {
    try {
      // Try a simple text-only request first
      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': 'Hello, are you working?',
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 50,
        }
      };

      print('Testing with URL: $_baseUrl');
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': _apiKey,
        },
        body: jsonEncode(requestBody),
      );

      print('Test connection status: ${response.statusCode}');
      print('Test response: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('Test connection error: $e');
      return false;
    }
  }

  // Method to list available models
  Future<void> listAvailableModels() async {
    try {
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models'),
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': _apiKey,
        },
      );

      print('Available models status: ${response.statusCode}');
      print('Available models: ${response.body}');
    } catch (e) {
      print('Error listing models: $e');
    }
  }

  Future<AnalysisResult> analyzeImage(File imageFile, {String? userContext}) async {
    // Convert image to base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    print('Image converted to base64, size: ${base64Image.length} characters');
    
    // Prepare the request payload
    final requestBody = {
      'contents': [
        {
          'parts': [
            {
              'text': _buildPrompt(userContext),
            },
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'topK': 32,
        'topP': 1,
        'maxOutputTokens': 2048,
      }
    };

    // Try primary model first
    try {
      return await _makeRequest(_baseUrl, requestBody, imageFile.path);
    } catch (e) {
      print('Primary model failed: $e');
      
      // Try fallback models
      for (final model in _fallbackModels) {
        try {
          final fallbackUrl = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';
          print('Trying fallback model: $model');
          return await _makeRequest(fallbackUrl, requestBody, imageFile.path);
        } catch (fallbackError) {
          print('Fallback model $model failed: $fallbackError');
          continue;
        }
      }
      
      throw Exception('All Gemini models failed. Last error: $e');
    }
  }

  Future<AnalysisResult> _makeRequest(String url, Map<String, dynamic> requestBody, String imagePath) async {
    print('Making request to: $url');
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'X-goog-api-key': _apiKey,
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return _parseGeminiResponse(data, imagePath);
    } else {
      print('API Error: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to analyze image: ${response.statusCode} - ${response.body}');
    }
  }

  String _buildPrompt(String? userContext) {
    return '''
You are a medical AI assistant specialized in dermatology and skin lesion analysis. 

IMPORTANT: This tool is ONLY for analyzing skin lesions and dermatological conditions. If the provided image does not contain skin, skin lesions, moles, rashes, or any dermatological conditions, you must respond with an error message.

First, examine the image and determine if it contains skin or dermatological content:
- If the image shows skin, moles, lesions, rashes, or dermatological conditions, proceed with analysis
- If the image shows anything else (faces, objects, landscapes, etc.), respond with: {"error": "This image does not appear to contain skin or dermatological content. Please upload an image of skin lesions, moles, or dermatological conditions for analysis."}

If the image contains skin/dermatological content, analyze it and provide your response in the following JSON format:

{
  "diseaseType": "melanoma|basalCellCarcinoma|squamousCellCarcinoma|benignMole|other|unknown",
  "stage": "early|developing|advanced|critical|benign|unknown",
  "confidence": 0.0-1.0,
  "riskScore": 0.0-1.0,
  "description": "Detailed description of the lesion characteristics",
  "symptoms": ["symptom1", "symptom2", "symptom3"],
  "recommendations": ["recommendation1", "recommendation2", "recommendation3"],
  "urgency": "low|medium|high|critical",
  "needsImmediateAttention": true/false
}

Analysis Guidelines:
1. Look for ABCDE criteria (Asymmetry, Border irregularity, Color variation, Diameter, Evolution)
2. Assess lesion characteristics: size, shape, color, texture, borders
3. Consider any visible changes or concerning features
4. Provide confidence score based on image quality and clarity
5. Assess risk level based on lesion characteristics
6. Give specific, actionable recommendations
7. Determine urgency level for medical attention

${userContext != null ? 'Additional Context: $userContext' : ''}

Please provide only the JSON response, no additional text.
''';
  }

  AnalysisResult _parseGeminiResponse(Map<String, dynamic> data, String imagePath) {
    try {
      final content = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (content == null) {
        throw Exception('No analysis content received from Gemini');
      }

      // Extract JSON from the response
      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0) {
        throw Exception('No valid JSON found in response');
      }

      final jsonString = content.substring(jsonStart, jsonEnd);
      final analysisData = jsonDecode(jsonString);

      // Check if the response contains an error (non-skin image)
      if (analysisData.containsKey('error')) {
        throw Exception(analysisData['error']);
      }

      return AnalysisResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: imagePath,
        diseaseType: DiseaseType.values.firstWhere(
          (e) => e.name == analysisData['diseaseType'],
          orElse: () => DiseaseType.unknown,
        ),
        stage: DiseaseStage.values.firstWhere(
          (e) => e.name == analysisData['stage'],
          orElse: () => DiseaseStage.unknown,
        ),
        confidence: (analysisData['confidence'] as num).toDouble(),
        riskScore: (analysisData['riskScore'] as num).toDouble(),
        description: analysisData['description'] ?? 'No description available',
        symptoms: List<String>.from(analysisData['symptoms'] ?? []),
        recommendations: List<String>.from(analysisData['recommendations'] ?? []),
        urgency: analysisData['urgency'] ?? 'low',
        needsImmediateAttention: analysisData['needsImmediateAttention'] ?? false,
        analyzedAt: DateTime.now(),
        rawResponse: data,
      );
    } catch (e) {
      // Check if it's a non-skin image error
      if (e.toString().contains('does not appear to contain skin')) {
        throw Exception('This image does not appear to contain skin or dermatological content. Please upload an image of skin lesions, moles, or dermatological conditions for analysis.');
      }
      
      // Fallback response if parsing fails
      return AnalysisResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: imagePath,
        diseaseType: DiseaseType.unknown,
        stage: DiseaseStage.unknown,
        confidence: 0.0,
        riskScore: 0.0,
        description: 'Analysis failed. Please try again with a clearer image.',
        symptoms: [],
        recommendations: ['Consult a dermatologist for proper evaluation'],
        urgency: 'low',
        needsImmediateAttention: false,
        analyzedAt: DateTime.now(),
        rawResponse: data,
      );
    }
  }

  Future<String> generateExplanation(AnalysisResult result) async {
    try {
      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': '''
Explain the analysis results for a skin lesion in simple, understandable terms:

Disease Type: ${result.diseaseType.name}
Stage: ${result.stage.name}
Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%
Risk Score: ${(result.riskScore * 100).toStringAsFixed(1)}%
Description: ${result.description}
Symptoms: ${result.symptoms.join(', ')}
Recommendations: ${result.recommendations.join(', ')}

Please provide a clear, patient-friendly explanation of what these results mean and what the person should do next.
'''
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'topK': 32,
          'topP': 1,
          'maxOutputTokens': 1024,
        }
      };

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 
               'Unable to generate explanation.';
      } else {
        return 'Unable to generate explanation at this time.';
      }
    } catch (e) {
      return 'Unable to generate explanation at this time.';
    }
  }
}
