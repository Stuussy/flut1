import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_add_game_page.dart';
import 'admin_add_component_page.dart';
import 'admin_ai_chat_page.dart';
import 'login_page.dart';

class AdminPanelPage extends StatefulWidget {
  final String adminEmail;

  const AdminPanelPage({super.key, required this.adminEmail});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  static const String _baseUrl = 'http://localhost:3001';

  int _selectedTab = 0;
  List<dynamic> _games = [];
  Map<String, dynamic> _components = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final gamesRes =
          await http.get(Uri.parse('$_baseUrl/admin/games'));
      final compsRes =
          await http.get(Uri.parse('$_baseUrl/admin/components'));

      if (gamesRes.statusCode == 200) {
        final data = jsonDecode(gamesRes.body);
        if (data['success'] == true) _games = data['games'] ?? [];
      }
      if (compsRes.statusCode == 200) {
        final data = jsonDecode(compsRes.body);
        if (data['success'] == true) _components = data['components'] ?? {};
      }
    } catch (e) {
      debugPrint("Error loading admin data: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteGame(String title) async {
    final confirmed = await _showConfirmDialog(
        "Удалить игру", "Вы уверены, что хотите удалить '$title'?");
    if (!confirmed) return;

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/admin/delete-game'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': title}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _showSnackBar("Игра удалена", const Color(0xFF4CAF50));
        _loadData();
      }
    } catch (e) {
      _showSnackBar("Ошибка удаления", Colors.red);
    }
  }

  Future<void> _deleteComponent(String type, String name) async {
    final confirmed = await _showConfirmDialog(
        "Удалить компонент", "Вы уверены, что хотите удалить '$name'?");
    if (!confirmed) return;

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/admin/delete-component'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'type': type, 'name': name}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _showSnackBar("Компонент удалён", const Color(0xFF4CAF50));
        _loadData();
      }
    } catch (e) {
      _showSnackBar("Ошибка удаления", Colors.red);
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            content: Text(message,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7))),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Отмена",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6))),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Удалить"),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  int get _totalComponents {
    int count = 0;
    _components.forEach((key, value) {
      if (value is List) count += value.length;
    });
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1E),
      floatingActionButton: _buildAiHelperFab(),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFFFA726)))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: const Color(0xFFFFA726),
                      child: IndexedStack(
                        index: _selectedTab,
                        children: [
                          _buildGamesTab(),
                          _buildComponentsTab(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAiHelperFab() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AdminAiChatPage(adminEmail: widget.adminEmail),
          ),
        );
      },
      backgroundColor: const Color(0xFF6C63FF),
      icon: const Icon(Icons.smart_toy, color: Colors.white, size: 22),
      label: const Text(
        "ИИ помощник",
        style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA726).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.admin_panel_settings,
                color: Color(0xFFFFA726), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Панель администратора",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      "${_games.length} игр",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12),
                    ),
                    Text(
                      "  |  $_totalComponents компонентов",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.red, size: 22),
              onPressed: _logout,
              tooltip: "Выйти",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildNavItem(
                icon: Icons.games,
                label: "Игры",
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.hardware,
                label: "Компоненты",
                index: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFFA726).withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFFFFA726)
                    : Colors.white.withOpacity(0.4),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFFFFA726)
                      : Colors.white.withOpacity(0.4),
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== GAMES TAB =====================

  Widget _buildGamesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              const Icon(Icons.games, color: Color(0xFFFFA726), size: 20),
              const SizedBox(width: 10),
              Text(
                "Игры (${_games.length})",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminAddGamePage()),
                    );
                    if (result == true) _loadData();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Добавить",
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _games.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.games,
                          color: Colors.white.withOpacity(0.2), size: 64),
                      const SizedBox(height: 16),
                      Text("Нет игр",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: _games.length,
                  itemBuilder: (context, index) =>
                      _buildGameCard(_games[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildGameCard(dynamic game) {
    final title = game['title'] ?? '';
    final min = game['minimum'];
    final rec = game['recommended'];
    final high = game['high'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.games,
                    color: Color(0xFF6C63FF), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: () => _deleteGame(title),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTierInfo("Мин", min, const Color(0xFF4CAF50)),
          const SizedBox(height: 6),
          _buildTierInfo("Рек", rec, const Color(0xFF6C63FF)),
          const SizedBox(height: 6),
          _buildTierInfo("Макс", high, const Color(0xFFFFA726)),
        ],
      ),
    );
  }

  Widget _buildTierInfo(String label, dynamic tier, Color color) {
    if (tier == null) return const SizedBox();
    final cpus = (tier['cpu'] as List?)?.join(', ') ?? '-';
    final gpus = (tier['gpu'] as List?)?.join(', ') ?? '-';
    final ram = tier['ram'] ?? '-';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "CPU: $cpus | GPU: $gpus | RAM: $ram",
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== COMPONENTS TAB =====================

  Widget _buildComponentsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              const Icon(Icons.hardware,
                  color: Color(0xFFFFA726), size: 20),
              const SizedBox(width: 10),
              Text(
                "Компоненты ($_totalComponents)",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const AdminAddComponentPage()),
                    );
                    if (result == true) _loadData();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Добавить",
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _components.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hardware,
                          color: Colors.white.withOpacity(0.2), size: 64),
                      const SizedBox(height: 16),
                      Text("Нет компонентов",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 16)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  children: [
                    if (_components.containsKey('cpu'))
                      _buildComponentSection(
                          "Процессоры (CPU)",
                          Icons.memory,
                          'cpu',
                          _components['cpu']),
                    if (_components.containsKey('gpu'))
                      _buildComponentSection(
                          "Видеокарты (GPU)",
                          Icons.videogame_asset,
                          'gpu',
                          _components['gpu']),
                    if (_components.containsKey('ram'))
                      _buildComponentSection(
                          "Оперативная память (RAM)",
                          Icons.storage,
                          'ram',
                          _components['ram']),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildComponentSection(
      String title, IconData icon, String type, dynamic items) {
    if (items == null || items is! List) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF6C63FF), size: 18),
              const SizedBox(width: 8),
              Text(
                "$title (${items.length})",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        ...items.map<Widget>((comp) => _buildComponentCard(type, comp)),
      ],
    );
  }

  Widget _buildComponentCard(String type, dynamic comp) {
    final name = comp['name'] ?? '';
    final price = comp['price'] ?? 0;
    final performance = comp['performance'] ?? 100;
    final budget = comp['budget'] ?? 'medium';

    Color budgetColor;
    String budgetLabel;
    switch (budget) {
      case 'low':
        budgetColor = const Color(0xFF4CAF50);
        budgetLabel = 'Эконом';
        break;
      case 'high':
        budgetColor = const Color(0xFFFFA726);
        budgetLabel = 'Премиум';
        break;
      default:
        budgetColor = const Color(0xFF6C63FF);
        budgetLabel = 'Средний';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: budgetColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        budgetLabel,
                        style: TextStyle(
                            color: budgetColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "\$$price",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.speed,
                        color: Colors.white.withOpacity(0.3), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "$performance",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.red, size: 18),
              onPressed: () => _deleteComponent(type, name),
            ),
          ),
        ],
      ),
    );
  }
}
