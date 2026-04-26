import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';
import 'writer_screen.dart';
import '../services/epub_project_service.dart';

class WriterProjectsScreen extends StatefulWidget {
  const WriterProjectsScreen({super.key});

  @override
  State<WriterProjectsScreen> createState() => _WriterProjectsScreenState();
}

class _WriterProjectsScreenState extends State<WriterProjectsScreen> {
  List<EpisodeProject> _projects = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  String? _projectFolderPath;
  bool _isGridView = false;
  final EpubProjectService _service = EpubProjectService();

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.manageExternalStorage.status;
    _hasPermission = status.isGranted;
    if (_hasPermission) {
      final prefs = await SharedPreferences.getInstance();
      _projectFolderPath = prefs.getString('writerProjectFolder');
      await _loadProjects();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadProjects() async {
    if (_projectFolderPath == null) {
      final folder = Directory('/storage/emulated/0/LUMING');
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
      _projectFolderPath = folder.path;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('writerProjectFolder', folder.path);
    }

    try {
      final folder = Directory(_projectFolderPath!);
      if (await folder.exists()) {
        final entities = folder.listSync();
        for (var entity in entities) {
          if (entity is File && entity.path.endsWith('.json')) {
            try {
              final content = await entity.readAsString();
              final json = jsonDecode(content);
              final project = EpisodeProject.fromJson(json);
              
              if (project.epubPath != null && 
                  await File(project.epubPath!).existsSync()) {
                _projects.add(project);
              }
            } catch (e) {
              debugPrint('Error loading project ${entity.path}: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading projects: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveProject(EpisodeProject project) async {
    if (_projectFolderPath == null) return;
    
    final sanitizedTitle = project.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final filePath = '$_projectFolderPath/$sanitizedTitle-${project.id}.json';
    
    final file = File(filePath);
    await file.writeAsString(jsonEncode(project.toJson()));
  }

  void _showAddOptions() {
    if (!_hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please grant storage permission first')),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.create, color: Colors.teal),
              title: const Text('New Empty Project'),
              subtitle: const Text('Start from scratch'),
              onTap: () {
                Navigator.pop(ctx);
                _showNewProjectDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload, color: Colors.orange),
              title: const Text('Import EPUB'),
              subtitle: const Text('Import existing epub file'),
              onTap: () {
                Navigator.pop(ctx);
                _importEpub();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNewProjectDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Project Title',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final now = DateTime.now();
                final id = now.millisecondsSinceEpoch.toString();
                String? epubPath;
                
                try {
                  epubPath = await _service.createEmptyEpub(
                    controller.text,
                    id,
                    _projectFolderPath!,
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating project: $e')),
                    );
                  }
                  return;
                }
                
                final project = EpisodeProject(
                  id: id,
                  title: controller.text,
                  epubPath: epubPath,
                  createdAt: now,
                  updatedAt: now,
                );
                
                await _saveProject(project);
                _projects.insert(0, project);
                setState(() {});
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _importEpub() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null) {
          final project = await _service.importEpub(path, _projectFolderPath!);
          if (project != null) {
            await _saveProject(project);
            _projects.insert(0, project);
            setState(() {});
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Imported: ${project.title}')),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error importing epub: $e');
    }
  }

  Future<void> _deleteProject(EpisodeProject project) async {
    if (_projectFolderPath == null) return;
    
    final sanitizedTitle = project.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final filePath = '$_projectFolderPath/$sanitizedTitle-${project.id}.json';
    
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
    
    if (project.epubPath != null) {
      final epubFile = File(project.epubPath!);
      if (await epubFile.exists()) {
        await epubFile.delete();
      }
    }
    
    _projects.removeWhere((p) => p.id == project.id);
    setState(() {});
  }

  void _openProject(EpisodeProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WriterScreen(project: project, onSave: _saveProject),
      ),
    ).then((_) => _loadProjects());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.folder),
          onPressed: _requestPermission,
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasPermission
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open, size: 64, color: Colors.teal),
                      const SizedBox(height: 16),
                      const Text('Storage Permission Required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _requestPermission,
                        icon: const Icon(Icons.security),
                        label: const Text('Set Up Storage'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      ),
                    ],
                  ),
                )
              : _projects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.library_books_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No Projects Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Tap + to create your first project', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : _isGridView
                      ? GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _projects.length,
                          itemBuilder: (context, index) {
                            final project = _projects[index];
                            return _buildGridItem(project);
                          },
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _projects.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final project = _projects[index];
                            return _buildListItem(project);
                          },
                        ),
      floatingActionButton: _hasPermission
          ? FloatingActionButton(
              onPressed: _showAddOptions,
              backgroundColor: Colors.teal,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildListItem(EpisodeProject project) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal,
          child: Text(
            project.title.isNotEmpty ? project.title[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(project.title),
        subtitle: Text(
          'Last edited: ${_formatDate(project.updatedAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton(
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'rename', child: Text('Rename')),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
          onSelected: (value) async {
            if (value == 'delete') {
              await _deleteProject(project);
            } else if (value == 'rename') {
              _showRenameDialog(project);
            }
          },
        ),
        onTap: () => _openProject(project),
      ),
    );
  }

  Widget _buildGridItem(EpisodeProject project) {
    return Card(
      child: InkWell(
        onTap: () => _openProject(project),
        onLongPress: () => _showProjectOptions(project),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.teal,
                child: Text(
                  project.title.isNotEmpty ? project.title[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                project.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(project.updatedAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProjectOptions(EpisodeProject project) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(project.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () { Navigator.pop(ctx); _showRenameDialog(project); },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () { Navigator.pop(ctx); _deleteProject(project); },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(EpisodeProject project) {
    final controller = TextEditingController(text: project.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Project Title', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final updated = EpisodeProject(
                  id: project.id,
                  title: controller.text,
                  epubPath: project.epubPath,
                  coverPath: project.coverPath,
                  createdAt: project.createdAt,
                  updatedAt: DateTime.now(),
                );
                await _saveProject(updated);
                setState(() {
                  final idx = _projects.indexWhere((p) => p.id == project.id);
                  if (idx != -1) _projects[idx] = updated;
                });
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _requestPermission() async {
    if (_hasPermission) {
      _loadProjects();
      return;
    }
    final status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      setState(() => _hasPermission = true);
      _loadProjects();
    }
  }

  Future<void> refresh() async {
    await _loadProjects();
  }
}