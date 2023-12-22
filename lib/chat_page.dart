import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:allen/openai_service.dart';
import 'package:allen/pallete.dart';
import 'package:animate_do/animate_do.dart';

class ChatMessage {
  final String content;
  final bool isUserMessage;
  final bool isImage;

  ChatMessage({required this.content, this.isUserMessage = false, this.isImage = false});
}

class ChatAi extends StatefulWidget {
  const ChatAi({super.key});

  @override
  State<ChatAi> createState() => _ChatAiState();
}

class _ChatAiState extends State<ChatAi> {
  final SpeechToText speechToText = SpeechToText();
  final FlutterTts flutterTts = FlutterTts();
  final OpenAIService openAIService = OpenAIService();
  List<ChatMessage> messages = [];
  String lastWords = ''; // Define lastWords here

  @override
  void initState() {
    super.initState();
    initSpeechToText();
  }

  Future<void> initSpeechToText() async {
    await speechToText.initialize(onStatus: onSpeechStatus);
  }

  void onSpeechStatus(String status) {
    if (status == 'done') {
      processSpeechResult(lastWords);
    }
  }

  Future<void> startListening() async {
    await speechToText.listen(onResult: onSpeechResult);
  }

  Future<void> stopListening() async {
    await speechToText.stop();
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      lastWords = result.recognizedWords; // Update lastWords on speech result
    });
  }

 // Inside _ChatAiState class

void processSpeechResult(String text) async {
  setState(() {
    messages.add(ChatMessage(content: text, isUserMessage: true));
  });

  String assistantResponse = await openAIService.isArtPromptAPI(text);
  bool isImage = assistantResponse.startsWith('http'); // Check if response is an image URL

  setState(() {
    messages.add(ChatMessage(content: assistantResponse, isUserMessage: false, isImage: isImage));
  });

  if (!isImage) {
    await systemSpeak(assistantResponse); // Speak out the assistant's text response
  }
}

  Future<void> systemSpeak(String content) async {
    await flutterTts.speak(content);
  }

  @override
  void dispose() {
    super.dispose();
    speechToText.stop();
    flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                if (message.isImage) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        message.content,
        fit: BoxFit.cover,
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Text('Error loading image'); // Display an error message or icon
        },
      ),
    ),
  );
}
 else {
                  return Align(
                    alignment: message.isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.all(8.0),
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: message.isUserMessage ? Pallete.firstSuggestionBoxColor : Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        message.content,
                        style: TextStyle(color: message.isUserMessage ? Colors.white : Colors.black),
                      ),
                    ),
                  ); // Display text
                }
              },
            ),
          ),
          // Add other widgets if needed
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Pallete.firstSuggestionBoxColor,
        onPressed: () async {
          if (await speechToText.hasPermission) {
            if (speechToText.isNotListening) {
              await startListening();
            } else {
              await stopListening();
            }
          } else {
            // Handle permission not granted scenario
          }
        },
        child: Icon(
          speechToText.isListening ? Icons.stop : Icons.mic,
        ),
      ),
    );
  }
}
