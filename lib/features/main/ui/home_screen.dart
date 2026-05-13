import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../constants/constants.dart';
import '../../../extensions/build_context_extension.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import 'view_model/home_state.dart';
import 'view_model/home_view_model.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
// All magic numbers live here. Change once, reflects everywhere.
class _DS {
  // Radii
  static const double radiusCard = 28.0;
  static const double radiusChip = 16.0;
  static const double radiusBubble = 50.0; // effectively circle

  // Spacing
  static const double spaceXS = 6.0;
  static const double spaceSM = 12.0;
  static const double spaceMD = 20.0;
  static const double spaceLG = 28.0;

  // Card padding
  static const EdgeInsets paddingCard = EdgeInsets.all(20.0);

  // Palette — accent colours tied to the app's soft-pastel identity
  static const Color accentPink  = Color(0xFFFFA7C4);
  static const Color accentBlue  = Color(0xFF7BB6FF);
  static const Color accentMint  = Color(0xFF6DCFB0);
  static const Color accentPeach = Color(0xFFFF9F6E);
  static const Color accentLilac = Color(0xFFB89CFF);

  // Chat card gradient — warm sage
  static const Color chatGradStart = Color(0xFFA8D8A8);
  static const Color chatGradEnd   = Color(0xFFD4EFC1);

  // Streak gradient
  static const Color streakOrange = Color(0xFFFFC06A);
  static const Color streakRed    = Color(0xFFFF8E6E);

  // Dark surface
  static const Color darkSurface = Color(0xFF1D2033);
}
// ──────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  final void Function(int tabIndex)? onTabChange;

  const HomeScreen({super.key, this.onTabChange});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  static const List<_MoodItem> _moods = [
    _MoodItem(emoji: '😢', label: 'Very Sad', color: Color(0xFF7B9ACC)),
    _MoodItem(emoji: '😔', label: 'Sad',      color: Color(0xFF91A7D0)),
    _MoodItem(emoji: '😊', label: 'Okay',     color: Color(0xFF8AC6B8)),
    _MoodItem(emoji: '😄', label: 'Happy',    color: Color(0xFFFFB38A)),
    _MoodItem(emoji: '🤩', label: 'Excited',  color: Color(0xFFFF8FA3)),
  ];

  late final AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  String get _formattedDate => DateFormat('EEEE, MMM d').format(DateTime.now());

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(homeViewModelProvider);

    return Scaffold(
      backgroundColor: context.primaryBackgroundColor,
      body: Stack(
        children: [
          _AnimatedBackground(controller: _backgroundController),
          SafeArea(
            child: homeAsync.when(
              loading: () => _buildBody(context, HomeState()),
              error:   (_, __) => _buildBody(context, HomeState()),
              data:    (state) => _buildBody(context, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    final selectedMoodIndex = state.selectedMoodIndex;
    final moodColor = selectedMoodIndex != null
        ? _moods[selectedMoodIndex].color
        : const Color(0xFFB8C9FF);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        _DS.spaceMD, _DS.spaceSM, _DS.spaceMD, 120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(state.userName),
          const SizedBox(height: _DS.spaceLG),
          _buildMoodCard(selectedMoodIndex, state.moodLocked, moodColor),
          const SizedBox(height: _DS.spaceMD),
          _buildQuickActions(),
          const SizedBox(height: _DS.spaceLG),
          _buildBentoGrid(),
          const SizedBox(height: _DS.spaceLG),
          _buildReflectionCard(),
          const SizedBox(height: _DS.spaceMD),
          _buildStreakCard(state.streakCount, state.weekStatus),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(String? userName) {
    final displayName = (userName != null && userName.isNotEmpty)
        ? userName
        : Constants.defaultName;
    final initial = displayName[0].toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formattedDate,
                style: AppTheme.body12.copyWith(
                  color: context.secondaryTextColor,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: _DS.spaceXS),
              Text(
                _greeting,
                style: AppTheme.body14.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
              const SizedBox(height: _DS.spaceXS),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  displayName,
                  key: ValueKey(displayName),
                  style: AppTheme.title32.copyWith(
                    color: context.primaryTextColor,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => widget.onTabChange?.call(4),
          child: Hero(
            tag: 'profile_avatar',
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_DS.accentPink, _DS.accentBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _DS.accentPink.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: AppTheme.title18.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ).animate().fade(duration: 500.ms).slideY(begin: -0.15);
  }

  // ── Mood card ─────────────────────────────────────────────────────────────

  Widget _buildMoodCard(int? selectedMoodIndex, bool moodLocked, Color moodColor) {
    final isDark = context.isDarkMode;

    return ClipRRect(
      borderRadius: BorderRadius.circular(_DS.radiusCard),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: _DS.paddingCard,
          decoration: BoxDecoration(
            color: context.secondaryWidgetColor.withOpacity(isDark ? 0.6 : 0.45),
            borderRadius: BorderRadius.circular(_DS.radiusCard),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: moodColor.withOpacity(isDark ? 0.10 : 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Text(
                    'How are you feeling today?',
                    style: AppTheme.subtitle16.copyWith(
                      color: context.primaryTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (moodLocked) _savedChip(moodColor),
                ],
              ),

              const SizedBox(height: _DS.spaceSM),

              // Mood label
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: selectedMoodIndex == null
                    ? Text(
                  'Pick a mood below',
                  key: const ValueKey('empty'),
                  style: AppTheme.body14.copyWith(
                    color: context.secondaryTextColor,
                  ),
                )
                    : Text(
                  'Feeling ${_moods[selectedMoodIndex].label} today',
                  key: ValueKey(selectedMoodIndex),
                  style: AppTheme.body14.copyWith(
                    color: moodColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: _DS.spaceLG),

              // Mood buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_moods.length, (index) {
                  return _MoodButton(
                    mood: _moods[index],
                    isSelected: selectedMoodIndex == index,
                    isLocked: moodLocked,
                    onTap: moodLocked
                        ? null
                        : () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(homeViewModelProvider.notifier)
                          .saveMood(index);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(delay: 100.ms).slideY(begin: 0.08);
  }

  Widget _savedChip(Color moodColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: moodColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(_DS.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 12, color: moodColor),
          const SizedBox(width: 4),
          Text(
            'Saved',
            style: AppTheme.body12.copyWith(
              color: moodColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick actions ─────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    final isDark = context.isDarkMode;

    final items = [
      (Icons.menu_book_rounded,      'Journal', const Color(0xFFFFD6E2)),
      (Icons.self_improvement_rounded,'Calm',   const Color(0xFFD9F6E7)),
      (Icons.nightlight_round,        'Sleep',  const Color(0xFFDCE4FF)),
      (Icons.graphic_eq_rounded,      'Focus',  const Color(0xFFFFEDCC)),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: _DS.spaceSM),
        itemBuilder: (_, i) {
          final (icon, label, chipColor) = items[i];
          final bg   = isDark ? chipColor.withOpacity(0.15) : chipColor;
          final fg   = isDark ? AppColors.mono20 : AppColors.mono90;
          final border = isDark ? Border.all(color: chipColor.withOpacity(0.3)) : null;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(_DS.radiusChip),
              border: border,
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTheme.body12.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).animate().fade(delay: 200.ms);
  }

  // ── Bento grid ────────────────────────────────────────────────────────────

  Widget _buildBentoGrid() {
    return Column(
      children: [
        // Chat CTA card
        GestureDetector(
          onTap: () => widget.onTabChange?.call(2),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_DS.chatGradStart, _DS.chatGradEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(_DS.radiusCard),
              boxShadow: [
                BoxShadow(
                  color: _DS.chatGradStart.withOpacity(0.30),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  top: -10,
                  child: Opacity(
                    opacity: 0.10,
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      size: 180,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: _DS.paddingCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Chat with Khayal',
                        style: AppTheme.title24.copyWith(
                          color: Colors.black.withOpacity(0.75),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: _DS.spaceXS),
                      Text(
                        'Your AI wellness companion is here',
                        style: AppTheme.body14.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: _DS.spaceMD),

        // Small bento row
        Row(
          children: [
            Expanded(
              child: _smallBentoCard(
                icon: Icons.air_rounded,
                title: 'Breathe',
                subtitle: '60 sec reset',
                colors: const [Color(0xFF7BC6FF), Color(0xFF9FE1FF)],
                onTap: () => widget.onTabChange?.call(1),
              ),
            ),
            const SizedBox(width: _DS.spaceMD),
            Expanded(
              child: _smallBentoCard(
                icon: Icons.music_note_rounded,
                title: 'Calm Beats',
                subtitle: 'Focus mode',
                colors: const [_DS.accentLilac, Color(0xFFE0C3FF)],
              ),
            ),
          ],
        ),
      ],
    ).animate().fade(delay: 250.ms).slideY(begin: 0.08);
  }

  Widget _smallBentoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> colors,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(_DS.radiusCard),
        ),
        padding: _DS.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const Spacer(),
            Text(
              title,
              style: AppTheme.title18.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTheme.body12.copyWith(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reflection card ───────────────────────────────────────────────────────

  Widget _buildReflectionCard() {
    final isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      padding: _DS.paddingCard,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.mono90.withOpacity(0.35)
            : _DS.darkSurface,
        borderRadius: BorderRadius.circular(_DS.radiusCard),
        border: isDark
            ? Border.all(color: context.primaryTextColor.withOpacity(0.08))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Lottie.asset('assets/animations/calm_orb.json', repeat: true),
          ),
          const SizedBox(width: _DS.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiny Reminder 🌱',
                  style: AppTheme.title16.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: _DS.spaceSM),
                Text(
                  'Progress is not linear. Oceans wave too, yet they still reach the shore.',
                  style: AppTheme.body14.copyWith(
                    color: Colors.white.withOpacity(0.80),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 300.ms);
  }

  // ── Streak card ───────────────────────────────────────────────────────────

  Widget _buildStreakCard(int streakCount, List<bool> weekStatus) {
    final isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      padding: _DS.paddingCard,
      decoration: BoxDecoration(
        color: context.secondaryWidgetColor.withOpacity(isDark ? 0.4 : 0.72),
        borderRadius: BorderRadius.circular(_DS.radiusCard),
        border: Border.all(
          color: isDark
              ? context.primaryTextColor.withOpacity(0.08)
              : Colors.white.withOpacity(0.55),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_DS.streakOrange, _DS.streakRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Text('🔥', style: TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: _DS.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$streakCount Day Streak',
                      style: AppTheme.title18.copyWith(
                        color: context.primaryTextColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: _DS.spaceXS),
                    Text(
                      'Consistency beats intensity. You showed up again ✨',
                      style: AppTheme.body12.copyWith(
                        color: context.secondaryTextColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: _DS.spaceMD),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dayBubble('M', weekStatus[0]),
              _dayBubble('T', weekStatus[1]),
              _dayBubble('W', weekStatus[2]),
              _dayBubble('T', weekStatus[3]),
              _dayBubble('F', weekStatus[4]),
              _dayBubble('S', weekStatus[5]),
              _dayBubble('S', weekStatus[6]),
            ],
          ),
        ],
      ),
    ).animate().fade(delay: 350.ms);
  }

  Widget _dayBubble(String day, bool active) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width:  active ? 20 : 12,
          height: active ? 20 : 12,
          decoration: BoxDecoration(
            color: active
                ? _DS.accentPeach
                : context.isDarkMode
                ? Colors.white.withOpacity(0.10)
                : AppColors.mono40.withOpacity(0.45),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: _DS.spaceXS),
        Text(
          day,
          style: AppTheme.body12.copyWith(color: context.secondaryTextColor),
        ),
      ],
    );
  }
}

// ── Animated background ────────────────────────────────────────────────────────

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [
                    Color(0xFF0F111A),
                    Color(0xFF161925),
                    Color(0xFF0D0F16),
                  ]
                      : const [
                    Color(0xFFEFF6FF),
                    Color(0xFFFFF4F8),
                    Color(0xFFF9F7FF),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -60 + (controller.value * 20),
              right: -40,
              child: _blurCircle(220, _DS.accentPink),
            ),
            Positioned(
              bottom: -80,
              left: -50 + (controller.value * 30),
              child: _blurCircle(260, _DS.accentBlue),
            ),
          ],
        );
      },
    );
  }

  Widget _blurCircle(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.32),
        ),
      ),
    );
  }
}

// ── Data models ────────────────────────────────────────────────────────────────

class _MoodItem {
  final String emoji;
  final String label;
  final Color color;

  const _MoodItem({
    required this.emoji,
    required this.label,
    required this.color,
  });
}

class _MoodButton extends StatefulWidget {
  final _MoodItem mood;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback? onTap;

  const _MoodButton({
    required this.mood,
    required this.isSelected,
    required this.isLocked,
    this.onTap,
  });

  @override
  State<_MoodButton> createState() => _MoodButtonState();
}

class _MoodButtonState extends State<_MoodButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      lowerBound: 0.95,
      upperBound: 1.05,
    );
    if (widget.isSelected) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _MoodButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dimmed = widget.isLocked && !widget.isSelected;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: dimmed ? 0.30 : 1,
        child: ScaleTransition(
          scale: _controller,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width:  widget.isSelected ? 40 : 34,
            height: widget.isSelected ? 40 : 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.isSelected
                  ? LinearGradient(colors: [
                widget.mood.color.withOpacity(0.9),
                widget.mood.color.withOpacity(0.55),
              ])
                  : null,
              color: widget.isSelected
                  ? null
                  : context.secondaryWidgetColor.withOpacity(0.5),
              boxShadow: widget.isSelected
                  ? [
                BoxShadow(
                  color: widget.mood.color.withOpacity(0.40),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
                  : [],
            ),
            child: Center(
              child: Text(
                widget.mood.emoji,
                style: TextStyle(fontSize: widget.isSelected ? 28 : 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}