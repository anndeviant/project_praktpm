import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/favorite_service.dart';
import '../models/favorite_model.dart';
import 'package:logger/logger.dart';

class FavoriteView extends StatefulWidget {
  const FavoriteView({super.key});

  @override
  State<FavoriteView> createState() => _FavoriteViewState();
}

class _FavoriteViewState extends State<FavoriteView> {
  final AuthService _authService = AuthService();
  final FavoriteService _favoriteService = FavoriteService();
  List<FavoriteQuest> _favorites = [];
  bool _isLoading = true;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        _favorites = await _favoriteService.getFavoritesByUserId(userId);
      }
    } catch (e) {
      _logger.e('Error loading favorites: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: _favorites.isEmpty ? _buildEmptyState() : _buildFavoritesList(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Favorites Yet',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Add quests to favorites from the quest list',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final favorite = _favorites[index];
        return _buildFavoriteCard(favorite);
      },
    );
  }

  Widget _buildFavoriteCard(FavoriteQuest favorite) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.favorite, color: Colors.red),
        title: Text(favorite.title),
        subtitle: Text('Added on ${_formatDate(favorite.addedAt)}'),
        trailing: IconButton(
          onPressed: () => _removeFavorite(favorite),
          icon: const Icon(Icons.delete_outline),
        ),
        onTap: () {
          // TODO: Navigate to quest detail or quest list with filter
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Opening ${favorite.title}')));
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _removeFavorite(FavoriteQuest favorite) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Favorite'),
            content: Text('Remove "${favorite.title}" from favorites?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _favoriteService.removeFavorite(favorite.questId, favorite.userId);
      _loadFavorites();
    }
  }
}
