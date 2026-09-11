import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import '../errors/error_mapper.dart';

/// Response guards for the shared [Dio] instance.
///
/// `dioProvider` is configured with `validateStatus: status < 500`, so 4xx
/// responses arrive here as normal [Response]s carrying the backend error
/// envelope. Every service MUST pass responses through these guards —
/// otherwise error envelopes would be parsed as payloads.

/// Asserts success and returns the body as a JSON object.
Map<String, dynamic> requireJsonObject(Response<Object?> res) {
  final status = res.statusCode ?? 500;
  if (status >= 400) {
    final data = res.data;
    throw ErrorMapper.fromEnvelope(
      status,
      data is Map<String, dynamic> ? data : null,
    );
  }
  final data = res.data;
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return data.map((k, v) => MapEntry('$k', v));
  throw const ParsingException('The server returned an unreadable response.');
}

/// Asserts success and returns the body as a JSON array.
List<dynamic> requireJsonArray(Response<Object?> res) {
  final status = res.statusCode ?? 500;
  if (status >= 400) {
    final data = res.data;
    throw ErrorMapper.fromEnvelope(
      status,
      data is Map<String, dynamic> ? data : null,
    );
  }
  final data = res.data;
  if (data is List) return data;
  throw const ParsingException('The server returned an unreadable response.');
}