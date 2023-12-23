import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:allen/openai_service.dart';
import 'package:allen/pallete.dart';

class ChatMessage {
  final String content;
  final bool isUserMessage;
  final bool isImage;

  ChatMessage(
      {required this.content,
      this.isUserMessage = false,
      this.isImage = false});
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final SpeechToText speechToText = SpeechToText();
  final FlutterTts flutterTts = FlutterTts();
  final OpenAIService openAIService = OpenAIService();
  List<ChatMessage> messages = [];
  String lastWords = '';
  TextEditingController textController = TextEditingController();

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
      lastWords = result.recognizedWords;
    });
  }

  void processSpeechResult(String text) async {
    setState(() {
      messages.add(ChatMessage(content: text, isUserMessage: true));
    });

    String assistantResponse = await openAIService.handleUserInput(text);
    bool isImage = assistantResponse.startsWith('http');

    setState(() {
      messages.add(ChatMessage(
          content: assistantResponse, isUserMessage: false, isImage: isImage));
    });

    if (!isImage) {
      await systemSpeak(assistantResponse);
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

  Widget buildMessage(ChatMessage message) {
    if (message.isImage) {
      // Image message design
      return Row(
        mainAxisAlignment: message.isUserMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUserMessage) ...[
            const Icon(Icons.computer, color: Colors.blue),
            const SizedBox(width: 8),
          ],
          Container(
            height: 256,
            width: 256,
            decoration: BoxDecoration(
              border: Border.all(
                  color: const Color.fromARGB(255, 124, 124, 125), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(message.content, fit: BoxFit.cover),
            ),
          ),
          if (message.isUserMessage) ...[
            const SizedBox(width: 8),
            const Icon(Icons.person, color: Colors.green),
          ],
        ],
      );
    } else {
      // Text message design
      return Row(
        mainAxisAlignment: message.isUserMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUserMessage) ...[
            const Icon(Icons.computer, color: Colors.blue),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              margin: const EdgeInsets.all(8.0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: message.isUserMessage
                    ? Pallete.firstSuggestionBoxColor
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                    color: message.isUserMessage ? Colors.white : Colors.black),
              ),
            ),
          ),
          if (message.isUserMessage) ...[
            const Icon(Icons.person, color: Colors.green),
            const SizedBox(width: 8),
          ],
        ],
      );
    }
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
                  return buildMessage(message);
                } else {
                  return buildMessage(message);
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: "Type a message",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Color.fromARGB(255, 50, 0, 201),
                  onPressed: () {
                    processSpeechResult(textController.text);
                    textController.clear();
                  },
                ),
                IconButton(
                  icon: Icon(speechToText.isListening ? Icons.stop : Icons.mic),
                  color: Color.fromARGB(255, 50, 0, 201),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
