import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/note_model.dart';

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // Create a new note
  Future<String?> createNote(Note note) async {
    try {
      DocumentReference docRef = await _firestore.collection('notes').add(note.toMap());
      _logger.i('Note created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.e('Error creating note: $e');
      return null;
    }
  }  // Get all notes for a user
  Future<List<Note>> getUserNotes(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('notes')
          .where('userId', isEqualTo: userId)
          .get();

      List<Note> notes = querySnapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();
      
      // Sort in memory: pinned notes first, then by updatedAt
      notes.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

      return notes;
    } catch (e) {
      _logger.e('Error getting user notes: $e');
      return [];
    }
  }  // Get notes by category
  Future<List<Note>> getNotesByCategory(String userId, String category) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('notes')
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .get();

      List<Note> notes = querySnapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();
      
      // Sort in memory: pinned notes first, then by updatedAt
      notes.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

      return notes;
    } catch (e) {
      _logger.e('Error getting notes by category: $e');
      return [];
    }
  }

  // Search notes
  Future<List<Note>> searchNotes(String userId, String query) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('notes')
          .where('userId', isEqualTo: userId)
          .get();

      List<Note> allNotes = querySnapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();      // Filter notes that contain the search query in title or content
      return allNotes.where((note) {
        return note.title.toLowerCase().contains(query.toLowerCase()) ||
               note.content.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      _logger.e('Error searching notes: $e');
      return [];
    }
  }

  // Update a note
  Future<bool> updateNote(Note note) async {
    try {
      await _firestore.collection('notes').doc(note.id).update(note.toMap());
      _logger.i('Note updated successfully');
      return true;
    } catch (e) {
      _logger.e('Error updating note: $e');
      return false;
    }
  }

  // Delete a note
  Future<bool> deleteNote(String noteId) async {
    try {
      await _firestore.collection('notes').doc(noteId).delete();
      _logger.i('Note deleted successfully');
      return true;
    } catch (e) {
      _logger.e('Error deleting note: $e');
      return false;
    }
  }

  // Pin/Unpin a note
  Future<bool> togglePinNote(String noteId, bool isPinned) async {
    try {
      await _firestore.collection('notes').doc(noteId).update({
        'isPinned': isPinned,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      _logger.i('Note pin status updated');
      return true;
    } catch (e) {
      _logger.e('Error updating note pin status: $e');
      return false;
    }
  }

  // Get note by ID
  Future<Note?> getNoteById(String noteId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('notes').doc(noteId).get();
      if (doc.exists) {
        return Note.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting note by ID: $e');
      return null;
    }
  }

  // Get user's note categories
  Future<List<String>> getUserCategories(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('notes')
          .where('userId', isEqualTo: userId)
          .get();

      Set<String> categories = {};
      for (var doc in querySnapshot.docs) {
        Note note = Note.fromFirestore(doc);
        categories.add(note.category);
      }

      List<String> categoryList = categories.toList();
      categoryList.sort();
      return categoryList;
    } catch (e) {
      _logger.e('Error getting user categories: $e');
      return [];
    }
  }

  // Get user's note statistics
  Future<Map<String, int>> getUserNoteStats(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('notes')
          .where('userId', isEqualTo: userId)
          .get();

      List<Note> notes = querySnapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();

      Map<String, int> stats = {
        'total': notes.length,
        'pinned': notes.where((note) => note.isPinned).length,
      };

      // Count by category
      Map<String, int> categoryCount = {};
      for (Note note in notes) {
        categoryCount[note.category] = (categoryCount[note.category] ?? 0) + 1;
      }

      stats.addAll(categoryCount);
      return stats;
    } catch (e) {
      _logger.e('Error getting user note stats: $e');
      return {};
    }
  }  // Stream of user notes for real-time updates
  Stream<List<Note>> streamUserNotes(String userId) {
    return _firestore
        .collection('notes')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          List<Note> notes = snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();
          
          // Sort in memory: pinned notes first, then by updatedAt
          notes.sort((a, b) {
            // First compare by pin status
            if (a.isPinned && !b.isPinned) return -1;
            if (!a.isPinned && b.isPinned) return 1;
            // Then compare by updatedAt (newest first)
            return b.updatedAt.compareTo(a.updatedAt);
          });

          return notes;
        });
  }
}
