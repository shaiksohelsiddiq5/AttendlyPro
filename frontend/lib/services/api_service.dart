class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://myattendancemanager.onrender.com',
  );
}
