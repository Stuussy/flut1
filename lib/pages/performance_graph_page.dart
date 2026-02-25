import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

class PerformanceGraphPage extends StatefulWidget {
  final String userEmail;

  const PerformanceGraphPage({
    super.key,
    required this.userEmail,
  });

  @override
  State<PerformanceGraphPage> createState() => _PerformanceGraphPageState();
}

class _PerformanceGraphPageState extends State<PerformanceGraphPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  
  List<Map<String, dynamic>> performanceData = [];
  Map<String, dynamic>? userPC;
  bool isLoading = true;

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
    
    loadPerformanceData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> loadPerformanceData() async {
    try {
      final url = Uri.parse('http://localhost:3001/performance-graph');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.userEmail,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            performanceData = List<Map<String, dynamic>>.from(data['performanceData']);
            userPC = data['userPC'];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
        _showSnackBar("Ошибка загрузки данных", Colors.red);
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
                      "График производительности",
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
                  : performanceData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.computer_outlined,
                                color: Colors.white.withOpacity(0.5),
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Добавьте характеристики ПК",
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
                                if (userPC != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF6C63FF),
                                          Color(0xFF4CAF50),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.computer,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            const Expanded(
                                              child: Text(
                                                "Ваш ПК",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        _buildPCSpec(Icons.memory, "CPU", userPC!['cpu'] ?? 'N/A'),
                                        const SizedBox(height: 8),
                                        _buildPCSpec(Icons.videogame_asset, "GPU", userPC!['gpu'] ?? 'N/A'),
                                        const SizedBox(height: 8),
                                        _buildPCSpec(Icons.storage, "RAM", userPC!['ram'] ?? 'N/A'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                ],

                                const Row(
                                  children: [
                                    Icon(Icons.bar_chart, color: Color(0xFF6C63FF), size: 20),
                                    SizedBox(width: 10),
                                    Text(
                                      "Производительность по играм",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                ...performanceData.map((game) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildGamePerformanceCard(game),
                                  );
                                }).toList(),

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

  Widget _buildPCSpec(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Text(
          "$label:",
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
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

  Widget _buildGamePerformanceCard(Map<String, dynamic> game) {
    final String gameTitle = game['game'];
    final int fps = game['fps'];
    final String status = game['status'];
    final statusColor = getStatusColor(status);
    
    final maxFPS = 300;
    final fpsPercentage = (fps / maxFPS).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  getStatusIcon(status),
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gameTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      getStatusText(status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$fps FPS",
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fpsPercentage,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusColor,
                            statusColor.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "${(fpsPercentage * 100).toInt()}%",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}