import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:allen/secrets.dart';

class OpenAIService {
  final List<Map<String, String>> messages = [];

  Future<String> handleUserInput(String userInput) async {
    String chatGPTResponse = await chatGPTAPI(userInput);

    if (shouldCallDallE(userInput)) {
      String dallEResponse = await dallEAPI(userInput);
      return dallEResponse;
    } else {
      return chatGPTResponse;
    }
  }

  bool shouldCallDallE(String chatGPTResponse) {
    String responseLower = chatGPTResponse.toLowerCase();

    List<String> imageIndicators = [
      'image of',
      'picture of',
      'visual representation',
      'show me',
      'illustration of',
      'photo of',
      'generate an image',
      'create a picture',
      'visualize',
      'depict',
      'image would help',
      'graphic of',
      'draw a picture',
      'draw an image',
      'draw a graphic',
      'draw a visual',
      'draw a diagram',
      'draw a chart',
      'draw a graph',
      'draw a map',
      'artistic representation',
      'artistic depiction',
      'artistic illustration',
      'artistic image',
      'artistic picture',
      'artistic visual',
      'artistic graphic',
      'artistic diagram',
      'creating an image',
      'creating a picture',
      'creating a graphic',
      'creating a visual',
      'to visualize',
      'to depict',
      'to illustrate',
      'to draw',
      'to create',
      'to generate',
    ];

    for (String indicator in imageIndicators) {
      if (responseLower.contains(indicator)) {
        return true;
      }
    }

    return false;
  }

  Future<String> chatGPTAPI(String prompt) async {
    messages.add({'role': 'user', 'content': prompt});

    try {
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIAPIKey',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": messages,
        }),
      );

      if (res.statusCode == 200) {
        String content =
            jsonDecode(res.body)['choices'][0]['message']['content'];
        content = content.trim();
        messages.add({'role': 'assistant', 'content': content});
        return content;
      }
      return 'An internal error occurred';
    } catch (e) {
      print('Error in chatGPTAPI: $e');
      return 'An internal error occurred';
    }
  }

  Future<String> dallEAPI(String prompt) async {
    messages.add({'role': 'user', 'content': prompt});

    try {
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIAPIKey',
        },
        body: jsonEncode({
          'prompt': prompt,
          'n': 1,
          'size': '256x256',
        }),
      );

      if (res.statusCode == 200) {
        String imageUrl = jsonDecode(res.body)['data'][0]['url'];
        imageUrl = imageUrl.trim();
        messages.add({'role': 'assistant', 'content': imageUrl});
        return imageUrl;
      }
      return 'An internal error occurred';
    } catch (e) {
      print('Error in dallEAPI: $e');
      return 'An internal error occurred';
    }
  }
}
