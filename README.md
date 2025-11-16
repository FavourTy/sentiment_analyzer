# Sentiment Analyzer

A Flutter app that classifies user text as 'Positive' or 'Negative' using on-device AI inference with TensorFlow Lite.

## Features

- **On-Device AI**: Uses TensorFlow Lite for fast, private sentiment analysis
- **Real-time Classification**: Analyzes text and provides sentiment scores instantly
- **Responsive Design**: Adapts to different screen sizes (mobile, tablet, desktop)
- **User-Friendly UI**: Material Design 3 interface with clear feedback
- **Offline Support**: All processing happens on-device, no internet required

## Getting Started

### Prerequisites

- Flutter SDK (^3.9.2)
- Dart SDK
- TensorFlow Lite model and vocabulary files

### Installation

1. Clone the repository:
```bash
git clone https://github.com/FavourTy/sentiment_analyzer.git
cd sentiment_analyzer
```

2. Install dependencies:
```bash
flutter pub get
```

3. **Important**: Replace the placeholder files in `assets/` with your actual model files:
   - `assets/sentiment_model.tflite` - Your trained TensorFlow Lite sentiment model
   - `assets/sentiment_vocab.txt` - Your vocabulary file (format: `word index`)

### Running the App

```bash
flutter run
```

## How It Works

### Architecture

The app uses the following components:

1. **Model Loading** (`_loadModelAndVocab()`):
   - Loads the TFLite model using `Interpreter.fromAsset()`
   - Parses the vocabulary file into a `Map<String, int>`
   - Updates UI state to show "Model loaded"

2. **Text Preprocessing** (`_tokenize()`):
   - Converts text to lowercase
   - Removes punctuation
   - Splits text into words
   - Maps words to integer indices using vocabulary
   - Handles unknown words (maps to `<unk>`)
   - Pads or truncates to fixed length (256 tokens)

3. **Prediction** (`_predict()`):
   - Creates input tensor with shape `[1, 256]`
   - Runs TFLite inference
   - Interprets output buffer with shape `[1, 2]` (negative/positive scores)
   - Displays sentiment and confidence percentage

### Vocabulary File Format

The `sentiment_vocab.txt` file should contain one word per line in the format:
```
word index
```

Example:
```
<pad> 0
<unk> 1
the 2
good 40
bad 45
```

### Model Requirements

Your TFLite model should:
- Accept input shape: `[1, 256]` (batch size 1, sequence length 256)
- Produce output shape: `[1, 2]` (batch size 1, 2 classes: negative/positive)
- Use integer token indices as input

## Dependencies

- **flutter**: SDK
- **tflite_flutter**: ^0.10.4 - TensorFlow Lite runtime for Flutter
- **cupertino_icons**: ^1.0.8 - iOS-style icons

## UI Components

- **Status Card**: Shows model loading status with icons
- **Text Input**: Multi-line TextField for entering text
- **Analyze Button**: Triggers sentiment analysis with loading state
- **Result Card**: Displays sentiment (Positive/Negative) and confidence score with color coding

## Error Handling

The app includes comprehensive error handling for:
- Model loading failures
- Vocabulary parsing errors
- Empty input text
- Inference errors

All errors are displayed to the user with descriptive messages.

## Testing

Run the widget tests:
```bash
flutter test
```

## Project Structure

```
sentiment_analyzer/
├── lib/
│   └── main.dart              # Main app code
├── assets/
│   ├── sentiment_model.tflite # TFLite model (replace with your model)
│   └── sentiment_vocab.txt    # Vocabulary file (replace with your vocab)
├── test/
│   └── widget_test.dart       # Widget tests
├── pubspec.yaml               # Dependencies and assets configuration
└── README.md                  # This file
```

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the MIT License.

## Resources

- [TensorFlow Lite Flutter Plugin](https://pub.dev/packages/tflite_flutter)
- [Flutter Documentation](https://docs.flutter.dev/)
- [TensorFlow Lite Documentation](https://www.tensorflow.org/lite)
