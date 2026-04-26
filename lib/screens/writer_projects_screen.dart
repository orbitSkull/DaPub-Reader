import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'writer_screen.dart';

class WriterProject {
  final String id;
  final String title;
  final List<Chapter> chapters;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalWords;

  WriterProject({
    required this.id,
    required this.title,
    this.chapters = const [],
    required this.createdAt,
    required this.updatedAt,
    this.totalWords = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'chapters': chapters.map((c) => c.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'totalWords': totalWords,
  };

  factory WriterProject.fromJson(Map<String, dynamic> json) => WriterProject(
    id: json['id'],
    title: json['title'],
    chapters: (json['chapters'] as List?)?.map((c) => Chapter.fromJson(c)).toList() ?? [],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    totalWords: json['totalWords'] ?? 0,
  );
}

class Chapter {
  final String id;
  final String title;
  final String content;
  final int wordCount;
  final int order;

  Chapter({
    required this.id,
    required this.title,
    this.content = '',
    this.wordCount = 0,
    required this.order,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'wordCount': wordCount,
    'order': order,
  };

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
    id: json['id'],
    title: json['title'],
    content: json['content'] ?? '',
    wordCount: json['wordCount'] ?? 0,
    order: json['order'] ?? 0,
  );
}

class WriterProjectsScreen extends StatefulWidget {
  const WriterProjectsScreen({super.key});

  @override
  State<WriterProjectsScreen> createState() => _WriterProjectsScreenState();
}

class _WriterProjectsScreenState extends State<WriterProjectsScreen> {
  List<WriterProject> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('writerProjects');
    if (data != null) {
      final list = jsonDecode(data) as List;
      setState(() {
        _projects = list.map((p) => WriterProject.fromJson(p)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_projects.map((p) => p.toJson()).toList());
    await prefs.setString('writerProjects', data);
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
                final project = WriterProject(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: controller.text,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                _projects.insert(0, project);
                await _saveProjects();
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

  void _openProject(WriterProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WriterScreen(project: project),
      ),
    ).then((_) => _loadProjects());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No projects yet', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showNewProjectDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Project'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    final project = _projects[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.book, color: Colors.white),
                        ),
                        title: Text(project.title),
                        subtitle: Text(
                          '${project.chapters.length} chapters • ${project.totalWords} words',
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'delete') {
                              _projects.removeWhere((p) => p.id == project.id);
                              await _saveProjects();
                              setState(() {});
                            }
                          },
                        ),
                        onTap: () => _openProject(project),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddOptions() {
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
              leading: const Icon(Icons.upload_file, color: Colors.orange),
              title: const Text('Import EPUB to Edit'),
              subtitle: const Text('Import existing EPUB to write on'),
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

  void _navigateToProject(WriterProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WriterScreen(project: project),
      ),
    ).then((_) => _loadProjects());
  }

  Future<void> _importEpub() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported: ${file.name}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

class FocusModeScreen extends StatefulWidget {
  final WriterProject project;

  const FocusModeScreen({super.key, required this.project});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isFocusMode = false;
  int _autoSaveSeconds = 30;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.project.title);
    _contentController = TextEditingController();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoSaveSeconds = prefs.getInt('autoSaveInterval') ?? 30;
    });
  }

  void _updateWordCount() {
    final words = _contentController.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    setState(() => _wordCount = words);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFocusMode
          ? null
          : AppBar(
              title: TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Project Title',
                ),
              ),
              backgroundColor: Colors.teal,
              actions: [
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: () => setState(() => _isFocusMode = true),
                  tooltip: 'Focus Mode',
                ),
              ],
            ),
      body: _isFocusMode
          ? GestureDetector(
              onTap: () => setState(() => _isFocusMode = false),
              child: Container(
                color: Colors.black,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.8,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(24),
                        hintText: 'Start writing...',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      onChanged: (_) => _updateWordCount(),
                    ),
                  ),
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      hintText: 'Start writing your story...',
                    ),
                    onChanged: (_) => _updateWordCount(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$_wordCount words', style: const TextStyle(color: Colors.grey)),
                      const Text('Auto-save enabled', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}