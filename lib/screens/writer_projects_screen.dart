import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'writer_screen.dart';

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

class WriterProject {
  final String id;
  final String title;
  final List<Chapter> chapters;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalWords;
  final String? folderPath;

  WriterProject({
    required this.id,
    required this.title,
    this.chapters = const [],
    required this.createdAt,
    required this.updatedAt,
    this.totalWords = 0,
    this.folderPath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'chapters': chapters.map((c) => c.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'totalWords': totalWords,
    'folderPath': folderPath,
  };

  factory WriterProject.fromJson(Map<String, dynamic> json) => WriterProject(
    id: json['id'],
    title: json['title'],
    chapters: (json['chapters'] as List?)?.map((c) => Chapter.fromJson(c)).toList() ?? [],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    totalWords: json['totalWords'] ?? 0,
    folderPath: json['folderPath'],
  );
}

class WriterProjectsScreen extends StatefulWidget {
  const WriterProjectsScreen({super.key});

  @override
  State<WriterProjectsScreen> createState() => _WriterProjectsScreenState();
}

class _WriterProjectsScreenState extends State<WriterProjectsScreen> {
  List<WriterProject> _projects = [];
  String? _projectFolderPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    _projectFolderPath = prefs.getString('writerProjectFolder');
    final data = prefs.getString('writerProjects');
    
    setState(() {
      _isLoading = true;
    });

    if (data != null) {
      _projects = (jsonDecode(data) as List)
          .map((e) => WriterProject.fromJson(e))
          .toList();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_projects.map((p) => p.toJson()).toList());
    await prefs.setString('writerProjects', data);
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_projectFolderPath == null)
              ListTile(
                leading: const Icon(Icons.folder_open, color: Colors.blue),
                title: const Text('Select Project Folder'),
                subtitle: const Text('Choose where to save your projects'),
                onTap: () {
                  Navigator.pop(ctx);
                  _selectProjectFolder();
                },
              ),
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

  Future<void> _selectProjectFolder() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('writerProjectFolder', result);
        setState(() {
          _projectFolderPath = result;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Project folder set: $result')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showNewProjectDialog() {
    if (_projectFolderPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select project folder first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
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
                final project = WriterProject(
                  id: now.millisecondsSinceEpoch.toString(),
                  title: controller.text,
                  createdAt: now,
                  updatedAt: now,
                  folderPath: _projectFolderPath,
                );
                
                if (_projectFolderPath != null) {
                  final projectDir = Directory('$_projectFolderPath/${project.id}');
                  await projectDir.create(recursive: true);
                }
                
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        backgroundColor: Colors.teal,
        actions: [
          if (_projectFolderPath != null)
            IconButton(
              icon: const Icon(Icons.folder),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Folder: $_projectFolderPath')),
                );
              },
            ),
        ],
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
}