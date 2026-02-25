import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'add_pc_page.dart';
import 'profile_page.dart';

class MainPage extends StatefulWidget {
  final String userEmail;
  const MainPage({super.key, required this.userEmail});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final GlobalKey<_HomePageRefreshState> _homePageKey = GlobalKey();
  final GlobalKey<_ProfilePageRefreshState> _profilePageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowOnboarding());
  }

  Future<void> _maybeShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_done') ?? false;
    if (!done && mounted) {
      await _showOnboarding();
      await prefs.setBool('onboarding_done', true);
    }
  }

  Future<void> _showOnboarding() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _OnboardingSheet(),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _onPCUpdated() async {
    _homePageKey.currentState?.refresh();
    _profilePageKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePageRefresh(
        key: _homePageKey,
        userEmail: widget.userEmail,
      ),
      AddPcPageWrapper(
        userEmail: widget.userEmail,
        onPCUpdated: _onPCUpdated,
      ),
      ProfilePageRefresh(
        key: _profilePageKey,
        userEmail: widget.userEmail,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1E),
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),

      bottomNavigationBar: Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Главная',
                  index: 0,
                ),

                _buildNavItem(
                  icon: Icons.computer,
                  label: 'Мой ПК',
                  index: 1,
                ),

                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: 'Профиль',
                  index: 2,
                ),
              ],
            ),
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
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF6C63FF).withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF6C63FF)
                    : Colors.white.withOpacity(0.4),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF6C63FF)
                      : Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingSheet extends StatefulWidget {
  const _OnboardingSheet();

  @override
  State<_OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends State<_OnboardingSheet> {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  static const _steps = [
    _OnboardingStep(
      icon: Icons.games_rounded,
      color: Color(0xFF6C63FF),
      title: 'Добро пожаловать в GamePulse!',
      body:
          'GamePulse помогает узнать, потянет ли ваш ПК любимую игру, и что обновить для лучшей производительности.',
    ),
    _OnboardingStep(
      icon: Icons.computer_rounded,
      color: Color(0xFF4CAF50),
      title: 'Добавьте характеристики ПК',
      body:
          'Перейдите во вкладку «Мой ПК» и введите процессор, видеокарту, ОЗУ и другие характеристики вашей системы.',
    ),
    _OnboardingStep(
      icon: Icons.speed_rounded,
      color: Color(0xFFFF9800),
      title: 'Проверьте совместимость',
      body:
          'Выберите игру на главном экране — получите оценку FPS и рекомендации по апгрейду от нашего ИИ.',
    ),
    _OnboardingStep(
      icon: Icons.star_rounded,
      color: Color(0xFFFFB300),
      title: 'Сохраняйте избранные',
      body:
          'Нажмите на звёздочку в карточке игры, чтобы добавить её в раздел «Избранное» для быстрого доступа (до 5 игр).',
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _steps.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: _steps.length,
              itemBuilder: (_, i) => _buildStep(_steps[i]),
            ),
          ),

          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_steps.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: active
                      ? const Color(0xFF6C63FF)
                      : Colors.white.withOpacity(0.25),
                ),
              );
            }),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                if (_page > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pageCtrl.previousPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Назад'),
                    ),
                  ),
                if (_page > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: Text(
                      _page == _steps.length - 1 ? 'Начать' : 'Далее',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildStep(_OnboardingStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: step.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, color: step.color, size: 50),
          ),
          const SizedBox(height: 32),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            step.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStep {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _OnboardingStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Wrapper widgets (unchanged from original)
// ─────────────────────────────────────────────────────────────────────────────

class AddPcPageWrapper extends StatelessWidget {
  final String userEmail;
  final VoidCallback onPCUpdated;

  const AddPcPageWrapper({
    super.key,
    required this.userEmail,
    required this.onPCUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return AddPcPageWithCallback(
      userEmail: userEmail,
      onPCUpdated: onPCUpdated,
    );
  }
}

class HomePageRefresh extends StatefulWidget {
  final String userEmail;

  const HomePageRefresh({super.key, required this.userEmail});

  @override
  State<HomePageRefresh> createState() => _HomePageRefreshState();
}

class _HomePageRefreshState extends State<HomePageRefresh> {
  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomePage(userEmail: widget.userEmail);
  }
}

class ProfilePageRefresh extends StatefulWidget {
  final String userEmail;

  const ProfilePageRefresh({super.key, required this.userEmail});

  @override
  State<ProfilePageRefresh> createState() => _ProfilePageRefreshState();
}

class _ProfilePageRefreshState extends State<ProfilePageRefresh> {
  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfilePage(userEmail: widget.userEmail);
  }
}
