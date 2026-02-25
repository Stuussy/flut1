import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/session_manager.dart';
import '../utils/api_config.dart';

class AddPcPageWithCallback extends StatefulWidget {
  final String userEmail;
  final VoidCallback? onPCUpdated;
  
  const AddPcPageWithCallback({
    super.key,
    required this.userEmail,
    this.onPCUpdated,
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
  
  bool _isLoading = false;
  bool _isSaving = false;
  
  final List<String> cpus = [
    'Intel i3-12100',
    'Intel i5-12400',
    'Intel i7-13620h',
    'Intel i9-14900k',
    'AMD Ryzen 3 3200g',
    'AMD Ryzen 5 5600x',
    'AMD Ryzen 7 5700x3d',
    'AMD Ryzen 9 9950x3d'
  ];

  final List<String> gpus = [
    'NVIDIA GTX 1650',
    'NVIDIA RTX 2060',
    'NVIDIA RTX 3060',
    'NVIDIA RTX 4060',
    'AMD RX 6600',
    'AMD RX 7800 XT'
  ];

  final List<String> rams = ['8 GB', '16 GB', '32 GB', '64 GB'];
  final List<String> storages = ['256 GB SSD', '512 GB SSD', '1 TB SSD', '2 TB SSD', '1 TB HDD'];
  final List<String> osList = ['Windows 10', 'Windows 11', 'Linux', 'MacOS'];

  @override
  void initState() {
    super.initState();
    _loadUserPC();
  }

  Future<void> _loadUserPC() async {
    try {
      final token = await SessionManager.getAuthToken() ?? '';
      final url = Uri.parse('${ApiConfig.baseUrl}/user/${widget.userEmail}');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user']['pcSpecs'] != null) {
          final pc = data['user']['pcSpecs'];
          if (mounted) {
            setState(() {
              selectedCPU = pc['cpu'];
              selectedGPU = pc['gpu'];
              selectedRAM = pc['ram'];
              selectedStorage = pc['storage'];
              selectedOS = pc['os'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Ошибка загрузки данных ПК: $e');
    }
  }

  Future<void> savePc() async {
    if (selectedCPU == null ||
        selectedGPU == null ||
        selectedRAM == null ||
        selectedStorage == null ||
        selectedOS == null) {
      _showSnackBar("Пожалуйста, заполните все поля", Colors.orange);
      return;
    }

    if (_isSaving) return;

    setState(() {
      _isLoading = true;
      _isSaving = true;
    });

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

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSnackBar("Характеристики ПК успешно обновлены!", const Color(0xFF4CAF50));

        widget.onPCUpdated?.call();

        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          setState(() {
            _isLoading = false;
            _isSaving = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _isSaving = false;
        });
        _showSnackBar("Ошибка: ${response.body}", Colors.red);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isSaving = false;
      });
      _showSnackBar("Ошибка соединения: $e", Colors.red);
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
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget buildDropdown(
      String label,
      IconData icon,
      String? value,
      List<String> items,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF6C63FF), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: DropdownButtonFormField<String>(
            dropdownColor: const Color(0xFF1A1A2E),
            value: value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              hintText: 'Выберите $label',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: const Color(0xFF6C63FF),
            ),
            onChanged: onChanged,
            items: items
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, style: const TextStyle(color: Colors.white)),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1E),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Мой ПК",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Введите характеристики вашего компьютера",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildDropdown(
                      "Процессор",
                      Icons.memory,
                      selectedCPU,
                      cpus,
                      (val) => setState(() => selectedCPU = val),
                    ),
                    const SizedBox(height: 20),
                    
                    buildDropdown(
                      "Видеокарта",
                      Icons.videogame_asset,
                      selectedGPU,
                      gpus,
                      (val) => setState(() => selectedGPU = val),
                    ),
                    const SizedBox(height: 20),
                    
                    buildDropdown(
                      "Оперативная память",
                      Icons.storage,
                      selectedRAM,
                      rams,
                      (val) => setState(() => selectedRAM = val),
                    ),
                    const SizedBox(height: 20),
                    
                    buildDropdown(
                      "Хранилище",
                      Icons.sd_storage,
                      selectedStorage,
                      storages,
                      (val) => setState(() => selectedStorage = val),
                    ),
                    const SizedBox(height: 20),
                    
                    buildDropdown(
                      "Операционная система",
                      Icons.computer,
                      selectedOS,
                      osList,
                      (val) => setState(() => selectedOS = val),
                    ),
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _isSaving) ? null : savePc,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: const Color(0xFF6C63FF).withOpacity(0.5),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.save_outlined, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    "Сохранить",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
  }
}

class AddPcPage extends StatefulWidget {
  final String userEmail;
  const AddPcPage({super.key, required this.userEmail});
  
  @override
  State<AddPcPage> createState() => _AddPcPageState();
}

class _AddPcPageState extends State<AddPcPage>
    with SingleTickerProviderStateMixin {
  String? selectedCPU;
  String? selectedGPU;
  String? selectedRAM;
  String? selectedStorage;
  String? selectedOS;
  
  bool _isLoading = false;
  bool _isSaving = false;
  
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final List<String> cpus = [
    'Intel i3-12100',
    'Intel i5-12400',
    'Intel i7-13620h',
    'Intel i9-14900k',
    'AMD Ryzen 3 3200g',
    'AMD Ryzen 5 5600x',
    'AMD Ryzen 7 5700x3d',
    'AMD Ryzen 9 9950x3d'
  ];

  final List<String> gpus = [
    'NVIDIA GTX 1650',
    'NVIDIA RTX 2060',
    'NVIDIA RTX 3060',
    'NVIDIA RTX 4060',
    'AMD RX 6600',
    'AMD RX 7800 XT'
  ];

  final List<String> rams = ['8 GB', '16 GB', '32 GB', '64 GB'];
  final List<String> storages = ['256 GB SSD', '512 GB SSD', '1 TB SSD', '2 TB SSD', '1 TB HDD'];
  final List<String> osList = ['Windows 10', 'Windows 11', 'Linux', 'MacOS'];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
    _loadUserPC();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPC() async {
    try {
      final token = await SessionManager.getAuthToken() ?? '';
      final url = Uri.parse('${ApiConfig.baseUrl}/user/${widget.userEmail}');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user']['pcSpecs'] != null) {
          final pc = data['user']['pcSpecs'];
          if (mounted) {
            setState(() {
              selectedCPU = pc['cpu'];
              selectedGPU = pc['gpu'];
              selectedRAM = pc['ram'];
              selectedStorage = pc['storage'];
              selectedOS = pc['os'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Ошибка загрузки данных ПК: $e');
    }
  }

  Future<void> savePc() async {
    if (selectedCPU == null ||
        selectedGPU == null ||
        selectedRAM == null ||
        selectedStorage == null ||
        selectedOS == null) {
      _showSnackBar("Пожалуйста, заполните все поля", Colors.orange);
      return;
    }

    if (_isSaving) return;

    setState(() {
      _isLoading = true;
      _isSaving = true;
    });

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

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSnackBar("Характеристики ПК успешно обновлены!", const Color(0xFF4CAF50));

        await Future.delayed(const Duration(milliseconds: 600));

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _isLoading = false;
          _isSaving = false;
        });
        _showSnackBar("Ошибка: ${response.body}", Colors.red);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isSaving = false;
      });
      _showSnackBar("Ошибка соединения: $e", Colors.red);
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
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget buildDropdown(
      String label,
      IconData icon,
      String? value,
      List<String> items,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF6C63FF), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: DropdownButtonFormField<String>(
            dropdownColor: const Color(0xFF1A1A2E),
            value: value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              hintText: 'Выберите $label',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: const Color(0xFF6C63FF),
            ),
            onChanged: onChanged,
            items: items
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, style: const TextStyle(color: Colors.white)),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSaving) {
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1E),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Мой ПК",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Введите характеристики вашего компьютера",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buildDropdown(
                          "Процессор",
                          Icons.memory,
                          selectedCPU,
                          cpus,
                          (val) => setState(() => selectedCPU = val),
                        ),
                        const SizedBox(height: 20),
                        
                        buildDropdown(
                          "Видеокарта",
                          Icons.videogame_asset,
                          selectedGPU,
                          gpus,
                          (val) => setState(() => selectedGPU = val),
                        ),
                        const SizedBox(height: 20),
                        
                        buildDropdown(
                          "Оперативная память",
                          Icons.storage,
                          selectedRAM,
                          rams,
                          (val) => setState(() => selectedRAM = val),
                        ),
                        const SizedBox(height: 20),
                        
                        buildDropdown(
                          "Хранилище",
                          Icons.sd_storage,
                          selectedStorage,
                          storages,
                          (val) => setState(() => selectedStorage = val),
                        ),
                        const SizedBox(height: 20),
                        
                        buildDropdown(
                          "Операционная система",
                          Icons.computer,
                          selectedOS,
                          osList,
                          (val) => setState(() => selectedOS = val),
                        ),
                        const SizedBox(height: 40),
                        
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: (_isLoading || _isSaving) ? null : savePc,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                              disabledBackgroundColor: const Color(0xFF6C63FF).withOpacity(0.5),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.save_outlined, size: 20),
                                      SizedBox(width: 10),
                                      Text(
                                        "Сохранить",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}