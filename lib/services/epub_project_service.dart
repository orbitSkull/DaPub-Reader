import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

class EpisodeProject {
  final String id;
  final String title;
  final String? epubPath;
  final String? coverPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProjectBookmark> bookmarks;

  EpisodeProject({
    required this.id,
    required this.title,
    this.epubPath,
    this.coverPath,
    required this.createdAt,
    required this.updatedAt,
    this.bookmarks = const [ProjectBookmark.all],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'epubPath': epubPath,
    'coverPath': coverPath,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'bookmarks': bookmarks.map((b) => b.name).toList(),
  };

  factory EpisodeProject.fromJson(Map<String, dynamic> json) => EpisodeProject(
    id: json['id'],
    title: json['title'],
    epubPath: json['epubPath'],
    coverPath: json['coverPath'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    bookmarks: (json['bookmarks'] as List?)?.map((b) => ProjectBookmark.values.firstWhere(
      (e) => e.name == b,
      orElse: () => ProjectBookmark.all,
    )).toList() ?? [ProjectBookmark.all],
  );
}

enum ProjectBookmark {
  all,
  recent,
  favourite,
}

class ChapterData {
  final String id;
  final String title;
  final String content;
  final int order;

  ChapterData({
    required this.id,
    required this.title,
    required this.content,
    required this.order,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'order': order,
  };

  factory ChapterData.fromJson(Map<String, dynamic> json) => ChapterData(
    id: json['id'],
    title: json['title'],
    content: json['content'] ?? '',
    order: json['order'] ?? 0,
  );
}

class EpubProjectService {
  Future<String> createEmptyEpub(String title, String folderPath) async {
    final sanitizedTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final epubPath = '$folderPath/$sanitizedTitle.epub';
    final chaptersPath = '$folderPath/$sanitizedTitle.chapters.json';
    
    final archive = Archive();
    
    final mimetypeBytes = 'application/epub+zip'.codeUnits;
    final mimetypeSize = mimetypeBytes.length;
    archive.addFile(ArchiveFile('mimetype', mimetypeSize, Uint8List.fromList(mimetypeBytes)));
    
    final containerXml = '<?xml version="1.0"?><container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles></container>';
    final containerBytes = containerXml.codeUnits;
    archive.addFile(ArchiveFile('META-INF/container.xml', containerBytes.length, Uint8List.fromList(containerBytes)));
    
    final contentOpf = '<?xml version="1.0"?><package version="2.0" xmlns="http://www.idpf.org/2007/opf" unique-identifier="bookid"><metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>$title</dc:title><dc:creator>Anonymous</dc:creator><dc:language>en</dc:language><dc:identifier id="bookid">urn:uuid:${DateTime.now().millisecondsSinceEpoch}</dc:identifier></metadata><manifest><item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"/><item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/></manifest><spine><itemref idref="chapter1"/></spine></package>';
    final opfBytes = contentOpf.codeUnits;
    archive.addFile(ArchiveFile('OEBPS/content.opf', opfBytes.length, Uint8List.fromList(opfBytes)));
    
    final navXhtml = '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"><html xmlns="http://www.w3.org/1999/xhtml"><head><title>Navigation</title></head><body><nav xmlns="http://www.idpf.org/2007/ops" type="toc"><h1>Contents</h1><ol><li><a href="chapter1.xhtml">Chapter 1</a></li></ol></nav></body></html>';
    final navBytes = navXhtml.codeUnits;
    archive.addFile(ArchiveFile('OEBPS/nav.xhtml', navBytes.length, Uint8List.fromList(navBytes)));
    
    final chapter1 = '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"><html xmlns="http://www.w3.org/1999/xhtml"><head><title>Chapter 1</title></head><body><h1>Chapter 1</h1><p>Start writing your story here...</p></body></html>';
    final ch1Bytes = chapter1.codeUnits;
    archive.addFile(ArchiveFile('OEBPS/chapter1.xhtml', ch1Bytes.length, Uint8List.fromList(ch1Bytes)));
    
    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw Exception('Failed to create EPUB');
    }
    
    final file = File(epubPath);
    await file.writeAsBytes(encoded);
    
    final chaptersFile = File(chaptersPath);
    final initialChapters = [
      ChapterData(id: '1', title: 'Chapter 1', content: '<p>Start writing your story here...</p>', order: 1).toJson()
    ];
    await chaptersFile.writeAsString(jsonEncode(initialChapters));
    
    return epubPath;
  }

  Future<List<ChapterData>> getChapters(String epubPath) async {
    final sanitizedTitle = epubPath.split('/').last.replaceAll('.epub', '');
    final folderPath = epubPath.substring(0, epubPath.lastIndexOf('/'));
    final chaptersFile = File('$folderPath/$sanitizedTitle.chapters.json');
    
    if (!await chaptersFile.existsSync()) {
      return [];
    }

    try {
      final content = await chaptersFile.readAsString();
      final List<dynamic> data = jsonDecode(content);
      return data.map((e) => ChapterData.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading chapters: $e');
      return [];
    }
  }

  Future<void> saveChapters(String epubPath, List<ChapterData> chapters) async {
    final sanitizedTitle = epubPath.split('/').last.replaceAll('.epub', '');
    final folderPath = epubPath.substring(0, epubPath.lastIndexOf('/'));
    final chaptersFile = File('$folderPath/$sanitizedTitle.chapters.json');
    
    final data = chapters.map((c) => c.toJson()).toList();
    await chaptersFile.writeAsString(jsonEncode(data));
  }

  Future<String?> setCover(String epubPath, Uint8List imageBytes, String extension) async {
    final file = File(epubPath);
    if (!await file.existsSync()) {
      return null;
    }

    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final newArchive = Archive();
      final coverName = 'OEBPS/cover.$extension';
      
      for (final archivedFile in archive.files) {
        if (!archivedFile.name.toLowerCase().contains('cover')) {
          newArchive.addFile(archivedFile);
        }
      }
      
      newArchive.addFile(ArchiveFile(coverName, imageBytes.length, imageBytes));
      
      final encoded = ZipEncoder().encode(newArchive);
      if (encoded != null) {
        await file.writeAsBytes(encoded);
        return coverName;
      }
    } catch (e) {
      debugPrint('Error setting cover: $e');
    }
    
    return null;
  }

  Future<void> removeCover(String epubPath) async {
    final file = File(epubPath);
    if (!await file.existsSync()) {
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final newArchive = Archive();
      
      for (final archivedFile in archive.files) {
        if (!archivedFile.name.toLowerCase().contains('cover')) {
          newArchive.addFile(archivedFile);
        }
      }
      
      final encoded = ZipEncoder().encode(newArchive);
      if (encoded != null) {
        await file.writeAsBytes(encoded);
      }
    } catch (e) {
      debugPrint('Error removing cover: $e');
    }
  }

  Future<String?> pickCoverImage() async {
    return null;
  }
}