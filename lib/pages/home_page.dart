import 'dart:async';
import '../utils/api_config.dart';
import '../utils/favorites_manager.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gamepulse/pages/game_info_page.dart';
import 'package:gamepulse/pages/performance_graph_page.dart';

class HomePage extends StatefulWidget {
  final String userEmail;

  const HomePage({super.key, required this.userEmail});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late PageController _carouselController;
  int _currentCarouselPage = 0;
  Timer? _carouselTimer;

  List<Map<String, dynamic>> games = [];
  List<Map<String, dynamic>> _filteredGames = [];
  List<String> _favoriteNames = [];
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Local UI metadata for known games; new games get defaults
  static const Map<String, Map<String, dynamic>> _gamesMeta = {
    "Counter-Strike 2": {
      "subtitle": "Тактический шутер",
      "colors": [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
      "image": "https://cdn.akamai.steamstatic.com/steam/apps/730/header.jpg",
    },
    "PUBG: Battlegrounds": {
      "subtitle": "Королевская битва",
      "colors": [Color(0xFF4A90E2), Color(0xFF5B9BD5)],
      "image": "https://cdn.akamai.steamstatic.com/steam/apps/578080/header.jpg",
    },
    "Minecraft": {
      "subtitle": "Песочница выживания",
      "colors": [Color(0xFF4CAF50), Color(0xFF66BB6A)],
      "image": "https://ichef.bbci.co.uk/news/480/cpsprodpb/15F8/production/_131442650_mediaitem131442649.jpg.webp",
    },
    "Valorant": {
      "subtitle": "Онлайн-шутер",
      "colors": [Color(0xFFE91E63), Color(0xFFF48FB1)],
      "image": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ06HnrYEhu3GWf9WQ80DN9RVNBxJf8pr96koaIzq_rzlnDT7C9wJjgwIcq1cy4hShwCjt4wnoN-bEEXE8Hxut7bwGz1Uglmv3l_0igGg&s=10",
    },
    "Cyberpunk 2077": {
      "subtitle": "Ролевая игра",
      "colors": [Color(0xFFFFEB3B), Color(0xFFFFC107)],
      "image": "https://cdn.akamai.steamstatic.com/steam/apps/1091500/header.jpg",
    },
    "Fortnite": {
      "subtitle": "Battle Royale",
      "colors": [Color(0xFF9C27B0), Color(0xFFBA68C8)],
      "image": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTDXJqIDmoPg6jnjMrZEQTJzNpGPOdXfEaSz9nYHkryP72XPC9LZCiyuZbS_Cd0fV2ZyUMg0f8Go58QhGsdBDtCqSitSkDUPgJ-ewQKqUs&s=10",
    },
    "GTA V": {
      "subtitle": "Экшен приключения",
      "colors": [Color(0xFFFF5722), Color(0xFFFF7043)],
      "image": "https://cdn.akamai.steamstatic.com/steam/apps/271590/header.jpg",
    },
    "The Witcher 3": {
      "subtitle": "RPG",
      "colors": [Color(0xFF607D8B), Color(0xFF78909C)],
      "image": "https://cdn.akamai.steamstatic.com/steam/apps/292030/header.jpg",
    },
    "Apex Legends": {
      "subtitle": "Battle Royale",
      "colors": [Color(0xFFF44336), Color(0xFFEF5350)],
      "image": "https://cdn.akamai.steamstatic.com/steam/apps/1172470/header.jpg",
    },
    "Dota 2": {
      "subtitle": "MOBA",
      "colors": [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
      "image": "https://cdn.akamai.steamstatic.com/steam/apps/570/header.jpg",
    },
    "League of Legends": {
      "subtitle": "MOBA",
      "colors": [Color(0xFF00BCD4), Color(0xFF26C6DA)],
      "image": "https://i0.wp.com/highschool.latimes.com/wp-content/uploads/2021/09/league-of-legends.jpeg?fit=1607%2C895&ssl=1",
    },
    "Overwatch 2": {
      "subtitle": "Командный шутер",
      "colors": [Color(0xFFFF9800), Color(0xFFFFB74D)],
      "image": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRTC0OSl0PFIUPiMZSXug145CxVQ2O6quodtg&s",
    },
    "Red Dead Redemption 2": {
      "subtitle": "Приключенческий экшен",
      "colors": [Color(0xFF795548), Color(0xFF8D6E63)],
      "image": "https://cdn.akamai.steamstatic.com/steam/apps/1174180/header.jpg",
    },
    "Elden Ring": {
      "subtitle": "RPG",
      "colors": [Color(0xFF9E9E9E), Color(0xFFBDBDBD)],
      "image": "https://cdn.akamai.steamstatic.com/steam/apps/1245620/header.jpg",
    },
    "Starfield": {
      "subtitle": "Космическая RPG",
      "colors": [Color(0xFF1A237E), Color(0xFF283593)],
      "image": "https://cdn.akamai.steamstatic.com/steam/apps/1716740/header.jpg",
    },
  };

  static const List<Color> _defaultColors = [Color(0xFF6C63FF), Color(0xFF4CAF50)];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    _carouselController = PageController(viewportFraction: 0.8);

    _loadGames();
    _loadFavorites();
  }

  Future<void> _loadGames() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/games'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> raw = data['games'];
          final loaded = raw.map<Map<String, dynamic>>((g) {
            final title = g['title'] as String;
            final meta = _gamesMeta[title];

            // Используем данные из API (image/subtitle), при отсутствии —
            // fallback на локальный _gamesMeta, потом дефолт.
            final apiImage = (g['image'] as String? ?? '').trim();
            final apiSubtitle = (g['subtitle'] as String? ?? '').trim();

            return {
              "title": title,
              "subtitle": apiSubtitle.isNotEmpty
                  ? apiSubtitle
                  : (meta?['subtitle'] ?? "Игра"),
              "colors": meta?['colors'] ?? _defaultColors,
              "image": apiImage.isNotEmpty
                  ? apiImage
                  : (meta?['image'] ?? ""),
            };
          }).toList();
          if (mounted) {
            setState(() {
              games = loaded;
              _filteredGames = loaded;
            });
            _startCarouselAutoScroll();
          }
        }
      }
    } catch (e) {
      debugPrint("Ошибка загрузки игр: $e");
    }
  }

  Future<void> _loadFavorites() async {
    final favs = await FavoritesManager.getFavorites();
    if (mounted) {
      setState(() {
        _favoriteNames = favs;
      });
    }
  }

  Future<void> _toggleFavorite(String gameTitle) async {
    try {
      final added = await FavoritesManager.toggleFavorite(gameTitle);
      await _loadFavorites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              added
                  ? '$gameTitle добавлена в избранное'
                  : '$gameTitle удалена из избранного',
            ),
            backgroundColor:
                added ? const Color(0xFF6C63FF) : Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _startCarouselAutoScroll() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_carouselController.hasClients && games.isNotEmpty) {
        int nextPage = (_currentCarouselPage + 1) % games.length;
        _carouselController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
      _filteredGames = _searchQuery.isEmpty
          ? games
          : games
              .where((g) =>
                  (g['title'] as String).toLowerCase().contains(_searchQuery) ||
                  (g['subtitle'] as String).toLowerCase().contains(_searchQuery))
              .toList();
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    _fadeController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1E),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),

            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: games.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6C63FF),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),

                            _buildCarousel(),

                            const SizedBox(height: 32),

                            // Favourites section
                            if (_favoriteNames.isNotEmpty) ...[
                              _buildSectionHeader(
                                Icons.star_rounded,
                                "Избранное",
                                color: const Color(0xFFFFB300),
                              ),
                              const SizedBox(height: 12),
                              _buildFavoritesRow(),
                              const SizedBox(height: 28),
                            ],

                            _buildSectionHeader(
                              Icons.videogame_asset,
                              "Все игры",
                            ),

                            const SizedBox(height: 12),

                            // Search field
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A2E),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchCtrl,
                                  onChanged: _onSearchChanged,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: Color(0xFF6C63FF),
                                      size: 20,
                                    ),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(
                                              Icons.close,
                                              color: Colors.white.withOpacity(0.5),
                                              size: 18,
                                            ),
                                            onPressed: () {
                                              _searchCtrl.clear();
                                              _onSearchChanged('');
                                            },
                                          )
                                        : null,
                                    hintText: "Поиск игры...",
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            _buildGameGrid(),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title,
      {Color color = const Color(0xFF6C63FF)}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "GamePulse",
                  style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Проверь совместимость игр",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PerformanceGraphPage(userEmail: widget.userEmail),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.3),
                ),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: Color(0xFF6C63FF),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: _carouselController,
        onPageChanged: (index) {
          setState(() {
            _currentCarouselPage = index;
          });
        },
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          final isFav = _favoriteNames.contains(game['title'] as String);

          return AnimatedBuilder(
            animation: _carouselController,
            builder: (context, child) {
              double scale = 1.0;

              if (_carouselController.position.haveDimensions) {
                final currentPage = _carouselController.page ?? 0;
                final distance = (currentPage - index).abs();
                scale = 1.0 - (distance * 0.15).clamp(0.0, 0.15);
              }

              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameInfoPage(
                      title: game["title"]!,
                      image: game["image"]!,
                      userEmail: widget.userEmail,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (game["colors"] as List<Color>)[0].withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: game["colors"],
                          ),
                        ),
                      ),

                      if ((game["image"] as String).isNotEmpty)
                        Image.network(
                          game["image"],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),

                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),

                      // Star button in top-right
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _toggleFavorite(game['title'] as String),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isFav ? Icons.star_rounded : Icons.star_border_rounded,
                              color: isFav
                                  ? const Color(0xFFFFB300)
                                  : Colors.white.withOpacity(0.8),
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game["title"]!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              game["subtitle"]!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
        },
      ),
    );
  }

  /// Horizontal scrollable row of favourite game cards.
  Widget _buildFavoritesRow() {
    final favGames = games
        .where((g) => _favoriteNames.contains(g['title'] as String))
        .toList();

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: favGames.length,
        itemBuilder: (context, index) {
          final game = favGames[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameInfoPage(
                  title: game["title"]!,
                  image: game["image"]!,
                  userEmail: widget.userEmail,
                ),
              ),
            ),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (game["colors"] as List<Color>)[0].withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: game["colors"],
                        ),
                      ),
                    ),
                    if ((game["image"] as String).isNotEmpty)
                      Image.network(
                        game["image"],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.85),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                    // Star badge
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFB300),
                          size: 14,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Text(
                        game["title"]!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameGrid() {
    if (_filteredGames.isEmpty && _searchQuery.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off, color: Colors.white.withOpacity(0.3), size: 48),
              const SizedBox(height: 12),
              Text(
                'Игра не найдена',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _filteredGames.length,
        itemBuilder: (context, index) {
          final game = _filteredGames[index];
          final isFav = _favoriteNames.contains(game['title'] as String);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GameInfoPage(
                    title: game["title"]!,
                    image: game["image"]!,
                    userEmail: widget.userEmail,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (game["colors"] as List<Color>)[0].withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: game["colors"],
                        ),
                      ),
                    ),

                    if ((game["image"] as String).isNotEmpty)
                      Image.network(
                        game["image"],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),

                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.9),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),

                    // Star / favourite toggle
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _toggleFavorite(game['title'] as String),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isFav ? Icons.star_rounded : Icons.star_border_rounded,
                            color: isFav
                                ? const Color(0xFFFFB300)
                                : Colors.white.withOpacity(0.8),
                            size: 16,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              game["title"]!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              game["subtitle"]!,
                              style: TextStyle(
                                color: (game["colors"] as List<Color>)[0],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Проверить",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
