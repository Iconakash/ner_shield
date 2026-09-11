import 'package:dio/dio.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/error_mapper.dart';
import '../core/network/api_responses.dart';
import '../models/shipment.dart';

/// Logistics reads/writes (reference `backend/app/shipments/router.py`).
///
/// Authorization is enforced server-side per operation (permission +
/// geographic scope on origin AND destination); the client only surfaces the
/// resulting status codes.
class ShipmentsService {
  ShipmentsService(this._dio);

  final Dio _dio;

  /// GET /shipments — RLS-scoped list, server-ordered by priority.
  Future<List<Shipment>> list() async {
    try {
      final res = await _dio.get<Object?>('/shipments');
      final rows = requireJsonArray(res);
      try {
        return rows
            .whereType<Map<String, dynamic>>()
            .map(Shipment.fromJson)
            .toList();
      } on TypeError {
        throw const ParsingException('Shipment rows were malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// GET /shipments/{id}/eta — backend-calculated ETA.
  Future<ShipmentEta> eta(String shipmentId) async {
    try {
      final res = await _dio.get<Object?>('/shipments/$shipmentId/eta');
      final body = requireJsonObject(res);
      try {
        return ShipmentEta.fromJson(body);
      } on TypeError {
        throw const ParsingException('ETA response was malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// POST /shipments/{id}/status — lifecycle transition
  /// (VEHICLE_ASSIGNED | ROUTE_ASSIGNED | IN_TRANSIT | DELIVERED | CANCELLED).
  Future<void> updateStatus(
    String shipmentId, {
    required String newStatus,
    String? note,
  }) async {
    try {
      final res = await _dio.post<Object?>(
        '/shipments/$shipmentId/status',
        data: {'new_status': newStatus, 'note': ?note},
      );
      requireJsonObject(res);
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// POST /shipments/{id}/confirm-delivery — delivery confirmation.
  Future<void> confirmDelivery(String shipmentId) async {
    try {
      final res = await _dio.post<Object?>(
        '/shipments/$shipmentId/confirm-delivery',
      );
      requireJsonObject(res);
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }
}