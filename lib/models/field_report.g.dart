// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'field_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FieldReport _$FieldReportFromJson(Map<String, dynamic> json) => _FieldReport(
  id: json['id'] as String,
  code: json['code'] as String?,
  incidentType: json['incident_type'] as String?,
  severity: json['severity'] as String?,
  status: json['status'] as String?,
  description: json['description'] as String?,
  stateCode: json['state_code'] as String?,
  districtCode: json['district_code'] as String?,
  segmentId: json['segment_id'] as String?,
  roadCode: json['road_code'] as String?,
  reporterId: json['reporter_id'] as String?,
  reporterName: json['reporter_name'] as String?,
  reportedAt: json['reported_at'] as String?,
  validatedAt: json['validated_at'] as String?,
  validatedBy: json['validated_by'] as String?,
  confidence: (json['confidence'] as num?)?.toDouble(),
  rejectReason: json['reject_reason'] as String?,
  source: json['source'] as String?,
  updatedAt: json['updated_at'] as String?,
  locationName: json['location_name'] as String?,
  media: (json['media'] as List<dynamic>?)
      ?.map((e) => FieldReportMedia.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$FieldReportToJson(_FieldReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'incident_type': instance.incidentType,
      'severity': instance.severity,
      'status': instance.status,
      'description': instance.description,
      'state_code': instance.stateCode,
      'district_code': instance.districtCode,
      'segment_id': instance.segmentId,
      'road_code': instance.roadCode,
      'reporter_id': instance.reporterId,
      'reporter_name': instance.reporterName,
      'reported_at': instance.reportedAt,
      'validated_at': instance.validatedAt,
      'validated_by': instance.validatedBy,
      'confidence': instance.confidence,
      'reject_reason': instance.rejectReason,
      'source': instance.source,
      'updated_at': instance.updatedAt,
      'location_name': instance.locationName,
      'media': instance.media,
    };

_FieldReportMedia _$FieldReportMediaFromJson(Map<String, dynamic> json) =>
    _FieldReportMedia(
      id: json['id'] as String,
      contentType: json['content_type'] as String?,
      byteSize: (json['byte_size'] as num?)?.toInt(),
      sha256: json['sha256'] as String?,
      storagePath: json['storage_path'] as String?,
      deduplicated: json['deduplicated'] as bool?,
      capturedAt: json['captured_at'] as String?,
      uploadedAt: json['uploaded_at'] as String?,
      localPath: json['local_path'] as String?,
    );

Map<String, dynamic> _$FieldReportMediaToJson(_FieldReportMedia instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content_type': instance.contentType,
      'byte_size': instance.byteSize,
      'sha256': instance.sha256,
      'storage_path': instance.storagePath,
      'deduplicated': instance.deduplicated,
      'captured_at': instance.capturedAt,
      'uploaded_at': instance.uploadedAt,
      'local_path': instance.localPath,
    };

_DraftMediaRef _$DraftMediaRefFromJson(Map<String, dynamic> json) =>
    _DraftMediaRef(
      clientRefId: json['client_ref_id'] as String,
      localPath: json['local_path'] as String,
      contentType: json['content_type'] as String?,
      sizeBytes: (json['size_bytes'] as num?)?.toInt(),
      sha256: json['sha256'] as String?,
      capturedAt: json['captured_at'] as String?,
    );

Map<String, dynamic> _$DraftMediaRefToJson(_DraftMediaRef instance) =>
    <String, dynamic>{
      'client_ref_id': instance.clientRefId,
      'local_path': instance.localPath,
      'content_type': instance.contentType,
      'size_bytes': instance.sizeBytes,
      'sha256': instance.sha256,
      'captured_at': instance.capturedAt,
    };

_FieldReportDraft _$FieldReportDraftFromJson(Map<String, dynamic> json) =>
    _FieldReportDraft(
      clientDraftId: json['client_draft_id'] as String,
      incidentType: json['incident_type'] as String?,
      severity: json['severity'] as String?,
      description: json['description'] as String?,
      stateCode: json['state_code'] as String?,
      districtCode: json['district_code'] as String?,
      segmentId: json['segment_id'] as String?,
      roadCode: json['road_code'] as String?,
      locationName: json['location_name'] as String?,
      lon: (json['lon'] as num?)?.toDouble(),
      lat: (json['lat'] as num?)?.toDouble(),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      mediaPaths:
          (json['media_paths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      mediaRefs:
          (json['media_refs'] as List<dynamic>?)
              ?.map((e) => DraftMediaRef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <DraftMediaRef>[],
    );

Map<String, dynamic> _$FieldReportDraftToJson(_FieldReportDraft instance) =>
    <String, dynamic>{
      'client_draft_id': instance.clientDraftId,
      'incident_type': instance.incidentType,
      'severity': instance.severity,
      'description': instance.description,
      'state_code': instance.stateCode,
      'district_code': instance.districtCode,
      'segment_id': instance.segmentId,
      'road_code': instance.roadCode,
      'location_name': instance.locationName,
      'lon': instance.lon,
      'lat': instance.lat,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'media_paths': instance.mediaPaths,
      'media_refs': instance.mediaRefs,
    };
