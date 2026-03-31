import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/storage/local_storage.dart';

class AuthService {
  static String? _token;

  /// 🔥 CHANGE BASE URL BASED ON DEVICE
  static const String baseUrl = "http://localhost:5000/api/auth";

  /// ================= INIT =================
  static Future<void> init() async {
    _token = await LocalStorage.getToken();
  }

  static String? get token => _token;

  static Map<String, String> get headers => {
    "Content-Type": "application/json",
    if (_token != null) "Authorization": "Bearer $_token",
  };

  /// ================= SIGNUP =================
  static Future<String?> signup({
    required String fullName,
    required String email,
    required String mobile,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/signup"),
        headers: headers,
        body: jsonEncode({
          "fullName": fullName,
          "email": email,
          "mobile": mobile,
          "password": password,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 201) {
        return null;
      } else {
        return data["message"] ?? data["msg"];
      }
    } catch (e) {
      return "Network Error";
    }
  }

  /// ================= LOGIN =================
  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: headers,
        body: jsonEncode({"email": email, "password": password}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        _token = data["token"];
        await LocalStorage.saveToken(_token!);
        return null;
      } else {
        return data["message"] ?? data["msg"];
      }
    } catch (e) {
      return "Network Error";
    }
  }

  /// ================= LOGOUT =================
  static Future<void> logout() async {
    _token = null;
    await LocalStorage.logout();
  }

  /// ================= CHECK LOGIN =================
  static Future<bool> isLoggedIn() async {
    final token = await LocalStorage.getToken();
    return token != null;
  }
}
