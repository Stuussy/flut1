import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_pc_page.dart';
import '../utils/session_manager.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final String userEmail;

  const ProfilePage({super.key, required this.userEmail});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? userData;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isRefreshing = false;

  final List<Map<String, dynamic>> checkHistory = [
    {"game": "Counter-Strike 2", "fps": "200 FPS", "result": "Отлично", "icon": Icons.check_circle, "color": Color(0xFF4CAF50)},
    {"game": "PUBG: Battlegrounds", "fps": "80 FPS", "result": "Хорошо", "icon": Icons.thumb_up, "color": Color(0xFF6C63FF)},
    {"game": "Valorant", "fps": "150 FPS", "result": "Отлично", "icon": Icons.check_circle, "color": Color(0xFF4CAF50)},
  ];

  @override
  void initState() {
    super.initState();
    fetchUserData();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      final url = Uri.parse('http://localhost:3001/user/${widget.userEmail}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              userData = data['user'];
              _isRefreshing = false;
            });
          }
        }
      } else {
        setState(() {
          _isRefreshing = false;
        });
      }
    } catch (e) {
      debugPrint("Ошибка загрузки профиля: $e");
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Выйти из аккаунта?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          "Вы уверены, что хотите выйти?",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Отмена", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              await SessionManager.logout();

              if (!mounted) return;

              Navigator.pop(context); // Закрываем диалог

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Выйти"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pc = userData?['pcSpecs'];
    
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1E),
      body: SafeArea(
        child: userData == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF6C63FF),
                ),
              )
            : RefreshIndicator(
                color: const Color(0xFF6C63FF),
                backgroundColor: const Color(0xFF1A1A2E),
                onRefresh: fetchUserData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Профиль",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        
                        const SizedBox(height: 32),

                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C63FF).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Color(0xFF6C63FF),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                userData!['username'] ?? 'User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.userEmail,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        if (pc != null && pc['cpu'] != null) ...[
                          _buildSectionTitle("Характеристики ПК", Icons.computer),
                          const SizedBox(height: 16),
                          _buildPCCard(pc),
                          const SizedBox(height: 32),
                        ],

                        _buildSectionTitle("История проверок", Icons.history),
                        const SizedBox(height: 16),
                        ...checkHistory.map((check) => _buildHistoryCard(check)).toList(),

                        const SizedBox(height: 32),

                        Column(
                          children: [
                           SizedBox(
  width: double.infinity,
  height: 54,
  child: ElevatedButton.icon(
    onPressed: _isRefreshing ? null : () async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddPcPage(userEmail: widget.userEmail),
        ),
      );
      
      if (result == true && mounted) {
        await fetchUserData();
      }
    },
    icon: const Icon(Icons.edit, size: 20),
    label: const Text(
      "Изменить ПК",
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
      disabledBackgroundColor: const Color(0xFF6C63FF).withOpacity(0.5),
    ),
  ),
),
                            
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton.icon(
                                onPressed: logout,
                                icon: const Icon(Icons.logout, size: 20),
                                label: const Text(
                                  "Выйти",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(
                                    color: Colors.red.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6C63FF), size: 20),
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
    );
  }

  Widget _buildPCCard(Map<String, dynamic> pc) {
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
        children: [
          _buildSpecRow(Icons.memory, "Процессор", pc['cpu'] ?? 'N/A'),
          const SizedBox(height: 12),
          _buildSpecRow(Icons.videogame_asset, "Видеокарта", pc['gpu'] ?? 'N/A'),
          const SizedBox(height: 12),
          _buildSpecRow(Icons.storage, "Память", pc['ram'] ?? 'N/A'),
          const SizedBox(height: 12),
          _buildSpecRow(Icons.sd_storage, "Хранилище", pc['storage'] ?? 'N/A'),
          const SizedBox(height: 12),
          _buildSpecRow(Icons.computer, "ОС", pc['os'] ?? 'N/A'),
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

  Widget _buildHistoryCard(Map<String, dynamic> check) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: check['color'].withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: check['color'].withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              check['icon'],
              color: check['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check['game'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "${check['fps']} • ${check['result']}",
                  style: TextStyle(
                    color: check['color'],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.white.withOpacity(0.2),
            size: 14,
          ),
        ],
      ),
    );
  }
}