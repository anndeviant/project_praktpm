import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/favorite_service.dart';
import '../services/prayer_service.dart';
import '../models/favorite_model.dart';
import '../models/prayer_model.dart';
import '../widgets/quest_theme.dart';
import 'package:logger/logger.dart';

class FavoriteView extends StatefulWidget {
  const FavoriteView({super.key});

  @override
  State<FavoriteView> createState() => _FavoriteViewState();
}

class _FavoriteViewState extends State<FavoriteView> {
  final AuthService _authService = AuthService();
  final FavoriteService _favoriteService = FavoriteService();
  final PrayerService _prayerService = PrayerService();
  List<FavoriteQuest> _favorites = [];
  RandomDua? _randomDoa;
  bool _isLoading = true;
  bool _isDoaLoading = false;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadFavorites(), _loadRandomDoa()]);
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

  Future<void> _loadRandomDoa() async {
    setState(() => _isDoaLoading = true);
    try {
      _randomDoa = await _prayerService.getRandomDoa();
    } catch (e) {
      _logger.e('Error loading random doa: $e');
    } finally {
      setState(() => _isDoaLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildRandomDoaCard(),
                    if (_favorites.isEmpty)
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: _buildEmptyState(),
                      )
                    else
                      _buildFavoritesList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildRandomDoaCard() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.book, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      'Doa Harian',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _isDoaLoading ? null : _loadRandomDoa,
                  icon:
                      _isDoaLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_randomDoa != null) ...[
              Text(
                _randomDoa!.judul,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _randomDoa!.arab,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _randomDoa!.indo,
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Sumber: ${_randomDoa!.source}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else if (_isDoaLoading) ...[
              const SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator()),
              ),
            ] else ...[
              SizedBox(
                height: 60,
                child: Center(
                  child: Text(
                    'Gagal memuat doa',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
