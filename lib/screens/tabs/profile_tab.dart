import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../l10n/locale_provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/api_client.dart';
import '../../services/social_service.dart';
import 'pocket_tab.dart';
import 'guide_register_screen.dart';
import 'messages_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../onboarding/language_screen.dart';
import 'view_profile_screen.dart';
import 'chat_screen.dart';
import 'my_bookings_screen.dart';
import 'insider_schedule_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _backdrop;
  bool _isGuide = false;

  @override
  void initState() {
    super.initState();
    _loadGuideStatus();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slide = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _backdrop = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggleSettings() {
    if (_ctrl.isCompleted) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
    }
  }

  // =========================================================================
  //  Build
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final panelWidth = MediaQuery.of(context).size.width * 0.50;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ---- main content ----
          _buildMainContent(context, state),

          // ---- backdrop ----
          if (!_ctrl.isDismissed)
            GestureDetector(
              onTap: _toggleSettings,
              child: AnimatedBuilder(
                animation: _backdrop,
                builder: (ctx, _) => Container(
                  color: Colors.black.withOpacity(0.26 * _backdrop.value),
                ),
              ),
            ),

          // ---- settings panel ----
          Align(
            alignment: Alignment.centerRight,
            child: AnimatedBuilder(
              animation: _slide,
              builder: (ctx, _) {
                return Transform.translate(
                  offset: Offset(panelWidth * _slide.value.dx, 0),
                  child: Container(
                    width: panelWidth,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 24,
                          offset: const Offset(-4, 0),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: _SettingsContent(
                        state: state,
                        onClose: _toggleSettings,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, AppState state) {
    final hasBg =
        state.backgroundPath != null && File(state.backgroundPath!).existsSync();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: hasBg
          ? BoxDecoration(
        image: DecorationImage(
          image: FileImage(File(state.backgroundPath!)),
          fit: BoxFit.cover,
        ),
      )
          : null,
      child: hasBg
          ? DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              AppColors.canvas.withOpacity(0.85),
            ],
          ),
        ),
        child: _buildBody(context, state),
      )
          : _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, AppState state) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _header(context),
          const SizedBox(height: 16),
          _profileCard(context, state),
          const SizedBox(height: 16),
          _tagsSection(context, state),
          const SizedBox(height: 16),
          _friendsSection(context),
          const SizedBox(height: 10),
          _messagesEntry(context),
          const SizedBox(height: 10),
          _bookingsEntry(context),
          const SizedBox(height: 20),
          _pocketEntry(context),
          const SizedBox(height: 20),
          _guideEntry(context),
        ],
      ),
    );
  }

  // =========================================================================
  //  Header
  // =========================================================================

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Text(context.t('profile'),
            style:
            const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.teal),
          onPressed: _toggleSettings,
        ),
      ],
    );
  }

  // =========================================================================
  //  Profile Card — jelly / glassmorphism
  // =========================================================================

  Widget _profileCard(BuildContext context, AppState state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.78),
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            children: [
              // avatar row
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _changeAvatar(context),
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.teal.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.surface,
                            backgroundImage: state.avatarBase64 != null
                                ? MemoryImage(base64Decode(state.avatarBase64!)) as ImageProvider<Object>?
                                : (state.avatarPath != null &&
                                File(state.avatarPath!).existsSync()
                                ? FileImage(File(state.avatarPath!)) as ImageProvider<Object>?
                                : null),
                            child: state.avatarBase64 == null && state.avatarPath == null
                                ? Text(
                              state.nickname.isNotEmpty
                                  ? state.nickname[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.teal),
                            )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.teal,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.teal.withOpacity(0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.nickname,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(state.nationFlag,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(state.nationality,
                                  style: const TextStyle(
                                      color: AppColors.inkSoft,
                                      fontSize: 14)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TagChip(
                            '${context.t('day')} ${state.daysInChina} ${context.t('in_china')}',
                            icon: Icons.calendar_today,
                            color: AppColors.green),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // edit profile button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    side: BorderSide(
                        color: AppColors.teal.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(AppRadii.chip),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _editProfile(context, state),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(context.t('edit_profile')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  //  Tags
  // =========================================================================

  Widget _tagsSection(BuildContext context, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_offer_outlined,
                size: 16, color: AppColors.teal),
            const SizedBox(width: 6),
            const Text('Tags',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _addTag(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (state.profileTags.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text('No tags yet. Add your interests!',
                style: TextStyle(
                    color: AppColors.inkFaint, fontSize: 13)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: state.profileTags
                .map((tag) => Chip(
              label: Text(tag,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink)),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () {
                context
                    .read<AppState>()
                    .removeProfileTag(tag);
              },
              backgroundColor:
              AppColors.teal.withOpacity(0.1),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(AppRadii.chip),
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize:
              MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 0),
            ))
                .toList(),
          ),
      ],
    );
  }

  void _addTag(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card)),
        title: const Text('Add Tag',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.ink),
          cursorColor: AppColors.teal,
          decoration: const InputDecoration(
            hintText: 'e.g. Foodie, Photographer, Hiking',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final tag = ctrl.text.trim();
              if (tag.isNotEmpty) {
                context.read<AppState>().addProfileTag(tag);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }


  // =========================================================================
  //  Friends
  // =========================================================================

  Widget _friendsSection(BuildContext context) {
    final state = context.watch<AppState>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            leading: Stack(
              children: [
                const Icon(Icons.people_outline,
                    color: AppColors.teal),
                if (state.hasIncomingRequests)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            title: const Text('My Friends',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink)),
            subtitle: Text(
                state.friendCount > 0
                    ? '${state.friendCount} ${state.friendCount == 1 ? 'friend' : 'friends'}'
                    : 'Connect with other travellers',
                style: const TextStyle(
                    color: AppColors.inkFaint, fontSize: 12)),
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chevron_right,
                    color: AppColors.inkFaint, size: 18),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _FriendListScreen(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _loadGuideStatus() async {
    try {
      final isGuide = await SocialService.instance.guideStatus();
      if (mounted) setState(() => _isGuide = isGuide);
    } catch (_) {}
  }

  Widget _guideEntry(BuildContext context) {
    // Wider card: use Transform to extend beyond ListView padding
    return Transform.translate(
      offset: const Offset(-12, 0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 16, // ListView width - left(20) - right(20) + 24 extra
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.card + 4),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.teal.withOpacity(0.18),
                  AppColors.teal.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadii.card + 4),
              border: Border.all(color: AppColors.teal.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  _isGuide ? Icons.verified_user : Icons.badge_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              title: Text(
                _isGuide ? 'You are an Insider' : context.t('become_guide'),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.ink,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _isGuide
                      ? 'Travellers can now find & message you'
                      : 'Verify your Chinese ID to guide travellers',
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 13,
                  ),
                ),
              ),
              trailing: _isGuide
                  ? const Icon(Icons.check_circle, color: AppColors.teal, size: 24)
                  : Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Apply',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                  ],
                ),
              ),
              onTap: _isGuide
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InsiderScheduleScreen(),
                  ),
                );
              }
                  : () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GuideRegisterScreen(),
                  ),
                );
                if (result == true && mounted) {
                  setState(() => _isGuide = true);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _bookingsEntry(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: ListTile(
            leading: Stack(
              children: [
                const Text('📋', style: TextStyle(fontSize: 22)),
              ],
            ),
            title: const Text('My Bookings',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink)),
            subtitle: const Text('1 ongoing',
                style: TextStyle(color: AppColors.inkFaint, fontSize: 12)),
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chevron_right,
                    color: AppColors.inkFaint, size: 18),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyBookingsScreen(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _pocketEntry(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: ListTile(
          leading: const Icon(Icons.backpack_outlined, color: AppColors.teal),
          title: Text(context.t('pocket'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink)),
          subtitle: Text(context.t('pocket_subtitle'),
              style: const TextStyle(color: AppColors.inkFaint, fontSize: 12)),
          trailing: const Icon(Icons.chevron_right,
              color: AppColors.inkFaint, size: 18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  backgroundColor: AppColors.canvas,
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    foregroundColor: AppColors.ink,
                  ),
                  body: const PocketTab(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _messagesEntry(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: ListTile(
            leading: const Icon(Icons.forum_outlined, color: AppColors.teal),
            title: const Text('Messages',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink)),
            subtitle: const Text('Your conversations with friends',
                style: TextStyle(color: AppColors.inkFaint, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.inkFaint, size: 18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MessagesScreen(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // =========================================================================
  //  Avatar
  // =========================================================================

  void _changeAvatar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inkFaint.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Set Avatar',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.ink)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.teal),
              title: const Text('Take Photo',
                  style: TextStyle(color: AppColors.ink)),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.teal),
              title: const Text('Choose from Gallery',
                  style: TextStyle(color: AppColors.ink)),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
            ),
            if (context.read<AppState>().avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text('Remove Photo',
                    style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<AppState>().setAvatarPath(null);
                  showGlideSnack(context, 'Avatar removed', icon: Icons.check_circle);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final file = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512);
      if (file != null && mounted) {
        // Read file bytes and convert to base64
        final bytes = await file.readAsBytes();
        final b64 = base64Encode(bytes);
        // Save local path too
        context.read<AppState>().setAvatarBase64(b64);
        // Upload to backend
        try {
          await ApiClient.instance.put('/api/user/profile', data: {
            'avatar_base64': b64,
          });
        } catch (_) {
          // backend offline — still show locally
        }
      }
    } catch (_) {
      if (mounted) {
        showGlideSnack(context, 'Could not access camera/gallery', icon: Icons.error);
      }
    }
  }

  // =========================================================================
  //  Edit Profile
  // =========================================================================

  void _editProfile(BuildContext context, AppState state) {
    final nick = TextEditingController(text: state.nickname);
    final nation = TextEditingController(text: state.nationality);
    final daysCtrl = TextEditingController(text: state.daysInChina.toString());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(context.t('edit_profile'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
              ),
              const SizedBox(height: 18),
              _editLabel('Nickname'),
              const SizedBox(height: 6),
              TextField(controller: nick,
                style: const TextStyle(fontSize: 14, color: AppColors.ink),),
              const SizedBox(height: 14),
              _editLabel('Nationality'),
              const SizedBox(height: 6),
              TextField(controller: nation,
                style: const TextStyle(fontSize: 14, color: AppColors.ink),),
              const SizedBox(height: 14),
              _editLabel('Days in China'),
              const SizedBox(height: 6),
              TextField(
                controller: daysCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 14, color: AppColors.ink),
                decoration: const InputDecoration(hintText: 'e.g. 7'),
              ),
              const SizedBox(height: 14),
              _editLabel('Background Image'),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
                    if (file != null) {
                      context.read<AppState>().setBackgroundPath(file.path);
                    }
                  },
                  icon: const Icon(Icons.wallpaper_outlined, size: 16),
                  label: Text(
                    state.backgroundPath != null ? 'Change Background' : 'Set Background',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.chip),
                    ),
                  ),
                ),
              ),
              if (state.backgroundPath != null) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => context.read<AppState>().setBackgroundPath(null),
                  child: const Text('Remove Background',
                      style: TextStyle(color: AppColors.danger)),
                ),
              ],
              const SizedBox(height: 22),
              GradientButton(
                label: context.t('save_changes'),
                onPressed: () async {
                  final days = int.tryParse(daysCtrl.text.trim());
                  context.read<AppState>().updateProfile(
                    nickname: nick.text,
                    nationality: nation.text,
                    daysInChina: days,
                  );
                  Navigator.pop(ctx);
                  showGlideSnack(context, context.t('profile_updated'),
                      icon: Icons.check_circle);
                  // Sync to backend
                  try {
                    await ApiClient.instance.put('/api/user/profile', data: {
                      'nickname': nick.text.trim(),
                      'nationality': nation.text.trim(),
                      if (days != null) 'days_in_china': days,
                    });
                  } catch (_) {
                    // Local state already updated; user sees success
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editLabel(String text) {
    return Text(text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.ink));
  }
}

// =============================================================================
//  Settings Panel Content
// =============================================================================

class _SettingsContent extends StatelessWidget {
  final AppState state;
  final VoidCallback onClose;

  const _SettingsContent({
    required this.state,
    required this.onClose,
  });

  void _syncRadar(bool value, String field) {
    ApiClient.instance.put('/api/radar/visibility', data: {field: value});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _settingsHeader(context),
          const SizedBox(height: 12),
          _sectionTitle('Privacy'),
          const SizedBox(height: 4),
          _switchItem(context, 'Show on Radar', Icons.radar,
              state.showOnRadar, (v) { state.setShowOnRadar(v); _syncRadar(v, 'show_on_radar'); }),
          _switchItem(context, 'Exact Location', Icons.my_location,
              state.showExactLocation, (v) { state.setShowExactLocation(v); _syncRadar(v, 'show_exact_location'); }),
          _switchItem(context, 'Allow Messages', Icons.chat_bubble_outline,
              state.allowMessages, (v) { state.setAllowMessages(v); _syncRadar(v, 'allow_messages'); }),
          _switchItem(context, 'Hide Profile', Icons.visibility_off_outlined,
              state.hideProfile, (v) { state.setHideProfile(v); _syncRadar(v, 'hide_profile'); }),
          _switchItem(context, 'Allow Profile View', Icons.person_search_outlined,
              state.allowProfileView, state.setAllowProfileView),
          const SizedBox(height: 12),
          _sectionTitle('Preferences'),
          const SizedBox(height: 4),
          _navItem(context, 'Language', state.language.nativeName,
              Icons.language, () => _showLanguagePicker(context)),
          _switchItem(context, 'Notifications', Icons.notifications_outlined,
              state.notificationsEnabled, (v) {
                state.setNotifications(v);
                ApiClient.instance.put('/api/user/preferences', data: {'notifications_enabled': v});
              }),
          const SizedBox(height: 12),
          _sectionTitle('Account'),
          const SizedBox(height: 4),
          _navItem(context, 'Change Password', '', Icons.lock_outline,
                  () => _showChangePassword(context)),
          _navItem(context, 'Help & Support', '', Icons.help_outline,
                  () => _showHelp(context)),
          _navItem(context, 'Delete Account', '', Icons.delete_outline,
                  () => _confirmDeleteAccount(context), danger: true),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger, width: 1.3),
              minimumSize: const Size.fromHeight(44),
            ),
            onPressed: () {
              onClose();
              Future.delayed(const Duration(milliseconds: 350), () {
                _confirmSignOut(context);
              });
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _settingsHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.settings, color: AppColors.teal, size: 20),
        const SizedBox(width: 8),
        const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.ink)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close, size: 18, color: AppColors.inkSoft),
          onPressed: onClose,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: AppColors.inkSoft)),
    );
  }

  Widget _switchItem(BuildContext context, String label, IconData icon,
      bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.ink)),
          ),
          SizedBox(
            height: 26,
            child: Transform.scale(
              scale: 0.65,
              child: Switch.adaptive(
                value: value,
                activeColor: AppColors.teal,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, String title, String trailing,
      IconData icon, VoidCallback onTap,
      {bool danger = false}) {
    final color = danger ? AppColors.danger : AppColors.teal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.chip),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: danger ? AppColors.danger : AppColors.ink)),
              ),
              if (trailing.isNotEmpty)
                Text(trailing,
                    style: const TextStyle(
                        color: AppColors.inkFaint, fontSize: 11.5)),
              if (trailing.isNotEmpty) const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 14, color: AppColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Language Picker (bottom sheet, NOT navigation) ----
  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.inkFaint.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Preferred Language',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.ink)),
            const SizedBox(height: 12),
            const Divider(height: 1),
            ...AppLanguage.all.map((lang) => ListTile(
              leading: Text(lang.flag, style: const TextStyle(fontSize: 22)),
              title: Text(lang.nativeName,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
              subtitle: Text(lang.name,
                  style: const TextStyle(fontSize: 12, color: AppColors.inkFaint)),
              trailing: state.language == lang
                  ? const Icon(Icons.check, color: AppColors.teal)
                  : null,
              onTap: () {
                context.read<AppState>().setLanguage(lang);
                context.read<LocaleProvider>().setLanguage(lang.code);
                Navigator.pop(ctx);
                showGlideSnack(context, 'Language changed to ${lang.nativeName}',
                    icon: Icons.check_circle);
              },
            )),
          ],
        ),
      ),
    );
  }

  // ---- Change Password ----
  void _showChangePassword(BuildContext context) {
    final curPw = TextEditingController();
    final newPw = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card)),
        title: const Text('Change Password',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: curPw,
              obscureText: true,
              style: const TextStyle(color: AppColors.ink),
              cursorColor: AppColors.teal,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock_outline, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPw,
              obscureText: true,
              style: const TextStyle(color: AppColors.ink),
              cursorColor: AppColors.teal,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final cur = curPw.text.trim();
              final nw = newPw.text.trim();
              if (cur.isEmpty || nw.length < 6) {
                showGlideSnack(context, 'Password must be at least 6 characters',
                    icon: Icons.info_outline);
                return;
              }
              try {
                await ApiClient.instance.post('/api/auth/change-password', data: {
                  'old_password': cur,
                  'new_password': nw,
                });
                Navigator.pop(ctx);
                showGlideSnack(context, 'Password changed successfully',
                    icon: Icons.check_circle);
              } catch (_) {
                showGlideSnack(context, 'Failed to change password',
                    icon: Icons.error);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: const Text('Help & Support',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.ink)),
        content: const Text(
          'Need a hand?\n\n'
              '• Explore the tabs: Chat, Insiders, Mic, Radar and Profile.\n'
              '• Use the Mic to translate on the go.\n'
              '• Find travellers and guides on Radar.\n\n'
              'For more help, contact the Glide China team at support@glidechina.app.',
          style: TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.ink),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Account',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.ink)),
        content: const Text(
          'This will permanently remove your account and data. '
              'This action cannot be undone.',
          style: TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.ink),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiClient.instance.delete('/api/user/account');
                ApiClient.instance.clearToken();
                context.read<AppState>().signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LanguageScreen()),
                      (route) => false,
                );
              } catch (_) {
                if (context.mounted) {
                  showGlideSnack(context, 'Failed to delete account',
                      icon: Icons.error);
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.ink)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(fontSize: 13.5, color: AppColors.ink)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ApiClient.instance.clearToken();
              context.read<AppState>().signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LanguageScreen()),
                    (route) => false,
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}


class _FriendListScreen extends StatefulWidget {
  @override
  State<_FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<_FriendListScreen> {
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    // Poll every 3s so new friends/requests appear without manual refresh.
    _pollTimer = Timer.periodic(
        const Duration(seconds: 3), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final friends = await SocialService.instance.listFriends();
      final requests = await SocialService.instance.incomingRequests();
      if (mounted) {
        // Merge AppState seed friends so the list is never empty for demo
        final appState = context.read<AppState>();
        final backendIds = friends.map((f) => f['user_id']).toSet();
        for (final f in appState.friends) {
          // Only add seed friends that aren't already from backend
          if (!backendIds.contains(f.id)) {
            friends.add({
              'user_id': f.id.hashCode.abs() % 100000 + 70000,
              'nickname': f.nickname,
              'flag': f.flag,
              'nationality': f.country,
              'days_in_china': f.daysInChina,
              'is_guide': false,
            });
          }
        }
        // Also merge AppState incoming requests
        final backendReqIds = requests.map((r) => r['request_id']).toSet();
        for (final r in appState.incomingRequests.values) {
          final mockId = r.id.hashCode.abs() % 100000 + 50000;
          if (!backendReqIds.contains(mockId)) {
            requests.add({
              'request_id': mockId,
              'user_id': mockId,
              'nickname': r.nickname,
              'flag': r.flag,
              'nationality': r.country,
            });
          }
        }
        // Only rebuild if something actually changed (avoid flicker).
        final changed = friends.length != _friends.length ||
            requests.length != _requests.length;
        if (changed || !silent) {
          setState(() {
            _friends = friends;
            _requests = requests;
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _respond(Map<String, dynamic> req, bool accept) async {
    final id = req['request_id'] as int?;
    if (id == null) return;
    final nickname = (req['nickname'] as String?) ?? 'Traveller';
    final flag = (req['flag'] as String?) ?? '\u{1F30D}';
    final country = (req['nationality'] as String?) ?? '';
    // Remove from requests list immediately
    setState(() => _requests.remove(req));
    if (accept) {
      // Actually add to AppState friends so it persists
      context.read<AppState>().addFriend(FriendInfo(
        id: 'friend_$id',
        nickname: nickname,
        flag: flag,
        country: country,
        avatarColor: AppColors.teal,
      ));
      // Also add to local friends list for immediate display
      setState(() {
        _friends.add({
          'user_id': id,
          'nickname': nickname,
          'flag': flag,
          'nationality': country,
          'is_guide': false,
        });
      });
    }
    // Try backend API but don't block on failure
    try {
      await SocialService.instance.respondToRequest(id, accept);
    } catch (_) {
      // Backend may not have this request — that's OK for demo
    }
    if (mounted) {
      showGlideSnack(context, accept ? 'Friend added!' : 'Request declined',
          icon: accept ? Icons.check_circle : Icons.person_remove_outlined);
    }
  }

  void _openProfile(Map<String, dynamic> f) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewProfileScreen(
          id: '${f['user_id']}',
          userId: f['user_id'] as int?,
          nickname: (f['nickname'] as String?) ?? 'Traveller',
          flag: (f['flag'] as String?) ?? '🌍',
          country: (f['nationality'] as String?) ?? '',
          daysInChina: 1,
          distance: '',
          avatarColor: AppColors.teal,
          isFriend: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('My Friends',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_requests.isNotEmpty) _requestsBanner(),
            if (_friends.isEmpty && _requests.isEmpty)
              _empty()
            else
              ..._friends.map(_friendTile),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.only(top: 100),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.group_outlined,
                size: 48, color: AppColors.inkFaint),
            const SizedBox(height: 12),
            Text(context.t('no_friends_yet'),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink)),
            const SizedBox(height: 6),
            const Text('Add friends from Radar or Insiders',
                style: TextStyle(color: AppColors.inkFaint, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _requestsBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.teal.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_requests.length} Friend Request${_requests.length == 1 ? '' : 's'}',
              style:
              const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink)),
          const SizedBox(height: 10),
          ..._requests.map((r) {
            final name = (r['nickname'] as String?) ?? 'Traveller';
            final flag = (r['flag'] as String?) ?? '🌍';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.teal,
                    child: Text(name[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('$name $flag',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink)),
                  ),
                  SizedBox(
                    height: 30,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        elevation: 0,
                      ),
                      onPressed: () => _respond(r, true),
                      child: const Text('Accept',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 30,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.inkFaint,
                        side: const BorderSide(color: AppColors.line),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () => _respond(r, false),
                      child: const Text('Decline',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _friendTile(Map<String, dynamic> f) {
    final name = (f['nickname'] as String?) ?? 'Traveller';
    final flag = (f['flag'] as String?) ?? '🌍';
    final country = (f['nationality'] as String?) ?? '';
    final userId = f['user_id'] as int?;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card)),
      color: AppColors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: () => _openProfile(f),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.teal,
                child: Text(name[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink)),
                        const SizedBox(width: 6),
                        Text(flag, style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                    if (country.isNotEmpty)
                      Text(country,
                          style: const TextStyle(
                              color: AppColors.inkFaint, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                onPressed: userId == null
                    ? null
                    : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      friendId: '$userId',
                      friendUserId: userId,
                      friendName: name,
                      friendFlag: flag,
                      friendAvatarColor: AppColors.teal,
                      isFriend: true,
                    ),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline,
                    color: AppColors.teal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
