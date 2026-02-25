import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminAiChatPage extends StatefulWidget {
  final String adminEmail;

  const AdminAiChatPage({super.key, required this.adminEmail});

  @override
  State<AdminAiChatPage> createState() => _AdminAiChatPageState();
}

class _AdminAiChatPageState extends State<AdminAiChatPage>
    with SingleTickerProviderStateMixin {
  static const String _baseUrl = 'http://localhost:3001';

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();

    _messages.add({
      'text':
          'Привет! Я ИИ помощник GamePulse.\n\nМогу помочь с вопросами о железе, играх, ценах и рекомендациях.\n\nВыберите вопрос или задайте свой!',
      'isUser': false,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  List<String> get _quickQuestions => const [
        'Какие популярные GPU в 2025?',
        'Лучшие процессоры для игр?',
        'Сколько RAM нужно для игр?',
        'Советы по ценообразованию',
      ];

  List<Map<String, dynamic>> _buildHistoryForBackend() {
    if (_messages.isEmpty) return [];
    final filtered =
        _messages.where((m) => m != _messages.first).toList();
    return filtered
        .map((m) => {
              'text': (m['text'] ?? '').toString(),
              'isUser': (m['isUser'] ?? false) == true,
            })
        .toList();
  }

  Future<void> _sendMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _messages.add({
        'text': trimmed,
        'isUser': true,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final url = Uri.parse('$_baseUrl/admin/ai-chat');
      final payload = {
        'question': trimmed,
        'messages': _buildHistoryForBackend(),
      };

      final response = await http
          .post(
            url,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Ошибка сервера (${response.statusCode})');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true || data['response'] == null) {
        throw Exception(data['message'] ?? 'Ошибка получения ответа');
      }

      setState(() {
        _messages.add({
          'text': data['response'].toString(),
          'isUser': false,
          'timestamp': DateTime.now().toIso8601String(),
        });
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'text': e.toString().replaceFirst('Exception: ', ''),
          'isUser': false,
          'timestamp': DateTime.now().toIso8601String(),
        });
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
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
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) =>
                      _buildMessageBubble(_messages[index]),
                ),
              ),
            ),
            if (_isLoading) _buildTypingRow(),
            if (_messages.length <= 1 && !_isLoading) _buildQuickQuestions(),
            const SizedBox(height: 8),
            _buildInputBar(),
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
            color: Colors.black.withOpacity(0.2),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.smart_toy,
                color: Color(0xFF6C63FF), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ИИ помощник",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
                Text(
                  "Помощь администратору",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Color(0xFF4CAF50), size: 8),
                SizedBox(width: 6),
                Text(
                  "Онлайн",
                  style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Color(0xFF6C63FF), strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text("ИИ печатает...",
                    style:
                        TextStyle(color: Color(0xFF6C63FF), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _quickQuestions.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(_quickQuestions[index],
                style: const TextStyle(color: Colors.white, fontSize: 13)),
            backgroundColor: const Color(0xFF6C63FF).withOpacity(0.15),
            side: BorderSide(
                color: const Color(0xFF6C63FF).withOpacity(0.3)),
            onPressed: () => _sendMessage(_quickQuestions[index]),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D1E),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _messageController,
                style:
                    const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Задайте вопрос...",
                  hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
                onSubmitted: (text) => _sendMessage(text),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(_messageController.text),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final bool isUser = message['isUser'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.smart_toy,
                  color: Color(0xFF6C63FF), size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF6C63FF)
                    : const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: SelectableText(
                (message['text'] ?? '').toString(),
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, height: 1.5),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16)),
              child:
                  const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
