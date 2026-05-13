import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../constants/constants.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../extensions/build_context_extension.dart';
import 'view_model/home_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  HomeScreen
//  • Greeting pulled from profileViewModelProvider (SharedPreferences / DB)
//  • Mood selector: persists today's choice via homeViewModelProvider
//  • Action cards route to the correct tab via the onTabChange callback
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  /// Called when a card requests a tab switch; index matches [MainTab] enum.
  final void Function(int tabIndex)? onTabChange;

  const HomeScreen({super.key, this.onTabChange});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  // ─── Mood data ──────────────────────────────────────────────────────────────
  static const List<_MoodItem> _moods = [
    _MoodItem('😢', 'Very Sad'),
    _MoodItem('😐', 'Sad'),
    _MoodItem('😊', 'Okay'),
    _MoodItem('😄', 'Happy'),
    _MoodItem('🤩', 'Excited'),
  ];

  // ─── Card press animations ───────────────────────────────────────────────
  late final List<AnimationController> _cardControllers;
  late final List<Animation<double>> _cardScales;

  @override
  void initState() {
    super.initState();
    _cardControllers = List.generate(
      2,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 120),
        lowerBound: 0.94,
        upperBound: 1.0,
        value: 1.0,
      ),
    );
    _cardScales = _cardControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _cardControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────
  String get _formattedDate =>
      DateFormat('EEE MMM d').format(DateTime.now()).toUpperCase();

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(homeViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFDFEBF5),
      body: SafeArea(
        child: homeAsync.when(
          loading: () => _buildBody(context, null, null),
          error: (_, __) => _buildBody(context, null, null),
          data: (state) =>
              _buildBody(context, state.userName, state.selectedMoodIndex),
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, String? userName, int? selectedMoodIndex) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 104),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, userName),
          const SizedBox(height: 28),
          _buildMoodSection(context, selectedMoodIndex),
          const SizedBox(height: 24),
          _buildActionCards(context),
          const SizedBox(height: 20),
          _buildStreakBanner(context),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  Header
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String? userName) {
    final displayName = (userName != null && userName.isNotEmpty)
        ? userName
        : Constants.defaultName;

    // First character for avatar
    final initial = displayName[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formattedDate,
                  style: AppTheme.body12.copyWith(
                    color: AppColors.mono60,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                // Animated greeting – fades in when userName resolves
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    'Hi, $displayName',
                    key: ValueKey(displayName),
                    style: AppTheme.title32.copyWith(
                      color: AppColors.mono100,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildAvatar(initial),
        ],
      ),
    );
  }

  Widget _buildAvatar(String initial) {
    return Stack(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.blueberry80,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.blueberry100.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: AppTheme.title18.copyWith(color: Colors.white),
            ),
          ),
        ),
        Positioned(
          top: 1,
          right: 1,
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: AppColors.rambutan80,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  Mood Selector
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildMoodSection(BuildContext context, int? selectedMoodIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeling today?',
            style: AppTheme.subtitle16.copyWith(color: AppColors.mono80),
          ),
          const SizedBox(height: 4),
          // Confirmation label
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: selectedMoodIndex != null
                ? Text(
                    key: ValueKey(selectedMoodIndex),
                    'You feel ${_moods[selectedMoodIndex].label} today',
                    style: AppTheme.body12.copyWith(
                      color: AppColors.blueberry100,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Text(
                    key: const ValueKey('empty'),
                    'Tap an emoji to log your mood',
                    style: AppTheme.body12.copyWith(color: AppColors.mono60),
                  ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_moods.length, (i) {
              final isSelected = i == selectedMoodIndex;
              return _MoodButton(
                mood: _moods[i],
                isSelected: isSelected,
                onTap: () {
                  // Persist via ViewModel
                  ref.read(homeViewModelProvider.notifier).saveMood(i);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  Action Cards
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildActionCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chat to Khayal → tab index 2 (chat)
          Expanded(
            child: _buildActionCard(
              cardIndex: 0,
              tabIndex: 2,
              backgroundColor: const Color(0xFFF2BDC0),
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: const Color(0xFF8B4F53),
              title: 'Chat to\nKhayal',
              subtitle: 'AI companion',
              titleColor: AppColors.mono90,
              subtitleColor: AppColors.mono60,
              height: 180,
            ),
          ),
          const SizedBox(width: 16),
          // Breathe → tab index 1 (journal, placeholder for breathe)
          Expanded(
            child: _buildActionCard(
              cardIndex: 1,
              tabIndex: 1,
              backgroundColor: const Color(0xFF5B9BBF),
              icon: Icons.air_rounded,
              iconColor: Colors.white,
              title: 'Breathe',
              subtitle: '3 min exercise',
              titleColor: Colors.white,
              subtitleColor: Colors.white70,
              height: 180,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required int cardIndex,
    required int tabIndex,
    required Color backgroundColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color titleColor,
    required Color subtitleColor,
    required double height,
  }) {
    return ScaleTransition(
      scale: _cardScales[cardIndex],
      child: GestureDetector(
        onTapDown: (_) => _cardControllers[cardIndex].reverse(),
        onTapUp: (_) {
          _cardControllers[cardIndex].forward();
          // Navigate to the target tab
          widget.onTabChange?.call(tabIndex);
        },
        onTapCancel: () => _cardControllers[cardIndex].forward(),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.40),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon bubble
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTheme.title18.copyWith(color: titleColor)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: AppTheme.body12.copyWith(color: subtitleColor)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  Streak Banner
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildStreakBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0E6),
                shape: BoxShape.circle,
              ),
              child:
                  const Center(child: Text('🔥', style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '3 Day Streak',
                    style: AppTheme.title16.copyWith(color: AppColors.mono90),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"Stress is caused by being \'here\' but wanting to be elsewhere." – Eckhart Tolle',
                    style: AppTheme.body12.copyWith(
                      color: AppColors.mono60,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Private helpers
// ─────────────────────────────────────────────────────────────────────────────

class _MoodItem {
  final String emoji;
  final String label;
  const _MoodItem(this.emoji, this.label);
}

/// Animated, interactive mood emoji button.
class _MoodButton extends StatefulWidget {
  final _MoodItem mood;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodButton({
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_MoodButton> createState() => _MoodButtonState();
}

class _MoodButtonState extends State<_MoodButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnim = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(_MoodButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger bounce when this emoji becomes selected
    if (widget.isSelected && !oldWidget.isSelected) {
      _bounceCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: widget.isSelected ? 60 : 48,
        height: widget.isSelected ? 60 : 48,
        decoration: BoxDecoration(
          color: widget.isSelected
              ? Colors.white.withOpacity(0.75)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: widget.isSelected
              ? Border.all(color: Colors.white, width: 2.5)
              : null,
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: ScaleTransition(
            scale: _bounceAnim,
            child: Text(
              widget.mood.emoji,
              style: TextStyle(fontSize: widget.isSelected ? 30 : 24),
            ),
          ),
        ),
      ),
    );
  }
}
