import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/session_manager.dart';
import '../utils/api_config.dart';
import '../utils/app_colors.dart';
import '../utils/cache_manager.dart';

// ─── Единый список железа (единственное место для изменений) ────────────────

const List<String> _kCpus = [
  // Intel Core i3
  'Intel Core i3-10100',
  'Intel Core i3-12100',
  // Intel Core i5
  'Intel Core i5-10400',
  'Intel Core i5-12400',
  'Intel Core i5-13400',
  'Intel Core i5-13600K',
  // Intel Core i7
  'Intel Core i7-10700K',
  'Intel Core i7-12700K',
  'Intel Core i7-13700K',
  'Intel Core i7-13620H',
  // Intel Core i9
  'Intel Core i9-12900K',
  'Intel Core i9-13900K',
  'Intel Core i9-14900K',
  // AMD Ryzen 3
  'AMD Ryzen 3 3200G',
  // AMD Ryzen 5
  'AMD Ryzen 5 3600',
  'AMD Ryzen 5 5600',
  'AMD Ryzen 5 5600X',
  'AMD Ryzen 5 7600X',
  // AMD Ryzen 7
  'AMD Ryzen 7 3700X',
  'AMD Ryzen 7 5700X',
  'AMD Ryzen 7 5700X3D',
  'AMD Ryzen 7 7700X',
  // AMD Ryzen 9
  'AMD Ryzen 9 5900X',
  'AMD Ryzen 9 5950X',
  'AMD Ryzen 9 7900X',
  'AMD Ryzen 9 9950X3D',
];

const List<String> _kGpus = [
  // NVIDIA GTX
  'NVIDIA GTX 1060 6GB',
  'NVIDIA GTX 1070',
  'NVIDIA GTX 1080',
  'NVIDIA GTX 1650',
  'NVIDIA GTX 1650 Super',
  'NVIDIA GTX 1660',
  'NVIDIA GTX 1660 Super',
  // NVIDIA RTX 20xx
  'NVIDIA RTX 2060',
  'NVIDIA RTX 2060 Super',
  'NVIDIA RTX 2070 Super',
  'NVIDIA RTX 2080 Ti',
  // NVIDIA RTX 30xx
  'NVIDIA RTX 3060',
  'NVIDIA RTX 3060 Ti',
  'NVIDIA RTX 3070',
  'NVIDIA RTX 3070 Ti',
  'NVIDIA RTX 3080',
  'NVIDIA RTX 3090',
  // NVIDIA RTX 40xx
  'NVIDIA RTX 4060',
  'NVIDIA RTX 4060 Ti',
  'NVIDIA RTX 4070',
  'NVIDIA RTX 4070 Ti Super',
  'NVIDIA RTX 4080',
  'NVIDIA RTX 4090',
  // AMD RX
  'AMD RX 570',
  'AMD RX 580',
  'AMD RX 5600 XT',
  'AMD RX 5700 XT',
  'AMD RX 6600',
  'AMD RX 6600 XT',
  'AMD RX 6700 XT',
  'AMD RX 6800 XT',
  'AMD RX 7600',
  'AMD RX 7800 XT',
  'AMD RX 7900 XTX',
  // Intel Arc
  'Intel Arc A770',
];

const List<String> _kRams = ['4 GB', '8 GB', '16 GB', '32 GB', '64 GB'];

const List<String> _kStorages = [
  '128 GB SSD',
  '256 GB SSD',
  '512 GB SSD',
  '1 TB SSD',
  '2 TB SSD',
  '500 GB HDD',
  '1 TB HDD',
  '2 TB HDD',
];

const List<String> _kOsList = [
  'Windows 10',
  'Windows 11',
  'Linux',
  'MacOS',
];

// ─── Основной виджет ────────────────────────────────────────────────────────

/// Универсальный виджет выбора характеристик ПК.
///
/// Режим вкладки (по умолчанию):  [showBackButton] = false,
///   после сохранения вызывает [onPCUpdated].
///
/// Режим отдельной страницы:       [showBackButton] = true,
///   после сохранения делает Navigator.pop(true).
class AddPcPageWithCallback extends StatefulWidget {
  final String userEmail;
  final VoidCallback? onPCUpdated;
  final bool showBackButton;

  const AddPcPageWithCallback({
    super.key,
    required this.userEmail,
    this.onPCUpdated,
    this.showBackButton = false,
  });

  @override
  State<AddPcPageWithCallback> createState() => _AddPcPageWithCallbackState();
}

class _AddPcPageWithCallbackState extends State<AddPcPageWithCallback> {
  String? selectedCPU;
  String? selectedGPU;
  String? selectedRAM;
  String? selectedStorage;
  String? selectedOS;

  // Флаги режима ручного ввода для каждого поля
  bool _cpuManual = false;
  bool _gpuManual = false;
  bool _ramManual = false;
  bool _storageManual = false;
  bool _osManual = false;

  // Контроллеры для полей ручного ввода
  final _cpuCtrl = TextEditingController();
  final _gpuCtrl = TextEditingController();
  final _ramCtrl = TextEditingController();
  final _storageCtrl = TextEditingController();
  final _osCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserPC();
  }

  Future<void> _loadUserPC() async {
    try {
      final token = await SessionManager.getAuthToken() ?? '';
      final url = Uri.parse('${ApiConfig.baseUrl}/user/${widget.userEmail}');
      final response =
          await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 401) {
        if (mounted) await SessionManager.handleUnauthorized(context);
        return;
      } else if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user']['pcSpecs'] != null) {
          final pc = data['user']['pcSpecs'];
          if (mounted) {
            setState(() {
              selectedCPU = _matchOrNull(pc['cpu'], _kCpus);
              selectedGPU = _matchOrNull(pc['gpu'], _kGpus);
              selectedRAM = _matchOrNull(pc['ram'], _kRams);
              selectedStorage = _matchOrNull(pc['storage'], _kStorages);
              selectedOS = _matchOrNull(pc['os'], _kOsList);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Ошибка загрузки данных ПК: $e');
    }
  }

  /// Возвращает [value] если оно есть в [list], иначе null.
  /// Защищает от ситуации когда сохранённое значение исчезло из списка.
  String? _matchOrNull(dynamic value, List<String> list) {
    if (value == null) return null;
    final s = value.toString();
    // Если значение не в списке — переключаем в режим ручного ввода
    return list.contains(s) ? s : s;
  }

  void _setManual(String field, bool isManual) {
    setState(() {
      switch (field) {
        case 'cpu':
          _cpuManual = isManual;
          if (isManual) { selectedCPU = null; _cpuCtrl.clear(); }
        case 'gpu':
          _gpuManual = isManual;
          if (isManual) { selectedGPU = null; _gpuCtrl.clear(); }
        case 'ram':
          _ramManual = isManual;
          if (isManual) { selectedRAM = null; _ramCtrl.clear(); }
        case 'storage':
          _storageManual = isManual;
          if (isManual) { selectedStorage = null; _storageCtrl.clear(); }
        case 'os':
          _osManual = isManual;
          if (isManual) { selectedOS = null; _osCtrl.clear(); }
      }
    });
  }

  TextEditingController _ctrlFor(String fieldKey) {
    switch (fieldKey) {
      case 'cpu': return _cpuCtrl;
      case 'gpu': return _gpuCtrl;
      case 'ram': return _ramCtrl;
      case 'storage': return _storageCtrl;
      default: return _osCtrl;
    }
  }

  /// Виджет поля с возможностью ручного ввода.
  Widget _buildFieldWithManual({
    required String fieldKey,
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required bool isManual,
    required void Function(String?) onChanged,
  }) {
    final ac = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.purple, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                      color: ac.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _setManual(fieldKey, !isManual),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isManual
                      ? AppColors.purple.withValues(alpha: 0.2)
                      : ac.text.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isManual
                        ? AppColors.purple.withValues(alpha: 0.5)
                        : ac.text.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isManual ? Icons.list_rounded : Icons.edit_rounded,
                      color: isManual
                          ? AppColors.purple
                          : ac.textMuted,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isManual ? 'Из списка' : 'Вручную',
                      style: TextStyle(
                        color: isManual
                            ? AppColors.purple
                            : ac.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (isManual)
          Container(
            decoration: BoxDecoration(
              color: ac.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.4)),
            ),
            child: TextField(
              enabled: !_isSaving,
              controller: _ctrlFor(fieldKey),
              style: TextStyle(color: ac.text, fontSize: 14),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: InputBorder.none,
                hintText: 'Введите $label вручную',
                hintStyle: TextStyle(
                    color: ac.textHint, fontSize: 13),
                suffixIcon: value != null && value.isNotEmpty
                    ? Icon(Icons.check_circle,
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.8),
                        size: 18)
                    : null,
              ),
              onChanged: onChanged,
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: ac.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ac.inputBorder),
            ),
            child: DropdownButtonFormField<String>(
              dropdownColor: ac.card,
              value: (value != null && items.contains(value)) ? value : null,
              isExpanded: true,
              style: TextStyle(color: ac.text, fontSize: 14),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: InputBorder.none,
                hintText: 'Выберите $label',
                hintStyle: TextStyle(color: ac.textHint, fontSize: 14),
              ),
              icon: const Icon(Icons.arrow_drop_down,
                  color: AppColors.purple),
              onChanged: onChanged,
              items: items
                  .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e)))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Future<void> _savePc() async {
    if (selectedCPU == null ||
        selectedGPU == null ||
        selectedRAM == null ||
        selectedStorage == null ||
        selectedOS == null) {
      _showSnackBar('Пожалуйста, заполните все поля', Colors.orange);
      return;
    }

    if (_isSaving) return;

    setState(() {
      _isLoading = true;
      _isSaving = true;
    });

    try {
      final token = await SessionManager.getAuthToken() ?? '';
      final url = Uri.parse('${ApiConfig.baseUrl}/add-pc');
      final body = jsonEncode({
        'email': widget.userEmail,
        'cpu': selectedCPU,
        'gpu': selectedGPU,
        'ram': selectedRAM,
        'storage': selectedStorage,
        'os': selectedOS,
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (!mounted) return;

      if (response.statusCode == 401) {
        await SessionManager.handleUnauthorized(context);
        return;
      } else if (response.statusCode == 200) {
        _showSnackBar(
            'Характеристики ПК успешно обновлены!', const Color(0xFF4CAF50));
        // Сбрасываем весь кэш совместимости — компоненты изменились,
        // поэтому FPS для всех игр нужно пересчитать
        await CacheManager.clearAll();
        SessionManager.pcChangeCount.value++;

        if (widget.showBackButton) {
          // Страничный режим — возвращаемся назад
          await Future.delayed(const Duration(milliseconds: 600));
          if (mounted) Navigator.of(context).pop(true);
        } else {
          // Режим вкладки — вызываем callback и сбрасываем флаги
          widget.onPCUpdated?.call();
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) _resetSaving();
        }
      } else {
        _resetSaving();
        _showSnackBar('Ошибка: ${response.body}', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _resetSaving();
      _showSnackBar('Ошибка соединения: $e', Colors.red);
    }
  }

  @override
  void dispose() {
    _cpuCtrl.dispose();
    _gpuCtrl.dispose();
    _ramCtrl.dispose();
    _storageCtrl.dispose();
    _osCtrl.dispose();
    super.dispose();
  }

  void _resetSaving() {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSaving = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == const Color(0xFF4CAF50)
                  ? Icons.check_circle
                  : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    IconData icon,
    String? value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    final ac = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.purple, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                  color: ac.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: ac.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ac.inputBorder),
          ),
          child: DropdownButtonFormField<String>(
            dropdownColor: ac.card,
            value: value,
            isExpanded: true,
            style: TextStyle(color: ac.text, fontSize: 14),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
              hintText: 'Выберите $label',
              hintStyle: TextStyle(color: ac.textHint),
            ),
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.purple),
            onChanged: onChanged,
            items: items
                .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e)))
                .toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    final scaffold = Scaffold(
      backgroundColor: ac.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Шапка ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (widget.showBackButton) ...[
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios,
                          color: ac.text, size: 20),
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Мой ПК',
                        style: TextStyle(
                            color: ac.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Введите характеристики вашего компьютера',
                        style: TextStyle(
                            color: ac.textMuted,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Форма ──────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFieldWithManual(
                      fieldKey: 'cpu',
                      label: 'Процессор',
                      icon: Icons.memory,
                      value: selectedCPU,
                      items: _kCpus,
                      isManual: _cpuManual,
                      onChanged: (v) => setState(() => selectedCPU = v),
                    ),
                    const SizedBox(height: 20),
                    _buildFieldWithManual(
                      fieldKey: 'gpu',
                      label: 'Видеокарта',
                      icon: Icons.videogame_asset,
                      value: selectedGPU,
                      items: _kGpus,
                      isManual: _gpuManual,
                      onChanged: (v) => setState(() => selectedGPU = v),
                    ),
                    const SizedBox(height: 20),
                    _buildFieldWithManual(
                      fieldKey: 'ram',
                      label: 'Оперативная память',
                      icon: Icons.storage,
                      value: selectedRAM,
                      items: _kRams,
                      isManual: _ramManual,
                      onChanged: (v) => setState(() => selectedRAM = v),
                    ),
                    const SizedBox(height: 20),
                    _buildFieldWithManual(
                      fieldKey: 'storage',
                      label: 'Хранилище',
                      icon: Icons.sd_storage,
                      value: selectedStorage,
                      items: _kStorages,
                      isManual: _storageManual,
                      onChanged: (v) => setState(() => selectedStorage = v),
                    ),
                    const SizedBox(height: 20),
                    _buildFieldWithManual(
                      fieldKey: 'os',
                      label: 'Операционная система',
                      icon: Icons.computer,
                      value: selectedOS,
                      items: _kOsList,
                      isManual: _osManual,
                      onChanged: (v) => setState(() => selectedOS = v),
                    ),
                    const SizedBox(height: 40),

                    // ── Кнопка сохранить ───────────────────────────────────
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _isSaving) ? null : _savePc,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          disabledBackgroundColor:
                              AppColors.purple.withValues(alpha: 0.5),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save_outlined, size: 20),
                                  SizedBox(width: 10),
                                  Text('Сохранить',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // PopScope предотвращает закрытие во время сохранения
    if (widget.showBackButton) {
      return PopScope(
        canPop: !_isSaving,
        child: scaffold,
      );
    }
    return scaffold;
  }
}

// ─── Тонкая обёртка для страничной навигации ────────────────────────────────

/// Используй при открытии через Navigator.push — показывает кнопку «Назад»
/// и делает pop(true) после успешного сохранения.
class AddPcPage extends StatelessWidget {
  final String userEmail;
  const AddPcPage({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return AddPcPageWithCallback(
      userEmail: userEmail,
      showBackButton: true,
    );
  }
}
