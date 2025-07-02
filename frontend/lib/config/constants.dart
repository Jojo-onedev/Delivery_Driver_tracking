class AppConstants {
  // URL de base de l'API - Remplacez 192.168.x.x par votre adresse IP locale
  static const String apiUrl = 'http://localhost:5000/api';

  // Statuts de livraison
  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusDelivered = 'delivered';
  static const String statusCancelled = 'cancelled';

  // Statuts des chauffeurs
  static const String driverStatusAvailable = 'available';
  static const String driverStatusOnDelivery = 'on_delivery';
  static const String driverStatusOffline = 'offline';

  // Types de véhicules
  static const String vehiculeTypeCar = 'car';
  static const String vehiculeTypeMotorbike = 'motorbike';

  // Chemins des routes
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeAdminHome = '/admin';
  static const String routeDriverHome = '/driver';
  static const String routeDeliveryDetails = '/delivery-details';
  static const String routeDriverDetails = '/driver-details';

  // Durées d'expiration
  static const int tokenExpirationHours = 24; // 24 heures
  static const int refreshTokenExpirationDays = 7; // 7 jours

  // Tailles maximales
  static const int maxImageSize = 5 * 1024 * 1024; // 5 Mo
  static const int maxFileSize = 10 * 1024 * 1024; // 10 Mo

  // Formats de date
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';

  // Valeurs par défaut
  static const int defaultPageSize = 10;
  static const int defaultDebounceTime = 500; // ms

  // Clés de stockage local
  static const String storageTokenKey = 'auth_token';
  static const String storageUserKey = 'user_data';
  static const String storageThemeKey = 'theme_mode';
  static const String storageLocaleKey = 'locale';

  // Messages d'erreur
  static const String errorNetwork =
      'Erreur de connexion. Veuillez vérifier votre connexion Internet.';
  static const String errorServer =
      'Erreur du serveur. Veuillez réessayer plus tard.';
  static const String errorUnauthorized =
      'Session expirée. Veuillez vous reconnecter.';
  static const String errorNotFound = 'Ressource non trouvée.';
  static const String errorUnknown = 'Une erreur inconnue est survenue.';
}
