class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://attendly-pro-backend.onrender.com',
  );
}
