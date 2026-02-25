import 'package:flutter/material.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  static const _purple = Color(0xFF6C63FF);
  static const _card = Color(0xFF1A1A2E);
  static const _bg = Color(0xFF0D0D1E);

  // Развёрнутые FAQ-пункты
  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      icon: Icons.calculate_rounded,
                      color: _purple,
                      title: 'Как рассчитывается FPS',
                      child: _buildFpsMethodology(),
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      icon: Icons.signal_cellular_alt_rounded,
                      color: const Color(0xFF4CAF50),
                      title: 'Статусы совместимости',
                      child: _buildStatusLegend(),
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      icon: Icons.help_outline_rounded,
                      color: const Color(0xFFFFB300),
                      title: 'Частые вопросы (FAQ)',
                      child: _buildFaq(),
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      icon: Icons.info_outline_rounded,
                      color: const Color(0xFF00BCD4),
                      title: 'О GamePulse',
                      child: _buildAboutBlock(),
                    ),
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
  Widget _buildHeader() {
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
            'О приложении',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ─── Section wrapper ──────────────────────────────────────────────────────
  Widget _buildSection({
    required IconData icon,
    required Color color,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ],
    );
  }

  // ─── FPS Methodology ─────────────────────────────────────────────────────
  Widget _buildFpsMethodology() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _methodStep(
          '1',
          'Сравнение характеристик',
          'Ваш CPU и GPU сравниваются с официальными минимальными и '
              'рекомендуемыми требованиями игры по балльной шкале.',
          const Color(0xFF6C63FF),
        ),
        const SizedBox(height: 12),
        _methodStep(
          '2',
          'Расчёт базового FPS',
          'На основе мощности вашего GPU вычисляется базовый FPS. '
              'Например, RTX 4090 даёт ~180+ FPS в 1080p для большинства игр.',
          const Color(0xFF4CAF50),
        ),
        const SizedBox(height: 12),
        _methodStep(
          '3',
          'Коррекция по CPU и RAM',
          'Если процессор или ОЗУ ниже рекомендуемых — FPS снижается '
              'пропорционально. Узкие места определяются автоматически.',
          const Color(0xFFFF9800),
        ),
        const SizedBox(height: 12),
        _methodStep(
          '4',
          'Итоговая оценка',
          'FPS округляется до 5 и присваивается статус: Отлично (≥80), '
              'Хорошо (60–79), Играбельно (30–59), Недостаточно (<30).',
          const Color(0xFFE91E63),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _purple.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: _purple, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Расчёт — это прогноз. Реальный FPS зависит от '
                  'настроек игры, разрешения, фоновых процессов.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _methodStep(
      String num, String title, String body, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(num,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const SizedBox(height: 3),
              Text(body,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Status legend ────────────────────────────────────────────────────────
  Widget _buildStatusLegend() {
    const statuses = [
      (
        'Отлично',
        '≥ 80 FPS',
        'Игра идёт плавно на высоких настройках. Можете включать 4K и Ultra.',
        Color(0xFF4CAF50),
        Icons.check_circle_rounded,
      ),
      (
        'Хорошо',
        '60–79 FPS',
        'Комфортная игра на средних-высоких настройках. Небольшой потенциал апгрейда.',
        Color(0xFF6C63FF),
        Icons.thumb_up_rounded,
      ),
      (
        'Играбельно',
        '30–59 FPS',
        'Игра работает, но возможны просадки. Снизьте настройки до средних.',
        Color(0xFFFFA726),
        Icons.warning_rounded,
      ),
      (
        'Недостаточно',
        '< 30 FPS',
        'ПК не справляется с игрой. Необходим апгрейд GPU или CPU.',
        Colors.red,
        Icons.error_rounded,
      ),
    ];

    return Column(
      children: statuses.map((s) {
        final (label, fps, desc, color, icon) = s;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(label,
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(fps,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(desc,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── FAQ ──────────────────────────────────────────────────────────────────
  Widget _buildFaq() {
    const items = [
      (
        'Почему FPS отличается от реального?',
        'Расчёт — это прогноз на основе спецификаций. Реальный FPS '
            'зависит от разрешения, графических настроек, фонового ПО, '
            'температуры и других факторов.',
      ),
      (
        'Как долго хранится кэш результатов?',
        'Результаты совместимости кэшируются на 24 часа. После этого '
            'данные обновляются автоматически. Можно принудительно '
            'обновить через «потяни вниз» на странице игры.',
      ),
      (
        'Почему мой GPU не в списке?',
        'Список содержит наиболее популярные GPU. Если вашей карты '
            'нет — используйте кнопку «Ввести вручную» и укажите '
            'модель текстом. Некоторые нестандартные модели могут '
            'давать неточный расчёт.',
      ),
      (
        'До скольки игр можно добавить в избранное?',
        'Максимум 5 игр. Это сделано для быстрого доступа к самым '
            'нужным играм. Чтобы добавить новую — снимите звёздочку '
            'с одной из текущих.',
      ),
      (
        'Как работает ИИ-рекомендации апгрейда?',
        'На странице совместимости кнопка «Апгрейд» открывает '
            'анализ от ИИ: конкретные компоненты для замены, '
            'бюджетные варианты и ожидаемый прирост FPS.',
      ),
    ];

    return Column(
      children: List.generate(items.length, (i) {
        final (q, a) = items[i];
        final isOpen = _expanded.contains(i);
        return Column(
          children: [
            InkWell(
              onTap: () => setState(
                  () => isOpen ? _expanded.remove(i) : _expanded.add(i)),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(q,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                    Icon(
                      isOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ),
            if (isOpen) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(a,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        height: 1.5)),
              ),
            ],
            if (i < items.length - 1)
              Divider(
                  height: 1,
                  color: Colors.white.withOpacity(0.07),
                  thickness: 1),
          ],
        );
      }),
    );
  }

  // ─── About block ──────────────────────────────────────────────────────────
  Widget _buildAboutBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.games, color: _purple, size: 28),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GamePulse',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('Версия 1.0.0',
                    style:
                        TextStyle(color: Color(0xFF6C63FF), fontSize: 13)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'GamePulse — приложение для проверки совместимости ПК с '
          'играми. Введите характеристики своего компьютера и мгновенно '
          'узнайте ожидаемый FPS и статус для любой игры из каталога. '
          'Встроенный ИИ подберёт оптимальные варианты апгрейда под ваш бюджет.',
          style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
              height: 1.5),
        ),
      ],
    );
  }
}
