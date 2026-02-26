import 'dart:convert';
import '../utils/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminAddGamePage extends StatefulWidget {
  const AdminAddGamePage({super.key});

  @override
  State<AdminAddGamePage> createState() => _AdminAddGamePageState();
}

class _AdminAddGamePageState extends State<AdminAddGamePage> {
  static String get _baseUrl => ApiConfig.baseUrl;

  final _titleController = TextEditingController();
  bool _isLoading = false;

  // Tier data
  final _minCpuController = TextEditingController();
  final _minGpuController = TextEditingController();
  String _minRam = '8 GB';

  final _recCpuController = TextEditingController();
  final _recGpuController = TextEditingController();
  String _recRam = '16 GB';

  final _highCpuController = TextEditingController();
  final _highGpuController = TextEditingController();
  String _highRam = '16 GB';

  final List<String> _minCpus = [];
  final List<String> _minGpus = [];
  final List<String> _recCpus = [];
  final List<String> _recGpus = [];
  final List<String> _highCpus = [];
  final List<String> _highGpus = [];

  final _ramOptions = ['8 GB', '16 GB', '32 GB', '64 GB'];

  @override
  void dispose() {
    _titleController.dispose();
    _minCpuController.dispose();
    _minGpuController.dispose();
    _recCpuController.dispose();
    _recGpuController.dispose();
    _highCpuController.dispose();
    _highGpuController.dispose();
    super.dispose();
  }

  void _addChip(TextEditingController controller, List<String> list) {
    final text = controller.text.trim();
    if (text.isNotEmpty && !list.contains(text)) {
      setState(() {
        list.add(text);
        controller.clear();
      });
    }
  }

  void _removeChip(List<String> list, int index) {
    setState(() => list.removeAt(index));
  }

  Future<void> _saveGame() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showSnackBar("Введите название игры", Colors.orange);
      return;
    }
    if (_minCpus.isEmpty || _minGpus.isEmpty) {
      _showSnackBar("Добавьте минимум 1 CPU и 1 GPU для минимальных требований", Colors.orange);
      return;
    }
    if (_recCpus.isEmpty || _recGpus.isEmpty) {
      _showSnackBar("Добавьте минимум 1 CPU и 1 GPU для рекомендуемых требований", Colors.orange);
      return;
    }
    if (_highCpus.isEmpty || _highGpus.isEmpty) {
      _showSnackBar("Добавьте минимум 1 CPU и 1 GPU для высоких требований", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('$_baseUrl/admin/add-game');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'minimum': {'cpu': _minCpus, 'gpu': _minGpus, 'ram': _minRam},
          'recommended': {'cpu': _recCpus, 'gpu': _recGpus, 'ram': _recRam},
          'high': {'cpu': _highCpus, 'gpu': _highGpus, 'ram': _highRam},
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _showSnackBar("Игра '$title' добавлена!", const Color(0xFF4CAF50));
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
                    _buildTextField(
                      controller: _titleController,
                      hintText: "Название игры",
                      icon: Icons.games,
                    ),
                    const SizedBox(height: 24),
                    _buildTierSection(
                      "Минимальные требования",
                      Icons.speed,
                      const Color(0xFF4CAF50),
                      _minCpuController,
                      _minGpuController,
                      _minCpus,
                      _minGpus,
                      _minRam,
                      (val) => setState(() => _minRam = val),
                    ),
                    const SizedBox(height: 24),
                    _buildTierSection(
                      "Рекомендуемые требования",
                      Icons.star,
                      const Color(0xFF6C63FF),
                      _recCpuController,
                      _recGpuController,
                      _recCpus,
                      _recGpus,
                      _recRam,
                      (val) => setState(() => _recRam = val),
                    ),
                    const SizedBox(height: 24),
                    _buildTierSection(
                      "Высокие требования",
                      Icons.diamond,
                      const Color(0xFFFFA726),
                      _highCpuController,
                      _highGpuController,
                      _highCpus,
                      _highGpus,
                      _highRam,
                      (val) => setState(() => _highRam = val),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveGame,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.save, size: 20),
                        label: Text(
                          _isLoading ? "Сохранение..." : "Сохранить игру",
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
          const Icon(Icons.add_circle, color: Color(0xFFFFA726), size: 24),
          const SizedBox(width: 12),
          const Text(
            "Добавить игру",
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
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
          prefixIcon: Icon(icon, color: const Color(0xFFFFA726), size: 20),
          hintText: hintText,
          hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.4), fontSize: 15),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildTierSection(
    String title,
    IconData icon,
    Color color,
    TextEditingController cpuController,
    TextEditingController gpuController,
    List<String> cpuList,
    List<String> gpuList,
    String ramValue,
    ValueChanged<String> onRamChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                    color: color, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // CPU
          _buildChipInput("CPU", cpuController, cpuList, Icons.memory, color),
          const SizedBox(height: 12),
          // GPU
          _buildChipInput(
              "GPU", gpuController, gpuList, Icons.videogame_asset, color),
          const SizedBox(height: 12),
          // RAM
          Row(
            children: [
              Icon(Icons.storage, color: color.withValues(alpha: 0.7), size: 18),
              const SizedBox(width: 8),
              Text("RAM:",
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D1E),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: DropdownButton<String>(
                    value: ramValue,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1A1A2E),
                    underline: const SizedBox(),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14),
                    items: _ramOptions
                        .map((r) => DropdownMenuItem(
                            value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) onRamChanged(val);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChipInput(
    String label,
    TextEditingController controller,
    List<String> chips,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color.withValues(alpha: 0.7), size: 18),
            const SizedBox(width: 8),
            Text("$label:",
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D1E),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Например: Intel i5-12400",
                    hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                  onSubmitted: (_) => _addChip(controller, chips),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _addChip(controller, chips),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.withValues(alpha: 0.2),
                  foregroundColor: color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.zero,
                  elevation: 0,
                ),
                child: const Icon(Icons.add, size: 20),
              ),
            ),
          ],
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              chips.length,
              (index) => Chip(
                label: Text(chips[index],
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12)),
                backgroundColor: color.withValues(alpha: 0.15),
                side: BorderSide(color: color.withValues(alpha: 0.3)),
                deleteIconColor: color,
                onDeleted: () => _removeChip(chips, index),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
