import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Nlp Projesi',
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final SpeechToText _speechToText = SpeechToText();
  // ignore: unused_field
  bool _speechEnabled = false;
  bool _firstTap = true;
  String _lastWords = '';
  String _lastApiResponse = '';
  double _lastConfidence = 0.0;
  // ignore: prefer_final_fields
  List<String> _list = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(minutes: 3),
    );
    setState(() {
      _firstTap = false;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      _lastConfidence = result.confidence;
    });

    if (!_speechToText.isListening) {
      _list.add(_lastWords);
    }
  }

  void _sendApiRequest() async {
    const apiUrl = 'http://192.168.1.15:4000/ai/legacy_audio_temp';

    final requestData = {
      'text': _list.join(" "),
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;

        setState(() {
          _lastApiResponse = 'AI Çıktısı: $responseBody';
        });
      } else {
        setState(() {
          _lastApiResponse = 'API Request Failed: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _lastApiResponse = 'Error sending API request: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NLP Projesi'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Tanınan Kelimeler:',
                style: TextStyle(fontSize: 20.0),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _speechToText.isListening
                      ? _lastWords
                      : _firstTap
                          ? 'Tap the microphone to start listening...'
                          : _list.join(' '),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'AI Çıktısı:',
                style: TextStyle(fontSize: 20.0),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _lastApiResponse,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Konuşma Hızı: $_lastConfidence',
                style: const TextStyle(fontSize: 20.0),
              ),
            ),
            ElevatedButton(
              onPressed:
                  _sendApiRequest, // Belirli bir düğmeye basıldığında API isteği atılır
              child: const Text('API İsteği At'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            _speechToText.isNotListening ? _startListening : _stopListening,
        tooltip: 'Dinle',
        child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}
