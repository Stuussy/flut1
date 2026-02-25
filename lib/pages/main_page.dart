import 'package:flutter/material.dart';
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