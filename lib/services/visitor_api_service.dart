import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/app_exception.dart';
import '../core/config.dart';
import '../models/visitor.dart';

/// All REST communication lives here; widgets never call HTTP directly.
///
/// Updates use PUT with the full object because it works on MockAPI,
/// json-server and most mock services (some don't support PATCH).
class VisitorApiService {
  VisitorApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ?? AppConfig.apiBaseUrl).replaceAll(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;

  static const _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  // GET /visitors -> list of visitors (JSON array parsed into Visitor objects)
  Future<List<Visitor>> fetchVisitors() async {
    final body = await _send(() => _client.get(_uri('/visitors'), headers: _headers));
    final decoded = _decode(body);
    if (decoded is! List) throw const InvalidResponseException();
    try {
      return decoded
          .map((e) => Visitor.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      throw const InvalidResponseException();
    }
  }

  // GET /visitors/{id} -> one visitor (used by the QR scanner)
  Future<Visitor> fetchVisitor(String id) async {
    final body = await _send(
          () => _client.get(_uri('/visitors/${Uri.encodeComponent(id)}'), headers: _headers),
    );
    return _toVisitor(_decode(body));
  }

  // POST /visitors -> creates a visitor; the server returns it with its new id
  Future<Visitor> createVisitor(Visitor visitor) async {
    final body = await _send(
          () => _client.post(
        _uri('/visitors'),
        headers: _headers,
        body: jsonEncode(visitor.toJson()),
      ),
    );
    return _toVisitor(_decode(body));
  }

  // PUT /visitors/{id} -> edit details and also check-in / check-out updates
  Future<Visitor> updateVisitor(Visitor visitor) async {
    final body = await _send(
          () => _client.put(
        _uri('/visitors/${Uri.encodeComponent(visitor.id)}'),
        headers: _headers,
        body: jsonEncode(visitor.toJson()),
      ),
    );
    return _toVisitor(_decode(body));
  }

  // DELETE /visitors/{id}
  Future<void> deleteVisitor(String id) async {
    await _send(
          () => _client.delete(_uri('/visitors/${Uri.encodeComponent(id)}'), headers: _headers),
    );
  }

  // ---- helpers ----

  Visitor _toVisitor(dynamic decoded) {
    if (decoded is! Map) throw const InvalidResponseException();
    try {
      return Visitor.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      throw const InvalidResponseException();
    }
  }

  dynamic _decode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      throw const InvalidResponseException();
    }
  }

  /// Central place for every HTTP call: applies a timeout, checks the status code
  /// and converts failures (no internet, timeout, 404, 5xx) into AppException
  /// subclasses with user-friendly messages, so the app never crashes on errors.
  Future<String> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(AppConfig.requestTimeout);
      final code = response.statusCode;
      // Debug logs: shown in the Run window so API failures are easy to diagnose.
      debugPrint('API ${response.request?.method} ${response.request?.url} -> $code');
      debugPrint('API body: ${response.body}');
      if (code >= 200 && code < 300) return response.body;
      if (code == 404) throw const NotFoundException();
      if (code >= 500) throw const ServerException();
      // Include the server's message (trimmed) so 400-type errors are easy to debug.
      final detail = response.body.length > 120
          ? response.body.substring(0, 120)
          : response.body;
      throw ServerException('Request failed (HTTP $code): $detail');
    } on TimeoutException {
      throw const NetworkException('The server took too long to respond. Please try again.');
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    }
  }

  void dispose() => _client.close();
}