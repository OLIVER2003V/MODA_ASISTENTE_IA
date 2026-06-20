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

  /// No description provided for @emailRequired.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresá tu email'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresá un email válido'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresá tu contraseña'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres'**
  String get passwordTooShort;

  /// No description provided for @nameRequired.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresá tu nombre'**
  String get nameRequired;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Por favor confirmá tu contraseña'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get passwordsDoNotMatch;

  /// No description provided for @mustAcceptTerms.
  ///
  /// In es, this message translates to:
  /// **'Debés aceptar los términos y condiciones'**
  String get mustAcceptTerms;

  /// No description provided for @takePhoto.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In es, this message translates to:
  /// **'Elegir de galería'**
  String get chooseFromGallery;

  /// No description provided for @changePhoto.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto'**
  String get changePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In es, this message translates to:
  /// **'Quitar foto'**
  String get removePhoto;

  /// No description provided for @uploadSelectedPhoto.
  ///
  /// In es, this message translates to:
  /// **'Subir foto seleccionada'**
  String get uploadSelectedPhoto;

  /// No description provided for @displayName.
  ///
  /// In es, this message translates to:
  /// **'Nombre visible'**
  String get displayName;

  /// No description provided for @yourName.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre'**
  String get yourName;

  /// No description provided for @nameMinChars.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 2 caracteres'**
  String get nameMinChars;

  /// No description provided for @nameMaxChars.
  ///
  /// In es, this message translates to:
  /// **'Máximo 60 caracteres'**
  String get nameMaxChars;

  /// No description provided for @chooseAvatar.
  ///
  /// In es, this message translates to:
  /// **'Elige un avatar'**
  String get chooseAvatar;

  /// No description provided for @avatarWillReplacePhoto.
  ///
  /// In es, this message translates to:
  /// **'Se eliminará la foto de perfil al elegir un avatar'**
  String get avatarWillReplacePhoto;

  /// No description provided for @photoUpdated.
  ///
  /// In es, this message translates to:
  /// **'Foto actualizada'**
  String get photoUpdated;

  /// No description provided for @errorUploadingPhoto.
  ///
  /// In es, this message translates to:
  /// **'Error al subir foto'**
  String get errorUploadingPhoto;

  /// No description provided for @photoDeleted.
  ///
  /// In es, this message translates to:
  /// **'Foto eliminada'**
  String get photoDeleted;

  /// No description provided for @errorDeletingPhoto.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar foto'**
  String get errorDeletingPhoto;

  /// No description provided for @nameUpdated.
  ///
  /// In es, this message translates to:
  /// **'Nombre actualizado'**
  String get nameUpdated;

  /// No description provided for @errorUpdatingName.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar nombre'**
  String get errorUpdatingName;

  /// No description provided for @avatarUpdated.
  ///
  /// In es, this message translates to:
  /// **'Avatar actualizado'**
  String get avatarUpdated;

  /// No description provided for @errorChangingAvatar.
  ///
  /// In es, this message translates to:
  /// **'Error al cambiar avatar'**
  String get errorChangingAvatar;

  /// No description provided for @outfitNoName.
  ///
  /// In es, this message translates to:
  /// **'Outfit sin nombre'**
  String get outfitNoName;

  /// No description provided for @noGarmentImages.
  ///
  /// In es, this message translates to:
  /// **'Sin prendas'**
  String get noGarmentImages;

  /// No description provided for @noOutfitsSaved.
  ///
  /// In es, this message translates to:
  /// **'Aún no tenés outfits guardados'**
  String get noOutfitsSaved;

  /// No description provided for @noOutfitsDescription.
  ///
  /// In es, this message translates to:
  /// **'Generá un outfit con la IA o creá uno manualmente...'**
  String get noOutfitsDescription;

  /// No description provided for @createOutfit.
  ///
  /// In es, this message translates to:
  /// **'Crear outfit'**
  String get createOutfit;

  /// No description provided for @newOutfit.
  ///
  /// In es, this message translates to:
  /// **'Nuevo outfit'**
  String get newOutfit;

  /// No description provided for @outfitName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del outfit'**
  String get outfitName;

  /// No description provided for @outfitCreated.
  ///
  /// In es, this message translates to:
  /// **'Outfit creado'**
  String get outfitCreated;

  /// No description provided for @deleteOutfitTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar outfit'**
  String get deleteOutfitTitle;

  /// No description provided for @deleteOutfitConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar \"{name}\"? Esta acción no se puede deshacer.'**
  String deleteOutfitConfirm(String name);

  /// No description provided for @noGarmentsInWardrobe.
  ///
  /// In es, this message translates to:
  /// **'No tenés prendas en tu armario'**
  String get noGarmentsInWardrobe;

  /// No description provided for @garmentNoName.
  ///
  /// In es, this message translates to:
  /// **'Prenda sin nombre'**
  String get garmentNoName;

  /// No description provided for @howItLooksOnYou.
  ///
  /// In es, this message translates to:
  /// **'Cómo te queda'**
  String get howItLooksOnYou;

  /// No description provided for @tryOnThisOutfit.
  ///
  /// In es, this message translates to:
  /// **'Probarme este outfit'**
  String get tryOnThisOutfit;

  /// No description provided for @tryOnDescription.
  ///
  /// In es, this message translates to:
  /// **'Genera una imagen realista con este outfit puesto'**
  String get tryOnDescription;

  /// No description provided for @regenerate.
  ///
  /// In es, this message translates to:
  /// **'Regenerar'**
  String get regenerate;

  /// No description provided for @needBodyPhoto.
  ///
  /// In es, this message translates to:
  /// **'Necesitás una foto de cuerpo completo'**
  String get needBodyPhoto;

  /// No description provided for @bodyPhotoDescription.
  ///
  /// In es, this message translates to:
  /// **'Subí una foto de cuerpo completo en tu perfil para usar la prueba virtual'**
  String get bodyPhotoDescription;

  /// No description provided for @goToMyProfile.
  ///
  /// In es, this message translates to:
  /// **'Ir a mi perfil'**
  String get goToMyProfile;

  /// No description provided for @couldNotGenerateImage.
  ///
  /// In es, this message translates to:
  /// **'No se pudo generar la imagen'**
  String get couldNotGenerateImage;

  /// No description provided for @imageSavedToGallery.
  ///
  /// In es, this message translates to:
  /// **'Imagen guardada en la galería'**
  String get imageSavedToGallery;

  /// No description provided for @couldNotSave.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar'**
  String get couldNotSave;

  /// No description provided for @errorDownloadingImage.
  ///
  /// In es, this message translates to:
  /// **'Error al descargar la imagen'**
  String get errorDownloadingImage;

  /// No description provided for @shareInCommunity.
  ///
  /// In es, this message translates to:
  /// **'Compartir en Comunidad'**
  String get shareInCommunity;

  /// No description provided for @outfitCaptionHint.
  ///
  /// In es, this message translates to:
  /// **'Contá algo sobre tu outfit (opcional)...'**
  String get outfitCaptionHint;

  /// No description provided for @publishing.
  ///
  /// In es, this message translates to:
  /// **'Publicando...'**
  String get publishing;

  /// No description provided for @publishedInCommunity.
  ///
  /// In es, this message translates to:
  /// **'¡Publicado en la comunidad!'**
  String get publishedInCommunity;

  /// No description provided for @selectedGarmentsCount.
  ///
  /// In es, this message translates to:
  /// **'Seleccioná las prendas ({count} seleccionadas)'**
  String selectedGarmentsCount(int count);

  /// No description provided for @preparingLook.
  ///
  /// In es, this message translates to:
  /// **'Preparando tu look...'**
  String get preparingLook;

  /// No description provided for @applyingGarments.
  ///
  /// In es, this message translates to:
  /// **'Aplicando las prendas...'**
  String get applyingGarments;

  /// No description provided for @adjustingDetails.
  ///
  /// In es, this message translates to:
  /// **'Ajustando los detalles...'**
  String get adjustingDetails;

  /// No description provided for @almostReady.
  ///
  /// In es, this message translates to:
  /// **'¡Casi listo!'**
  String get almostReady;

  /// No description provided for @oneMoreMoment.
  ///
  /// In es, this message translates to:
  /// **'Un momento más...'**
  String get oneMoreMoment;

  /// No description provided for @aiGeneratingImage.
  ///
  /// In es, this message translates to:
  /// **'La IA está generando tu imagen'**
  String get aiGeneratingImage;

  /// No description provided for @closetDeleted.
  ///
  /// In es, this message translates to:
  /// **'Armario eliminado'**
  String get closetDeleted;

  /// No description provided for @editGarment.
  ///
  /// In es, this message translates to:
  /// **'Editar prenda'**
  String get editGarment;

  /// No description provided for @garmentDeleted.
  ///
  /// In es, this message translates to:
  /// **'Prenda eliminada'**
  String get garmentDeleted;

  /// No description provided for @editCloset.
  ///
  /// In es, this message translates to:
  /// **'Editar armario'**
  String get editCloset;

  /// No description provided for @deleteCloset.
  ///
  /// In es, this message translates to:
  /// **'Eliminar armario'**
  String get deleteCloset;

  /// No description provided for @addGarment.
  ///
  /// In es, this message translates to:
  /// **'Agregar prenda'**
  String get addGarment;

  /// No description provided for @createMyCloset.
  ///
  /// In es, this message translates to:
  /// **'Crear mi armario'**
  String get createMyCloset;

  /// No description provided for @addFirstGarment.
  ///
  /// In es, this message translates to:
  /// **'Agregar primera prenda'**
  String get addFirstGarment;

  /// No description provided for @closetNameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre del armario es requerido'**
  String get closetNameRequired;

  /// No description provided for @closetUpdated.
  ///
  /// In es, this message translates to:
  /// **'Armario actualizado'**
  String get closetUpdated;

  /// No description provided for @garmentAdded.
  ///
  /// In es, this message translates to:
  /// **'Prenda agregada'**
  String get garmentAdded;

  /// No description provided for @mustAddGarment.
  ///
  /// In es, this message translates to:
  /// **'Debes agregar al menos una prenda'**
  String get mustAddGarment;

  /// No description provided for @closetCreated.
  ///
  /// In es, this message translates to:
  /// **'Armario creado exitosamente'**
  String get closetCreated;

  /// No description provided for @next.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get next;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get back;

  /// No description provided for @createCloset.
  ///
  /// In es, this message translates to:
  /// **'Crear armario'**
  String get createCloset;

  /// No description provided for @errorLoading.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar'**
  String get errorLoading;

  /// No description provided for @premiumRequired.
  ///
  /// In es, this message translates to:
  /// **'Esta función requiere Premium'**
  String get premiumRequired;

  /// No description provided for @findYourStyle.
  ///
  /// In es, this message translates to:
  /// **'Encuentra tu estilo'**
  String get findYourStyle;

  /// No description provided for @whatDoYouWantToDo.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres hacer?'**
  String get whatDoYouWantToDo;

  /// No description provided for @recommendedForYou.
  ///
  /// In es, this message translates to:
  /// **'Recomendado para ti'**
  String get recommendedForYou;

  /// No description provided for @otherCompatibleStyles.
  ///
  /// In es, this message translates to:
  /// **'Otros estilos compatibles'**
  String get otherCompatibleStyles;

  /// No description provided for @tryThisStyle.
  ///
  /// In es, this message translates to:
  /// **'Probar este estilo'**
  String get tryThisStyle;

  /// No description provided for @hairstyleCatalog.
  ///
  /// In es, this message translates to:
  /// **'Catálogo de peinados'**
  String get hairstyleCatalog;

  /// No description provided for @noHairstylesAvailable.
  ///
  /// In es, this message translates to:
  /// **'Sin peinados disponibles'**
  String get noHairstylesAvailable;

  /// No description provided for @howToUploadPhoto.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo quieres subir tu foto?'**
  String get howToUploadPhoto;

  /// No description provided for @fromGallery.
  ///
  /// In es, this message translates to:
  /// **'Desde galería'**
  String get fromGallery;

  /// No description provided for @selectExistingPhoto.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una foto existente'**
  String get selectExistingPhoto;

  /// No description provided for @facialDetectionCamera.
  ///
  /// In es, this message translates to:
  /// **'Usa la cámara con detección facial'**
  String get facialDetectionCamera;

  /// No description provided for @tryAnotherStyle.
  ///
  /// In es, this message translates to:
  /// **'Probar otro estilo'**
  String get tryAnotherStyle;

  /// No description provided for @analyzingFace.
  ///
  /// In es, this message translates to:
  /// **'Analizando tu rostro...'**
  String get analyzingFace;

  /// No description provided for @reportPost.
  ///
  /// In es, this message translates to:
  /// **'Reportar publicación'**
  String get reportPost;

  /// No description provided for @deletePost.
  ///
  /// In es, this message translates to:
  /// **'Eliminar publicación'**
  String get deletePost;

  /// No description provided for @reportSent.
  ///
  /// In es, this message translates to:
  /// **'Reporte enviado. Gracias por mantener la comunidad.'**
  String get reportSent;

  /// No description provided for @copiedToClipboard.
  ///
  /// In es, this message translates to:
  /// **'Copiado al portapapeles'**
  String get copiedToClipboard;

  /// No description provided for @commentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Comentarios'**
  String get commentsTitle;

  /// No description provided for @noCommentsYet.
  ///
  /// In es, this message translates to:
  /// **'Sin comentarios todavía'**
  String get noCommentsYet;

  /// No description provided for @newPost.
  ///
  /// In es, this message translates to:
  /// **'Nueva publicación'**
  String get newPost;

  /// No description provided for @whatDoYouWantToShare.
  ///
  /// In es, this message translates to:
  /// **'¿Qué querés compartir?'**
  String get whatDoYouWantToShare;

  /// No description provided for @changeType.
  ///
  /// In es, this message translates to:
  /// **'Cambiar tipo'**
  String get changeType;

  /// No description provided for @chooseOutfit.
  ///
  /// In es, this message translates to:
  /// **'Elegí un outfit'**
  String get chooseOutfit;

  /// No description provided for @tapToChoosePhoto.
  ///
  /// In es, this message translates to:
  /// **'Tocar para elegir una foto'**
  String get tapToChoosePhoto;

  /// No description provided for @writeFashionTip.
  ///
  /// In es, this message translates to:
  /// **'Escribí tu tip de moda'**
  String get writeFashionTip;

  /// No description provided for @descriptionOptional.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get descriptionOptional;

  /// No description provided for @reactions.
  ///
  /// In es, this message translates to:
  /// **'Reacciones'**
  String get reactions;

  /// No description provided for @noReactions.
  ///
  /// In es, this message translates to:
  /// **'Sin reacciones'**
  String get noReactions;

  /// No description provided for @loginToPublish.
  ///
  /// In es, this message translates to:
  /// **'Iniciá sesión para publicar'**
  String get loginToPublish;

  /// No description provided for @postedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'✅ Publicado exitosamente'**
  String get postedSuccessfully;

  /// No description provided for @clearFilters.
  ///
  /// In es, this message translates to:
  /// **'Limpiar filtros'**
  String get clearFilters;

  /// No description provided for @captionCopied.
  ///
  /// In es, this message translates to:
  /// **'Caption copiado al portapapeles'**
  String get captionCopied;

  /// No description provided for @copyCaption.
  ///
  /// In es, this message translates to:
  /// **'Copiar caption'**
  String get copyCaption;

  /// No description provided for @colorPalette.
  ///
  /// In es, this message translates to:
  /// **'Paleta de colores'**
  String get colorPalette;

  /// No description provided for @keywords.
  ///
  /// In es, this message translates to:
  /// **'Palabras clave'**
  String get keywords;

  /// No description provided for @contentTypes.
  ///
  /// In es, this message translates to:
  /// **'Tipos de contenido'**
  String get contentTypes;

  /// No description provided for @postIdeas.
  ///
  /// In es, this message translates to:
  /// **'Ideas de publicaciones'**
  String get postIdeas;

  /// No description provided for @noHashtagsAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay hashtags disponibles'**
  String get noHashtagsAvailable;

  /// No description provided for @allHashtagsCopied.
  ///
  /// In es, this message translates to:
  /// **'Todos los hashtags copiados'**
  String get allHashtagsCopied;

  /// No description provided for @copyAll.
  ///
  /// In es, this message translates to:
  /// **'Copiar todos'**
  String get copyAll;

  /// No description provided for @idealMoments.
  ///
  /// In es, this message translates to:
  /// **'Momentos ideales'**
  String get idealMoments;

  /// No description provided for @avoidPosting.
  ///
  /// In es, this message translates to:
  /// **'Evitar publicar'**
  String get avoidPosting;

  /// No description provided for @generatingGuideFor.
  ///
  /// In es, this message translates to:
  /// **'Generando guía para {network}...'**
  String generatingGuideFor(String network);

  /// No description provided for @generateGuideFor.
  ///
  /// In es, this message translates to:
  /// **'Generar guía para {network}'**
  String generateGuideFor(String network);

  /// No description provided for @hashtagCopied.
  ///
  /// In es, this message translates to:
  /// **'{tag} copiado'**
  String hashtagCopied(String tag);

  /// No description provided for @create.
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get create;

  /// No description provided for @preparingPhoto.
  ///
  /// In es, this message translates to:
  /// **'Preparando tu foto...'**
  String get preparingPhoto;

  /// No description provided for @applyingHairstyle.
  ///
  /// In es, this message translates to:
  /// **'Aplicando el peinado...'**
  String get applyingHairstyle;

  /// No description provided for @adjustingStyle.
  ///
  /// In es, this message translates to:
  /// **'Ajustando el estilo...'**
  String get adjustingStyle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'ko',
    'pt',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
