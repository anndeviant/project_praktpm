import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/note_service.dart';
import '../models/note_model.dart';
import '../widgets/quest_theme.dart';
import 'note_editor_view.dart';
import 'note_detail_view.dart';

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  final AuthService _authService = AuthService();
  final NoteService _noteService = NoteService();

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: QuestTheme.backgroundLight,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [QuestTheme.backgroundLight, QuestTheme.surfaceColor],
            ),
          ),
          child: const Center(child: Text('Please log in to view notes')),
        ),
      );
    }

    return Scaffold(
      backgroundColor: QuestTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('My Notes'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: QuestTheme.primaryGradient),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [QuestTheme.backgroundLight, QuestTheme.surfaceColor],
          ),
        ),
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: QuestTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: QuestTheme.cardShadow,
              ),
              child: const Column(
                children: [
                  Icon(Icons.note_alt, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'My Notes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Organize your thoughts and ideas',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Search Section
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: QuestTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: QuestTheme.cardShadow,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search notes...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: QuestTheme.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: QuestTheme.textMuted.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: QuestTheme.textMuted.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: QuestTheme.primaryBlue,
                      ),
                    ),
                    filled: true,
                    fillColor: QuestTheme.surfaceColor,
                  ),
                ),
              ),
            ),

            // Notes List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: StreamBuilder<List<Note>>(
                  stream: _noteService.streamUserNotes(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: QuestTheme.errorColor,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Error loading notes',
                              style: TextStyle(
                                fontSize: 18,
                                color: QuestTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Please try again later',
                              style: TextStyle(color: QuestTheme.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    List<Note> notes = snapshot.data ?? [];

                    // Filter notes based on search query
                    if (_searchQuery.isNotEmpty) {
                      notes =
                          notes
                              .where(
                                (note) =>
                                    note.title.toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    ) ||
                                    note.content.toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    ),
                              )
                              .toList();
                    }

                    if (notes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: const BoxDecoration(
                                color: QuestTheme.surfaceColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.note_add,
                                size: 64,
                                color: QuestTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No notes yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: QuestTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No notes match your search'
                                  : 'Tap the + button to create your first note',
                              style: const TextStyle(
                                color: QuestTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: notes.length,
                      padding: const EdgeInsets.only(bottom: 80),
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return _buildNoteCard(note);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NoteEditorView()),
          );
        },
        backgroundColor: QuestTheme.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: QuestTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: QuestTheme.cardShadow,
        border: Border.all(
          color:
              note.isPinned
                  ? QuestTheme.accentGold.withValues(alpha: 0.3)
                  : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NoteDetailView(note: note)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  if (note.isPinned)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: QuestTheme.accentGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.push_pin,
                            size: 14,
                            color: QuestTheme.accentGold,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Pinned',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: QuestTheme.accentGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: QuestTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      note.category,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: QuestTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                note.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: QuestTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Content Preview
              Text(
                note.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: QuestTheme.textSecondary,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: QuestTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(note.updatedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: QuestTheme.textMuted,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _togglePin(note),
                    icon: Icon(
                      note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 20,
                      color:
                          note.isPinned
                              ? QuestTheme.accentGold
                              : QuestTheme.textMuted,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 6), // Reduced spacing
                  IconButton(
                    onPressed: () => _editNote(note),
                    icon: const Icon(
                      Icons.edit,
                      size: 18, // Reduced icon size
                      color: QuestTheme.textMuted,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _togglePin(Note note) async {
    try {
      await _noteService.togglePinNote(note.id, !note.isPinned);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating note: $e')));
      }
    }
  }

  void _editNote(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteEditorView(note: note)),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
