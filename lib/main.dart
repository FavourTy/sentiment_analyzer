import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sentiment Analyzer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SentimentAnalyzerHomePage(),
    );
  }
}

class SentimentAnalyzerHomePage extends StatefulWidget {
  const SentimentAnalyzerHomePage({super.key});

  @override
  State<SentimentAnalyzerHomePage> createState() =>
      _SentimentAnalyzerHomePageState();
}

class _SentimentAnalyzerHomePageState
    extends State<SentimentAnalyzerHomePage> {
  final TextEditingController _textController = TextEditingController();
  Interpreter? _interpreter;
  Map<String, int> _vocab = {};
  String _statusMessage = 'Loading model...';
  String _result = '';
  bool _isLoading = true;
  bool _isAnalyzing = false;

  // Constants for the model
  static const int maxLen = 256;
  static const String padToken = '<pad>';
  static const String unkToken = '<unk>';

  @override
  void initState() {
    super.initState();
    _loadModelAndVocab();
  }

  @override
  void dispose() {
    _textController.dispose();
    _interpreter?.close();
    super.dispose();
  }

  /// Load the TFLite model and vocabulary file
  Future<void> _loadModelAndVocab() async {
    try {
      // Load the TFLite model
      _interpreter = await Interpreter.fromAsset('assets/sentiment_model.tflite');

      // Load and parse the vocabulary file
      final vocabData = await rootBundle.loadString('assets/sentiment_vocab.txt');
      final lines = vocabData.split('\n');

      final Map<String, int> vocabMap = {};
      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;

        final parts = line.split(' ');
        if (parts.length >= 2) {
          final word = parts[0];
          final index = int.tryParse(parts[1]);
          if (index != null) {
            vocabMap[word] = index;
          }
        }
      }

      setState(() {
        _vocab = vocabMap;
        _statusMessage = 'Model loaded successfully!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading model: $e';
        _isLoading = false;
      });
    }
  }

  /// Tokenize and preprocess the input text
  List<int> _tokenize(String text) {
    // Clean the text: lowercase and remove punctuation
    String cleanedText = text.toLowerCase();
    cleanedText = cleanedText.replaceAll(RegExp(r'[^\w\s]'), '');

    // Split into words
    final words = cleanedText.split(RegExp(r'\s+'));

    // Convert words to indices
    final List<int> indices = [];
    final int unkIndex = _vocab[unkToken] ?? 1;
    final int padIndex = _vocab[padToken] ?? 0;

    for (var word in words) {
      if (word.isEmpty) continue;
      final index = _vocab[word] ?? unkIndex;
      indices.add(index);
    }

    // Pad or truncate to maxLen
    if (indices.length > maxLen) {
      return indices.sublist(0, maxLen);
    } else {
      while (indices.length < maxLen) {
        indices.add(padIndex);
      }
      return indices;
    }
  }

  /// Run prediction on the input text
  Future<void> _predict(String text) async {
    if (_interpreter == null) {
      setState(() {
        _result = 'Error: Model not loaded';
      });
      return;
    }

    if (text.trim().isEmpty) {
      setState(() {
        _result = 'Please enter some text to analyze';
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _result = 'Analyzing...';
    });

    try {
      // Tokenize the input text
      final inputTokens = _tokenize(text);

      // Create input tensor with shape [1, 256]
      final input = [inputTokens];

      // Create output buffer with shape [1, 2]
      // [negative_score, positive_score]
      final output = List.filled(1, List.filled(2, 0.0)).map((e) => List<double>.from(e)).toList();

      // Run inference
      _interpreter!.run(input, output);

      // Interpret the output
      final negativeScore = output[0][0];
      final positiveScore = output[0][1];

      final String sentiment;
      final double confidence;

      if (positiveScore > negativeScore) {
        sentiment = 'Positive';
        confidence = positiveScore;
      } else {
        sentiment = 'Negative';
        confidence = negativeScore;
      }

      setState(() {
        _result = 'Sentiment: $sentiment\nConfidence: ${(confidence * 100).toStringAsFixed(2)}%';
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error during prediction: $e';
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Sentiment Analyzer'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth > 600 ? 40.0 : 16.0,
                  vertical: 24.0,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 800,
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status message
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                _isLoading
                                    ? Icons.hourglass_empty
                                    : _statusMessage.contains('Error')
                                        ? Icons.error_outline
                                        : Icons.check_circle_outline,
                                color: _isLoading
                                    ? Colors.orange
                                    : _statusMessage.contains('Error')
                                        ? Colors.red
                                        : Colors.green,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _statusMessage,
                                  style: TextStyle(
                                    fontSize: constraints.maxWidth > 600 ? 16 : 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Input text field
                      TextField(
                        controller: _textController,
                        maxLines: 5,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          hintText: 'Enter text to analyze sentiment...',
                          labelText: 'Text Input',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        style: TextStyle(
                          fontSize: constraints.maxWidth > 600 ? 16 : 14,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Analyze button
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading || _isAnalyzing
                              ? null
                              : () => _predict(_textController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isAnalyzing
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Analyzing...',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Analyze Sentiment',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Result card
                      if (_result.isNotEmpty)
                        Card(
                          elevation: 4,
                          color: _result.contains('Positive')
                              ? Colors.green[50]
                              : _result.contains('Negative')
                                  ? Colors.red[50]
                                  : null,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _result.contains('Positive')
                                          ? Icons.sentiment_satisfied
                                          : _result.contains('Negative')
                                              ? Icons.sentiment_dissatisfied
                                              : Icons.analytics,
                                      size: 32,
                                      color: _result.contains('Positive')
                                          ? Colors.green
                                          : _result.contains('Negative')
                                              ? Colors.red
                                              : Colors.blue,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Result',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _result,
                                  style: TextStyle(
                                    fontSize: constraints.maxWidth > 600 ? 18 : 16,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
