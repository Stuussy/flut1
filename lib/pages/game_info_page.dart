import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'upgrade_recommendations_page.dart';
import '../utils/session_manager.dart';
import '../utils/api_config.dart';

class GameInfoPage extends StatefulWidget {
  final String title;
  final String image;
  final String userEmail;

  const GameInfoPage({
    super.key,
    required this.title,
    required this.image,
    required this.userEmail,
  });

  @override
  State<GameInfoPage> createState() => _GameInfoPageState();
}

class _GameInfoPageState extends State<GameInfoPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  
  Map<String, dynamic>? compatibilityData;
  bool isLoading = true;

  final Map<String, Map<String, dynamic>> gameThemes = {
    "Counter-Strike 2": {
      "colors": [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
      "icon": Icons.whatshot,
    },
    "PUBG: Battlegrounds": {
      "colors": [Color(0xFF4A90E2), Color(0xFF5B9BD5)],
      "icon": Icons.military_tech,
    },
    "Minecraft": {
      "colors": [Color(0xFF4CAF50), Color(0xFF66BB6A)],
      "icon": Icons.view_in_ar,
    },
    "Valorant": {
      "colors": [Color(0xFFE91E63), Color(0xFFF48FB1)],
      "icon": Icons.flash_on,
    },
    "Cyberpunk 2077": {
      "colors": [Color(0xFFFFEB3B), Color(0xFFFFC107)],
      "icon": Icons.theater_comedy,
    },
    "Fortnite": {
      "colors": [Color(0xFF9C27B0), Color(0xFFBA68C8)],
      "icon": Icons.groups,
    },
    "GTA V": {
      "colors": [Color(0xFFFF5722), Color(0xFFFF7043)],
      "icon": Icons.directions_car,
    },
    "The Witcher 3": {
      "colors": [Color(0xFF607D8B), Color(0xFF78909C)],
      "icon": Icons.castle,
    },
    "Apex Legends": {
      "colors": [Color(0xFFF44336), Color(0xFFEF5350)],
      "icon": Icons.sports_esports,
    },
    "Dota 2": {
      "colors": [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
      "icon": Icons.shield,
    },
    "League of Legends": {
      "colors": [Color(0xFF00BCD4), Color(0xFF26C6DA)],
      "icon": Icons.sports_kabaddi,
    },
    "Overwatch 2": {
      "colors": [Color(0xFFFF9800), Color(0xFFFFB74D)],
      "icon": Icons.people,
    },
    "Red Dead Redemption 2": {
      "colors": [Color(0xFF795548), Color(0xFF8D6E63)],
      "icon": Icons.terrain,
    },
    "Elden Ring": {
      "colors": [Color(0xFF9E9E9E), Color(0xFFBDBDBD)],
      "icon": Icons.auto_awesome,
    },
    "Starfield": {
      "colors": [Color(0xFF1A237E), Color(0xFF283593)],
      "icon": Icons.rocket_launch,
    },
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();
    
    checkCompatibility();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> checkCompatibility() async {
    try {
      final token = await SessionManager.getAuthToken() ?? '';
      final url = Uri.parse('${ApiConfig.baseUrl}/check-game-compatibility');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'email': widget.userEmail,
          'gameTitle': widget.title,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            compatibilityData = data;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          _showSnackBar(data['message'] ?? "Ошибка проверки", Colors.red);
        }
      } else {
        setState(() {
          isLoading = false;
        });
        _showSnackBar("Ошибка проверки совместимости", Colors.red);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar("Ошибка соединения: $e", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'excellent':
        return const Color(0xFF4CAF50);
      case 'good':
        return const Color(0xFF6C63FF);
      case 'playable':
        return const Color(0xFFFFA726);
      case 'insufficient':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'excellent':
        return 'Отлично';
      case 'good':
        return 'Хорошо';
      case 'playable':
        return 'Играбельно';
      case 'insufficient':
        return 'Недостаточно';
      default:
        return 'Неизвестно';
    }
  }

  IconData getStatusIcon(String status) {
    switch (status) {
      case 'excellent':
        return Icons.check_circle;
      case 'good':
        return Icons.thumb_up;
      case 'playable':
        return Icons.warning;
      case 'insufficient':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameTheme = gameThemes[widget.title] ?? {
      "colors": [Color(0xFF6C63FF), Color(0xFF4CAF50)],
      "icon": Icons.games,
    };

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1E),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gameTheme["colors"],
                ),
              ),
              child: Stack(
                children: [
                  Opacity(
                    opacity: 0.1,
                    child: Center(
                      child: Icon(
                        gameTheme["icon"],
                        size: 150,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF0D0D1E),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  
                  Positioned(
                    bottom: 20,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Проверка совместимости",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6C63FF),
                      ),
                    )
                  : compatibilityData == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.white.withOpacity(0.5),
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Сначала добавьте характеристики ПК",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF6C63FF),
                          backgroundColor: const Color(0xFF1A1A2E),
                          onRefresh: checkCompatibility,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildCompactResultCard(),

                                  const SizedBox(height: 16),

                                  _buildPCSpecsCard(),

                                  const SizedBox(height: 16),

                                  _buildGameRequirementsCard(),

                                  const SizedBox(height: 16),

                                  if (compatibilityData!['compatibility']['status'] != 'excellent')
                                    _buildUpgradeButton(),

                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactResultCard() {
    final compatibility = compatibilityData!['compatibility'];
    final status = compatibility['status'];
    final statusColor = getStatusColor(status);
    final fps = compatibility['estimatedFPS'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.15),
            statusColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              getStatusIcon(status),
              color: statusColor,
              size: 40,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getStatusText(status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  compatibility['message'],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.speed,
                        color: statusColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "$fps FPS",
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityCard() {
    final compatibility = compatibilityData!['compatibility'];
    final status = compatibility['status'];
    final statusColor = getStatusColor(status);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            getStatusIcon(status),
            color: statusColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            getStatusText(status),
            style: TextStyle(
              color: statusColor,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            compatibility['message'],
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFPSCard() {
    final estimatedFPS = compatibilityData!['compatibility']['estimatedFPS'];
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6C63FF),
            Color(0xFF4CAF50),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Ожидаемый FPS",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "$estimatedFPS",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.speed,
              color: Colors.white,
              size: 48,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameRequirementsCard() {
    final gameReqs = compatibilityData!['gameRequirements'];

    if (gameReqs == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt, color: Color(0xFF6C63FF), size: 20),
              const SizedBox(width: 10),
              const Text(
                "Требования игры",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildCompactRequirementRow(
            "Минимум",
            gameReqs['minimum'],
            const Color(0xFFFFA726),
          ),

          const Divider(height: 16, color: Colors.white10),

          _buildCompactRequirementRow(
            "Рекомендуется",
            gameReqs['recommended'],
            const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRequirementRow(String label, Map<String, dynamic> reqs, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildSmallChip("CPU", reqs['cpu'] is List ? (reqs['cpu'] as List).first : reqs['cpu'], Icons.memory),
            _buildSmallChip("GPU", reqs['gpu'] is List ? (reqs['gpu'] as List).first : reqs['gpu'], Icons.videogame_asset),
            _buildSmallChip("RAM", reqs['ram'], Icons.storage),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 6),
          Text(
            "$label: ",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRequirementsSection(String title, Map<String, dynamic> reqs, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSpecRow(Icons.memory, "CPU", _formatList(reqs['cpu'])),
        const SizedBox(height: 8),
        _buildSpecRow(Icons.videogame_asset, "GPU", _formatList(reqs['gpu'])),
        const SizedBox(height: 8),
        _buildSpecRow(Icons.storage, "RAM", reqs['ram'] ?? 'N/A'),
      ],
    );
  }
  
  String _formatList(dynamic value) {
    if (value is List) {
      return value.join(', ');
    }
    return value?.toString() ?? 'N/A';
  }

  Widget _buildPCSpecsCard() {
    final userPC = compatibilityData!['userPC'];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.computer, color: Color(0xFF6C63FF), size: 20),
              SizedBox(width: 10),
              Text(
                "Ваш ПК",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSpecRow(Icons.memory, "CPU", userPC['cpu'] ?? 'N/A'),
          const SizedBox(height: 12),
          _buildSpecRow(Icons.videogame_asset, "GPU", userPC['gpu'] ?? 'N/A'),
          const SizedBox(height: 12),
          _buildSpecRow(Icons.storage, "RAM", userPC['ram'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6C63FF), size: 18),
        const SizedBox(width: 12),
        Text(
          "$label:",
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradeButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UpgradeRecommendationsPage(
                userEmail: widget.userEmail,
                gameTitle: widget.title,
              ),
            ),
          );
        },
        icon: const Icon(Icons.upgrade, size: 20),
        label: const Text(
          "Рекомендации по улучшению",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}