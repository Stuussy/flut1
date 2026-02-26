import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/theme_manager.dart';
import '../utils/cache_manager.dart';
import '../utils/app_colors.dart';
import 'about_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _purple = AppColors.purple;

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return Scaffold(
      backgroundColor: ac.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, ac),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Тема ──────────────────────────────────────────────
                    _sectionLabel('Оформление', ac),
                    const SizedBox(height: 10),
                    _buildThemeSelector(context, ac),

                    const SizedBox(height: 24),

                    // ── Кэш ───────────────────────────────────────────────
                    _sectionLabel('Данные', ac),
                    const SizedBox(height: 10),
                    _buildCacheTile(context, ac),

                    const SizedBox(height: 24),

                    // ── Информация ────────────────────────────────────────
                    _sectionLabel('Информация', ac),
                    const SizedBox(height: 10),
                    _buildInfoGroup(context, ac),

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
  Widget _buildHeader(BuildContext context, AppColors ac) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: ac.text, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'Настройки',
            style: TextStyle(
                color: ac.text,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, AppColors ac) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: ac.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }

  // ─── Выбор темы (3 кнопки) ───────────────────────────────────────────────
  Widget _buildThemeSelector(BuildContext context, AppColors ac) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.notifier,
      builder: (_, current, __) {
        return Container(
          decoration: BoxDecoration(
            color: ac.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ac.subtleBorder),
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
                  Text('Тема приложения',
                      style: TextStyle(
                          color: ac.text,
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
                    ac,
                  ),
                  const SizedBox(width: 8),
                  _themeOption(
                    current,
                    ThemeMode.light,
                    Icons.light_mode_rounded,
                    'Светлая',
                    ac,
                  ),
                  const SizedBox(width: 8),
                  _themeOption(
                    current,
                    ThemeMode.system,
                    Icons.brightness_auto_rounded,
                    'Системная',
                    ac,
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
      ThemeMode current, ThemeMode value, IconData icon, String label, AppColors ac) {
    final isActive = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => ThemeManager.setTheme(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? _purple : ac.text.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? _purple : ac.text.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isActive
                      ? Colors.white
                      : ac.text.withValues(alpha: 0.5),
                  size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? Colors.white
                      : ac.text.withValues(alpha: 0.5),
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
  Widget _buildCacheTile(BuildContext context, AppColors ac) {
    return Container(
      decoration: BoxDecoration(
        color: ac.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.subtleBorder),
      ),
      child: _tile(
        context: context,
        ac: ac,
        icon: Icons.delete_sweep_rounded,
        iconColor: Colors.red,
        label: 'Очистить кэш',
        subtitle: 'Данные совместимости (TTL 24 ч)',
        trailing: Icon(Icons.chevron_right, color: ac.text.withValues(alpha: 0.24)),
        onTap: () => _confirmClearCache(context, ac),
      ),
    );
  }

  Future<void> _confirmClearCache(BuildContext context, AppColors ac) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ac.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Очистить кэш?',
            style: TextStyle(color: ac.text, fontWeight: FontWeight.w700)),
        content: Text(
          'Все сохранённые результаты совместимости будут удалены. '
          'При следующем открытии игры данные загрузятся с сервера заново.',
          style: TextStyle(
              color: ac.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена',
                style: TextStyle(color: ac.textMuted)),
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
  Widget _buildInfoGroup(BuildContext context, AppColors ac) {
    return Container(
      decoration: BoxDecoration(
        color: ac.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.subtleBorder),
      ),
      child: Column(
        children: [
          _tile(
            context: context,
            ac: ac,
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF00BCD4),
            label: 'О приложении',
            subtitle: 'Методология, FAQ, статусы FPS',
            trailing:
                Icon(Icons.chevron_right, color: ac.text.withValues(alpha: 0.24)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
            showDivider: true,
          ),
          _tile(
            context: context,
            ac: ac,
            icon: Icons.support_agent_rounded,
            iconColor: const Color(0xFF4CAF50),
            label: 'Поддержка',
            subtitle: 'Сообщить об ошибке или задать вопрос',
            trailing:
                Icon(Icons.open_in_new_rounded, color: ac.text.withValues(alpha: 0.24), size: 18),
            onTap: () => _launchSupport(context, ac),
            showDivider: true,
          ),
          _tile(
            context: context,
            ac: ac,
            icon: Icons.tag_rounded,
            iconColor: ac.textMuted,
            label: 'Версия приложения',
            subtitle: 'v1.0.0 (build 1)',
            trailing: null,
            onTap: null,
          ),
        ],
      ),
    );
  }

  Future<void> _launchSupport(BuildContext context, AppColors ac) async {
    final uri = Uri.parse('mailto:support@gamepulse.app?subject=GamePulse%20Support');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Напишите нам: support@gamepulse.app'),
          backgroundColor: ac.card,
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
    required BuildContext context,
    required AppColors ac,
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
                    color: iconColor.withValues(alpha: 0.12),
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
                          style: TextStyle(
                              color: ac.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              color: ac.textMuted,
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
              color: ac.divider),
      ],
    );
  }
}
