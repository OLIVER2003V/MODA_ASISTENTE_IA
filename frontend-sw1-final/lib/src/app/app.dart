import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/services/theme_service.dart';
import '../core/providers/locale_provider.dart';
import '../features/community/presentation/providers/community_provider.dart';
import '../features/hairstyle/presentation/providers/hairstyle_provider.dart';
import '../features/notifications/presentation/providers/notification_provider.dart';
import '../features/outfit/presentation/providers/outfit_history_provider.dart';
import '../features/people/presentation/providers/people_provider.dart';
import '../features/profile/presentation/providers/profile_provider.dart';
import '../features/subscription/presentation/providers/subscription_provider.dart';
import '../features/wardrobe/presentation/providers/wardrobe_provider.dart';
import 'router/app_router.dart';

class App extends StatefulWidget {
  const App({super.key});

  // Acceso global al ThemeService
  static final ThemeService themeService = ThemeService();

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _localeProvider = LocaleProvider();

  @override
  void initState() {
    super.initState();
    App.themeService.addListener(_onThemeChanged);
    _localeProvider.loadLocale();
  }

  @override
  void dispose() {
    App.themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _localeProvider),
        ChangeNotifierProvider(create: (_) => WardrobeProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => PeopleProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => OutfitHistoryProvider()),
        ChangeNotifierProvider(create: (_) => HairstyleProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp.router(
            title: AppConstants.appName,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: App.themeService.materialThemeMode,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
            // ── Localización ───────────────────────────────────────────────
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: localeProvider.locale,
          );
        },
      ),
    );
  }
}
