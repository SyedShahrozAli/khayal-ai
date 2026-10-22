import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../extensions/build_context_extension.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../model/journal_entry.dart';
import 'crisis_safety_banner.dart';
import 'journal_prompts.dart';
import 'view_model/journal_view_model.dart';

class JournalWriteScreen extends ConsumerStatefulWidget {
  final JournalEntry? existing;
  final bool startWithVoice;

  const JournalWriteScreen({
    super.key,
    this.existing,
    this.startWithVoice = false,
  });

  @override
  ConsumerState<JournalWriteScreen> createState() => _JournalWriteScreenState();
}

class _JournalWriteScreenState extends ConsumerState<JournalWriteScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _tagsCtrl;

  // Language & Directionality (FE-1, LOC-1, LOC-2, USE-1)
  late String _selectedLanguage; // 'en', 'ur', 'romanized_ur'
  late String _entryType; // 'text', 'voice'

  // Voice journaling (FE-2, PER-2)
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechInitialized = false;
  bool _isListening = false;
  String _preSpeechContent = '';
  String _speechStatus = '';

  // Safety & State flags
  bool _hasCrisisRisk = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  JournalPrompt? _selectedPrompt;

  // Pulse animation for mic
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _contentCtrl = TextEditingController(text: e?.contentText ?? '');
    _tagsCtrl = TextEditingController(text: e?.tags.join(', ') ?? '');
    _selectedLanguage = e?.language ?? 'en';
    _entryType = e?.entryType ?? (widget.startWithVoice ? 'voice' : 'text');

    _contentCtrl.addListener(_onContentChanged);
    _titleCtrl.addListener(_markChanged);
    _tagsCtrl.addListener(_markChanged);

    // Initial crisis check
    _hasCrisisRisk = CrisisScanner.hasCrisisIntent(_contentCtrl.text);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onError: (err) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _speechStatus = 'Mic: ${err.errorMsg}';
            });
          }
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() {
                _isListening = false;
                _speechStatus = '';
              });
            }
          }
        },
      );
      if (mounted) {
        setState(() => _speechInitialized = available);
        if (available && widget.startWithVoice && widget.existing == null) {
          _startListening();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _speechInitialized = false);
      }
    }
  }

  void _onContentChanged() {
    _markChanged();
    final hasRisk = CrisisScanner.hasCrisisIntent(_contentCtrl.text);
    if (hasRisk != _hasCrisisRisk) {
      setState(() => _hasCrisisRisk = hasRisk);
    }
  }

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  @override
  void dispose() {
    if (_isListening) {
      _speech.stop();
    }
    _pulseController.dispose();
    _contentCtrl.removeListener(_onContentChanged);
    _titleCtrl.removeListener(_markChanged);
    _tagsCtrl.removeListener(_markChanged);
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  List<String> get _parsedTags {
    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (_selectedPrompt != null && !tags.contains(_selectedPrompt!.tag)) {
      tags.add(_selectedPrompt!.tag);
    }
    return tags;
  }

  bool get _isUrdu => _selectedLanguage == 'ur';
  TextDirection get _textDirection =>
      _isUrdu ? TextDirection.rtl : TextDirection.ltr;

  TextStyle get _contentTextStyle {
    if (_isUrdu) {
      return GoogleFonts.notoNastaliqUrdu(
        fontSize: 16,
        height: 2.1,
        fontWeight: FontWeight.w400,
        color: context.primaryTextColor,
      );
    }
    return TextStyle(
      fontSize: 16,
      color: context.primaryTextColor,
      height: 1.6,
      fontWeight: FontWeight.w400,
    );
  }

  TextStyle get _titleTextStyle {
    if (_isUrdu) {
      return GoogleFonts.notoNastaliqUrdu(
        fontSize: 19,
        height: 2.1,
        fontWeight: FontWeight.w800,
        color: context.primaryTextColor,
      );
    }
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: context.primaryTextColor,
      letterSpacing: -0.3,
    );
  }

  // Voice recording toggle (FE-2)
  Future<void> _toggleListening() async {
    HapticFeedback.mediumImpact();
    if (!_speechInitialized) {
      final available = await _speech.initialize();
      if (!available) {
        if (mounted) {
          context.showWarningSnackBar(
            _isUrdu
                ? 'مائیکروفون کی اجازت دستیاب نہیں ہے'
                : 'Microphone permission or speech recognition is not available',
          );
        }
        return;
      }
      setState(() => _speechInitialized = true);
    }

    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _speechStatus = '';
      });
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    _preSpeechContent = _contentCtrl.text.trim();
    _entryType = 'voice';

    final locale = _isUrdu ? 'ur_PK' : 'en_US';
    setState(() {
      _isListening = true;
      _speechStatus = _isUrdu
          ? 'سن رہا ہے... بولیں 🎙️'
          : 'Listening... Speak freely 🎙️';
    });

    try {
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            final words = result.recognizedWords;
            setState(() {
              if (_preSpeechContent.isEmpty) {
                _contentCtrl.text = words;
              } else {
                _contentCtrl.text = '$_preSpeechContent $words';
              }
              _contentCtrl.selection = TextSelection.fromPosition(
                TextPosition(offset: _contentCtrl.text.length),
              );
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: locale,
          listenMode: stt.ListenMode.dictation,
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _speechStatus = 'Mic error: $e';
        });
      }
    }
  }

  // Insert prompt template (FE-3)
  void _applyPrompt(JournalPrompt prompt) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedPrompt = prompt;
      final template = _isUrdu ? prompt.templateUr : prompt.templateEn;
      if (_contentCtrl.text.trim().isEmpty) {
        _contentCtrl.text = template;
      } else {
        _contentCtrl.text = '${_contentCtrl.text.trim()}\n\n$template';
      }
      _contentCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _contentCtrl.text.length),
      );

      if (_titleCtrl.text.trim().isEmpty) {
        _titleCtrl.text = _isUrdu ? prompt.titleUr : prompt.titleEn;
      }

      final existingTags = _parsedTags;
      if (!existingTags.contains(prompt.tag)) {
        if (_tagsCtrl.text.trim().isEmpty) {
          _tagsCtrl.text = prompt.tag;
        } else {
          _tagsCtrl.text = '${_tagsCtrl.text.trim()}, ${prompt.tag}';
        }
      }
      _hasUnsavedChanges = true;
    });
  }

  // Save entry (FE-4, FE-5, REL-1)
  Future<void> _save({bool asDraft = false}) async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      context.showWarningSnackBar(
        _isUrdu
            ? 'براہ کرم کچھ لکھنے کے بعد محفوظ کریں'
            : 'Please write or record something before saving.',
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }

    setState(() => _isSaving = true);

    try {
      final title = _titleCtrl.text.trim().isEmpty
          ? null
          : _titleCtrl.text.trim();
      final vm = ref.read(journalViewModelProvider.notifier);

      if (widget.existing != null) {
        await vm.updateEntry(
          id: widget.existing!.id,
          title: title,
          contentText: content,
          language: _selectedLanguage,
          entryType: _entryType,
          tags: _parsedTags,
        );
      } else {
        await vm.createEntry(
          title: title,
          contentText: content,
          entryType: _entryType,
          language: _selectedLanguage,
          tags: _parsedTags,
          isDraft: asDraft,
        );
      }

      _hasUnsavedChanges = false;
      if (mounted) {
        Navigator.of(context).pop(true);
        context.showSuccessSnackBar(
          asDraft
              ? (_isUrdu ? 'مسودہ محفوظ کر لیا گیا ✓' : 'Draft saved offline ✓')
              : (_isUrdu
                    ? 'تحریر محفوظ ہو گئی ✓'
                    : 'Entry saved successfully ✓'),
        );
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Save error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: context.isDarkMode
            ? const Color(0xFF1D2033)
            : const Color(0xFFFFFDF9),
        title: Text(
          _isUrdu ? 'کیا آپ واپس جانا چاہتے ہیں؟' : 'Discard changes?',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          _isUrdu
              ? 'آپ کی تبدیلیاں محفوظ نہیں ہوئیں۔ کیا آپ باہر نکلنا چاہتے ہیں؟'
              : 'You have unsaved reflections. Save as draft or discard?',
          style: TextStyle(color: context.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              _isUrdu ? 'خارج کریں' : 'Discard',
              style: const TextStyle(
                color: Color(0xFFDE6B48),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, false);
              _save(asDraft: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF7A81B),
              foregroundColor: const Color(0xFF221400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              _isUrdu ? 'ڈرافٹ بنائیں' : 'Save Draft',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final wordCount = _contentCtrl.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final readingMinutes = (wordCount / 130).ceil();
    final todayStr = DateFormat('EEEE, MMM d').format(DateTime.now());

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: context.isDarkMode
            ? const Color(0xFF161722)
            : const Color(0xFFF6F2EB),
        appBar: AppBar(
          backgroundColor: context.isDarkMode
              ? const Color(0xFF161722)
              : const Color(0xFFF6F2EB),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            tooltip: 'Back',
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing != null
                    ? (_isUrdu ? 'تحریر میں ترمیم' : 'Edit Reflection')
                    : (_isUrdu ? 'روزانہ خیال' : 'Daily Reflection'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                todayStr,
                style: TextStyle(
                  fontSize: 11,
                  color: context.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            // Draft button
            if (widget.existing == null && !_isSaving)
              TextButton(
                onPressed: () => _save(asDraft: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE6DA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _isUrdu ? 'ڈرافٹ' : 'Draft',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4A3828),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

            // Save / Done Button
            Padding(
              padding: const EdgeInsets.only(right: 14.0, left: 4.0),
              child: Center(
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Color(0xFFF7A81B),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () => _save(asDraft: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF7A81B),
                          foregroundColor: const Color(0xFF221400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          minimumSize: const Size(64, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          elevation: 0,
                        ),
                        child: Text(
                          _isUrdu ? 'محفوظ کریں' : 'Save',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF221400),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ── Active Listening Banner (FE-2) ────────────────────────────
              if (_isListening)
                Container(
                  width: double.infinity,
                  color: const Color(0xFFDE6B48).withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDE6B48),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _speechStatus,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFDE6B48),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _toggleListening,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _isUrdu ? 'مکمل کریں' : 'Done',
                          style: const TextStyle(
                            color: Color(0xFFDE6B48),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Crisis Guardrail Banner (REL-3) ───────────────────────────
              if (_hasCrisisRisk)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: CrisisSafetyBanner(),
                ),

              // ── Main Content Area ─────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 1. Language Toggle Strip ──────────────────────────
                      Row(
                        children: [
                          Text(
                            _isUrdu ? 'زبان:' : 'Language:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.secondaryTextColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _buildLanguageChip('English', 'en'),
                          const SizedBox(width: 6),
                          _buildLanguageChip('اردو', 'ur'),
                          const SizedBox(width: 6),
                          _buildLanguageChip('Roman Urdu', 'romanized_ur'),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── 2. Guided Prompts Carousel ────────────────────────
                      _buildPromptsSection(),
                      const SizedBox(height: 16),

                      // ── 3. Journal Writing Canvas (Paper Card) ────────────
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? const Color(0xFF1D2033)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Title Input
                            Directionality(
                              textDirection: _textDirection,
                              child: TextField(
                                controller: _titleCtrl,
                                style: _titleTextStyle,
                                textDirection: _textDirection,
                                decoration: InputDecoration(
                                  hintText: _isUrdu
                                      ? 'عنوان (اختیاری)...'
                                      : 'Reflection Title (optional)...',
                                  hintStyle: _titleTextStyle.copyWith(
                                    color: context.secondaryTextColor
                                        .withValues(alpha: 0.4),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                textCapitalization:
                                    TextCapitalization.sentences,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Divider(
                              color: context.isDarkMode
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFF0EBE1),
                              height: 1,
                            ),
                            const SizedBox(height: 14),

                            // Reflection Content Field
                            Directionality(
                              textDirection: _textDirection,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight:
                                      MediaQuery.sizeOf(context).height * 0.32,
                                ),
                                child: TextField(
                                  controller: _contentCtrl,
                                  style: _contentTextStyle,
                                  textDirection: _textDirection,
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: InputDecoration(
                                    hintText: _isUrdu
                                        ? 'آج آپ کیسا محسوس کر رہے ہیں؟ اپنے دل کی بات یہاں لکھیں یا مائیک دبائیں...'
                                        : 'What is on your mind? Express your thoughts freely or tap the mic to speak...',
                                    hintStyle: _contentTextStyle.copyWith(
                                      color: context.secondaryTextColor
                                          .withValues(alpha: 0.4),
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Divider(
                              color: context.isDarkMode
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFF0EBE1),
                              height: 1,
                            ),
                            const SizedBox(height: 12),

                            // Tags Input
                            Row(
                              children: [
                                const Text(
                                  '#',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFDE6B48),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _tagsCtrl,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: context.primaryTextColor,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: _isUrdu
                                          ? 'ٹیگز (مثال: شکرگزاری, سکون, کام)'
                                          : 'Tags (e.g. gratitude, calm, focus)',
                                      hintStyle: TextStyle(
                                        fontSize: 13,
                                        color: context.secondaryTextColor
                                            .withValues(alpha: 0.45),
                                        fontWeight: FontWeight.normal,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── 4. Bottom Floating Mic & Word-Count Bar ────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? const Color(0xFF1D2033)
                      : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Mic Pulsating Action Button
                    GestureDetector(
                      onTap: _toggleListening,
                      child: ScaleTransition(
                        scale: _isListening
                            ? _pulseAnimation
                            : const AlwaysStoppedAnimation(1.0),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _isListening
                                ? const Color(0xFFDE6B48)
                                : const Color(0xFFF7A81B),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (_isListening
                                            ? const Color(0xFFDE6B48)
                                            : const Color(0xFFF7A81B))
                                        .withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: HugeIcon(
                              icon: _isListening
                                  ? HugeIcons.strokeRoundedMic01
                                  : HugeIcons.strokeRoundedMic02,
                              color: _isListening
                                  ? Colors.white
                                  : const Color(0xFF221400),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Label & Mode
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isListening
                              ? (_isUrdu
                                    ? 'آواز ریکارڈ ہو رہی ہے...'
                                    : 'Recording voice...')
                              : (_entryType == 'voice'
                                    ? 'Voice Reflection'
                                    : 'Text Reflection'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _isListening
                                ? const Color(0xFFDE6B48)
                                : context.primaryTextColor,
                          ),
                        ),
                        Text(
                          _isUrdu
                              ? 'بولنے کے لیے مائیک دبائیں'
                              : 'Tap mic to speak (EN / UR)',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Word count indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF0EBE1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$wordCount words • $readingMinutes min',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageChip(String label, String code) {
    final isSelected = _selectedLanguage == code;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedLanguage = code;
          _markChanged();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF7A81B)
              : (context.isDarkMode
                    ? context.secondaryWidgetColor
                    : const Color(0xFFEDE6DA)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? const Color(0xFF221400)
                : context.secondaryTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildPromptsSection() {
    // Custom prompt colors from our palette
    final promptColors = [
      const Color(0xFFDE6B48),
      const Color(0xFFBDDC90),
      const Color(0xFFEBDCCB),
      const Color(0xFF90A959),
      const Color(0xFFEF798A),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text('💡', style: TextStyle(fontSize: 14)),
            SizedBox(width: 6),
            Text(
              'Guided Prompts (CBT & Gratitude)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF996800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: JournalPrompts.prompts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final prompt = JournalPrompts.prompts[idx];
              final isChosen = _selectedPrompt?.id == prompt.id;
              final promptTitle = _isUrdu ? prompt.titleUr : prompt.titleEn;
              final color = promptColors[idx % promptColors.length];

              return GestureDetector(
                onTap: () => _applyPrompt(prompt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isChosen ? const Color(0xFFF7A81B) : color,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isChosen ? const Color(0xFFF7A81B) : color)
                            .withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: isChosen
                            ? const Color(0xFF221400)
                            : (color == const Color(0xFFDE6B48) ||
                                      color == const Color(0xFF90A959) ||
                                      color == const Color(0xFFEF798A)
                                  ? Colors.white
                                  : const Color(0xFF221400)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        promptTitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isChosen
                              ? const Color(0xFF221400)
                              : (color == const Color(0xFFDE6B48) ||
                                        color == const Color(0xFF90A959) ||
                                        color == const Color(0xFFEF798A)
                                    ? Colors.white
                                    : const Color(0xFF221400)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
