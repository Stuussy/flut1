import 'dart:async';
import '../utils/api_config.dart';
import '../utils/app_colors.dart';
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
  String? _selectedGenre; // null = все жанры

  // ─── Состояние ошибки сети ───────────────────────────────────────────────
  bool _hasError = false;
  String _errorMessage = '';

  // ─── Жанры ──────────────────────────────────────────────────────────────
  static const List<String> _genreList = [
    'Шутер',
    'RPG',
    'MOBA',
    'Battle Royale',
    'Экшен',
    'Песочница',
  ];

  /// Определяет жанр игры по subtitle.
  String _genreFor(String subtitle) {
    final s = subtitle.toLowerCase();
    if (s.contains('moba')) return 'MOBA';
    if (s.contains('battle royale') || s.contains('королевская')) {
      return 'Battle Royale';
    }
    if (s.contains('rpg') || s.contains('ролевая')) return 'RPG';
    if (s.contains('шутер')) return 'Шутер';
    if (s.contains('экшен') || s.contains('приключ')) return 'Экшен';
    if (s.contains('песочница')) return 'Песочница';
    return '';
  }

  // ─── Локальные метаданные (цвета + fallback image/subtitle) ─────────────
  static const Map<String, Map<String, dynamic>> _gamesMeta = {
    "Counter-Strike 2": {
      "subtitle": "Тактический шутер",
      "colors": [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
      "image": "https://cdn.akamai.steamstatic.com/steam/apps/730/header.jpg",
    },
    "PUBG: Battlegrounds": {
      "subtitle": "Королевская битва",
      "colors": [Color(0xFF4A90E2), Color(0xFF5B9BD5)],
      "image":
          "https://cdn.akamai.steamstatic.com/steam/apps/578080/header.jpg",
    },
    "Minecraft": {
      "subtitle": "Песочница выживания",
      "colors": [Color(0xFF4CAF50), Color(0xFF66BB6A)],
      "image":
          "https://ichef.bbci.co.uk/news/480/cpsprodpb/15F8/production/_131442650_mediaitem131442649.jpg.webp",
    },
    "Valorant": {
      "subtitle": "Онлайн-шутер",
      "colors": [Color(0xFFE91E63), Color(0xFFF48FB1)],
      "image":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ06HnrYEhu3GWf9WQ80DN9RVNBxJf8pr96koaIzq_rzlnDT7C9wJjgwIcq1cy4hShwCjt4wnoN-bEEXE8Hxut7bwGz1Uglmv3l_0igGg&s=10",
    },
    "Cyberpunk 2077": {
      "subtitle": "Ролевая игра",
      "colors": [Color(0xFFFFEB3B), Color(0xFFFFC107)],
      "image":
          "https://cdn.akamai.steamstatic.com/steam/apps/1091500/header.jpg",
    },
    "Fortnite": {
      "subtitle": "Battle Royale",
      "colors": [Color(0xFF9C27B0), Color(0xFFBA68C8)],
      "image":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTDXJqIDmoPg6jnjMrZEQTJzNpGPOdXfEaSz9nYHkryP72XPC9LZCiyuZbS_Cd0fV2ZyUMg0f8Go58QhGsdBDtCqSitSkDUPgJ-ewQKqUs&s=10",
    },
    "GTA V": {
      "subtitle": "Экшен приключения",
      "colors": [Color(0xFFFF5722), Color(0xFFFF7043)],
      "image":
          "https://cdn.akamai.steamstatic.com/steam/apps/271590/header.jpg",
    },
    "The Witcher 3": {
      "subtitle": "RPG",
      "colors": [Color(0xFF607D8B), Color(0xFF78909C)],
      "image":
          "https://cdn.akamai.steamstatic.com/steam/apps/292030/header.jpg",
    },
    "Apex Legends": {
      "subtitle": "Battle Royale",
      "colors": [Color(0xFFF44336), Color(0xFFEF5350)],
      "image":
          "https://cdn.akamai.steamstatic.com/steam/apps/1172470/header.jpg",
    },
    "Dota 2": {
      "subtitle": "MOBA",
      "colors": [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
      "image": "https://cdn.akamai.steamstatic.com/steam/apps/570/header.jpg",
    },
    "League of Legends": {
      "subtitle": "MOBA",
      "colors": [Color(0xFF00BCD4), Color(0xFF26C6DA)],
      "image":
          "https://i0.wp.com/highschool.latimes.com/wp-content/uploads/2021/09/league-of-legends.jpeg?fit=1607%2C895&ssl=1",
    },
    "Overwatch 2": {
      "subtitle": "Командный шутер",
      "colors": [Color(0xFFFF9800), Color(0xFFFFB74D)],
      "image":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRTC0OSl0PFIUPiMZSXug145CxVQ2O6quodtg&s",
    },
    "Red Dead Redemption 2": {
      "subtitle": "Приключенческий экшен",
      "colors": [Color(0xFF795548), Color(0xFF8D6E63)],
      "image":
          "https://cdn.akamai.steamstatic.com/steam/apps/1174180/header.jpg",
    },
    "Elden Ring": {
      "subtitle": "RPG",
      "colors": [Color(0xFF9E9E9E), Color(0xFFBDBDBD)],
      "image":
          "https://cdn.akamai.steamstatic.com/steam/apps/1245620/header.jpg",
    },
    "Starfield": {
      "subtitle": "Космическая RPG",
      "colors": [Color(0xFF1A237E), Color(0xFF283593)],
      "image":
          "https://cdn.akamai.steamstatic.com/steam/apps/1716740/header.jpg",
    },
  };

  static const List<Color> _defaultColors = [
    Color(0xFF6C63FF),
    Color(0xFF4CAF50)
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    _carouselController = PageController(viewportFraction: 0.8);

    // Слушаем изменения избранного из любого места приложения
    FavoritesManager.changeCount.addListener(_loadFavorites);

    _loadGames();
    _loadFavorites();
  }

  // ─── Загрузка игр ────────────────────────────────────────────────────────
  Future<void> _loadGames() async {
    if (mounted) setState(() => _hasError = false);

    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/games'))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> raw = data['games'];
          final loaded = raw.map<Map<String, dynamic>>((g) {
            final title = g['title'] as String;
            final meta = _gamesMeta[title];

            final apiImage = (g['image'] as String? ?? '').trim();
            final apiSubtitle = (g['subtitle'] as String? ?? '').trim();
            final subtitle = apiSubtitle.isNotEmpty
                ? apiSubtitle
                : (meta?['subtitle'] ?? 'Игра');

            return {
              'title': title,
              'subtitle': subtitle,
              'genre': _genreFor(subtitle),
              'colors': meta?['colors'] ?? _defaultColors,
              'image':
                  apiImage.isNotEmpty ? apiImage : (meta?['image'] ?? ''),
            };
          }).toList();

          if (mounted) {
            setState(() {
              games = loaded;
              _filteredGames = loaded;
              _hasError = false;
            });
            _startCarouselAutoScroll();
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Ошибка сервера (${response.statusCode})';
          });
        }
      }
    } catch (e) {
      debugPrint("Ошибка загрузки игр: $e");
      if (mounted) {
        final msg = e.toString().toLowerCase();
        final isNetwork = msg.contains('socket') ||
            msg.contains('connection') ||
            msg.contains('timeout') ||
            msg.contains('network') ||
            msg.contains('failed host');
        setState(() {
          _hasError = true;
          _errorMessage = isNetwork
              ? 'Нет подключения к интернету'
              : 'Не удалось загрузить данные';
        });
      }
    }
  }

  // ─── Избранное ───────────────────────────────────────────────────────────
  Future<void> _loadFavorites() async {
    final favs = await FavoritesManager.getFavorites();
    if (mounted) setState(() => _favoriteNames = favs);
  }

  Future<void> _toggleFavorite(String gameTitle) async {
    final isFav = _favoriteNames.contains(gameTitle);

    // Проверяем лимит ДО запроса — моментальная обратная связь
    if (!isFav && _favoriteNames.length >= FavoritesManager.maxFavorites) {
      _showFavoritesLimitSheet();
      return;
    }

    // ── Оптимистичное обновление (UI меняется немедленно) ─────────────────
    setState(() {
      if (isFav) {
        _favoriteNames =
            _favoriteNames.where((n) => n != gameTitle).toList();
      } else {
        _favoriteNames = [..._favoriteNames, gameTitle];
      }
    });

    try {
      final added = await FavoritesManager.toggleFavorite(gameTitle);
      // Синхронизируемся с реальным хранилищем
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
      // Откатываем оптимистичное обновление при ошибке
      await _loadFavorites();
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

  // ─── Фильтры ─────────────────────────────────────────────────────────────
  void _applyFilters() {
    setState(() {
      _filteredGames = games.where((g) {
        final matchesSearch = _searchQuery.isEmpty ||
            (g['title'] as String).toLowerCase().contains(_searchQuery) ||
            (g['subtitle'] as String).toLowerCase().contains(_searchQuery);
        final matchesGenre = _selectedGenre == null ||
            (g['genre'] as String) == _selectedGenre;
        return matchesSearch && matchesGenre;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applyFilters();
  }

  void _selectGenre(String genre) {
    setState(() {
      _selectedGenre = (_selectedGenre == genre) ? null : genre;
    });
    _applyFilters();
  }

  // ─── Карусель ────────────────────────────────────────────────────────────
  void _startCarouselAutoScroll() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_carouselController.hasClients && games.isNotEmpty) {
        final nextPage = (_currentCarouselPage + 1) % games.length;
        _carouselController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    FavoritesManager.changeCount.removeListener(_loadFavorites);
    _carouselTimer?.cancel();
    _carouselController.dispose();
    _fadeController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return Scaffold(
      backgroundColor: ac.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _hasError
                  ? _buildNoInternetWidget()
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: games.isEmpty
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF6C63FF),
                              ),
                            )
                          : _buildContent(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      color: const Color(0xFF6C63FF),
      backgroundColor: AppColors.of(context).card,
      onRefresh: () async {
        await _loadGames();
        await _loadFavorites();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          _buildCarousel(),

          const SizedBox(height: 32),

          // ── Избранное ────────────────────────────────────────────────────
          if (_favoriteNames.isNotEmpty) ...[
            _buildSectionHeader(
              Icons.star_rounded,
              'Избранное (${_favoriteNames.length}/${FavoritesManager.maxFavorites})',
              color: const Color(0xFFFFB300),
            ),
            const SizedBox(height: 12),
            _buildFavoritesRow(),
            const SizedBox(height: 28),
          ],

          // ── Все игры ─────────────────────────────────────────────────────
          _buildSectionHeader(Icons.videogame_asset, 'Все игры'),
          const SizedBox(height: 12),

          // Поиск
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Builder(builder: (context) {
              final ac = AppColors.of(context);
              return Container(
                decoration: BoxDecoration(
                  color: ac.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ac.inputBorder),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  style: TextStyle(color: ac.text, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search,
                        color: Color(0xFF6C63FF), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close,
                                color: ac.textMuted, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    hintText: 'Поиск игры...',
                    hintStyle: TextStyle(
                        color: ac.textHint, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          // ── Фильтры по жанру ─────────────────────────────────────────────
          _buildGenreFilters(),

          const SizedBox(height: 16),

          _buildGameGrid(),

          const SizedBox(height: 20),
        ],
      ),
      ),
    );
  }

  // ─── Экран ошибки сети ───────────────────────────────────────────────────
  Widget _buildNoInternetWidget() {
    final ac = AppColors.of(context);
    final isNetworkErr = _errorMessage.contains('интернет') ||
        _errorMessage.contains('подключ');
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isNetworkErr ? Colors.red : Colors.orange)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNetworkErr ? Icons.wifi_off_rounded : Icons.error_outline,
                color: isNetworkErr ? Colors.red : Colors.orange,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isNetworkErr ? 'Нет подключения' : 'Ошибка загрузки',
              style: TextStyle(
                  color: ac.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: ac.textMuted,
                  fontSize: 14,
                  height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadGames,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Повторить',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Лимит избранного ────────────────────────────────────────────────────
  void _showFavoritesLimitSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Builder(builder: (sheetCtx) {
        final ac = AppColors.of(sheetCtx);
        return Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: ac.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ac.text.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded,
                  color: Color(0xFFFFB300), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Лимит избранного',
              style: TextStyle(
                  color: ac.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Вы уже добавили максимальное количество игр '
              '(${FavoritesManager.maxFavorites} из ${FavoritesManager.maxFavorites}).\n'
              'Снимите звёздочку с одной игры, чтобы добавить новую.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: ac.textSecondary,
                  fontSize: 14,
                  height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text('Понятно',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
      }),
    );
  }

  // ─── Заголовок секции ─────────────────────────────────────────────────────
  Widget _buildSectionHeader(IconData icon, String title,
      {Color color = const Color(0xFF6C63FF)}) {
    final ac = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
                color: ac.text,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    final ac = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ac.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
                    color: ac.textSecondary,
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
                  builder: (_) =>
                      PerformanceGraphPage(userEmail: widget.userEmail),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.bar_chart_rounded,
                  color: Color(0xFF6C63FF), size: 24),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Фильтры жанра ───────────────────────────────────────────────────────
  Widget _buildGenreFilters() {
    final ac = AppColors.of(context);
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _genreList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final genre = _genreList[i];
          final isActive = _selectedGenre == genre;
          return GestureDetector(
            onTap: () => _selectGenre(genre),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF6C63FF)
                    : ac.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF6C63FF)
                      : ac.text.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                genre,
                style: TextStyle(
                  color: isActive ? Colors.white : ac.textSecondary,
                  fontSize: 12,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Placeholder для изображения ─────────────────────────────────────────
  Widget _buildImagePlaceholder({double iconSize = 28}) {
    final ac = AppColors.of(context);
    return Container(
      color: ac.card,
      child: Center(
        child: Icon(
          Icons.videogame_asset_outlined,
          color: ac.text.withValues(alpha: 0.12),
          size: iconSize,
        ),
      ),
    );
  }

  // ─── Карусель ────────────────────────────────────────────────────────────
  Widget _buildCarousel() {
    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: _carouselController,
        onPageChanged: (index) {
          setState(() => _currentCarouselPage = index);
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
              return Transform.scale(scale: scale, child: child);
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
                      color: (game["colors"] as List<Color>)[0]
                          .withValues(alpha: 0.3),
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
                      // Gradient bg
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: game["colors"],
                          ),
                        ),
                      ),
                      // Image with placeholder
                      if ((game["image"] as String).isNotEmpty)
                        Image.network(
                          game["image"],
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                                  ? child
                                  : _buildImagePlaceholder(),
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                        ),
                      // Bottom gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                      // Star button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () =>
                              _toggleFavorite(game['title'] as String),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isFav
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: isFav
                                  ? const Color(0xFFFFB300)
                                  : Colors.white.withValues(alpha: 0.8),
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      // Title + subtitle
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
                                  fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              game["subtitle"]!,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11),
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

  // ─── Строка избранных ────────────────────────────────────────────────────
  Widget _buildFavoritesRow() {
    final favGames =
        games.where((g) => _favoriteNames.contains(g['title'])).toList();

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
                    color: (game["colors"] as List<Color>)[0]
                        .withValues(alpha: 0.25),
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
                        loadingBuilder: (_, child, progress) =>
                            progress == null
                                ? child
                                : _buildImagePlaceholder(iconSize: 20),
                        errorBuilder: (_, __, ___) =>
                            const SizedBox.shrink(),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.star_rounded,
                            color: Color(0xFFFFB300), size: 14),
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
                            fontWeight: FontWeight.w700),
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

  // ─── Сетка игр ───────────────────────────────────────────────────────────
  Widget _buildGameGrid() {
    final isEmpty =
        _filteredGames.isEmpty && (_searchQuery.isNotEmpty || _selectedGenre != null);

    if (isEmpty) {
      final ac = AppColors.of(context);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off,
                  color: ac.textMuted, size: 48),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Игра не найдена'
                    : 'Нет игр в этом жанре',
                style: TextStyle(
                    color: ac.textMuted, fontSize: 15),
              ),
              if (_selectedGenre != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedGenre = null);
                    _applyFilters();
                  },
                  child: const Text('Сбросить фильтр',
                      style: TextStyle(color: Color(0xFF6C63FF))),
                ),
              ],
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
          final isFav =
              _favoriteNames.contains(game['title'] as String);

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
                    color: (game["colors"] as List<Color>)[0]
                        .withValues(alpha: 0.2),
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
                        loadingBuilder: (_, child, progress) =>
                            progress == null
                                ? child
                                : _buildImagePlaceholder(),
                        errorBuilder: (_, __, ___) =>
                            const SizedBox.shrink(),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.9),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                    // Star button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () =>
                            _toggleFavorite(game['title'] as String),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isFav
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: isFav
                                ? const Color(0xFFFFB300)
                                : Colors.white.withValues(alpha: 0.8),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    // Info
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
                                  fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              game["subtitle"]!,
                              style: TextStyle(
                                  color: (game["colors"] as List<Color>)[0],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow,
                                      color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text('Проверить',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
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
