// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Style AI';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get confirm => 'Confirmer';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String get retry => 'Réessayer';

  @override
  String get close => 'Fermer';

  @override
  String get edit => 'Modifier';

  @override
  String get search => 'Rechercher';

  @override
  String get refresh => 'Actualiser';

  @override
  String get done => 'Terminé';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get navChat => 'Chat';

  @override
  String get navWardrobe => 'Garde-robe';

  @override
  String get navCommunity => 'Communauté';

  @override
  String get navHairstyles => 'Coiffures';

  @override
  String get navProfile => 'Profil';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get rememberMe => 'Se souvenir de moi';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get loginButton => 'Connexion';

  @override
  String get noAccount => 'Pas encore de compte ? ';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get registerTitle => 'Créer un compte';

  @override
  String get name => 'Nom';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get alreadyHaveAccount => 'Déjà un compte ? ';

  @override
  String get signIn => 'Se connecter';

  @override
  String get registerButton => 'S\'inscrire';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get appearance => 'Apparence';

  @override
  String get theme => 'Thème';

  @override
  String get language => 'Langue';

  @override
  String get account => 'Compte';

  @override
  String get profileTile => 'Profil';

  @override
  String get profileTileSub => 'Voir et modifier votre profil';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSub => 'Configurer les notifications push';

  @override
  String get information => 'Informations';

  @override
  String get about => 'À propos';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get terms => 'Conditions d\'utilisation';

  @override
  String get privacy => 'Politique de confidentialité';

  @override
  String get logout => 'Déconnexion';

  @override
  String get logoutTitle => 'Déconnexion';

  @override
  String get logoutConfirm => 'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get selectTheme => 'Sélectionner le thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeSystemSub => 'Suivre la configuration de l\'appareil';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeLightSub => 'Toujours en mode clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeDarkSub => 'Toujours en mode sombre';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get langSpanish => 'Español';

  @override
  String get langSpanishSub => 'Passer à l\'espagnol';

  @override
  String get langEnglish => 'English';

  @override
  String get langEnglishSub => 'Switch to English';

  @override
  String get langPortuguese => 'Português';

  @override
  String get langPortugueseSub => 'Passer au portugais';

  @override
  String get aboutContent =>
      'Votre assistant personnel de mode avec l\'intelligence artificielle. Créez des tenues parfaites, organisez votre garde-robe et partagez votre style avec la communauté.';

  @override
  String get subscriptionTitle => 'Abonnement Premium';

  @override
  String get premiumTitle => 'StyleAI Premium';

  @override
  String get subscribeNow => 'S\'abonner maintenant';

  @override
  String get whatsIncluded => 'Qu\'inclut Premium ?';

  @override
  String get choosePlan => 'Choisissez votre plan';

  @override
  String get monthly => 'Mensuel';

  @override
  String get annual => 'Annuel';

  @override
  String get perMonth => 'par mois';

  @override
  String get perYear => 'par an';

  @override
  String get save33 => 'Économisez 33%';

  @override
  String get securePayment =>
      'Paiement sécurisé via Stripe.\nVous pouvez annuler à tout moment.';

  @override
  String get freePlan => 'Plan gratuit';

  @override
  String get pastDue => 'Paiement en retard';

  @override
  String get cancelledPlan => 'Annulé';

  @override
  String get activeBenefits => 'Avantages actifs';

  @override
  String planRenews(String date) {
    return 'Votre plan se renouvelle le $date';
  }

  @override
  String get premiumActive => 'Vous êtes Premium';

  @override
  String get unlimitedAI => 'Assistant IA illimité';

  @override
  String get unlimitedAIDesc => 'Générez des tenues avec IA sans restrictions';

  @override
  String get hairstyleRec => 'Recommandations de coiffure';

  @override
  String get hairstyleRecDesc =>
      'Analyse faciale et suggestions personnalisées';

  @override
  String get virtualTryOn => 'Essayage virtuel de coiffures';

  @override
  String get virtualTryOnDesc => 'Visualisez le look avant de l\'adopter';

  @override
  String get priorityAccess => 'Accès prioritaire';

  @override
  String get priorityAccessDesc =>
      'Premier à accéder aux nouvelles fonctionnalités';

  @override
  String approxLocal(String price, String currency) {
    return 'approx. $price $currency';
  }

  @override
  String get chargedUSD => 'Facturé en USD · Taux de change approximatif';

  @override
  String get communityTitle => 'Communauté';

  @override
  String get publish => 'Publier';

  @override
  String get forYou => 'Pour vous';

  @override
  String get following => 'Abonnements';

  @override
  String get searchPeople => 'Rechercher des personnes';

  @override
  String get personalBranding => 'Personal branding';

  @override
  String get myProfile => 'Mon Profil';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get fashionProfile => 'Mon Profil Mode';

  @override
  String get gender => 'Genre';

  @override
  String get age => 'Âge';

  @override
  String get height => 'Taille';

  @override
  String get weight => 'Poids';

  @override
  String get profession => 'Profession';

  @override
  String get skinTone => 'Teint de peau';

  @override
  String get faceShape => 'Forme du visage';

  @override
  String get notSpecified => 'Non spécifié';

  @override
  String get memberSince => 'Membre depuis';

  @override
  String get wardrobe => 'Garde-robe';

  @override
  String get closets => 'Armoires';

  @override
  String get garments => 'Vêtements';

  @override
  String get myOutfits => 'Mes Tenues';

  @override
  String get hairstyles => 'Coiffures';

  @override
  String get catalog => 'Catalogue';

  @override
  String get aiRecommends => 'IA Recommande';

  @override
  String get tryOn => 'Essayer';

  @override
  String get all => 'Tous';

  @override
  String get favorites => 'Favoris';

  @override
  String get aiAssistant => 'Assistant IA';

  @override
  String get newConversation => 'Nouvelle conversation';

  @override
  String get typeMessage => 'Écrire un message...';

  @override
  String get recording => 'Enregistrement...';

  @override
  String get transcribing => 'Transcription audio...';

  @override
  String get emailRequired => 'Veuillez saisir votre email';

  @override
  String get emailInvalid => 'Veuillez saisir un email valide';

  @override
  String get passwordRequired => 'Veuillez saisir votre mot de passe';

  @override
  String get passwordTooShort =>
      'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get nameRequired => 'Veuillez saisir votre nom';

  @override
  String get confirmPasswordRequired => 'Veuillez confirmer votre mot de passe';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get mustAcceptTerms => 'Vous devez accepter les termes et conditions';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get chooseFromGallery => 'Choisir dans la galerie';

  @override
  String get changePhoto => 'Changer la photo';

  @override
  String get removePhoto => 'Supprimer la photo';

  @override
  String get uploadSelectedPhoto => 'Télécharger la photo sélectionnée';

  @override
  String get displayName => 'Nom affiché';

  @override
  String get yourName => 'Votre nom';

  @override
  String get nameMinChars => 'Minimum 2 caractères';

  @override
  String get nameMaxChars => 'Maximum 60 caractères';

  @override
  String get chooseAvatar => 'Choisissez un avatar';

  @override
  String get avatarWillReplacePhoto =>
      'La photo de profil sera supprimée lors du choix d\'un avatar';

  @override
  String get photoUpdated => 'Photo mise à jour';

  @override
  String get errorUploadingPhoto => 'Erreur lors du téléchargement de la photo';

  @override
  String get photoDeleted => 'Photo supprimée';

  @override
  String get errorDeletingPhoto => 'Erreur lors de la suppression de la photo';

  @override
  String get nameUpdated => 'Nom mis à jour';

  @override
  String get errorUpdatingName => 'Erreur lors de la mise à jour du nom';

  @override
  String get avatarUpdated => 'Avatar mis à jour';

  @override
  String get errorChangingAvatar => 'Erreur lors du changement d\'avatar';

  @override
  String get outfitNoName => 'Tenue sans nom';

  @override
  String get noGarmentImages => 'Pas de vêtements';

  @override
  String get noOutfitsSaved => 'Aucune tenue sauvegardée';

  @override
  String get noOutfitsDescription =>
      'Générez une tenue avec l\'IA ou créez-en une manuellement avec le bouton +';

  @override
  String get createOutfit => 'Créer une tenue';

  @override
  String get newOutfit => 'Nouvelle tenue';

  @override
  String get outfitName => 'Nom de la tenue';

  @override
  String get outfitCreated => 'Tenue créée';

  @override
  String get deleteOutfitTitle => 'Supprimer la tenue';

  @override
  String deleteOutfitConfirm(String name) {
    return 'Supprimer \"$name\" ? Cette action est irréversible.';
  }

  @override
  String get noGarmentsInWardrobe =>
      'Vous n\'avez pas de vêtements dans votre garde-robe';

  @override
  String get garmentNoName => 'Vêtement sans nom';

  @override
  String get howItLooksOnYou => 'Comment ça vous va';

  @override
  String get tryOnThisOutfit => 'Essayer cette tenue';

  @override
  String get tryOnDescription =>
      'Générez une image réaliste de comment ça vous irait';

  @override
  String get regenerate => 'Régénérer';

  @override
  String get needBodyPhoto => 'Vous avez besoin d\'une photo en pied';

  @override
  String get bodyPhotoDescription =>
      'Pour voir comment la tenue vous va, téléchargez une photo en pied dans votre profil';

  @override
  String get goToMyProfile => 'Aller à mon profil';

  @override
  String get couldNotGenerateImage => 'Impossible de générer l\'image';

  @override
  String get imageSavedToGallery => 'Image sauvegardée dans la galerie';

  @override
  String get couldNotSave => 'Impossible de sauvegarder';

  @override
  String get errorDownloadingImage =>
      'Erreur lors du téléchargement de l\'image';

  @override
  String get shareInCommunity => 'Partager dans la Communauté';

  @override
  String get outfitCaptionHint =>
      'Dites quelque chose sur votre tenue (optionnel)...';

  @override
  String get publishing => 'Publication...';

  @override
  String get publishedInCommunity => 'Publié dans la communauté !';

  @override
  String selectedGarmentsCount(int count) {
    return 'Sélectionnez les vêtements ($count sélectionnés)';
  }

  @override
  String get preparingLook => 'Préparation de votre look...';

  @override
  String get applyingGarments => 'Application des vêtements...';

  @override
  String get adjustingDetails => 'Ajustement des détails...';

  @override
  String get almostReady => 'Presque prêt !';

  @override
  String get oneMoreMoment => 'Encore un instant...';

  @override
  String get aiGeneratingImage => 'L\'IA génère votre image avec FLUX.2';

  @override
  String get closetDeleted => 'Garde-robe supprimée';

  @override
  String get editGarment => 'Modifier le vêtement';

  @override
  String get garmentDeleted => 'Vêtement supprimé';

  @override
  String get editCloset => 'Modifier la garde-robe';

  @override
  String get deleteCloset => 'Supprimer la garde-robe';

  @override
  String get addGarment => 'Ajouter un vêtement';

  @override
  String get createMyCloset => 'Créer ma garde-robe';

  @override
  String get addFirstGarment => 'Ajouter le premier vêtement';

  @override
  String get closetNameRequired => 'Le nom est requis';

  @override
  String get closetUpdated => 'Garde-robe mise à jour';

  @override
  String get garmentAdded => 'Vêtement ajouté';

  @override
  String get mustAddGarment => 'Vous devez ajouter au moins un vêtement';

  @override
  String get closetCreated => 'Garde-robe créée avec succès';

  @override
  String get next => 'Suivant';

  @override
  String get back => 'Retour';

  @override
  String get createCloset => 'Créer une garde-robe';

  @override
  String get errorLoading => 'Erreur de chargement';

  @override
  String get premiumRequired => 'Cette fonctionnalité nécessite Premium';

  @override
  String get findYourStyle => 'Trouvez votre style';

  @override
  String get whatDoYouWantToDo => 'Que voulez-vous faire ?';

  @override
  String get recommendedForYou => 'Recommandé pour vous';

  @override
  String get otherCompatibleStyles => 'Autres styles compatibles';

  @override
  String get tryThisStyle => 'Essayer ce style';

  @override
  String get hairstyleCatalog => 'Catalogue de coiffures';

  @override
  String get noHairstylesAvailable => 'Aucune coiffure disponible';

  @override
  String get howToUploadPhoto =>
      'Comment voulez-vous télécharger votre photo ?';

  @override
  String get fromGallery => 'Depuis la galerie';

  @override
  String get selectExistingPhoto => 'Sélectionnez une photo existante';

  @override
  String get facialDetectionCamera =>
      'Utiliser la caméra avec détection faciale';

  @override
  String get tryAnotherStyle => 'Essayer un autre style';

  @override
  String get analyzingFace => 'Analyse de votre visage...';

  @override
  String get reportPost => 'Signaler la publication';

  @override
  String get deletePost => 'Supprimer la publication';

  @override
  String get reportSent =>
      'Signalement envoyé. Merci de garder la communauté sûre.';

  @override
  String get copiedToClipboard => 'Copié dans le presse-papiers';

  @override
  String get commentsTitle => 'Commentaires';

  @override
  String get noCommentsYet => 'Pas encore de commentaires';

  @override
  String get newPost => 'Nouvelle publication';

  @override
  String get whatDoYouWantToShare => 'Que voulez-vous partager ?';

  @override
  String get changeType => 'Changer de type';

  @override
  String get chooseOutfit => 'Choisissez une tenue';

  @override
  String get tapToChoosePhoto => 'Appuyez pour choisir une photo';

  @override
  String get writeFashionTip => 'Écrivez votre conseil mode';

  @override
  String get descriptionOptional => 'Description (optionnel)';

  @override
  String get reactions => 'Réactions';

  @override
  String get noReactions => 'Pas de réactions';

  @override
  String get loginToPublish => 'Connectez-vous pour publier';

  @override
  String get postedSuccessfully => '✅ Publié avec succès';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get captionCopied => 'Légende copiée dans le presse-papiers';

  @override
  String get copyCaption => 'Copier la légende';

  @override
  String get colorPalette => 'Palette de couleurs';

  @override
  String get keywords => 'Mots-clés';

  @override
  String get contentTypes => 'Types de contenu';

  @override
  String get postIdeas => 'Idées de publications';

  @override
  String get noHashtagsAvailable => 'Aucun hashtag disponible';

  @override
  String get allHashtagsCopied => 'Tous les hashtags copiés';

  @override
  String get copyAll => 'Tout copier';

  @override
  String get idealMoments => 'Moments idéaux';

  @override
  String get avoidPosting => 'Éviter de publier';

  @override
  String generatingGuideFor(String network) {
    return 'Génération du guide pour $network...';
  }

  @override
  String generateGuideFor(String network) {
    return 'Générer le guide pour $network';
  }

  @override
  String hashtagCopied(String tag) {
    return '$tag copié';
  }

  @override
  String get create => 'Créer';

  @override
  String get preparingPhoto => 'Préparation de votre photo...';

  @override
  String get applyingHairstyle => 'Application de la coiffure...';

  @override
  String get adjustingStyle => 'Ajustement du style...';
}
