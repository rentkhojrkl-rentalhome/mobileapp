
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../models/property.dart';
import 'auth_service.dart';

class RentKhojApi {
  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://backend-0c33.onrender.com/api',
  );

  static Map<String, String> get _authHeaders {
    final token = AuthService.instance.token;

    if (token == null || token.isEmpty) {
      throw Exception('Please login first.');
    }

    return {
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer $token',
    };
  }

  static Future<List<Property>> properties() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);

    try {
      final request =
          await client.getUrl(Uri.parse('$baseUrl/properties'));

      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/json',
      );

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );

      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw HttpException('Server error ${response.statusCode}: $body');
      }

      final decoded = jsonDecode(body);

      final List<dynamic> items;

      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final data = decoded['properties'] ?? decoded['items'];

        if (data is! List) {
          throw const FormatException('Unexpected property response');
        }

        items = data;
      } else {
        throw const FormatException('Invalid property response');
      }

      return items
          .whereType<Map<String, dynamic>>()
          .map(Property.fromJson)
          .toList();
    } finally {
      client.close(force: true);
    }
  }

  // Fetch properties belonging to the logged-in owner.
  static Future<List<Property>> myProperties() async {
    final client = HttpClient();

    try {
      final request =
          await client.getUrl(Uri.parse('$baseUrl/properties/mine'));

      _authHeaders.forEach(request.headers.set);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw HttpException(
          'Unable to load your listings (${response.statusCode}): $body',
        );
      }

      final decoded = jsonDecode(body);

      if (decoded is! Map<String, dynamic> ||
          decoded['properties'] is! List) {
        throw const FormatException('Invalid owner listings response');
      }

      return (decoded['properties'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Property.fromJson)
          .toList();
    } finally {
      client.close(force: true);
    }
  }

  // Upload property photos to Cloudinary through the backend.
  static Future<List<String>> uploadPropertyImages(
    List<File> files,
  ) async {
    if (files.isEmpty) {
      throw Exception('Please select at least one photo.');
    }

    if (files.length > 10) {
      throw Exception('You can upload a maximum of 10 photos.');
    }

    const boundaryPrefix = 'RentKhojBoundary';
    final boundary =
        '$boundaryPrefix${Random().nextInt(1000000000)}';

    final client = HttpClient();

    try {
      final request = await client.postUrl(
        Uri.parse('$baseUrl/properties/upload-images'),
      );

      _authHeaders.forEach(request.headers.set);

      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );

      for (final file in files) {
        final bytes = await file.readAsBytes();

        if (bytes.length > 8 * 1024 * 1024) {
          throw Exception('Each photo must be smaller than 8 MB.');
        }

        final extension = file.path.split('.').last.toLowerCase();

        final mimeType = switch (extension) {
          'jpg' || 'jpeg' => 'image/jpeg',
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => throw Exception('Only JPG, PNG and WEBP images are supported.'),
        };

        final filename = file.uri.pathSegments.last;

        request.add(
          utf8.encode(
            '--$boundary\r\n'
            'Content-Disposition: form-data; name="files"; filename="$filename"\r\n'
            'Content-Type: $mimeType\r\n\r\n',
          ),
        );

        request.add(bytes);
        request.add(utf8.encode('\r\n'));
      }

      request.add(utf8.encode('--$boundary--\r\n'));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw HttpException(
          'Image upload failed (${response.statusCode}): $body',
        );
      }

      final decoded = jsonDecode(body);

      if (decoded is! Map<String, dynamic> ||
          decoded['image_urls'] is! List) {
        throw const FormatException('Invalid image upload response');
      }

      return (decoded['image_urls'] as List)
          .map((url) => url.toString())
          .toList();
    } finally {
      client.close(force: true);
    }
  }

  // Create a new property listing.
  static Future<Map<String, dynamic>> createProperty(
    Map<String, dynamic> propertyData,
  ) async {
    final client = HttpClient();

    try {
      final request = await client.postUrl(
        Uri.parse('$baseUrl/properties'),
      );

      _authHeaders.forEach(request.headers.set);

      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json',
      );

      request.add(utf8.encode(jsonEncode(propertyData)));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 201) {
        throw HttpException(
          'Property creation failed (${response.statusCode}): $body',
        );
      }

      final decoded = jsonDecode(body);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid property creation response');
      }

      return decoded;
    } finally {
      client.close(force: true);
    }
  }
}
