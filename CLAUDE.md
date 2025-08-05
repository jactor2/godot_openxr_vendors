# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the Godot OpenXR Vendors plugin, providing vendor-specific XR device support (Meta, Pico, HTC, etc.) and access to vendor-specific OpenXR extensions for Godot Engine 4.2+. The plugin is built as a GDExtension using C++ and includes Android support through Gradle.

## Development Commands

### Building the Plugin
```bash
# Linux/MacOS - Build complete plugin
./gradlew buildPlugin

# Windows - Build complete plugin  
gradlew.bat buildPlugin

# Build individual components
./gradlew build                    # Build Android AAR binaries only
scons target=template_debug        # Build desktop debug binaries
scons target=template_release      # Build desktop release binaries
```

### Cleaning
```bash
./gradlew clean                    # Clean all build artifacts
```

### Prerequisites Setup
```bash
git submodule update --init        # Initialize godot-cpp submodule
```

### Code Formatting
Install clang-format and copy contents of `hooks/` folder to `.git/hooks/` for automatic formatting.

## Architecture

### Core Structure
- **`plugin/src/main/cpp/`**: Main C++ source code
  - `extensions/`: OpenXR extension wrappers (FB, HTC, Meta-specific)
  - `export/`: Platform-specific export plugins (Meta, Pico, Lynx, MagicLeap, Khronos)
  - `classes/`: High-level API classes (scene management, spatial entities, etc.)
  - `register_types.cpp`: Plugin registration entry point

### Key Components
- **Extension Wrappers**: Bridge OpenXR vendor extensions to Godot (e.g., `openxr_fb_*`, `openxr_meta_*`)
- **Export Plugins**: Handle platform-specific export configuration and Android manifest generation
- **Manager Classes**: High-level APIs for spatial anchors, scene management, hand tracking

### Build System
- **SCons**: Builds C++ GDExtension binaries for desktop and Android
- **Gradle**: Builds Android AAR packages and orchestrates the entire build process
- **godot-cpp**: Submodule providing Godot C++ bindings

### Platform Support
- **Android**: Primary target with vendor-specific AAR builds
- **Desktop**: Limited support for testing/development
- **Vendors**: Meta/Oculus, Pico, HTC, Lynx, MagicLeap with separate export plugins

### Configuration Files
- `build.gradle`: Main Gradle build configuration with SCons integration
- `config.gradle`: Version and dependency management
- `SConstruct`: SCons build script for C++ compilation
- `thirdparty/godot_cpp_gdextension_api/extension_api.json`: Godot API definitions

### Sample Projects
Located in `samples/` directory, each demonstrates specific vendor features (hand tracking, passthrough, scene management, etc.) with corresponding export presets.