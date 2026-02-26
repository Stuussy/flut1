import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'ai_chat_page.dart';
import '../utils/session_manager.dart';
import '../utils/api_config.dart';

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

  // AI Smart Recommendations state
  Map<String, dynamic>? _aiSmartData;
  bool _aiSmartLoading = false;
  bool _aiSmartVisible = false;

  String selectedBudget = "medium"; // "low", "medium", "high"

  double _usdToKztRate = 480.0;

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

    _fetchKztRate();
    loadRecommendations();
  }

  Future<void> _fetchKztRate() async {
    try {
      final resp = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/USD'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['result'] == 'success') {
          final rate = (data['rates']['KZT'] as num?)?.toDouble();
          if (rate != null && mounted) {
            setState(() => _usdToKztRate = rate);
          }
        }
      }
    } catch (_) {
      // Fall back to hardcoded rate — no action needed
    }
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
      final url = Uri.parse('${ApiConfig.baseUrl}/upgrade-recommendations');
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

  Future<void> _loadAiSmartRecommendations() async {
    setState(() {
      _aiSmartLoading = true;
      _aiSmartVisible = true;
    });

    try {
      final token = await SessionManager.getAuthToken() ?? '';
      final budgetAmount = selectedBudget == 'low' ? 200 : selectedBudget == 'high' ? 1000 : 500;
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/ai-smart-upgrade-recommendations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'email': widget.userEmail,
          'gameTitle': widget.gameTitle,
          'budget': budgetAmount,
          'targetFPS': 60,
        }),
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['success'] == true) {
          setState(() {
            _aiSmartData = data;
            _aiSmartLoading = false;
          });
        } else {
          setState(() => _aiSmartLoading = false);
          _showSnackBar(data['message'] ?? 'Ошибка AI анализа', Colors.red);
        }
      } else {
        setState(() => _aiSmartLoading = false);
        _showSnackBar('Ошибка сервера: ${resp.statusCode}', Colors.red);
      }
    } catch (e) {
      if (mounted) setState(() => _aiSmartLoading = false);
      _showSnackBar('Ошибка соединения: $e', Colors.red);
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showSnackBar("Не удалось открыть ссылку", Colors.red);
    }
  }

  String _convertToKzt(num usdPrice) {
    final kztPrice = (usdPrice * _usdToKztRate).toInt();
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
                                color: Colors.white.withValues(alpha: 0.5),
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Не удалось загрузить рекомендации",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
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
                                      color: Colors.white.withValues(alpha: 0.1),
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
                                    color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
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
                                                color: Colors.white.withValues(alpha: 0.9),
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
                                            color: Colors.white.withValues(alpha: 0.2),
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

                                // AI Smart Recommendations button
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton.icon(
                                    onPressed: _aiSmartLoading ? null : _loadAiSmartRecommendations,
                                    icon: _aiSmartLoading
                                        ? const SizedBox(
                                            width: 18, height: 18,
                                            child: CircularProgressIndicator(
                                              color: Colors.white, strokeWidth: 2))
                                        : const Icon(Icons.auto_awesome, size: 20),
                                    label: Text(
                                      _aiSmartLoading
                                          ? 'Анализирую систему...'
                                          : 'AI Deep Analysis — Узкое место',
                                      style: const TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF9C27B0),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16)),
                                      elevation: 0,
                                    ),
                                  ),
                                ),

                                // AI Smart results
                                if (_aiSmartVisible && _aiSmartData != null) ...[
                                  const SizedBox(height: 20),
                                  _buildAiSmartSection(_aiSmartData!),
                                ],

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
                                            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
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
                                            color: Colors.white.withValues(alpha: 0.6),
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

  Widget _buildAiSmartSection(Map<String, dynamic> data) {
    final analysis = data['analysis'] as Map<String, dynamic>?;
    final aiRecs = data['recommendations'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF9C27B0).withValues(alpha: 0.15),
            const Color(0xFF6C63FF).withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFF6C63FF)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'AI Smart Analysis',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  widget.gameTitle,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bottleneck highlight
                if (analysis != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Узкое место (Bottleneck)',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          analysis['bottleneck'] ?? '',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          analysis['bottleneckReason'] ?? '',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Impact breakdown
                  _buildImpactRow(Icons.memory, 'CPU', analysis['cpuImpact'] ?? ''),
                  const SizedBox(height: 8),
                  _buildImpactRow(
                      Icons.videogame_asset, 'GPU', analysis['gpuImpact'] ?? ''),
                  const SizedBox(height: 8),
                  _buildImpactRow(Icons.storage, 'RAM', analysis['ramImpact'] ?? ''),
                  const SizedBox(height: 12),

                  // Overall assessment
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      analysis['overallAssessment'] ?? '',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // AI component recommendations
                if (aiRecs.isNotEmpty) ...[
                  const Text(
                    'AI-рекомендации по компонентам',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  ...aiRecs.map<Widget>((rec) {
                    final priority = rec['priority'] as String? ?? 'medium';
                    final pColor = getPriorityColor(priority);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: pColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: pColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  rec['component'] ?? '',
                                  style: TextStyle(
                                      color: pColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  rec['name'] ?? '',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '\$${rec['price']}',
                                style: TextStyle(
                                    color: pColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          if ((rec['reason'] as String? ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              rec['reason'] ?? '',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 11),
                            ),
                          ],
                          if ((rec['fpsGain'] as String? ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.speed,
                                    color: Color(0xFF4CAF50), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  rec['fpsGain'] ?? '',
                                  style: const TextStyle(
                                      color: Color(0xFF4CAF50),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                          if ((rec['link'] as String? ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _launchUrl(rec['link'] as String),
                              child: Row(
                                children: [
                                  const Icon(Icons.shopping_cart_outlined,
                                      color: Color(0xFF6C63FF), size: 14),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Найти на Amazon',
                                    style: TextStyle(
                                        color: Color(0xFF6C63FF),
                                        fontSize: 12,
                                        decoration: TextDecoration.underline),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactRow(IconData icon, String label, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF6C63FF), size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
              color: Color(0xFF6C63FF),
              fontSize: 12,
              fontWeight: FontWeight.w700),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
          ),
        ),
      ],
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
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.white.withValues(alpha: 0.4),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.white.withValues(alpha: 0.6),
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
          color: priorityColor.withValues(alpha: 0.3),
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
                  color: priorityColor.withValues(alpha: 0.15),
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
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
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
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.close, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Text(
                  "Сейчас:",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
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
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check, color: Color(0xFF4CAF50), size: 16),
                const SizedBox(width: 8),
                Text(
                  "Улучшить на:",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
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
                      color: Colors.white.withValues(alpha: 0.5),
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