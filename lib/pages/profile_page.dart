import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_pc_page.dart';
import '../utils/session_manager.dart';
import '../utils/api_config.dart';
import '../utils/theme_manager.dart';
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

  List<Map<String, dynamic>> checkHistory = [];

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
      final token = await SessionManager.getAuthToken() ?? '';
      final url = Uri.parse('${ApiConfig.baseUrl}/user/${widget.userEmail}');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            final rawHistory =
                (data['user']['checkHistory'] as List<dynamic>? ?? []);
            setState(() {
              userData = data['user'];
              checkHistory = rawHistory.map((e) {
                final status = e['status'] as String? ?? '';
                return {
                  'game': e['game'] as String? ?? '',
                  'fps': '${e['fps'] ?? 0} FPS',
                  'result': _statusText(status),
                  'icon': _statusIcon(status),
                  'color': _statusColor(status),
                };
              }).toList();
              _isRefreshing = false;
            });
          }
        }
      } else {
        if (mounted) setState(() => _isRefreshing = false);
      }
    } catch (e) {
      debugPrint("Ошибка загрузки профиля: $e");
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'excellent': return 'Отлично';
      case 'good': return 'Хорошо';
      case 'playable': return 'Играбельно';
      case 'insufficient': return 'Недостаточно';
      default: return 'Неизвестно';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'excellent': return Icons.check_circle;
      case 'good': return Icons.thumb_up;
      case 'playable': return Icons.warning;
      case 'insufficient': return Icons.error;
      default: return Icons.help;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'excellent': return const Color(0xFF4CAF50);
      case 'good': return const Color(0xFF6C63FF);
      case 'playable': return const Color(0xFFFFA726);
      case 'insufficient': return Colors.red;
      default: return Colors.grey;
    }
  }

  // ── Edit username dialog ───────────────────────────────────────────────────
  void _showEditUsernameDialog() {
    final ctrl = TextEditingController(text: userData?['username'] ?? '');
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit, color: Color(0xFF6C63FF), size: 24),
              SizedBox(width: 10),
              Text('Изменить имя',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
            ],
          ),
          content: _dialogTextField(ctrl, 'Новое имя пользователя', Icons.person_outline),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: Text('Отмена', style: TextStyle(color: Colors.white.withOpacity(0.6))),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final newName = ctrl.text.trim();
                      if (newName.isEmpty) return;
                      setDialogState(() => saving = true);
                      try {
                        final token = await SessionManager.getAuthToken() ?? '';
                        final resp = await http.post(
                          Uri.parse('${ApiConfig.baseUrl}/update-profile'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token',
                          },
                          body: jsonEncode({
                            'email': widget.userEmail,
                            'username': newName,
                          }),
                        );
                        if (!mounted) return;
                        final data = jsonDecode(resp.body);
                        if (data['success'] == true) {
                          Navigator.pop(ctx);
                          await fetchUserData();
                          _showSnackBar('Имя успешно изменено', const Color(0xFF4CAF50));
                        } else {
                          _showSnackBar(data['message'] ?? 'Ошибка', Colors.red);
                        }
                      } catch (e) {
                        _showSnackBar('Ошибка соединения', Colors.red);
                      } finally {
                        setDialogState(() => saving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: saving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Сохранить', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Change password dialog ─────────────────────────────────────────────────
  void _showChangePasswordDialog() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Color(0xFF6C63FF), size: 24),
              SizedBox(width: 10),
              Text('Смена пароля',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogTextField(oldPassCtrl, 'Текущий пароль', Icons.lock_outline, obscure: true),
              const SizedBox(height: 10),
              _dialogTextField(newPassCtrl, 'Новый пароль', Icons.lock_reset, obscure: true),
              const SizedBox(height: 10),
              _dialogTextField(confirmCtrl, 'Подтвердите пароль', Icons.lock_reset, obscure: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: Text('Отмена', style: TextStyle(color: Colors.white.withOpacity(0.6))),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final oldPass = oldPassCtrl.text;
                      final newPass = newPassCtrl.text;
                      final confirm = confirmCtrl.text;

                      if (oldPass.isEmpty || newPass.isEmpty) {
                        _showSnackBar('Заполните все поля', Colors.orange);
                        return;
                      }
                      if (newPass.length < 8) {
                        _showSnackBar('Пароль минимум 8 символов', Colors.orange);
                        return;
                      }
                      if (newPass != confirm) {
                        _showSnackBar('Пароли не совпадают', Colors.red);
                        return;
                      }

                      setDialogState(() => saving = true);
                      try {
                        final token = await SessionManager.getAuthToken() ?? '';
                        final resp = await http.post(
                          Uri.parse('${ApiConfig.baseUrl}/change-password'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token',
                          },
                          body: jsonEncode({
                            'email': widget.userEmail,
                            'oldPassword': oldPass,
                            'newPassword': newPass,
                          }),
                        );
                        if (!mounted) return;
                        final data = jsonDecode(resp.body);
                        if (data['success'] == true) {
                          Navigator.pop(ctx);
                          _showSnackBar('Пароль успешно изменён', const Color(0xFF4CAF50));
                        } else {
                          _showSnackBar(data['message'] ?? 'Ошибка', Colors.red);
                        }
                      } catch (e) {
                        _showSnackBar('Ошибка соединения', Colors.red);
                      } finally {
                        setDialogState(() => saving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: saving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Изменить', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogTextField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
                        if (checkHistory.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              "Вы ещё не проверяли совместимость игр",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          ...checkHistory.map((check) => _buildHistoryCard(check)).toList(),

                        const SizedBox(height: 32),

                        Column(
                          children: [
                            // Theme toggle
                            ValueListenableBuilder<ThemeMode>(
                              valueListenable: ThemeManager.notifier,
                              builder: (_, mode, __) {
                                final isDark = mode == ThemeMode.dark;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A2E),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isDark
                                            ? Icons.dark_mode_rounded
                                            : Icons.light_mode_rounded,
                                        color: isDark
                                            ? const Color(0xFF6C63FF)
                                            : const Color(0xFFFFB300),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          isDark
                                              ? 'Тёмная тема'
                                              : 'Светлая тема',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Switch(
                                        value: isDark,
                                        onChanged: (val) =>
                                            ThemeManager.setDarkMode(val),
                                        activeColor: const Color(0xFF6C63FF),
                                        inactiveThumbColor:
                                            const Color(0xFFFFB300),
                                        inactiveTrackColor:
                                            const Color(0xFFFFB300)
                                                .withOpacity(0.35),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 12),

                            // Edit username
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed: _showEditUsernameDialog,
                                icon: const Icon(Icons.person_outline, size: 20),
                                label: const Text(
                                  "Изменить имя",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C63FF).withOpacity(0.8),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Change password
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed: _showChangePasswordDialog,
                                icon: const Icon(Icons.lock_outline, size: 20),
                                label: const Text(
                                  "Сменить пароль",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A1A2E),
                                  foregroundColor: const Color(0xFF6C63FF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: const Color(0xFF6C63FF).withOpacity(0.5),
                                    ),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Edit PC
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