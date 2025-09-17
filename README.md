# ZViewer - Multimedia Viewer Application

A cross-platform multimedia viewer application built with Flutter for viewing images and videos.

## Project Structure

```
zviewer/
├── application/              # Flutter application
│   ├── lib/                 # Dart source code
│   │   ├── main.dart        # Application entry point
│   │   └── widgets/         # UI components
│   │       └── multimedia_viewer/
│   ├── test/                # Unit tests
│   ├── assets/              # Media assets
│   └── pubspec.yaml         # Flutter dependencies
├── docs/                    # Project documentation
│   ├── architecture/        # Technical architecture docs
│   ├── prd/                # Product requirements
│   └── stories/            # User stories and tasks
└── web-bundles/            # BMAD agent configurations
```

## Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Platform-specific development tools (Android Studio, Xcode, etc.)

### Running the Application

1. Navigate to the application directory:
   ```bash
   cd application
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

## Features

- **Cross-platform support**: Web, Android, iOS, Windows, Linux, macOS
- **Image viewing**: Support for JPEG, PNG, WebP formats
- **Video playback**: Support for MP4, WebM formats
- **Touch gestures**: Pinch to zoom, pan, swipe navigation
- **Keyboard navigation**: Arrow keys, escape key support
- **Error handling**: Graceful error recovery with retry functionality

## Development

This project follows Flutter best practices and includes:
- Comprehensive unit tests
- Modular widget architecture
- Cross-platform compatibility
- Error handling and loading states

## Documentation

See the `docs/` directory for detailed documentation including:
- Architecture specifications
- Product requirements
- User stories and development tasks