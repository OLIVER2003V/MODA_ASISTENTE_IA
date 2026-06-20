import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('es'),
    Locale('en'),
    Locale('pt'),
    Locale('fr'),
    Locale('it'),
    Locale('de'),
    Locale('zh'),
    Locale('ja'),
    Locale('ko'),
    Locale('ar'),
  ];

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'Style AI'**
  String get appName;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @search.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get search;

  /// No description provided for @refresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get refresh;

  /// No description provided for @done.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get done;

  /// No description provided for @yes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @navChat.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navWardrobe.
  ///
  /// In es, this message translates to:
  /// **'Guardarropa'**
  String get navWardrobe;

  /// No description provided for @navCommunity.
  ///
  /// In es, this message translates to:
  /// **'Comunidad'**
  String get navCommunity;

  /// No description provided for @navHairstyles.
  ///
  /// In es, this message translates to:
  /// **'Peinados'**
  String get navHairstyles;

  /// No description provided for @navProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @loginTitle.
  ///
  /// In es, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @email.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In es, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @rememberMe.
  ///
  /// In es, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In es, this message translates to:
  /// **'Forget Password?'**
  String get forgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In es, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @noAccount.
  ///
  /// In es, this message translates to:
  /// **'Don\'t have an Account? '**
  String get noAccount;

  /// No description provided for @signUp.
  ///
  /// In es, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @registerTitle.
  ///
  /// In es, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @name.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get name;

  /// No description provided for @confirmPassword.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get confirmPassword;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tenés cuenta? '**
  String get alreadyHaveAccount;

  /// No description provided for @signIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get signIn;

  /// No description provided for @registerButton.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get registerButton;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settingsTitle;

  /// No description provided for @appearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @account.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get account;

  /// No description provided for @profileTile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profileTile;

  /// No description provided for @profileTileSub.
  ///
  /// In es, this message translates to:
  /// **'Ver y editar tu perfil'**
  String get profileTileSub;

  /// No description provided for @notifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notifications;

  /// No description provided for @notificationsSub.
  ///
  /// In es, this message translates to:
  /// **'Configurar notificaciones push'**
  String get notificationsSub;

  /// No description provided for @information.
  ///
  /// In es, this message translates to:
  /// **'Información'**
  String get information;

  /// No description provided for @about.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get about;

  /// No description provided for @versionLabel.
  ///
  /// In es, this message translates to:
  /// **'Versión {version}'**
  String versionLabel(String version);

  /// No description provided for @terms.
  ///
  /// In es, this message translates to:
  /// **'Términos y condiciones'**
  String get terms;

  /// No description provided for @privacy.
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get privacy;

  /// No description provided for @logout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logout;

  /// No description provided for @logoutTitle.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logoutTitle;

  /// No description provided for @logoutConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que querés cerrar sesión?'**
  String get logoutConfirm;

  /// No description provided for @selectTheme.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar tema'**
  String get selectTheme;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @themeSystemSub.
  ///
  /// In es, this message translates to:
  /// **'Seguir configuración del dispositivo'**
  String get themeSystemSub;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeLightSub.
  ///
  /// In es, this message translates to:
  /// **'Tema claro siempre'**
  String get themeLightSub;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @themeDarkSub.
  ///
  /// In es, this message translates to:
  /// **'Tema oscuro siempre'**
  String get themeDarkSub;

  /// No description provided for @selectLanguage.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar idioma'**
  String get selectLanguage;

  /// No description provided for @langSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get langSpanish;

  /// No description provided for @langSpanishSub.
  ///
  /// In es, this message translates to:
  /// **'Idioma actual'**
  String get langSpanishSub;

  /// No description provided for @langEnglish.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langEnglishSub.
  ///
  /// In es, this message translates to:
  /// **'Cambiar a inglés'**
  String get langEnglishSub;

  /// No description provided for @langPortuguese.
  ///
  /// In es, this message translates to:
  /// **'Português'**
  String get langPortuguese;

  /// No description provided for @langPortugueseSub.
  ///
  /// In es, this message translates to:
  /// **'Mudar para português'**
  String get langPortugueseSub;

  /// No description provided for @aboutContent.
  ///
  /// In es, this message translates to:
  /// **'Tu asistente personal de moda con inteligencia artificial. Crea outfits perfectos, organiza tu armario y comparte tu estilo con la comunidad.'**
  String get aboutContent;

  /// No description provided for @subscriptionTitle.
  ///
  /// In es, this message translates to:
  /// **'Suscripción Premium'**
  String get subscriptionTitle;

  /// No description provided for @premiumTitle.
  ///
  /// In es, this message translates to:
  /// **'StyleAI Premium'**
  String get premiumTitle;

  /// No description provided for @subscribeNow.
  ///
  /// In es, this message translates to:
  /// **'Suscribirme ahora'**
  String get subscribeNow;

  /// No description provided for @whatsIncluded.
  ///
  /// In es, this message translates to:
  /// **'¿Qué incluye Premium?'**
  String get whatsIncluded;

  /// No description provided for @choosePlan.
  ///
  /// In es, this message translates to:
  /// **'Elegí tu plan'**
  String get choosePlan;

  /// No description provided for @monthly.
  ///
  /// In es, this message translates to:
  /// **'Mensual'**
  String get monthly;

  /// No description provided for @annual.
  ///
  /// In es, this message translates to:
  /// **'Anual'**
  String get annual;

  /// No description provided for @perMonth.
  ///
  /// In es, this message translates to:
  /// **'por mes'**
  String get perMonth;

  /// No description provided for @perYear.
  ///
  /// In es, this message translates to:
  /// **'por año'**
  String get perYear;

  /// No description provided for @save33.
  ///
  /// In es, this message translates to:
  /// **'Ahorrá 33%'**
  String get save33;

  /// No description provided for @securePayment.
  ///
  /// In es, this message translates to:
  /// **'Pagás de forma segura con Stripe.\nPodés cancelar en cualquier momento.'**
  String get securePayment;

  /// No description provided for @freePlan.
  ///
  /// In es, this message translates to:
  /// **'Plan gratuito'**
  String get freePlan;

  /// No description provided for @pastDue.
  ///
  /// In es, this message translates to:
  /// **'Pago vencido'**
  String get pastDue;

  /// No description provided for @cancelledPlan.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get cancelledPlan;

  /// No description provided for @activeBenefits.
  ///
  /// In es, this message translates to:
  /// **'Beneficios activos'**
  String get activeBenefits;

  /// No description provided for @planRenews.
  ///
  /// In es, this message translates to:
  /// **'Tu plan se renueva el {date}'**
  String planRenews(String date);

  /// No description provided for @premiumActive.
  ///
  /// In es, this message translates to:
  /// **'Sos Premium'**
  String get premiumActive;

  /// No description provided for @unlimitedAI.
  ///
  /// In es, this message translates to:
  /// **'Asistente IA ilimitado'**
  String get unlimitedAI;

  /// No description provided for @unlimitedAIDesc.
  ///
  /// In es, this message translates to:
  /// **'Genera outfits con IA sin restricciones'**
  String get unlimitedAIDesc;

  /// No description provided for @hairstyleRec.
  ///
  /// In es, this message translates to:
  /// **'Recomendaciones de peinado'**
  String get hairstyleRec;

  /// No description provided for @hairstyleRecDesc.
  ///
  /// In es, this message translates to:
  /// **'Análisis facial y sugerencias personalizadas'**
  String get hairstyleRecDesc;

  /// No description provided for @virtualTryOn.
  ///
  /// In es, this message translates to:
  /// **'Prueba virtual de peinados'**
  String get virtualTryOn;

  /// No description provided for @virtualTryOnDesc.
  ///
  /// In es, this message translates to:
  /// **'Visualizá el look antes de adoptarlo'**
  String get virtualTryOnDesc;

  /// No description provided for @priorityAccess.
  ///
  /// In es, this message translates to:
  /// **'Acceso prioritario'**
  String get priorityAccess;

  /// No description provided for @priorityAccessDesc.
  ///
  /// In es, this message translates to:
  /// **'Primero en acceder a nuevas funciones'**
  String get priorityAccessDesc;

  /// No description provided for @approxLocal.
  ///
  /// In es, this message translates to:
  /// **'aprox. {price} {currency}'**
  String approxLocal(String price, String currency);

  /// No description provided for @chargedUSD.
  ///
  /// In es, this message translates to:
  /// **'Se cobra en USD · Tipo de cambio aproximado'**
  String get chargedUSD;

  /// No description provided for @communityTitle.
  ///
  /// In es, this message translates to:
  /// **'Comunidad'**
  String get communityTitle;

  /// No description provided for @publish.
  ///
  /// In es, this message translates to:
  /// **'Publicar'**
  String get publish;

  /// No description provided for @forYou.
  ///
  /// In es, this message translates to:
  /// **'Para vos'**
  String get forYou;

  /// No description provided for @following.
  ///
  /// In es, this message translates to:
  /// **'Siguiendo'**
  String get following;

  /// No description provided for @searchPeople.
  ///
  /// In es, this message translates to:
  /// **'Buscar personas'**
  String get searchPeople;

  /// No description provided for @personalBranding.
  ///
  /// In es, this message translates to:
  /// **'Branding personal'**
  String get personalBranding;

  /// No description provided for @myProfile.
  ///
  /// In es, this message translates to:
  /// **'Mi Perfil'**
  String get myProfile;

  /// No description provided for @editProfile.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get editProfile;

  /// No description provided for @fashionProfile.
  ///
  /// In es, this message translates to:
  /// **'Mi Perfil de Moda'**
  String get fashionProfile;

  /// No description provided for @gender.
  ///
  /// In es, this message translates to:
  /// **'Género'**
  String get gender;

  /// No description provided for @age.
  ///
  /// In es, this message translates to:
  /// **'Edad'**
  String get age;

  /// No description provided for @height.
  ///
  /// In es, this message translates to:
  /// **'Estatura'**
  String get height;

  /// No description provided for @weight.
  ///
  /// In es, this message translates to:
  /// **'Peso'**
  String get weight;

  /// No description provided for @profession.
  ///
  /// In es, this message translates to:
  /// **'Profesión'**
  String get profession;

  /// No description provided for @skinTone.
  ///
  /// In es, this message translates to:
  /// **'Tono de piel'**
  String get skinTone;

  /// No description provided for @faceShape.
  ///
  /// In es, this message translates to:
  /// **'Forma del rostro'**
  String get faceShape;

  /// No description provided for @notSpecified.
  ///
  /// In es, this message translates to:
  /// **'No especificado'**
  String get notSpecified;

  /// No description provided for @memberSince.
  ///
  /// In es, this message translates to:
  /// **'Miembro desde'**
  String get memberSince;

  /// No description provided for @wardrobe.
  ///
  /// In es, this message translates to:
  /// **'Guardarropa'**
  String get wardrobe;

  /// No description provided for @closets.
  ///
  /// In es, this message translates to:
  /// **'Armarios'**
  String get closets;

  /// No description provided for @garments.
  ///
  /// In es, this message translates to:
  /// **'Prendas'**
  String get garments;

  /// No description provided for @myOutfits.
  ///
  /// In es, this message translates to:
  /// **'Mis Outfits'**
  String get myOutfits;

  /// No description provided for @hairstyles.
  ///
  /// In es, this message translates to:
  /// **'Peinados'**
  String get hairstyles;

  /// No description provided for @catalog.
  ///
  /// In es, this message translates to:
  /// **'Catálogo'**
  String get catalog;

  /// No description provided for @aiRecommends.
  ///
  /// In es, this message translates to:
  /// **'IA Recomienda'**
  String get aiRecommends;

  /// No description provided for @tryOn.
  ///
  /// In es, this message translates to:
  /// **'Probar'**
  String get tryOn;

  /// No description provided for @all.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get all;

  /// No description provided for @favorites.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get favorites;

  /// No description provided for @aiAssistant.
  ///
  /// In es, this message translates to:
  /// **'Asistente IA'**
  String get aiAssistant;

  /// No description provided for @newConversation.
  ///
  /// In es, this message translates to:
  /// **'Nueva conversación'**
  String get newConversation;

  /// No description provided for @typeMessage.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje...'**
  String get typeMessage;

  /// No description provided for @recording.
  ///
  /// In es, this message translates to:
  /// **'Grabando...'**
  String get recording;

  /// No description provided for @transcribing.
  ///
  /// In es, this message translates to:
  /// **'Transcribiendo audio...'**
  String get transcribing;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt', 'fr', 'it', 'de', 'zh', 'ja', 'ko', 'ar']
          .contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'de':
      return AppLocalizationsDe();
    case 'zh':
      return AppLocalizationsZh();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'ar':
      return AppLocalizationsAr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
