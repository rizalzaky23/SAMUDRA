class AppConstants {
  // API
  static const apiBaseUrl = 'https://samudra.rizalzaky.cloud/api';
  
  // Storage Keys
  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';
  static const userKey = 'user_data';
  static const isGuestKey = 'is_guest';

  // Risk Levels
  static const riskSafe = 'Aman';
  static const riskWarning = 'Waspada';
  static const riskAlert = 'Siaga';
  static const riskDanger = 'Awas';

  // Tsunami risk thresholds (km dari episentrum)
  static const tsunamiRiskRadiusKm = 500.0;
  static const siagaRadiusKm = 200.0;
  static const awasRadiusKm = 100.0;

  // Magnitude thresholds
  static const tsunamiMinMagnitude = 6.5;
  static const siagaMinMagnitude = 7.0;

  // Timeouts
  static const connectTimeout = 30000; // ms
  static const receiveTimeout = 30000; // ms
}
