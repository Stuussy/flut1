import 'dart:convert';
import '../utils/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminAddComponentPage extends StatefulWidget {
  final String adminToken;
  const AdminAddComponentPage({super.key, this.adminToken = ''});

  @override
  State<AdminAddComponentPage> createState() =>
      _AdminAddComponentPageState();
}

class _AdminAddComponentPageState extends State<AdminAddComponentPage> {
  static String get _baseUrl => ApiConfig.baseUrl;

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _linkController = TextEditingController();
  final _performanceController = TextEditingController();

  String _selectedType = 'cpu';
  String _selectedBudget = 'medium';
  bool _isLoading = false;

  final _typeOptions = [
    {'value': 'cpu', 'label': 'Процессор (CPU)', 'icon': Icons.memory},
    {
      'value': 'gpu',
      'label': 'Видеокарта (GPU)',
      'icon': Icons.videogame_asset
    },
    {'value': 'ram', 'label': 'Оперативная память (RAM)', 'icon': Icons.storage},
  ];

  final _budgetOptions = [
    {'value': 'low', 'label': 'Эконом', 'color': const Color(0xFF4CAF50)},
    {'value': 'medium', 'label': 'Средний', 'color': const Color(0xFF6C63FF)},
    {'value': 'high', 'label': 'Премиум', 'color': const Color(0xFFFFA726)},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _linkController.dispose();
    _performanceController.dispose();
    super.dispose();
  }

  Future<void> _saveComponent() async {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final link = _linkController.text.trim();
    final perfText = _performanceController.text.trim();

    if (name.isEmpty) {
      _showSnackBar("Введите название компонента", Colors.orange);
      return;
    }
    if (priceText.isEmpty) {
      _showSnackBar("Введите цену", Colors.orange);
      return;
    }

    final price = int.tryParse(priceText);
    if (price == null || price <= 0) {
      _showSnackBar("Введите корректную цену", Colors.orange);
      return;
    }

    final performance = int.tryParse(perfText) ?? 100;

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('$_baseUrl/admin/add-component');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.adminToken}'},
        body: jsonEncode({
          'type': _selectedType,
          'name': name,
          'price': price,
          'link': link,
          'performance': performance,
          'budget': _selectedBudget,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _showSnackBar(
            "Компонент '$name' добавлен!", const Color(0xFF4CAF50));
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pop(context, true);
      } else {
        _showSnackBar(data['message'] ?? "Ошибка", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Ошибка подключения", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1E),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Component Type
                    _buildSectionTitle("Тип компонента", Icons.category),
                    const SizedBox(height: 12),
                    _buildTypeSelector(),
                    const SizedBox(height: 24),

                    // Name
                    _buildSectionTitle("Название", Icons.label),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _nameController,
                      hintText: _selectedType == 'cpu'
                          ? "Например: Intel i7-14700K"
                          : _selectedType == 'gpu'
                              ? "Например: NVIDIA RTX 4070"
                              : "Например: 32 GB",
                      icon: Icons.edit,
                    ),
                    const SizedBox(height: 24),

                    // Price
                    _buildSectionTitle("Цена (USD)", Icons.attach_money),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _priceController,
                      hintText: "Например: 350",
                      icon: Icons.monetization_on,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),

                    // Link
                    _buildSectionTitle(
                        "Ссылка на магазин (опционально)", Icons.link),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _linkController,
                      hintText: "https://www.dns-shop.ru/...",
                      icon: Icons.shopping_cart,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 24),

                    // Performance
                    _buildSectionTitle(
                        "Производительность (очки)", Icons.speed),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _performanceController,
                      hintText: "100-350 (по умолчанию 100)",
                      icon: Icons.trending_up,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),

                    // Budget
                    _buildSectionTitle("Категория бюджета", Icons.savings),
                    const SizedBox(height: 12),
                    _buildBudgetSelector(),
                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveComponent,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.save, size: 20),
                        label: Text(
                          _isLoading
                              ? "Сохранение..."
                              : "Сохранить компонент",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
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
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.add_circle,
              color: Color(0xFFFFA726), size: 24),
          const SizedBox(width: 12),
          const Text(
            "Добавить компонент",
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFFA726), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon:
              Icon(icon, color: const Color(0xFFFFA726), size: 20),
          hintText: hintText,
          hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      children: _typeOptions.map((option) {
        final isSelected = _selectedType == option['value'];
        final color =
            isSelected ? const Color(0xFFFFA726) : Colors.white.withValues(alpha: 0.4);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () =>
                setState(() => _selectedType = option['value'] as String),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFA726).withValues(alpha: 0.1)
                    : const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFFA726).withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(option['icon'] as IconData, color: color, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    option['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(Icons.check_circle,
                        color: Color(0xFFFFA726), size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBudgetSelector() {
    return Row(
      children: _budgetOptions.map((option) {
        final isSelected = _selectedBudget == option['value'];
        final color = option['color'] as Color;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: option != _budgetOptions.last ? 10 : 0,
            ),
            child: InkWell(
              onTap: () => setState(
                  () => _selectedBudget = option['value'] as String),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.2)
                      : const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : Colors.white.withValues(alpha: 0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    option['label'] as String,
                    style: TextStyle(
                      color: isSelected ? color : Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
