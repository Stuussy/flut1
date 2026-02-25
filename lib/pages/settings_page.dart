import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/theme_manager.dart';
import '../utils/cache_manager.dart';
import 'about_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _purple = Color(0xFF6C63FF);
  static const _card = Color(0xFF1A1A2E);
  static const _bg = Color(0xFF0D0D1E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Тема ──────────────────────────────────────────────
                    _sectionLabel('Оформление'),
                    const SizedBox(height: 10),
                    _buildThemeSelector(),

                    const SizedBox(height: 24),

                    // ── Кэш ───────────────────────────────────────────────
                    _sectionLabel('Данные'),
                    const SizedBox(height: 10),
                    _buildCacheTile(context),

                    const SizedBox(height: 24),

                    // ── Информация ────────────────────────────────────────
                    _sectionLabel('Информация'),
                    const SizedBox(height: 10),
                    _buildInfoGroup(context),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _card,
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
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'Настройки',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withOpacity(0.4),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }

  // ─── Выбор темы (3 кнопки) ───────────────────────────────────────────────
  Widget _buildThemeSelector() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.notifier,
      builder: (_, current, __) {
        return Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    current == ThemeMode.dark
                        ? Icons.dark_mode_rounded
                        : current == ThemeMode.light
                            ? Icons.light_mode_rounded
                            : Icons.brightness_auto_rounded,
                    color: _purple,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Text('Тема приложения',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _themeOption(
                    current,
                    ThemeMode.dark,
                    Icons.dark_mode_rounded,
                    'Тёмная',
                  ),
                  const SizedBox(width: 8),
                  _themeOption(
                    current,
                    ThemeMode.light,
                    Icons.light_mode_rounded,
                    'Светлая',
                  ),
                  const SizedBox(width: 8),
                  _themeOption(
                    current,
                    ThemeMode.system,
                    Icons.brightness_auto_rounded,
                    'Системная',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _themeOption(
      ThemeMode current, ThemeMode value, IconData icon, String label) {
    final isActive = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => ThemeManager.setTheme(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isActive ? _purple : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? _purple : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isActive
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                  size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Очистка кэша ────────────────────────────────────────────────────────
  Widget _buildCacheTile(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: _tile(
        icon: Icons.delete_sweep_rounded,
        iconColor: Colors.red,
        label: 'Очистить кэш',
        subtitle: 'Данные совместимости (TTL 24 ч)',
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: () => _confirmClearCache(context),
      ),
    );
  }

  Future<void> _confirmClearCache(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Очистить кэш?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'Все сохранённые результаты совместимости будут удалены. '
          'При следующем открытии игры данные загрузятся с сервера заново.',
          style: TextStyle(
              color: Colors.white.withOpacity(0.65), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final count = await CacheManager.clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 0
                ? 'Кэш очищен ($count записей)'
                : 'Кэш уже пуст'),
            backgroundColor: count > 0 ? Colors.red : Colors.grey,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ─── Информация ───────────────────────────────────────────────────────────
  Widget _buildInfoGroup(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          _tile(
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF00BCD4),
            label: 'О приложении',
            subtitle: 'Методология, FAQ, статусы FPS',
            trailing:
                const Icon(Icons.chevron_right, color: Colors.white24),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
            showDivider: true,
          ),
          _tile(
            icon: Icons.support_agent_rounded,
            iconColor: const Color(0xFF4CAF50),
            label: 'Поддержка',
            subtitle: 'Сообщить об ошибке или задать вопрос',
            trailing:
                const Icon(Icons.open_in_new_rounded, color: Colors.white24, size: 18),
            onTap: () => _launchSupport(context),
            showDivider: true,
          ),
          _tile(
            icon: Icons.tag_rounded,
            iconColor: Colors.white54,
            label: 'Версия приложения',
            subtitle: 'v1.0.0 (build 1)',
            trailing: null,
            onTap: null,
          ),
        ],
      ),
    );
  }

  Future<void> _launchSupport(BuildContext context) async {
    final uri = Uri.parse('mailto:support@gamepulse.app?subject=GamePulse%20Support');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Напишите нам: support@gamepulse.app'),
          backgroundColor: const Color(0xFF1A1A2E),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ─── Generic tile ─────────────────────────────────────────────────────────
  Widget _tile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required Widget? trailing,
    required VoidCallback? onTap,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 12)),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
              height: 1,
              thickness: 1,
              indent: 16,
              endIndent: 16,
              color: Colors.white.withOpacity(0.06)),
      ],
    );
  }
}
