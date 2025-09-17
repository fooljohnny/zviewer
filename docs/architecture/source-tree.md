# Source Tree Structure

This document describes the current source code organization and file structure of the ZViewer project.

## Project Root Structure

```
zviewer/
├── application/                    # Flutter application source code
├── docs/                          # Project documentation
├── web-bundles/                   # BMAD agent configurations
└── README.md                      # Project overview
```

## Flutter Application Structure (`application/`)

### Core Application Files
```
application/
├── lib/
│   ├── main.dart                  # Application entry point
│   └── widgets/
│       └── multimedia_viewer/     # Core multimedia viewing widgets
│           ├── multimedia_viewer.dart    # Main multimedia viewer component
│           ├── image_viewer.dart         # Image viewing functionality
│           ├── video_viewer.dart         # Video viewing functionality
│           └── gesture_handler.dart      # Gesture handling utilities
├── test/
│   ├── widget_test.dart           # Main widget tests
│   └── widgets/
│       └── multimedia_viewer/     # Widget-specific tests
│           ├── image_viewer_test.dart
│           ├── video_viewer_test.dart
│           └── gesture_handler_test.dart
├── assets/                        # Application assets (images, videos, etc.)
├── windows/                       # Windows platform-specific code
│   ├── runner/                    # Windows runner implementation
│   └── flutter/                   # Flutter Windows integration
├── pubspec.yaml                   # Flutter dependencies and configuration
├── pubspec.lock                   # Locked dependency versions
├── analysis_options.yaml          # Dart analysis configuration
└── README.md                      # Application-specific documentation
```

## Core Widget Architecture

### Multimedia Viewer Module (`lib/widgets/multimedia_viewer/`)

The multimedia viewer is organized as a cohesive module with the following components:

1. **`multimedia_viewer.dart`** - Main orchestrator widget
   - Determines media type (image/video) based on file extension
   - Routes to appropriate viewer (ImageViewer or VideoViewer)
   - Handles unsupported format errors

2. **`image_viewer.dart`** - Image viewing functionality
   - Implements photo viewing with zoom, pan, and gesture support
   - Uses photo_view package for advanced image interactions

3. **`video_viewer.dart`** - Video viewing functionality
   - Implements video playback with controls
   - Uses video_player package for media playback

4. **`gesture_handler.dart`** - Gesture handling utilities
   - Common gesture handling logic shared between viewers
   - Navigation gesture support (swipe for next/previous)

## Dependencies

### Core Flutter Dependencies
- **flutter**: Core Flutter SDK
- **cupertino_icons**: iOS-style icons
- **photo_view**: Advanced image viewing with zoom/pan
- **video_player**: Video playback functionality
- **path_provider**: File system path utilities

### Development Dependencies
- **flutter_test**: Testing framework
- **flutter_lints**: Code quality and linting

## Platform Support

### Windows Platform (`windows/`)
- Native Windows application runner
- CMake build configuration
- Flutter Windows integration
- Custom window handling and utilities

## Documentation Structure (`docs/`)

```
docs/
├── architecture/                  # Technical architecture documentation
│   ├── frontend-architectural-approach.md
│   ├── frontend-data-flow.md
│   ├── frontend-technology-stack.md
│   ├── server-architectural-approach.md
│   ├── server-microservice-breakdown.md
│   ├── server-technology-stack.md
│   └── source-tree.md            # This file
├── prd/                          # Product Requirements Documentation
├── stories/                      # User stories and development tasks
└── [various spec files]          # Additional specifications
```

## Build Output Structure

```
application/build/
├── flutter_assets/               # Compiled Flutter assets
├── native_assets/               # Platform-specific native assets
└── [generated files]            # Flutter build artifacts
```

## Key Design Principles

1. **Modular Architecture**: Each media type (image/video) has its own dedicated viewer
2. **Separation of Concerns**: Gesture handling is separated into its own utility module
3. **Platform Agnostic**: Core logic is platform-independent, with platform-specific code isolated
4. **Testable Design**: Each widget has corresponding test files for comprehensive coverage
5. **Asset Management**: Centralized asset handling through Flutter's asset system

## File Naming Conventions

- **Widget files**: `snake_case.dart` (e.g., `multimedia_viewer.dart`)
- **Test files**: `{widget_name}_test.dart`
- **Documentation**: `kebab-case.md`
- **Assets**: Descriptive names with appropriate extensions

This structure supports the current multimedia viewing functionality while providing a foundation for future enhancements and additional media types.
