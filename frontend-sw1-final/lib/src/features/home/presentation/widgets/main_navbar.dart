import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:mobile/src/core/services/dm_service.dart';
import 'package:mobile/src/core/services/fcm_service.dart';
import 'package:mobile/src/core/services/storage_service.dart';
import 'package:mobile/src/features/chat/presentation/pages/chat_page.dart';
import 'package:mobile/src/features/community/presentation/pages/community_page.dart';
import 'package:mobile/src/features/dm/presentation/pages/dm_chat_page.dart';
import 'package:mobile/src/features/hairstyle/presentation/pages/hairstyle_main_page.dart';
import 'package:mobile/src/features/profile/presentation/pages/profile_page.dart';
import 'package:mobile/src/features/wardrobe/presentation/pages/wardrobe_page.dart';

class MainNavbar extends StatefulWidget {
  const MainNavbar({super.key});

  @override
  State<MainNavbar> createState() => _MainNavbarState();
}

class _MainNavbarState extends State<MainNavbar> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    ChatPage(),
    WardrobePage(),
    CommunityPage(),
    HairstyleMainPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingNotification());
  }

  Future<void> _checkPendingNotification() async {
    final convId = FcmService.consumePendingConversationId();
    if (convId == null || !mounted) return;

    final user = await StorageService.getUser();
    if (!mounted) return;

    DmConversation? conv;
    try {
      final convs = await DmService.getConversations();
      conv = convs.firstWhere((c) => c.id == convId, orElse: () => throw Exception());
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DmChatPage(
          conversationId: convId,
          otherUser: conv?.otherUser,
          currentUserId: user?.id ?? '',
        ),
      ),
    );
  }

  List<GButton> _buildTabs(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return [
      GButton(icon: Icons.auto_awesome, text: l.navChat),
      GButton(icon: Icons.checkroom, text: l.navWardrobe),
      GButton(icon: Icons.groups, text: l.navCommunity),
      GButton(icon: Icons.content_cut, text: l.navHairstyles),
      GButton(icon: Icons.person, text: l.navProfile),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6),
            child: GNav(
              gap: 4,
              activeColor: Colors.white,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              iconSize: 22,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: theme.colorScheme.primary,
              tabs: _buildTabs(context),
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
