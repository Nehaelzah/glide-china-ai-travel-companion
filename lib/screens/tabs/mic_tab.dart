import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/locale_provider.dart';
import '../../models/models.dart';
import '../../providers/mic_provider.dart';
import '../../services/speech_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Live conversation translation. Note the [dispose] call that clears the
/// temporary conversation memory when the user leaves this tab.
class MicTab extends StatefulWidget {
  const MicTab({super.key});

  @override
  State<MicTab> createState() => _MicTabState();
}

class _MicTabState extends State<MicTab> {
  final _typeController = TextEditingController();
  bool _touristSide = false; // which side is about to speak
  bool? _recordingSide; // null = not recording; true/false = which side
  String _liveText = ''; // words recognised so far in current recording

  @override
  void dispose() {
    // Conversation is intentionally NOT cleared here — it persists for the
    // whole app session and only goes away when the app is closed.
    SpeechService.instance.stopListening();
    _typeController.dispose();
    super.dispose();
  }

  void _pickLanguage(bool isSideA) {
    final mic = context.read<MicProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LangPickSheet(
        current: isSideA ? mic.sideA : mic.sideB,
        onPick: (l) {
          isSideA ? mic.setSideA(l) : mic.setSideB(l);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mic = context.watch<MicProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.t('live_translate'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),

            _languageBar(mic),
            Expanded(
              child: mic.turns.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                itemCount: mic.turns.length,
                itemBuilder: (context, i) =>
                    _turnCard(mic.turns[i], mic),
              ),
            ),
            _controls(mic),
          ],
        ),
      ),
    );
  }

  /// Begin recording for [touristSide]. Called on press-down.
  Future<void> _startRecording(bool touristSide) async {
    if (_recordingSide != null) return; // already recording
    final mic = context.read<MicProvider>();
    final lang = touristSide ? mic.sideA : mic.sideB;

    final started = await SpeechService.instance.startListening(
      language: lang.code,
      onResult: (text, isFinal) {
        setState(() => _liveText = text);
      },
    );

    if (!started) {
      if (mounted) {
        showGlideSnack(context,
            'Microphone not available. Check permission and use Chrome.',
            icon: Icons.mic_off_outlined);
      }
      return;
    }
    setState(() {
      _recordingSide = touristSide;
      _touristSide = touristSide;
      _liveText = '';
    });
  }

  /// Stop recording (press-up). Send whatever was heard for translation.
  Future<void> _stopRecording() async {
    if (_recordingSide == null) return;
    final side = _recordingSide!;
    await SpeechService.instance.stopListening();
    final heard = _liveText.trim();
    setState(() {
      _recordingSide = null;
      _liveText = '';
    });
    if (heard.isNotEmpty) {
      // ignore: use_build_context_synchronously
      context.read<MicProvider>().addTurn(heard, fromUserSide: side);
    }
  }

  Widget _languageBar(MicProvider mic) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(child: _langChip(mic.sideA, () => _pickLanguage(true))),
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.swap_horiz, color: AppColors.teal, size: 18),
                onPressed: mic.swapSides,
              ),
            ),
            Expanded(child: _langChip(mic.sideB, () => _pickLanguage(false))),
          ],
        ),
      ),
    );
  }

  Widget _langChip(AppLanguage lang, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.chip),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(lang.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 1),
            Text(
              lang.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 10,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.record_voice_over,
                size: 40, color: AppColors.teal),
          ),
          const SizedBox(height: 16),
          Text(
            context.t('tap_mic'),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              context.t('mic_context_hint'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkFaint, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _turnCard(TranslationTurn turn, MicProvider mic) {
    final tourist = turn.fromUserSide;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment:
        tourist ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: tourist ? AppColors.surface : null,
                gradient: tourist ? null : AppColors.brandGradient,
                borderRadius: BorderRadius.circular(AppRadii.card),
                boxShadow: tourist ? AppShadows.soft : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(turn.sourceText,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.inkSoft,
                      )),
                  const SizedBox(height: 6),
                  Text(turn.translatedText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: AppColors.ink,
                      )),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final ok = await SpeechService.instance.speak(
                          turn.translatedText,
                          language: turn.targetLang);
                      if (!ok && mounted) {
                        showGlideSnack(
                            context,
                            'No ${turn.targetLang} voice on this device. '
                                'Install it in system settings.',
                            icon: Icons.record_voice_over_outlined);
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volume_up_outlined,
                            size: 15,
                            color: AppColors.ink),
                        const SizedBox(width: 4),
                        Text('${context.t('play')} ${turn.targetLang}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls(MicProvider mic) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
              color: AppColors.teal.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        children: [
          // Typed fallback (the prototype can't capture real audio).
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _typeController,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: AppColors.teal,
                  decoration: InputDecoration(
                    hintText: _touristSide
                        ? '${context.t('type_in')} ${mic.sideA.name}…'
                        : '${context.t('type_in')} ${mic.sideB.name}…',
                    hintStyle: const TextStyle(color: AppColors.inkFaint),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (t) {
                    mic.addTurn(t, fromUserSide: _touristSide);
                    _typeController.clear();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: AppColors.teal),
                icon: const Icon(Icons.send, size: 18),
                onPressed: () {
                  mic.addTurn(_typeController.text,
                      fromUserSide: _touristSide);
                  _typeController.clear();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recordingSide != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.graphic_eq,
                        color: AppColors.teal, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _liveText.isEmpty
                            ? '${context.t('listening')}…'
                            : _liveText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _micButton(
                  active: !_touristSide,
                  lang: mic.sideB,
                  busy: _recordingSide == false,
                  onStart: () => _startRecording(false),
                  onStop: _stopRecording,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _micButton(
                  active: _touristSide,
                  lang: mic.sideA,
                  busy: _recordingSide == true,
                  onStart: () => _startRecording(true),
                  onStop: _stopRecording,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _micButton({
    required bool active,
    required AppLanguage lang,
    required bool busy,
    required VoidCallback onStart,
    required VoidCallback onStop,
  }) {
    return GestureDetector(
      onTapDown: (_) => onStart(),
      onTapUp: (_) => onStop(),
      onTapCancel: onStop,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: (active || busy) ? AppColors.brandGradient : null,
          color: (active || busy) ? null : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Column(
          children: [
            Icon(busy ? Icons.graphic_eq : Icons.mic,
                color: (active || busy) ? AppColors.ink : AppColors.teal,
                size: 26),
            const SizedBox(height: 4),
            Text(busy ? context.t('listening') : lang.name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.ink,
                )),
          ],
        ),
      ),
    );
  }
}

class _LangPickSheet extends StatelessWidget {
  final AppLanguage current;
  final ValueChanged<AppLanguage> onPick;
  const _LangPickSheet({required this.current, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(999)),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.t('choose_lang'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...AppLanguage.all.map((l) => ListTile(
            leading: Text(l.flag, style: const TextStyle(fontSize: 24)),
            title: Text(
              l.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            trailing: current.code == l.code
                ? const Icon(Icons.check_circle, color: AppColors.teal)
                : null,
            onTap: () => onPick(l),
          )),
        ],
      ),
    );
  }
}
