import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';

import '../../../extensions/build_context_extension.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../profile/ui/view_model/profile_view_model.dart';
import '../../../routing/routes.dart';
import '../model/survey_question.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Map<String, dynamic> _answers = {};
  bool _isFinalizing = false;

  void _onAnswer(String questionId, dynamic value) {
    setState(() {
      _answers[questionId] = value;
    });
  }

  void _nextPage() {
    if (_currentPage < onboardingQuestions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finalizeSurvey();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _finalizeSurvey() async {
    setState(() {
      _isFinalizing = true;
    });

    // Show the "Personalizing" animation for 5 seconds
    await Future.delayed(const Duration(seconds: 5));

    try {
      await ref.read(profileViewModelProvider.notifier).setWasShowOnboarding();
      await ref.read(profileViewModelProvider.notifier).updateProfile(
            surveyData: _answers,
          );
      if (mounted) {
        context.pushReplacement(Routes.main);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isFinalizing = false;
        });
        context.showErrorSnackBar('Failed to save survey results');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinalizing) {
      return const _PersonalizingView();
    }

    final currentQuestion = onboardingQuestions[_currentPage];
    final progress = (_currentPage + 1) / onboardingQuestions.length;
    final isLastPage = _currentPage == onboardingQuestions.length - 1;
    final hasAnswer = _answers.containsKey(currentQuestion.id);

    return Scaffold(
      backgroundColor: context.secondaryBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _currentPage > 0 ? _previousPage : null,
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: _currentPage > 0
                              ? context.primaryTextColor
                              : Colors.transparent,
                        ),
                      ),
                      Text(
                        'Step ${_currentPage + 1} of ${onboardingQuestions.length}',
                        style: AppTheme.body12.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 48), // Spacer for balance
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: context.isDarkMode
                          ? Colors.white10
                          : Colors.black.withOpacity(0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.blueberry100,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: onboardingQuestions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionContent(onboardingQuestions[index]);
                },
              ),
            ),

            // Navigation Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: hasAnswer ? _nextPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueberry100,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: context.isDarkMode
                      ? Colors.white10
                      : Colors.black.withOpacity(0.05),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isLastPage ? 'Finish' : 'Continue',
                  style: AppTheme.label16.copyWith(
                    fontWeight: FontWeight.w700,
                    color: hasAnswer ? Colors.white : context.secondaryTextColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionContent(SurveyQuestion question) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.blueberry100.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              question.category.toUpperCase(),
              style: AppTheme.body16.copyWith(
                color: AppColors.blueberry100,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            question.question,
            style: AppTheme.title24.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 32),
          _buildAnswerInput(question),
        ],
      ),
    );
  }

  Widget _buildAnswerInput(SurveyQuestion question) {
    switch (question.type) {
      case QuestionType.mcq:
        return Column(
          children: question.options!.map((option) {
            final isSelected = _answers[question.id] == option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SelectionCard(
                text: option,
                isSelected: isSelected,
                onTap: () => _onAnswer(question.id, option),
              ),
            );
          }).toList(),
        );

      case QuestionType.multiSelect:
        final selectedOptions = List<String>.from(_answers[question.id] ?? []);
        return Column(
          children: question.options!.map((option) {
            final isSelected = selectedOptions.contains(option);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SelectionCard(
                text: option,
                isSelected: isSelected,
                isMulti: true,
                onTap: () {
                  if (isSelected) {
                    selectedOptions.remove(option);
                  } else {
                    selectedOptions.add(option);
                  }
                  _onAnswer(question.id, selectedOptions.isEmpty ? null : selectedOptions);
                },
              ),
            );
          }).toList(),
        );

      case QuestionType.scale:
        final currentVal = (_answers[question.id] as num?)?.toDouble() ?? 
                           (question.minScale! + (question.maxScale! - question.minScale!) / 2).toDouble();
        return Column(
          children: [
            const SizedBox(height: 40),
            Text(
              currentVal.toInt().toString(),
              style: AppTheme.title32.copyWith(
                color: AppColors.blueberry100,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.blueberry100,
                inactiveTrackColor: AppColors.blueberry100.withOpacity(0.1),
                thumbColor: AppColors.blueberry100,
                overlayColor: AppColors.blueberry100.withOpacity(0.1),
                trackHeight: 8,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              ),
              child: Slider(
                value: currentVal,
                min: question.minScale!.toDouble(),
                max: question.maxScale!.toDouble(),
                divisions: question.maxScale! - question.minScale!,
                onChanged: (val) {
                  _onAnswer(question.id, val.toInt());
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(question.minScale.toString(), style: AppTheme.body14),
                  Text(question.maxScale.toString(), style: AppTheme.body14),
                ],
              ),
            ),
          ],
        );

      case QuestionType.fillIn:
        return TextField(
          autofocus: true,
          style: AppTheme.body16,
          decoration: InputDecoration(
            hintText: question.placeholder,
            hintStyle: TextStyle(color: context.secondaryTextColor.withOpacity(0.5)),
            filled: true,
            fillColor: context.secondaryWidgetColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(20),
          ),
          onChanged: (val) {
            _onAnswer(question.id, val.trim().isEmpty ? null : val.trim());
          },
        );
    }
  }
}

class _SelectionCard extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool isMulti;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.text,
    required this.isSelected,
    this.isMulti = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.blueberry100.withOpacity(0.1) 
              : context.secondaryWidgetColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? AppColors.blueberry100 
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: AppTheme.body16.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.blueberry100 : context.primaryTextColor,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                isMulti ? Icons.check_box_rounded : Icons.check_circle_rounded,
                color: AppColors.blueberry100,
                size: 20,
              )
            else
              Icon(
                isMulti ? Icons.check_box_outline_blank_rounded : Icons.radio_button_off_rounded,
                color: context.secondaryTextColor.withOpacity(0.3),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _PersonalizingView extends StatefulWidget {
  const _PersonalizingView();

  @override
  State<_PersonalizingView> createState() => _PersonalizingViewState();
}

class _PersonalizingViewState extends State<_PersonalizingView> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _dotsController;
  int _dotCount = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _timer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dotsController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.secondaryBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulse Animation
            ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.1).animate(
                CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.blueberry100, AppColors.rambutan80],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blueberry100.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedMagicWand01,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
            Text(
              'Personalizing your sacred space${"." * _dotCount}',
              style: AppTheme.title20.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Text(
                'Taking a moment to tailor Khayal AI to your unique rhythm and needs.',
                textAlign: TextAlign.center,
                style: AppTheme.body14.copyWith(
                  color: context.secondaryTextColor,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
