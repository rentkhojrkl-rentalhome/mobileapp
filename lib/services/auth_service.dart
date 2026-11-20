
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://backend-0c33.onrender.com/api',
  );

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String _tokenKey = 'rentkhoj_token';

  String? _token;

  String? get token => _token;
  bool get isLoggedIn => _token != null;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<void> restoreSession() async {
    _token = await _storage.read(key: _tokenKey);
  }

  Future<dynamic> _request({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = _headers;

    if (!authenticated) {
      headers.remove('Authorization');
    }

    late http.Response response;

    try {
      switch (method) {
        case 'GET':
          response = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 30));
          break;

        case 'POST':
          response = await http
              .post(
                uri,
                headers: headers,
                body: jsonEncode(body ?? {}),
              )
              .timeout(const Duration(seconds: 30));
          break;

        case 'PATCH':
          response = await http
              .patch(
                uri,
                headers: headers,
                body: jsonEncode(body ?? {}),
              )
              .timeout(const Duration(seconds: 30));
          break;

        default:
          throw Exception('Unsupported HTTP method: $method');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = response.body;
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      String message = 'Request failed (${response.statusCode})';

      if (decoded is Map) {
        final detail = decoded['detail'];

        if (detail is List) {
          message = detail
              .map((e) => e is Map
                  ? e['msg']?.toString() ?? e.toString()
                  : e.toString())
              .join('\n');
        } else if (detail != null) {
          message = detail.toString();
        } else if (decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } else if (decoded is String && decoded.isNotEmpty) {
        message = decoded;
      }

      throw Exception(message);
    }

    return decoded;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return {'data': value};
  }

  // REGISTER
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'tenant',
  }) async {
    final result = await _request(
      method: 'POST',
      endpoint: '/auth/register',
      body: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'password': password,
        'role': role,
      },
    );

    return _asMap(result);
  }

  // VERIFY EMAIL OTP
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final result = await _request(
      method: 'POST',
      endpoint: '/auth/verify-email',
      body: {
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
      },
    );

    return _asMap(result);
  }

  // RESEND OTP
  Future<Map<String, dynamic>> resendOtp({
    required String email,
  }) async {
    final result = await _request(
      method: 'POST',
      endpoint: '/auth/resend-otp',
      body: {
        'email': email.trim().toLowerCase(),
      },
    );

    return _asMap(result);
  }

  // LOGIN
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final result = await _request(
      method: 'POST',
      endpoint: '/auth/login',
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    final data = _asMap(result);
    final accessToken = data['access_token'] ?? data['token'];

    if (accessToken == null ||
        accessToken.toString().isEmpty) {
      throw Exception(
        'Login response did not contain an access token.',
      );
    }

    _token = accessToken.toString();

    await _storage.write(
      key: _tokenKey,
      value: _token,
    );

    return data;
  }

  // GET CURRENT USER
  Future<Map<String, dynamic>> getCurrentUser() async {
    if (_token == null) {
      throw Exception('Please login first.');
    }

    final result = await _request(
      method: 'GET',
      endpoint: '/auth/me',
      authenticated: true,
    );

    return _asMap(result);
  }

  // FORGOT PASSWORD
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final result = await _request(
      method: 'POST',
      endpoint: '/auth/forgot-password',
      body: {
        'email': email.trim().toLowerCase(),
      },
    );

    return _asMap(result);
  }

  // RESET PASSWORD
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final result = await _request(
      method: 'POST',
      endpoint: '/auth/reset-password',
      body: {
        'token': token,
        'new_password': newPassword,
      },
    );

    return _asMap(result);
  }

  // UPDATE PROFILE
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? phone,
  }) async {
    if (_token == null) {
      throw Exception('Please login first.');
    }

    final result = await _request(
      method: 'PATCH',
      endpoint: '/auth/profile',
      authenticated: true,
      body: {
        'name': name.trim(),
        'phone': phone,
      },
    );

    return _asMap(result);
  }

  // UPDATE PHONE
  Future<Map<String, dynamic>> updatePhone({
    required String phone,
  }) async {
    if (_token == null) {
      throw Exception('Please login first.');
    }

    final result = await _request(
      method: 'PATCH',
      endpoint: '/auth/phone',
      authenticated: true,
      body: {
        'phone': phone.trim(),
      },
    );

    return _asMap(result);
  }

  
  // UPLOAD PROFILE PHOTO
  Future<Map<String, dynamic>> uploadProfilePhoto(
    XFile image,
  ) async {
    if (_token == null) {
      throw Exception('Please login first.');
    }

    try {
      final extension = p.extension(image.path).toLowerCase();

      final MediaType contentType;

      switch (extension) {
        case '.jpg':
        case '.jpeg':
          contentType = MediaType('image', 'jpeg');
          break;
        case '.png':
          contentType = MediaType('image', 'png');
          break;
        case '.webp':
          contentType = MediaType('image', 'webp');
          break;
        default:
          throw Exception(
            'Unsupported image format. Please select JPG, PNG or WEBP.',
          );
      }

      final uri = Uri.parse('$baseUrl/auth/profile/photo');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $_token';

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          image.path,
          filename: 'profile$extension',
          contentType: contentType,
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      debugPrint('PHOTO UPLOAD STATUS: ${response.statusCode}');
      debugPrint('PHOTO UPLOAD RESPONSE: ${response.body}');

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = response.body;
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        String message = 'Photo upload failed';

        if (decoded is Map && decoded['detail'] != null) {
          message = decoded['detail'].toString();
        }

        throw Exception(message);
      }

      return _asMap(decoded);
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }


  // LOGOUT
  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: _tokenKey);
  }

  // CHECK EXISTING SESSION
  Future<bool> checkSession() async {
    await restoreSession();

    if (_token == null) return false;

    try {
      await getCurrentUser();
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }
}
