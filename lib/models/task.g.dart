// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaskItem _$TaskItemFromJson(Map<String, dynamic> json) => _TaskItem(
  id: json['id'] as String,
  title: json['title'] as String?,
  description: json['description'] as String?,
  priority: json['priority'] as String?,
  status: json['status'] as String?,
  sourceType: json['source_type'] as String?,
  sourceId: json['source_id'] as String?,
  assigneeId: json['assignee_id'] as String?,
  stateCode: json['state_code'] as String?,
  districtCode: json['district_code'] as String?,
  createdAt: json['created_at'] as String?,
  completedAt: json['completed_at'] as String?,
);

Map<String, dynamic> _$TaskItemToJson(_TaskItem instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'priority': instance.priority,
  'status': instance.status,
  'source_type': instance.sourceType,
  'source_id': instance.sourceId,
  'assignee_id': instance.assigneeId,
  'state_code': instance.stateCode,
  'district_code': instance.districtCode,
  'created_at': instance.createdAt,
  'completed_at': instance.completedAt,
};

_FieldMedia _$FieldMediaFromJson(Map<String, dynamic> json) => _FieldMedia(
  id: json['id'] as String,
  kind: json['kind'] as String?,
  filename: json['filename'] as String?,
  mimeType: json['mime_type'] as String?,
  sizeBytes: (json['size_bytes'] as num?)?.toInt(),
  uploadedAt: json['uploaded_at'] as String?,
  signedUrl: json['signed_url'] as String?,
  signedUrlExpiresAt: json['signed_url_expires_at'] as String?,
);

Map<String, dynamic> _$FieldMediaToJson(_FieldMedia instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': instance.kind,
      'filename': instance.filename,
      'mime_type': instance.mimeType,
      'size_bytes': instance.sizeBytes,
      'uploaded_at': instance.uploadedAt,
      'signed_url': instance.signedUrl,
      'signed_url_expires_at': instance.signedUrlExpiresAt,
    };

_SatelliteEvidence _$SatelliteEvidenceFromJson(Map<String, dynamic> json) =>
    _SatelliteEvidence(
      id: json['id'] as String,
      sceneId: json['scene_id'] as String?,
      source: json['source'] as String?,
      capturedAt: json['captured_at'] as String?,
      stateCode: json['state_code'] as String?,
      districtCode: json['district_code'] as String?,
      cloudCoverPct: (json['cloud_cover_pct'] as num?)?.toDouble(),
      productType: json['product_type'] as String?,
      signedUrl: json['signed_url'] as String?,
      signedUrlExpiresAt: json['signed_url_expires_at'] as String?,
    );

Map<String, dynamic> _$SatelliteEvidenceToJson(_SatelliteEvidence instance) =>
    <String, dynamic>{
      'id': instance.id,
      'scene_id': instance.sceneId,
      'source': instance.source,
      'captured_at': instance.capturedAt,
      'state_code': instance.stateCode,
      'district_code': instance.districtCode,
      'cloud_cover_pct': instance.cloudCoverPct,
      'product_type': instance.productType,
      'signed_url': instance.signedUrl,
      'signed_url_expires_at': instance.signedUrlExpiresAt,
    };
