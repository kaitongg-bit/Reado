import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:quick_pm/features/feed/presentation/feed_provider.dart';
import 'package:quick_pm/models/feed_item.dart';

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _idController = TextEditingController();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Daily Update');

  // State
  String _selectedModuleId = 'B'; // Default to Reado Guide
  String _difficulty = 'Medium';
  bool _isPublishing = false;
  bool _useCustomId = false;

  @override
  void initState() {
    super.initState();
    _generateId();
  }

  void _generateId() {
    // Format: m-YYYYMMDD-HHmm
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(now);
    _idController.text = '${_selectedModuleId.toLowerCase()}_$timestamp';
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _questionController.dispose();
    _answerController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _handlePublish() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPublishing = true);

    try {
      final item = FeedItem(
        id: _idController.text.trim(),
        moduleId: _selectedModuleId,
        title: _titleController.text.trim(),
        category: _categoryController.text.trim(),
        difficulty: _difficulty,
        pages: [
          OfficialPage(
            _contentController.text, // Markdown content
            flashcardQuestion: _questionController.text.trim(),
            flashcardAnswer: _answerController.text.trim(),
          ),
        ],
      );

      final dataService = ref.read(dataServiceProvider);
      await dataService.saveOfficialFeedItem(item);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Published Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Clear form for next item? Or stay? Let's stay but regenerate ID.
        _generateId();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Publish Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CMS: 发布新内容'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateId,
            tooltip: 'Reset ID',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Module Selector
              DropdownButtonFormField<String>(
                value: _selectedModuleId,
                decoration: const InputDecoration(labelText: 'Target Module'),
                items: const [
                  DropdownMenuItem(
                      value: 'A', child: Text('Module A: STAR 面试法')),
                  DropdownMenuItem(
                      value: 'B', child: Text('Module B: Reado 指南')),
                  DropdownMenuItem(
                      value: 'C', child: Text('Module C: (Beta) Daily')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedModuleId = val;
                      if (!_useCustomId) _generateId();
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // 2. ID (Auto-generated)
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'Unique ID',
                  helperText: 'Unique database identifier',
                ),
                validator: (v) => v == null || v.isEmpty ? 'ID required' : null,
              ),
              const SizedBox(height: 16),

              // 3. Metadata
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _difficulty,
                      decoration:
                          const InputDecoration(labelText: 'Difficulty'),
                      items: ['Easy', 'Medium', 'Hard']
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) => setState(() => _difficulty = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Content (Main)
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Markdown Content',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  helperText: 'Use # for headers, ** for bold.',
                ),
                maxLines: 12,
                minLines: 6,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Content required' : null,
              ),
              const SizedBox(height: 24),

              // 5. Flashcard
              Card(
                color: isDark ? Colors.white10 : Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.flash_on, color: Colors.orangeAccent),
                          SizedBox(width: 8),
                          Text('Flashcard (Required)',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _questionController,
                        decoration: const InputDecoration(
                          labelText: 'Question',
                          prefixIcon: Icon(Icons.help_outline),
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Question required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _answerController,
                        decoration: const InputDecoration(
                          labelText: 'Answer',
                          prefixIcon: Icon(Icons.check_circle_outline),
                        ),
                        maxLines: 3,
                        validator: (v) => v!.isEmpty ? 'Answer required' : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 6. Publish Button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isPublishing ? null : _handlePublish,
                  icon: _isPublishing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cloud_upload),
                  label:
                      Text(_isPublishing ? 'PUBLISHING...' : 'PUBLISH TO APP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
