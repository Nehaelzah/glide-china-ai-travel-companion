import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/locale_provider.dart';
import '../../services/social_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// 3-step wizard to become an Insider: Identity -> Skills -> Terms.
class GuideRegisterScreen extends StatefulWidget {
  const GuideRegisterScreen({super.key});

  @override
  State<GuideRegisterScreen> createState() => _GuideRegisterScreenState();
}

class _GuideRegisterScreenState extends State<GuideRegisterScreen> {
  int _step = 0; // 0 Identity, 1 Skills, 2 Terms

  // Step 1
  final _idCtrl = TextEditingController();
  Uint8List? _front;
  Uint8List? _back;

  // Step 2
  final Map<String, String> _languages = {}; // language -> level
  final _customLangCtrl = TextEditingController();
  Uint8List? _cert;
  final Set<String> _interests = {};

  // Step 3
  bool _agree1 = false;
  bool _agree2 = false;
  bool _submitting = false;

  static const _commonLanguages = [
    'English', 'Chinese', 'Japanese', 'Korean', 'French',
    'Spanish', 'Thai', 'German', 'Arabic', 'Hindi',
  ];
  static const _levels = ['Native', 'Fluent', 'Working Proficiency', 'Basic'];
  static const _interestOptions = [
    ['🍜', 'Foodie'], ['🌃', 'Nightlife'], ['🏛️', 'History & Culture'],
    ['🏙️', 'City'], ['🛍️', 'Shopping'], ['⚽', 'Sports'],
    ['🏞️', 'Outdoor Adventure'], ['📷', 'Photo Tour'],
    ['👨‍👩‍👧', 'Family & Kids'], ['💼', 'Business'],
  ];

  Future<void> _pick(void Function(Uint8List) set) async {
    final x = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);
    if (x != null) {
      final bytes = await x.readAsBytes();
      setState(() => set(bytes));
    }
  }

  String? _b64(Uint8List? b) =>
      b == null ? null : 'data:image/jpeg;base64,${base64Encode(b)}';

  bool get _step1Valid =>
      _idCtrl.text.replaceAll(RegExp(r'\D'), '').length == 18 &&
      _front != null &&
      _back != null;
  bool get _step2Valid => _languages.isNotEmpty && _interests.isNotEmpty;
  bool get _step3Valid => _agree1 && _agree2;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final langs = _languages.entries
          .map((e) => {'language': e.key, 'level': e.value})
          .toList();
      debugPrint('[GuideRegister] Submitting registration...');
      debugPrint('[GuideRegister] ID: ${_idCtrl.text.replaceAll(RegExp(r'\D'), '')}');
      debugPrint('[GuideRegister] Languages: $langs');
      debugPrint('[GuideRegister] Interests: ${_interests.toList()}');
      final ok = await SocialService.instance.registerGuide(
        chinaId: _idCtrl.text.replaceAll(RegExp(r'\D'), ''),
        idFront: _b64(_front),
        idBack: _b64(_back),
        languages: langs,
        cert: _b64(_cert),
        interests: _interests.toList(),
        acceptedTerms: true,
      );
      debugPrint('[GuideRegister] Registration result: ok=$ok');
      if (ok && mounted) {
        Navigator.pop(context, true);
        showGlideSnack(context, 'You are now an Insider!',
            icon: Icons.verified);
      } else if (!ok && mounted) {
        setState(() => _submitting = false);
        showGlideSnack(context, 'Registration failed. Please check your information.',
            icon: Icons.error);
      }
    } on DioException catch (e) {
      debugPrint('[GuideRegister] DioException: ${e.message}');
      debugPrint('[GuideRegister] Response: ${e.response?.data}');
      if (mounted) {
        setState(() => _submitting = false);
        // Extract specific error detail from backend response
        String errorMsg = 'Something went wrong. Please check your details.';
        final data = e.response?.data;
        if (data is Map && data.containsKey('detail')) {
          errorMsg = data['detail'].toString();
        } else if (data is Map && data.containsKey('message')) {
          errorMsg = data['message'].toString();
        } else if (e.response?.statusCode == 401) {
          errorMsg = 'Not authenticated. Please log in again.';
        } else if (e.response?.statusCode == 500) {
          errorMsg = 'Server error. Please try again later.';
        }
        showGlideSnack(context, errorMsg, icon: Icons.error);
      }
    } catch (e) {
      debugPrint('[GuideRegister] Unexpected error: $e');
      if (mounted) {
        setState(() => _submitting = false);
        showGlideSnack(context, 'Network error. Please check your connection.',
            icon: Icons.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: const Text('Become an Insider',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: Column(
        children: [
          _stepper(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: _step == 0
                  ? _identityStep()
                  : _step == 1
                      ? _skillsStep()
                      : _termsStep(),
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _stepper() {
    final steps = ['Identity', 'Skills', 'Terms'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: i <= _step ? AppColors.teal : AppColors.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: i < _step
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text('${i + 1}',
                            style: TextStyle(
                                color: i == _step
                                    ? Colors.white
                                    : AppColors.inkFaint,
                                fontWeight: FontWeight.w800,
                                fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(steps[i],
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            i == _step ? FontWeight.w800 : FontWeight.w500,
                        color: i <= _step ? AppColors.teal : AppColors.inkFaint)),
              ],
            ),
            if (i < steps.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4),
                  color: i < _step ? AppColors.teal : AppColors.line,
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ---------------- STEP 1: IDENTITY ----------------
  Widget _identityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Verify Your Identity',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            )),
        const SizedBox(height: 4),
        const Text("Let's build trust in our community.",
            style: TextStyle(color: AppColors.inkSoft, fontSize: 14)),
        const SizedBox(height: 18),
        Row(children: const [
          Icon(Icons.lock_outline, size: 15, color: AppColors.teal),
          SizedBox(width: 6),
          Text('ENCRYPTED & SECURE',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.teal,
                  letterSpacing: 1)),
        ]),
        const SizedBox(height: 14),
        const Text('Chinese ID Number',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.ink,
            )),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _idCtrl,
                keyboardType: TextInputType.number,
                maxLength: 18,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Enter your 18-digit Chinese ID number',
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text('Upload your ID photos',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.ink,
            )),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _uploadBox('Front of ID', _front, () => _pick((b) => _front = b))),
            const SizedBox(width: 12),
            Expanded(child: _uploadBox('Back of ID', _back, () => _pick((b) => _back = b))),
          ],
        ),
      ],
    );
  }

  Widget _uploadBox(String label, Uint8List? img, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: img != null ? AppColors.teal : AppColors.line,
              width: img != null ? 2 : 1),
          image: img != null
              ? DecorationImage(image: MemoryImage(img), fit: BoxFit.cover)
              : null,
        ),
        child: img != null
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined,
                      color: AppColors.teal, size: 26),
                  const SizedBox(height: 8),
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.inkSoft, fontSize: 12)),
                ],
              ),
      ),
    );
  }

  // ---------------- STEP 2: SKILLS ----------------
  Widget _skillsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Show Your Expertise',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('What makes you a great guide?',
            style: TextStyle(color: AppColors.inkSoft, fontSize: 14)),
        const SizedBox(height: 18),
        const Text('LANGUAGE PROFICIENCY',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: 1)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final lang in _commonLanguages) _langPill(lang),
          ],
        ),
        const SizedBox(height: 10),
        // custom language
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customLangCtrl,
                decoration: InputDecoration(
                  hintText: 'Other language…',
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                final t = _customLangCtrl.text.trim();
                if (t.isNotEmpty) {
                  setState(() {
                    _languages[t] = 'Fluent';
                    _customLangCtrl.clear();
                  });
                  _pickLevel(t);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
        if (_languages.isNotEmpty) ...[
          const SizedBox(height: 6),
          ..._languages.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 15, color: AppColors.teal),
                    const SizedBox(width: 6),
                    Text('${e.key} — ',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(e.value,
                        style: const TextStyle(
                            color: AppColors.inkSoft, fontSize: 13)),
                  ],
                ),
              )),
        ],
        const SizedBox(height: 18),
        const Text('ENGLISH PROFICIENCY',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
        const SizedBox(height: 8),
        const Text(
            'Upload an English test certificate (IELTS, PTE, TOEFL, etc.).',
            style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick((b) => _cert = b),
                icon: Icon(_cert != null ? Icons.check : Icons.upload_file,
                    size: 18),
                label: Text(_cert != null ? 'Certificate added' : 'Upload'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    side: BorderSide(color: AppColors.teal.withOpacity(0.4))),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => launchUrl(
              Uri.parse(
                  'https://www.britishcouncil.org/exam/aptis/take-test'),
              mode: LaunchMode.externalApplication),
          child: const Text(
            "Don't have a certificate? Take a free test with the British Council →",
            style: TextStyle(
                color: AppColors.teal,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline),
          ),
        ),
        const SizedBox(height: 20),
        const Text('INTERESTS  (MAX 5)',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final it in _interestOptions) _interestCard(it[0], it[1]),
          ],
        ),
      ],
    );
  }

  Widget _langPill(String lang) {
    final selected = _languages.containsKey(lang);
    return GestureDetector(
      onTap: () {
        if (selected) {
          setState(() => _languages.remove(lang));
        } else {
          _pickLevel(lang);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.teal : AppColors.line),
        ),
        child: Text(
          selected ? '$lang ✓' : lang,
          style: TextStyle(
              color: selected ? Colors.white : AppColors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 13),
        ),
      ),
    );
  }

  void _pickLevel(String lang) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your $lang level',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            for (final level in _levels)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(level),
                trailing: _languages[lang] == level
                    ? const Icon(Icons.check_circle, color: AppColors.teal)
                    : null,
                onTap: () {
                  setState(() => _languages[lang] = level);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _interestCard(String emoji, String label) {
    final selected = _interests.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _interests.remove(label);
          } else {
            if (_interests.length >= 5) {
              showGlideSnack(context, 'You can pick up to 5 interests',
                  icon: Icons.info_outline);
              return;
            }
            _interests.add(label);
          }
        });
      },
      child: Container(
        width: (MediaQuery.of(context).size.width - 40 - 10) / 2,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.teal : AppColors.line,
              width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: selected ? AppColors.teal : AppColors.ink)),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.teal, size: 16),
          ],
        ),
      ),
    );
  }

  // ---------------- STEP 3: TERMS ----------------
  Widget _termsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Final Step: Agree & Submit',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Review the agreement and submit.',
            style: TextStyle(color: AppColors.inkSoft, fontSize: 14)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Insider Service Agreement',
                  style:
                      TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              SizedBox(height: 12),
              _Term('Commission',
                  'The platform takes a 10% commission on all completed bookings.'),
              _Term('Privacy',
                  'You must protect traveller privacy and never share personal contact info outside the platform until a booking is confirmed.'),
              _Term('Safety',
                  'You are responsible for your own safety and the safety of the travellers during any service you provide.'),
              _Term('Conduct',
                  'You will provide honest, respectful, and professional service, and follow all local laws and platform rules.'),
              _Term('Off-platform bookings',
                  'Arranging bookings or payments outside the platform is not allowed and may result in removal.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.teal,
          value: _agree1,
          onChanged: (v) => setState(() => _agree1 = v ?? false),
          title: const Text('I have read and agree to the Service Agreement',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.teal,
          value: _agree2,
          onChanged: (v) => setState(() => _agree2 = v ?? false),
          title: const Text('I agree to the Safety & Conduct Guidelines',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.teal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '"I hereby confirm that all information provided is true, and I will abide by the platform rules to provide safe, high-quality service."',
            style: TextStyle(
                fontStyle: FontStyle.italic,
                color: AppColors.teal,
                fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _bottomBar() {
    final canNext = _step == 0
        ? _step1Valid
        : _step == 1
            ? _step2Valid
            : _step3Valid;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Row(
          children: [
            if (_step > 0)
              OutlinedButton(
                onPressed: () => setState(() => _step--),
                child: const Icon(Icons.arrow_back, size: 18),
              ),
            if (_step > 0) const SizedBox(width: 10),
            Expanded(
              child: GradientButton(
                label: _step < 2
                    ? 'Continue'
                    : (_submitting ? 'Submitting…' : 'Become an Insider'),
                icon: _step < 2 ? Icons.arrow_forward : Icons.verified,
                onPressed: !canNext || _submitting
                    ? null
                    : () {
                        if (_step < 2) {
                          setState(() => _step++);
                        } else {
                          _submit();
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Term extends StatelessWidget {
  final String title;
  final String body;
  const _Term(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  ',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        color: AppColors.ink, fontSize: 12.5, height: 1.4),
                    children: [
                      TextSpan(
                          text: '$title: ',
                          style:
                              const TextStyle(fontWeight: FontWeight.w800)),
                      TextSpan(text: body),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
