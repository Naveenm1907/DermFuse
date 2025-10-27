import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';
import '../models/disease_tracking.dart';

class AIService {
  static const String _apiKey = 'AIzaSyA8MUkO9ctoE-YLKE-m7OfCS-gl-DJlNjI';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  
  // Fallback models to try if the primary one fails (free tier models)
  static const List<String> _fallbackModels = [
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-pro',
  ];
  
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // Create a custom HTTP client with better network handling
  http.Client _createHttpClient() {
    final client = http.Client();
    return client;
  }

  // Method to make HTTP requests with retry logic and better error handling
  Future<http.Response> _makeHttpRequest(
    String url,
    Map<String, dynamic> body, {
    int maxRetries = 3,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    int retryCount = 0;
    Exception? lastException;

    while (retryCount < maxRetries) {
      try {
        final client = _createHttpClient();
        
        print('Attempt ${retryCount + 1}/$maxRetries: Making request to $url');
        
        final request = http.Request('POST', Uri.parse(url));
        request.headers.addAll({
          'Content-Type': 'application/json; charset=UTF-8',
          'X-goog-api-key': _apiKey,
          'Accept': 'application/json',
          'User-Agent': 'DermFuse/1.0',
        });
        request.body = jsonEncode(body);

        final streamedResponse = await client.send(request).timeout(
          timeout,
          onTimeout: () {
            throw TimeoutException('Request timeout after ${timeout.inSeconds} seconds');
          },
        );

        final response = await http.Response.fromStream(streamedResponse);
        client.close();

        print('Response status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          return response;
        } else if (response.statusCode >= 400 && response.statusCode < 500) {
          // Client error - don't retry
          print('Client error: ${response.statusCode} - ${response.body}');
          throw Exception('API error: ${response.statusCode} - ${response.body}');
        } else {
          // Server error - retry
          print('Server error: ${response.statusCode} - ${response.body}');
          lastException = Exception('Server error: ${response.statusCode}');
        }
      } on TimeoutException catch (e) {
        print('Timeout error (attempt ${retryCount + 1}): $e');
        lastException = e;
      } on SocketException catch (e) {
        print('Network error (attempt ${retryCount + 1}): $e');
        lastException = e;
        
        // Check if it's a DNS resolution error
        if (e.osError?.errorCode == 7 || e.message.contains('Failed host lookup')) {
          print('DNS resolution error detected. Trying alternative approach...');
          // Wait longer before retry for DNS issues
          await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        }
      } on Exception catch (e) {
        print('General error (attempt ${retryCount + 1}): $e');
        lastException = e;
      }

      retryCount++;
      
      if (retryCount < maxRetries) {
        // Exponential backoff
        final waitTime = Duration(seconds: 2 * retryCount);
        print('Waiting ${waitTime.inSeconds} seconds before retry...');
        await Future.delayed(waitTime);
      }
    }

    throw lastException ?? Exception('Failed after $maxRetries attempts');
  }

  Future<AnalysisResult> analyzeImage(File imageFile, {String? userContext}) async {
    try {
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
          'temperature': 0.4,
          'topK': 32,
          'topP': 0.95,
          'maxOutputTokens': 2048,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_NONE',
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_NONE',
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_NONE',
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_NONE',
          },
        ],
      };

      print('Making request to: $_baseUrl');
      
      // Try with the primary model first
      try {
        final response = await _makeHttpRequest(_baseUrl, requestBody);
        return _parseAIResponse(response);
      } catch (e) {
        print('Primary model failed: $e');
        
        // Try fallback models
        for (final model in _fallbackModels) {
          try {
            final fallbackUrl = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';
            print('Trying fallback model: $model');
            
            final response = await _makeHttpRequest(fallbackUrl, requestBody);
            return _parseAIResponse(response);
          } catch (e) {
            print('Fallback model $model failed: $e');
            continue;
          }
        }
        
        throw Exception('All AI models failed. Last error: $e');
      }
    } catch (e) {
      print('Error in analyzeImage: $e');
      throw Exception('Failed to analyze image: $e');
    }
  }

  AnalysisResult _parseAIResponse(http.Response response) {
    try {
      if (response.statusCode != 200) {
        throw Exception('AI API error: ${response.statusCode} - ${response.body}');
      }

      final data = jsonDecode(response.body);
      print('AI response data: $data');

      // Check for prompt feedback (safety filters)
      if (data['promptFeedback'] != null) {
        final promptFeedback = data['promptFeedback'];
        print('Prompt feedback: $promptFeedback');
        
        if (promptFeedback['blockReason'] != null) {
          throw Exception('Request blocked by safety filters: ${promptFeedback['blockReason']}');
        }
      }

      if (data['candidates'] == null || (data['candidates'] as List).isEmpty) {
        // Check if there's a finishReason that explains why there are no candidates
        if (data['promptFeedback'] != null) {
          throw Exception('No candidates returned. Prompt feedback: ${data['promptFeedback']}');
        }
        throw Exception('No response from AI. Full response: ${response.body}');
      }

      final candidate = data['candidates'][0];
      if (candidate == null) {
        throw Exception('Empty candidate in response');
      }

      // Check finish reason
      if (candidate['finishReason'] != null && candidate['finishReason'] != 'STOP') {
        print('Warning: Finish reason is ${candidate['finishReason']}');
        if (candidate['finishReason'] == 'SAFETY') {
          throw Exception('Response blocked by safety filters');
        }
      }

      final content = candidate['content'];
      if (content == null) {
        throw Exception('No content in candidate. Finish reason: ${candidate['finishReason']}, Full candidate: $candidate');
      }

      final parts = content['parts'];
      if (parts == null || (parts as List).isEmpty) {
        throw Exception('No parts in content. Content: $content');
      }

      final textPart = parts[0];
      if (textPart == null || textPart['text'] == null) {
        throw Exception('No text in first part. Part: $textPart');
      }

      final text = textPart['text'] as String;
      print('AI response text (length: ${text.length}): ${text.substring(0, text.length > 500 ? 500 : text.length)}...');

      return _parseAnalysisText(text);
    } catch (e) {
      print('Error parsing AI response: $e');
      print('Full response body: ${response.body}');
      rethrow;
    }
  }

  AnalysisResult _parseAnalysisText(String text) {
    try {
      if (text.isEmpty) {
        throw Exception('Empty response text from AI');
      }

      // Extract JSON from markdown code blocks if present
      String jsonText = text.trim();
      
      // Remove markdown code blocks
      if (jsonText.contains('```json')) {
        final start = jsonText.indexOf('```json') + 7;
        final end = jsonText.lastIndexOf('```');
        if (end > start) {
          jsonText = jsonText.substring(start, end).trim();
        }
      } else if (jsonText.contains('```')) {
        final start = jsonText.indexOf('```') + 3;
        final end = jsonText.lastIndexOf('```');
        if (end > start) {
          jsonText = jsonText.substring(start, end).trim();
        }
      }

      // Try to find JSON object in the text
      final jsonStart = jsonText.indexOf('{');
      final jsonEnd = jsonText.lastIndexOf('}');
      
      if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
        throw Exception('No valid JSON object found in response. Text: $jsonText');
      }
      
      jsonText = jsonText.substring(jsonStart, jsonEnd + 1);

      print('Parsing JSON: $jsonText');
      
      if (jsonText.isEmpty || jsonText == '{}') {
        throw Exception('Empty JSON object in response');
      }

      final analysisJson = jsonDecode(jsonText) as Map<String, dynamic>;

      // Check if it's an error response (non-skin image)
      if (analysisJson.containsKey('error')) {
        final errorMessage = analysisJson['error'];
        throw Exception(errorMessage ?? 'Unknown error from AI');
      }

      // Validate required fields
      if (!analysisJson.containsKey('diseaseType')) {
        throw Exception('Missing required field: diseaseType. Response: $analysisJson');
      }
      if (!analysisJson.containsKey('stage')) {
        throw Exception('Missing required field: stage. Response: $analysisJson');
      }

      // Create AnalysisResult with proper defaults for missing fields
      return AnalysisResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: '', // Will be set by the caller
        diseaseType: DiseaseType.values.firstWhere(
          (e) => e.name == analysisJson['diseaseType'],
          orElse: () => DiseaseType.unknown,
        ),
        stage: DiseaseStage.values.firstWhere(
          (e) => e.name == analysisJson['stage'],
          orElse: () => DiseaseStage.unknown,
        ),
        confidence: (analysisJson['confidence'] as num).toDouble(),
        riskScore: (analysisJson['riskScore'] as num).toDouble(),
        description: analysisJson['description'] as String,
        symptoms: List<String>.from(analysisJson['symptoms'] as List),
        recommendations: List<String>.from(analysisJson['recommendations'] as List),
        urgency: analysisJson['urgency'] as String,
        needsImmediateAttention: analysisJson['needsImmediateAttention'] as bool,
        analyzedAt: DateTime.now(),
        rawResponse: analysisJson,
      );
    } catch (e) {
      print('Error parsing AI response text: $e');
      print('Raw text: $text');
      throw Exception('Failed to parse AI response: $e');
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

  Future<String> generateExplanation(String aiResponse) async {
    try {
      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': '''
Based on this dermatological analysis, provide a clear, compassionate explanation for the patient in 2-3 paragraphs:

$aiResponse

Focus on:
1. What the analysis found
2. What it means for the patient
3. Next steps they should take

Use simple, non-technical language that's easy to understand.
''',
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1024,
        }
      };

      final response = await _makeHttpRequest(_baseUrl, requestBody);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content'];
          if (content != null && content['parts'] != null && content['parts'].isNotEmpty) {
            return content['parts'][0]['text'] as String;
          }
        }
      }
      
      return 'Unable to generate explanation at this time.';
    } catch (e) {
      print('Error generating explanation: $e');
      return 'Unable to generate explanation at this time.';
    }
  }
}
