import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = kDebugMode
      ? 'http://localhost:3000'
      : String.fromEnvironment(
          'API_URL',
          defaultValue: 'https://attendly-pro-backend.onrender.com',
        );
}
