import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/note_service.dart';
import '../models/note_model.dart';
import '../widgets/quest_theme.dart';
import 'package:logger/logger.dart';

class NoteEditorView extends StatefulWidget {
  final Note? note;

  const NoteEditorView({super.key, this.note});

  @override
  State<NoteEditorView> createState() => _NoteEditorViewState();
}

class _NoteEditorViewState extends State<NoteEditorView> {
  final AuthService _authService = AuthService();
  final NoteService _noteService = NoteService();
  final Logger _logger = Logger();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String _selectedCategory = 'General';
  bool _isLoading = false;

  final List<String> _predefinedCategories = [
    'General',
    'KKN',
    'Meeting',
    'Ideas',
    'Todo',
    'Important',
    'Personal',
    'Work',
    'Study',
    'Travel',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _loadNoteData();
    }
  }

  void _loadNoteData() {
    final note = widget.note!;
    _titleController.text = note.title;
    _contentController.text = note.content;
    _selectedCategory = note.category;
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();

      if (widget.note == null) {
        // Create new note
        final newNote = Note(
          id: '',
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          userId: userId,
          createdAt: now,
          updatedAt: now,
          category: _selectedCategory,
          isPinned: false,
        );

        final noteId = await _noteService.createNote(newNote);
        if (noteId != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Note created successfully')),
            );
            Navigator.pop(context, true);
          }
        } else {
          throw Exception('Failed to create note');
        }
      } else {
        // Update existing note
        final updatedNote = widget.note!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
          updatedAt: now,
        );

        final success = await _noteService.updateNote(updatedNote);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Note updated successfully')),
            );
            Navigator.pop(context, true);
          }
        } else {
          throw Exception('Failed to update note');
        }
      }
    } catch (e) {
      _logger.e('Error saving note: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuestTheme.backgroundLight,
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: QuestTheme.primaryGradient),
        ),
        actions: [
          if (!_isLoading)
            IconButton(onPressed: _saveNote, icon: const Icon(Icons.save)),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [QuestTheme.backgroundLight, QuestTheme.surfaceColor],
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: QuestTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: QuestTheme.cardShadow,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        widget.note == null ? Icons.note_add : Icons.edit_note,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.note == null ? 'Create New Note' : 'Edit Note',
                        style: const TextStyle(
                          fontSize: 20, // Reduced font size
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4), // Reduced spacing
                      Text(
                        widget.note == null
                            ? 'Capture your thoughts and ideas'
                            : 'Update your note content',
                        style: const TextStyle(
                          fontSize: 13, // Reduced font size
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: QuestTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: QuestTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: QuestTheme.surfaceColor,
                        ),
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Category Field
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: QuestTheme.surfaceColor,
                        ),
                        items:
                            _predefinedCategories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Content Field
                      TextFormField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          labelText: 'Content',
                          prefixIcon: const Icon(Icons.description),
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: QuestTheme.surfaceColor,
                        ),
                        maxLines: 10,
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Please enter some content';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveNote,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: QuestTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon:
                              _isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Icon(Icons.save),
                          label: Text(
                            widget.note == null ? 'Create Note' : 'Update Note',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
