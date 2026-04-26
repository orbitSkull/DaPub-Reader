import 'package:flutter/material.dart';
import '../services/ideabox_service.dart';

class IdeaBoxScreen extends StatefulWidget {
  const IdeaBoxScreen({super.key});

  @override
  State<IdeaBoxScreen> createState() => _IdeaBoxScreenState();
}

class _IdeaBoxScreenState extends State<IdeaBoxScreen> {
  final IdeaBoxService _service = IdeaBoxService();
  String _selectedCategory = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _service.loadIdeas();
  }

  void _showAddIdeaDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        String category = 'general';
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('New Idea'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Write your idea...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  items: _service.categories.map((c) => 
                    DropdownMenuItem(value: c, child: Text(c.toUpperCase()))
                  ).toList(),
                  onChanged: (value) => setDialogState(() => category = value!),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    await _service.addIdea(controller.text, category: category);
                    setState(() {});
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPromptDialog() {
    final prompt = WritingPrompt.getPromptWithGenre();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Writing Prompt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(label: Text(prompt['genre'] ?? ''), backgroundColor: Colors.teal[100]),
            const SizedBox(height: 12),
            Text(prompt['prompt'] ?? '', style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showPromptDialog();
            },
            child: const Text('New Prompt'),
          ),
          TextButton(
            onPressed: () async {
              await _service.addIdea(
                '[Prompt] ${prompt['genre']}: ${prompt['prompt']}',
                category: 'prompt',
                tags: [prompt['genre'] ?? ''],
              );
              setState(() {});
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Use This'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _searchQuery.isEmpty 
        ? _service.getIdeasByCategory(_selectedCategory)
        : _service.searchIdeas(_searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: const Text('IdeaBox'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: _showPromptDialog,
            tooltip: 'Writing Prompts',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search ideas...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                'all', ..._service.categories
              ].map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat.toUpperCase()),
                  selected: _selectedCategory == cat,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  selectedColor: Colors.teal[200],
                ),
              )).toList(),
            ),
          ),
          const Divider(),
          Expanded(
            child: filtered.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('No ideas yet', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _showPromptDialog,
                          icon: const Icon(Icons.lightbulb),
                          label: const Text('Get a Prompt'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final idea = filtered[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            idea.isVoiceNote ? Icons.mic : Icons.lightbulb,
                            color: idea.category == 'prompt' ? Colors.orange : Colors.teal,
                          ),
                          title: Text(
                            idea.content.length > 50 
                                ? '${idea.content.substring(0, 50)}...'
                                : idea.content,
                            maxLines: 2,
                          ),
                          subtitle: Text(
                            '${idea.category.toUpperCase()} • ${_formatDate(idea.createdAt)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              await _service.deleteIdea(idea.id);
                              setState(() {});
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddIdeaDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${date.day}/${date.month}';
  }
}