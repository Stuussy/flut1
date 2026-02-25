import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'ai_chat_page.dart';
import '../utils/session_manager.dart';

class UpgradeRecommendationsPage extends StatefulWidget {
  final String userEmail;
  final String gameTitle;

  const UpgradeRecommendationsPage({
    super.key,
    required this.userEmail,
    required this.gameTitle,
  });

  @override
  State<UpgradeRecommendationsPage> createState() => _UpgradeRecommendationsPageState();
}

class _UpgradeRecommendationsPageState extends State<UpgradeRecommendationsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  
  Map<String, dynamic>? recommendationsData;
  bool isLoading = true;
  
  String selectedBudget = "medium"; // "low", "medium", "high"
  
  final double usdToKztRate = 480.0;

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
    
    loadRecommendations();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> loadRecommendations() async {
    setState(() => isLoading = true);

    try {
      final token = await SessionManager.getAuthToken() ?? '';
      final url = Uri.parse('http://localhost:3001/upgrade-recommendations');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'email': widget.userEmail,
          'gameTitle': widget.gameTitle,
          'budget': selectedBudget,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            recommendationsData = data;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
        _showSnackBar("Ошибка загрузки рекомендаций", Colors.red);
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

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showSnackBar("Не удалось открыть ссылку", Colors.red);
    }
  }

  String _convertToKzt(num usdPrice) {
    final kztPrice = (usdPrice * usdToKztRate).toInt();
    return _formatKzt(kztPrice);
  }
  
  String _formatKzt(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFF44336);
      case 'medium':
        return const Color(0xFFFFA726);
      case 'low':
        return const Color(0xFF6C63FF);
      default:
        return const Color(0xFF6C63FF);
    }
  }

  IconData getComponentIcon(String component) {
    if (component.contains('Процессор')) return Icons.memory;
    if (component.contains('Видеокарта')) return Icons.videogame_asset;
    if (component.contains('память')) return Icons.storage;
    return Icons.hardware;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1E),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Рекомендации по апгрейду",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
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
                  : recommendationsData == null
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
                                "Не удалось загрузить рекомендации",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
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
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.account_balance_wallet,
                                            color: Color(0xFF6C63FF),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            "Выберите бюджет",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildBudgetButton(
                                              "Эконом",
                                              "low",
                                              Icons.savings,
                                              const Color(0xFF4CAF50),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildBudgetButton(
                                              "Средний",
                                              "medium",
                                              Icons.star,
                                              const Color(0xFF6C63FF),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildBudgetButton(
                                              "Премиум",
                                              "high",
                                              Icons.diamond,
                                              const Color(0xFFFFA726),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        color: Color(0xFF6C63FF),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          recommendationsData!['budgetMessage'] ?? "",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                if (recommendationsData!['recommendations'].isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF6C63FF), Color(0xFF9C8ADE)],
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
                                              "Общая стоимость",
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.9),
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "${_convertToKzt(recommendationsData!['totalCost'])} ₸",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 28,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Icon(
                                            Icons.shopping_cart,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                
                                const SizedBox(height: 24),
                                
                                ...List.generate(
                                  recommendationsData!['recommendations'].length,
                                  (index) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildRecommendationCard(
                                      recommendationsData!['recommendations'][index],
                                      index + 1,
                                    ),
                                  ),
                                ),
                                
                                if (recommendationsData!['recommendations'].isEmpty)
                                  Center(
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Icon(
                                            Icons.celebration,
                                            color: Color(0xFF4CAF50),
                                            size: 64,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        const Text(
                                          "🎉 Ваш ПК идеален!",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Для игры ${widget.gameTitle}",
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.6),
                                            fontSize: 14,
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
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetButton(String label, String value, IconData icon, Color color) {
    final isSelected = selectedBudget == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedBudget = value;
        });
        loadRecommendations();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.white.withOpacity(0.4),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation, int number) {
    final priorityColor = getPriorityColor(recommendation['priority']);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: priorityColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "$number",
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                getComponentIcon(recommendation['component']),
                color: priorityColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation['component'],
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AiChatPage(
                        userEmail: widget.userEmail,
                        gameTitle: widget.gameTitle,
                        recommendation: recommendation,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.smart_toy,
                        color: Color(0xFF6C63FF),
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "ИИ помощник",
                        style: TextStyle(
                          color: Color(0xFF6C63FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.close, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Text(
                  "Сейчас:",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation['current'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check, color: Color(0xFF4CAF50), size: 16),
                const SizedBox(width: 8),
                Text(
                  "Улучшить на:",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation['recommended'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Цена",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${_convertToKzt(recommendation['price'])} ₸",
                    style: const TextStyle(
                      color: Color(0xFF6C63FF),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _launchUrl(recommendation['link']),
                icon: const Icon(Icons.shopping_cart, size: 16),
                label: const Text(
                  "Купить",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}