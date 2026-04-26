# DaPub-Reader Project Plan

## Overview
This project aims to create a Flutter Android application for opening and reading .epub files with text-to-speech functionality using the Piper TTS plugin. The application now features dual modes: Reader and Writer, each with specialized functionality.

## Features

### Reader Mode Features
1. EPUB file reading capability
2. Text-to-speech using Piper TTS plugin
3. Basic UI for file selection and reading
4. Playback controls for TTS
5. Settings for voice selection and speed
6. Custom bookmarks for marking favorite passages
7. Your Creations collection for tracking written works
8. Progress tracking and statistics

### Writer Mode Features (Planned)
1. **Projects Manager**: File-manager for manuscripts organized by Chapters/Scenes
2. **IdeaBox**: Categorized scratchpad for quick-capture fragments and voice-to-text notes
3. **Writer Stats**: Dashboard for word counts, daily writing streaks, and 'velocity' metrics
4. **Reader Portal**: Bridge to exit and return to the main Reader Library
5. **Studio Settings**: Focused on 'Typewriter Mode,' EPUB export presets, and custom dictionaries

## Creative Features/Ideas for Writer Mode
- **Auto-save drafts** to prevent losing work
- **Writing prompts** generator for writer's block
- **Focus mode** - distraction-free fullscreen writing
- **Scene/Chapter reordering** via drag-and-drop
- **Character tracking** - notes for each character in a story
- **Timeline view** for story events
- **Collaboration ready** - export projects as sharing
- **Voice typing** - dictation for hands-free writing
- **Writing goals** - daily word count targets with notifications
- **Session timer** - track writing time per session
- **Revision history** - auto-versioning of drafts
- **EPUB/FB2 export** - export written works as EPUB
- **Location tags** - tag scenes by location
- **POV tracking** - track POV per chapter
- **Word frequency** analysis

## Technical Requirements
- Flutter SDK
- Android platform targeting
- Dependencies:
  - flutter_epub_reader (or similar EPUB parsing library)
  - piper_tts_plugin (from https://github.com/dev-6768/piper_tts_plugin)
  - just_audio (for audio playback)
  - path_provider (for file system access)
  - permission_handler (for storage permissions)
  - hive (for local database - Writer mode)
  - record (for voice-to-text functionality)

## Architecture
- Clean architecture with separation of concerns
- State management using Provider
- Modular design for easy maintenance
- Dual-mode navigation (Reader/Writer) with separate state management

## Milestones
1. Project setup and basic UI (Reader mode complete)
2. EPUB file integration (Reader mode complete)
3. TTS integration with Piper plugin (Reader mode complete)
4. Playback controls implementation (Reader mode complete)
5. Custom bookmarks and statistics (Reader mode complete)
6. Writer mode foundation and UI
7. Projects Manager implementation
8. IdeaBox with voice-to-text integration
9. Writer Stats dashboard
10. Reader Portal bridge
11. Studio Settings and export functionality
12. Testing and refinement for both modes
13. Build and deployment preparation