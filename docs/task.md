# DaPub-Reader Task List

## Phase 1: Project Setup
- [ ] Initialize Flutter project (already done)
- [ ] Set up git repository
- [ ] Add required dependencies to pubspec.yaml
- [ ] Configure Android permissions for file access
- [ ] Create basic folder structure (lib/features, lib/widgets, lib/utils, etc.)

## Phase 2: Basic UI Implementation
- [ ] Create home screen with file picker/button
- [ ] Design EPUB reader screen layout
- [ ] Implement file selection functionality
- [ ] Add basic navigation between screens

## Phase 3: EPUB Reading Integration
- [ ] Research and select EPUB parsing library
- [ ] Implement EPUB file loading and parsing
- [ ] Extract text content from EPUB files
- [ ] Display EPUB content in readable format
- [ ] Add basic text formatting (fonts, sizes, etc.)

## Phase 4: TTS Integration with Piper Plugin
- [ ] Add piper_tts_plugin dependency
- [ ] Implement voice model loading functionality
- [ ] Create TTS synthesis service
- [ ] Integrate with EPUB text content
- [ ] Add playback controls (play, pause, stop, seek)
- [ ] Implement voice selection UI

## Phase 5: Feature Enhancements
- [ ] Add settings for speech rate and pitch
- [ ] Implement bookmarking/saving reading position
- [ ] Add support for different EPUB formats
- [ ] Implement text highlighting during TTS playback
- [ ] Add error handling for unsupported files

## Phase 6: Testing and Refinement
- [ ] Test with various EPUB files
- [ ] Optimize performance for large files
- [ ] Ensure proper Android permissions handling
- [ ] Test TTS functionality with different voices
- [ ] Fix any bugs or issues discovered

## Phase 7: Build and Deployment
- [ ] Create release build for Android
- [ ] Generate signed APK
- [ ] Prepare for potential Play Store deployment
- [ ] Document installation process