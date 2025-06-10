import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note_model.dart';
import '../services/note_service.dart';
import '../widgets/quest_theme.dart';
import 'note_editor_view.dart';

class NoteDetailView extends StatefulWidget {
  final Note note;

  const NoteDetailView({super.key, required this.note});

  @override
  State<NoteDetailView> createState() => _NoteDetailViewState();
}

class _NoteDetailViewState extends State<NoteDetailView> {
  final NoteService _noteService = NoteService();
  late Note _note;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
  }

  Future<void> _deleteNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Note'),
            content: Text('Are you sure you want to delete "${_note.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      final success = await _noteService.deleteNote(_note.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate deletion
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete note')));
      }
    }
  }

  Future<void> _togglePin() async {
    final success = await _noteService.togglePinNote(_note.id, !_note.isPinned);
    if (success) {
      setState(() {
        _note = _note.copyWith(isPinned: !_note.isPinned);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_note.isPinned ? 'Note pinned' : 'Note unpinned'),
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard() async {
    final text = '${_note.title}\n\n${_note.content}';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note copied to clipboard')));
    }
  }

  Future<void> _shareNote() async {
    // Note: You might want to add share_plus package for actual sharing
    final text = '${_note.title}\n\n${_note.content}';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note copied to clipboard (share feature)'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuestTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Note Details'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: QuestTheme.primaryGradient),
        ),
        actions: [
          IconButton(
            onPressed: _togglePin,
            icon: Icon(
              _note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _note.isPinned ? Colors.orange : null,
            ),
            tooltip: _note.isPinned ? 'Unpin note' : 'Pin note',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  final navigator = Navigator.of(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteEditorView(note: _note),
                    ),
                  ).then((updated) {
                    if (updated == true && mounted) {
                      navigator.pop(true);
                    }
                  });
                  break;
                case 'copy':
                  _copyToClipboard();
                  break;
                case 'share':
                  _shareNote();
                  break;
                case 'delete':
                  _deleteNote();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'copy',
                    child: Row(
                      children: [
                        Icon(Icons.copy),
                        SizedBox(width: 8),
                        Text('Copy'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share),
                        SizedBox(width: 8),
                        Text('Share'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title - more compact
            Text(
              _note.title,
              style: const TextStyle(
                fontSize: 20, // Reduced font size
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12), // Reduced spacing
            // Metadata row - more compact
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ), // Reduced padding
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8), // Reduced radius
                  ),
                  child: Text(
                    _note.category,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 12, // Reduced font size
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Created: ${_note.formattedDate}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11, // Reduced font size
                      ),
                    ),
                    if (_note.createdAt != _note.updatedAt)
                      Text(
                        'Updated: ${_note.updatedAt.day}/${_note.updatedAt.month}/${_note.updatedAt.year}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12), // Reduced spacing
            // Content section - more compact
            const Text(
              'Content',
              style: TextStyle(
                fontSize: 14, // Reduced font size
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6), // Reduced spacing
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                _note.content,
                style: const TextStyle(
                  fontSize: 14, // Reduced font size
                  height: 1.4, // Reduced line height
                ),
              ),
            ),

            const SizedBox(height: 20), // Reduced spacing
            // Quick actions - more compact
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final navigator = Navigator.of(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteEditorView(note: _note),
                        ),
                      ).then((updated) {
                        if (updated == true && mounted) {
                          navigator.pop(true);
                        }
                      });
                    },
                    icon: const Icon(Icons.edit, size: 18), // Reduced icon size
                    label: const Text('Edit', style: TextStyle(fontSize: 14)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ), // Compact padding
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyToClipboard,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy', style: TextStyle(fontSize: 14)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
