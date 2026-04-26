import 'bookmark_type.dart';

class EpisodeProject {
  final String id;
  final String title;
  final String? epubPath;
  final String? coverPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<BookmarkType> bookmarks;

  EpisodeProject({
    required this.id,
    required this.title,
    this.epubPath,
    this.coverPath,
    required this.createdAt,
    required this.updatedAt,
    required this.bookmarks,
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
        bookmarks: (json['bookmarks'] as List<dynamic>?)
                ?.map((e) => BookmarkType.values.firstWhere((b) => b.name == e))
                .toList() ??
            [BookmarkType.all],
      );
}
