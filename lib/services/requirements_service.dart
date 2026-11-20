
import 'dart:convert';
import 'dart:io';

import 'auth_service.dart';

class RequirementsService {
  RequirementsService._();

  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://backend-0c33.onrender.com/api',
  );

  static Map<String, String> get _headers {
    final token = AuthService.instance.token;

    if (token == null || token.isEmpty) {
      throw Exception('Please login first.');
    }

    return {
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer $token',
    };
  }

  // Common API request handler
  static Future<dynamic> _request({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);

    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final HttpClientRequest request;

      switch (method) {
        case 'POST':
          request = await client.postUrl(uri);
          break;
        case 'GET':
          request = await client.getUrl(uri);
          break;
        case 'PATCH':
          request = await client.patchUrl(uri);
          break;
        case 'DELETE':
          request = await client.deleteUrl(uri);
          break;
        default:
          throw Exception('Unsupported request method.');
      }

      _headers.forEach(request.headers.set);

      if (body != null) {
        request.add(utf8.encode(jsonEncode(body)));
      }

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );

      final responseBody = await response
          .transform(utf8.decoder)
          .join();

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        String message = responseBody;

        try {
          final decoded = jsonDecode(responseBody);
          if (decoded is Map && decoded['detail'] != null) {
            message = decoded['detail'].toString();
          }
        } catch (_) {}

        throw HttpException(
          'Request failed (${response.statusCode}): $message',
        );
      }

      if (responseBody.isEmpty) return null;

      return jsonDecode(responseBody);
    } finally {
      client.close(force: true);
    }
  }

  // Create a tenant room requirement.
  static Future<Map<String, dynamic>> createRequirement({
    required String roomType,
    required String area,
    required int monthlyBudget,
    required String moveIn,
    required String furnishing,
    String? notes,
  }) async {
    final result = await _request(
      method: 'POST',
      endpoint: '/requirements',
      body: {
        'room_type': roomType,
        'area': area,
        'monthly_budget': monthlyBudget,
        'move_in': moveIn,
        'furnishing': furnishing,
        'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
      },
    );

    if (result is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid requirement creation response.',
      );
    }

    return result;
  }

  // Get requirements posted by the logged-in tenant.
  static Future<List<Map<String, dynamic>>> myRequirements() async {
    final result = await _request(
      method: 'GET',
      endpoint: '/requirements/mine',
    );

    if (result is! Map<String, dynamic> ||
        result['requirements'] is! List) {
      throw const FormatException(
        'Invalid requirements response.',
      );
    }

    return (result['requirements'] as List)
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  // Close or reopen one of the tenant's requirements.
  static Future<Map<String, dynamic>> updateRequirement({
    required String requirementId,
    required String status,
  }) async {
    if (!['open', 'closed'].contains(status)) {
      throw ArgumentError('Status must be open or closed.');
    }

    final result = await _request(
      method: 'PATCH',
      endpoint: '/requirements/$requirementId',
      body: {'status': status},
    );

    if (result is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid requirement update response.',
      );
    }

    return result;
  }

  // Soft delete a tenant's own requirement.
  static Future<void> deleteRequirement({
    required String requirementId,
  }) async {
    await _request(
      method: 'DELETE',
      endpoint: '/requirements/$requirementId',
    );
  }

  // Find properties matching one of the tenant's requirements.
  static Future<List<Map<String, dynamic>>> matchingProperties(
    String requirementId,
  ) async {
    final result = await _request(
      method: 'GET',
      endpoint: '/requirements/$requirementId/matches',
    );

    if (result is! Map<String, dynamic> ||
        result['properties'] is! List) {
      throw const FormatException(
        'Invalid matching properties response.',
      );
    }

    return (result['properties'] as List)
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  // Get open requirements matching the logged-in owner's properties.
  static Future<List<Map<String, dynamic>>> ownerMatchingRequirements() async {
    final result = await _request(
      method: 'GET',
      endpoint: '/requirements/owner/matching',
    );

    if (result is! Map<String, dynamic> ||
        result['requirements'] is! List) {
      throw const FormatException(
        'Invalid owner requirements response.',
      );
    }

    return (result['requirements'] as List)
        .whereType<Map<String, dynamic>>()
        .toList();
  }
}
