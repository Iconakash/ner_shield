// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'field_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FieldReport {

 String get id; String? get code; String? get incidentType; String? get severity; String? get status; String? get description; String? get stateCode; String? get districtCode; String? get segmentId; String? get roadCode; String? get reporterId; String? get reporterName; String? get reportedAt; String? get validatedAt; String? get validatedBy; double? get confidence; String? get rejectReason; String? get source; String? get updatedAt; String? get locationName; List<FieldReportMedia>? get media;
/// Create a copy of FieldReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FieldReportCopyWith<FieldReport> get copyWith => _$FieldReportCopyWithImpl<FieldReport>(this as FieldReport, _$identity);

  /// Serializes this FieldReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FieldReport;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FieldReport&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.incidentType, _this.incidentType) || other.incidentType == _this.incidentType)&&(identical(other.severity, _this.severity) || other.severity == _this.severity)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.stateCode, _this.stateCode) || other.stateCode == _this.stateCode)&&(identical(other.districtCode, _this.districtCode) || other.districtCode == _this.districtCode)&&(identical(other.segmentId, _this.segmentId) || other.segmentId == _this.segmentId)&&(identical(other.roadCode, _this.roadCode) || other.roadCode == _this.roadCode)&&(identical(other.reporterId, _this.reporterId) || other.reporterId == _this.reporterId)&&(identical(other.reporterName, _this.reporterName) || other.reporterName == _this.reporterName)&&(identical(other.reportedAt, _this.reportedAt) || other.reportedAt == _this.reportedAt)&&(identical(other.validatedAt, _this.validatedAt) || other.validatedAt == _this.validatedAt)&&(identical(other.validatedBy, _this.validatedBy) || other.validatedBy == _this.validatedBy)&&(identical(other.confidence, _this.confidence) || other.confidence == _this.confidence)&&(identical(other.rejectReason, _this.rejectReason) || other.rejectReason == _this.rejectReason)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.locationName, _this.locationName) || other.locationName == _this.locationName)&&const DeepCollectionEquality().equals(other.media, _this.media));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FieldReport;
  return Object.hashAll([runtimeType,_this.id,_this.code,_this.incidentType,_this.severity,_this.status,_this.description,_this.stateCode,_this.districtCode,_this.segmentId,_this.roadCode,_this.reporterId,_this.reporterName,_this.reportedAt,_this.validatedAt,_this.validatedBy,_this.confidence,_this.rejectReason,_this.source,_this.updatedAt,_this.locationName,const DeepCollectionEquality().hash(_this.media)]);
}

@override
String toString() {
  final _this = this as FieldReport;
  return 'FieldReport(id: ${_this.id}, code: ${_this.code}, incidentType: ${_this.incidentType}, severity: ${_this.severity}, status: ${_this.status}, description: ${_this.description}, stateCode: ${_this.stateCode}, districtCode: ${_this.districtCode}, segmentId: ${_this.segmentId}, roadCode: ${_this.roadCode}, reporterId: ${_this.reporterId}, reporterName: ${_this.reporterName}, reportedAt: ${_this.reportedAt}, validatedAt: ${_this.validatedAt}, validatedBy: ${_this.validatedBy}, confidence: ${_this.confidence}, rejectReason: ${_this.rejectReason}, source: ${_this.source}, updatedAt: ${_this.updatedAt}, locationName: ${_this.locationName}, media: ${_this.media})';
}


}

/// @nodoc
abstract mixin class $FieldReportCopyWith<$Res>  {
  factory $FieldReportCopyWith(FieldReport value, $Res Function(FieldReport) _then) = _$FieldReportCopyWithImpl;
@useResult
$Res call({
 String id, String? code, String? incidentType, String? severity, String? status, String? description, String? stateCode, String? districtCode, String? segmentId, String? roadCode, String? reporterId, String? reporterName, String? reportedAt, String? validatedAt, String? validatedBy, double? confidence, String? rejectReason, String? source, String? updatedAt, String? locationName, List<FieldReportMedia>? media
});




}
/// @nodoc
class _$FieldReportCopyWithImpl<$Res>
    implements $FieldReportCopyWith<$Res> {
  _$FieldReportCopyWithImpl(this._self, this._then);

  final FieldReport _self;
  final $Res Function(FieldReport) _then;

/// Create a copy of FieldReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = freezed,Object? incidentType = freezed,Object? severity = freezed,Object? status = freezed,Object? description = freezed,Object? stateCode = freezed,Object? districtCode = freezed,Object? segmentId = freezed,Object? roadCode = freezed,Object? reporterId = freezed,Object? reporterName = freezed,Object? reportedAt = freezed,Object? validatedAt = freezed,Object? validatedBy = freezed,Object? confidence = freezed,Object? rejectReason = freezed,Object? source = freezed,Object? updatedAt = freezed,Object? locationName = freezed,Object? media = freezed,}) {
  return _then(FieldReport(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,incidentType: freezed == incidentType ? _self.incidentType : incidentType // ignore: cast_nullable_to_non_nullable
as String?,severity: freezed == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,stateCode: freezed == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String?,districtCode: freezed == districtCode ? _self.districtCode : districtCode // ignore: cast_nullable_to_non_nullable
as String?,segmentId: freezed == segmentId ? _self.segmentId : segmentId // ignore: cast_nullable_to_non_nullable
as String?,roadCode: freezed == roadCode ? _self.roadCode : roadCode // ignore: cast_nullable_to_non_nullable
as String?,reporterId: freezed == reporterId ? _self.reporterId : reporterId // ignore: cast_nullable_to_non_nullable
as String?,reporterName: freezed == reporterName ? _self.reporterName : reporterName // ignore: cast_nullable_to_non_nullable
as String?,reportedAt: freezed == reportedAt ? _self.reportedAt : reportedAt // ignore: cast_nullable_to_non_nullable
as String?,validatedAt: freezed == validatedAt ? _self.validatedAt : validatedAt // ignore: cast_nullable_to_non_nullable
as String?,validatedBy: freezed == validatedBy ? _self.validatedBy : validatedBy // ignore: cast_nullable_to_non_nullable
as String?,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,rejectReason: freezed == rejectReason ? _self.rejectReason : rejectReason // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,locationName: freezed == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String?,media: freezed == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as List<FieldReportMedia>?,
  ));
}

}


/// Adds pattern-matching-related methods to [FieldReport].
extension FieldReportPatterns on FieldReport {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FieldReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FieldReport() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FieldReport value)  $default,){
final _that = this;
switch (_that) {
case _FieldReport():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FieldReport value)?  $default,){
final _that = this;
switch (_that) {
case _FieldReport() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? code,  String? incidentType,  String? severity,  String? status,  String? description,  String? stateCode,  String? districtCode,  String? segmentId,  String? roadCode,  String? reporterId,  String? reporterName,  String? reportedAt,  String? validatedAt,  String? validatedBy,  double? confidence,  String? rejectReason,  String? source,  String? updatedAt,  String? locationName,  List<FieldReportMedia>? media)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FieldReport() when $default != null:
return $default(_that.id,_that.code,_that.incidentType,_that.severity,_that.status,_that.description,_that.stateCode,_that.districtCode,_that.segmentId,_that.roadCode,_that.reporterId,_that.reporterName,_that.reportedAt,_that.validatedAt,_that.validatedBy,_that.confidence,_that.rejectReason,_that.source,_that.updatedAt,_that.locationName,_that.media);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? code,  String? incidentType,  String? severity,  String? status,  String? description,  String? stateCode,  String? districtCode,  String? segmentId,  String? roadCode,  String? reporterId,  String? reporterName,  String? reportedAt,  String? validatedAt,  String? validatedBy,  double? confidence,  String? rejectReason,  String? source,  String? updatedAt,  String? locationName,  List<FieldReportMedia>? media)  $default,) {final _that = this;
switch (_that) {
case _FieldReport():
return $default(_that.id,_that.code,_that.incidentType,_that.severity,_that.status,_that.description,_that.stateCode,_that.districtCode,_that.segmentId,_that.roadCode,_that.reporterId,_that.reporterName,_that.reportedAt,_that.validatedAt,_that.validatedBy,_that.confidence,_that.rejectReason,_that.source,_that.updatedAt,_that.locationName,_that.media);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? code,  String? incidentType,  String? severity,  String? status,  String? description,  String? stateCode,  String? districtCode,  String? segmentId,  String? roadCode,  String? reporterId,  String? reporterName,  String? reportedAt,  String? validatedAt,  String? validatedBy,  double? confidence,  String? rejectReason,  String? source,  String? updatedAt,  String? locationName,  List<FieldReportMedia>? media)?  $default,) {final _that = this;
switch (_that) {
case _FieldReport() when $default != null:
return $default(_that.id,_that.code,_that.incidentType,_that.severity,_that.status,_that.description,_that.stateCode,_that.districtCode,_that.segmentId,_that.roadCode,_that.reporterId,_that.reporterName,_that.reportedAt,_that.validatedAt,_that.validatedBy,_that.confidence,_that.rejectReason,_that.source,_that.updatedAt,_that.locationName,_that.media);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FieldReport extends FieldReport {
  const _FieldReport({required this.id, this.code, this.incidentType, this.severity, this.status, this.description, this.stateCode, this.districtCode, this.segmentId, this.roadCode, this.reporterId, this.reporterName, this.reportedAt, this.validatedAt, this.validatedBy, this.confidence, this.rejectReason, this.source, this.updatedAt, this.locationName,  List<FieldReportMedia>? media}): _media = media,super._();
  factory _FieldReport.fromJson(Map<String, dynamic> json) => _$FieldReportFromJson(json);

@override final  String id;
@override final  String? code;
@override final  String? incidentType;
@override final  String? severity;
@override final  String? status;
@override final  String? description;
@override final  String? stateCode;
@override final  String? districtCode;
@override final  String? segmentId;
@override final  String? roadCode;
@override final  String? reporterId;
@override final  String? reporterName;
@override final  String? reportedAt;
@override final  String? validatedAt;
@override final  String? validatedBy;
@override final  double? confidence;
@override final  String? rejectReason;
@override final  String? source;
@override final  String? updatedAt;
@override final  String? locationName;
 final  List<FieldReportMedia>? _media;
@override List<FieldReportMedia>? get media {
  final value = _media;
  if (value == null) return null;
  if (_media is EqualUnmodifiableListView) return _media;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of FieldReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FieldReportCopyWith<_FieldReport> get copyWith => __$FieldReportCopyWithImpl<_FieldReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FieldReportToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FieldReport&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.incidentType, incidentType) || other.incidentType == incidentType)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.status, status) || other.status == status)&&(identical(other.description, description) || other.description == description)&&(identical(other.stateCode, stateCode) || other.stateCode == stateCode)&&(identical(other.districtCode, districtCode) || other.districtCode == districtCode)&&(identical(other.segmentId, segmentId) || other.segmentId == segmentId)&&(identical(other.roadCode, roadCode) || other.roadCode == roadCode)&&(identical(other.reporterId, reporterId) || other.reporterId == reporterId)&&(identical(other.reporterName, reporterName) || other.reporterName == reporterName)&&(identical(other.reportedAt, reportedAt) || other.reportedAt == reportedAt)&&(identical(other.validatedAt, validatedAt) || other.validatedAt == validatedAt)&&(identical(other.validatedBy, validatedBy) || other.validatedBy == validatedBy)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.rejectReason, rejectReason) || other.rejectReason == rejectReason)&&(identical(other.source, source) || other.source == source)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.locationName, locationName) || other.locationName == locationName)&&const DeepCollectionEquality().equals(other.media, _media));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,code,incidentType,severity,status,description,stateCode,districtCode,segmentId,roadCode,reporterId,reporterName,reportedAt,validatedAt,validatedBy,confidence,rejectReason,source,updatedAt,locationName,const DeepCollectionEquality().hash(_media)]);
}

@override
String toString() {
    return 'FieldReport(id: $id, code: $code, incidentType: $incidentType, severity: $severity, status: $status, description: $description, stateCode: $stateCode, districtCode: $districtCode, segmentId: $segmentId, roadCode: $roadCode, reporterId: $reporterId, reporterName: $reporterName, reportedAt: $reportedAt, validatedAt: $validatedAt, validatedBy: $validatedBy, confidence: $confidence, rejectReason: $rejectReason, source: $source, updatedAt: $updatedAt, locationName: $locationName, media: $media)';
}


}

/// @nodoc
abstract mixin class _$FieldReportCopyWith<$Res> implements $FieldReportCopyWith<$Res> {
  factory _$FieldReportCopyWith(_FieldReport value, $Res Function(_FieldReport) _then) = __$FieldReportCopyWithImpl;
@override @useResult
$Res call({
 String id, String? code, String? incidentType, String? severity, String? status, String? description, String? stateCode, String? districtCode, String? segmentId, String? roadCode, String? reporterId, String? reporterName, String? reportedAt, String? validatedAt, String? validatedBy, double? confidence, String? rejectReason, String? source, String? updatedAt, String? locationName, List<FieldReportMedia>? media
});




}
/// @nodoc
class __$FieldReportCopyWithImpl<$Res>
    implements _$FieldReportCopyWith<$Res> {
  __$FieldReportCopyWithImpl(this._self, this._then);

  final _FieldReport _self;
  final $Res Function(_FieldReport) _then;

/// Create a copy of FieldReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = freezed,Object? incidentType = freezed,Object? severity = freezed,Object? status = freezed,Object? description = freezed,Object? stateCode = freezed,Object? districtCode = freezed,Object? segmentId = freezed,Object? roadCode = freezed,Object? reporterId = freezed,Object? reporterName = freezed,Object? reportedAt = freezed,Object? validatedAt = freezed,Object? validatedBy = freezed,Object? confidence = freezed,Object? rejectReason = freezed,Object? source = freezed,Object? updatedAt = freezed,Object? locationName = freezed,Object? media = freezed,}) {
  return _then(_FieldReport(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,incidentType: freezed == incidentType ? _self.incidentType : incidentType // ignore: cast_nullable_to_non_nullable
as String?,severity: freezed == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,stateCode: freezed == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String?,districtCode: freezed == districtCode ? _self.districtCode : districtCode // ignore: cast_nullable_to_non_nullable
as String?,segmentId: freezed == segmentId ? _self.segmentId : segmentId // ignore: cast_nullable_to_non_nullable
as String?,roadCode: freezed == roadCode ? _self.roadCode : roadCode // ignore: cast_nullable_to_non_nullable
as String?,reporterId: freezed == reporterId ? _self.reporterId : reporterId // ignore: cast_nullable_to_non_nullable
as String?,reporterName: freezed == reporterName ? _self.reporterName : reporterName // ignore: cast_nullable_to_non_nullable
as String?,reportedAt: freezed == reportedAt ? _self.reportedAt : reportedAt // ignore: cast_nullable_to_non_nullable
as String?,validatedAt: freezed == validatedAt ? _self.validatedAt : validatedAt // ignore: cast_nullable_to_non_nullable
as String?,validatedBy: freezed == validatedBy ? _self.validatedBy : validatedBy // ignore: cast_nullable_to_non_nullable
as String?,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,rejectReason: freezed == rejectReason ? _self.rejectReason : rejectReason // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,locationName: freezed == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String?,media: freezed == media ? _self._media : media // ignore: cast_nullable_to_non_nullable
as List<FieldReportMedia>?,
  ));
}


}


/// @nodoc
mixin _$FieldReportMedia {

 String get id; String? get contentType; int? get byteSize; String? get sha256; String? get storagePath; bool? get deduplicated; String? get capturedAt; String? get uploadedAt; String? get localPath;
/// Create a copy of FieldReportMedia
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FieldReportMediaCopyWith<FieldReportMedia> get copyWith => _$FieldReportMediaCopyWithImpl<FieldReportMedia>(this as FieldReportMedia, _$identity);

  /// Serializes this FieldReportMedia to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FieldReportMedia;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FieldReportMedia&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.contentType, _this.contentType) || other.contentType == _this.contentType)&&(identical(other.byteSize, _this.byteSize) || other.byteSize == _this.byteSize)&&(identical(other.sha256, _this.sha256) || other.sha256 == _this.sha256)&&(identical(other.storagePath, _this.storagePath) || other.storagePath == _this.storagePath)&&(identical(other.deduplicated, _this.deduplicated) || other.deduplicated == _this.deduplicated)&&(identical(other.capturedAt, _this.capturedAt) || other.capturedAt == _this.capturedAt)&&(identical(other.uploadedAt, _this.uploadedAt) || other.uploadedAt == _this.uploadedAt)&&(identical(other.localPath, _this.localPath) || other.localPath == _this.localPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FieldReportMedia;
  return Object.hash(runtimeType,_this.id,_this.contentType,_this.byteSize,_this.sha256,_this.storagePath,_this.deduplicated,_this.capturedAt,_this.uploadedAt,_this.localPath);
}

@override
String toString() {
  final _this = this as FieldReportMedia;
  return 'FieldReportMedia(id: ${_this.id}, contentType: ${_this.contentType}, byteSize: ${_this.byteSize}, sha256: ${_this.sha256}, storagePath: ${_this.storagePath}, deduplicated: ${_this.deduplicated}, capturedAt: ${_this.capturedAt}, uploadedAt: ${_this.uploadedAt}, localPath: ${_this.localPath})';
}


}

/// @nodoc
abstract mixin class $FieldReportMediaCopyWith<$Res>  {
  factory $FieldReportMediaCopyWith(FieldReportMedia value, $Res Function(FieldReportMedia) _then) = _$FieldReportMediaCopyWithImpl;
@useResult
$Res call({
 String id, String? contentType, int? byteSize, String? sha256, String? storagePath, bool? deduplicated, String? capturedAt, String? uploadedAt, String? localPath
});




}
/// @nodoc
class _$FieldReportMediaCopyWithImpl<$Res>
    implements $FieldReportMediaCopyWith<$Res> {
  _$FieldReportMediaCopyWithImpl(this._self, this._then);

  final FieldReportMedia _self;
  final $Res Function(FieldReportMedia) _then;

/// Create a copy of FieldReportMedia
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? contentType = freezed,Object? byteSize = freezed,Object? sha256 = freezed,Object? storagePath = freezed,Object? deduplicated = freezed,Object? capturedAt = freezed,Object? uploadedAt = freezed,Object? localPath = freezed,}) {
  return _then(FieldReportMedia(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,contentType: freezed == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String?,byteSize: freezed == byteSize ? _self.byteSize : byteSize // ignore: cast_nullable_to_non_nullable
as int?,sha256: freezed == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String?,storagePath: freezed == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String?,deduplicated: freezed == deduplicated ? _self.deduplicated : deduplicated // ignore: cast_nullable_to_non_nullable
as bool?,capturedAt: freezed == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as String?,uploadedAt: freezed == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as String?,localPath: freezed == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FieldReportMedia].
extension FieldReportMediaPatterns on FieldReportMedia {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FieldReportMedia value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FieldReportMedia() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FieldReportMedia value)  $default,){
final _that = this;
switch (_that) {
case _FieldReportMedia():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FieldReportMedia value)?  $default,){
final _that = this;
switch (_that) {
case _FieldReportMedia() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? contentType,  int? byteSize,  String? sha256,  String? storagePath,  bool? deduplicated,  String? capturedAt,  String? uploadedAt,  String? localPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FieldReportMedia() when $default != null:
return $default(_that.id,_that.contentType,_that.byteSize,_that.sha256,_that.storagePath,_that.deduplicated,_that.capturedAt,_that.uploadedAt,_that.localPath);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? contentType,  int? byteSize,  String? sha256,  String? storagePath,  bool? deduplicated,  String? capturedAt,  String? uploadedAt,  String? localPath)  $default,) {final _that = this;
switch (_that) {
case _FieldReportMedia():
return $default(_that.id,_that.contentType,_that.byteSize,_that.sha256,_that.storagePath,_that.deduplicated,_that.capturedAt,_that.uploadedAt,_that.localPath);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? contentType,  int? byteSize,  String? sha256,  String? storagePath,  bool? deduplicated,  String? capturedAt,  String? uploadedAt,  String? localPath)?  $default,) {final _that = this;
switch (_that) {
case _FieldReportMedia() when $default != null:
return $default(_that.id,_that.contentType,_that.byteSize,_that.sha256,_that.storagePath,_that.deduplicated,_that.capturedAt,_that.uploadedAt,_that.localPath);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FieldReportMedia implements FieldReportMedia {
  const _FieldReportMedia({required this.id, this.contentType, this.byteSize, this.sha256, this.storagePath, this.deduplicated, this.capturedAt, this.uploadedAt, this.localPath});
  factory _FieldReportMedia.fromJson(Map<String, dynamic> json) => _$FieldReportMediaFromJson(json);

@override final  String id;
@override final  String? contentType;
@override final  int? byteSize;
@override final  String? sha256;
@override final  String? storagePath;
@override final  bool? deduplicated;
@override final  String? capturedAt;
@override final  String? uploadedAt;
@override final  String? localPath;

/// Create a copy of FieldReportMedia
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FieldReportMediaCopyWith<_FieldReportMedia> get copyWith => __$FieldReportMediaCopyWithImpl<_FieldReportMedia>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FieldReportMediaToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FieldReportMedia&&(identical(other.id, id) || other.id == id)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.byteSize, byteSize) || other.byteSize == byteSize)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.storagePath, storagePath) || other.storagePath == storagePath)&&(identical(other.deduplicated, deduplicated) || other.deduplicated == deduplicated)&&(identical(other.capturedAt, capturedAt) || other.capturedAt == capturedAt)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt)&&(identical(other.localPath, localPath) || other.localPath == localPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,contentType,byteSize,sha256,storagePath,deduplicated,capturedAt,uploadedAt,localPath);
}

@override
String toString() {
    return 'FieldReportMedia(id: $id, contentType: $contentType, byteSize: $byteSize, sha256: $sha256, storagePath: $storagePath, deduplicated: $deduplicated, capturedAt: $capturedAt, uploadedAt: $uploadedAt, localPath: $localPath)';
}


}

/// @nodoc
abstract mixin class _$FieldReportMediaCopyWith<$Res> implements $FieldReportMediaCopyWith<$Res> {
  factory _$FieldReportMediaCopyWith(_FieldReportMedia value, $Res Function(_FieldReportMedia) _then) = __$FieldReportMediaCopyWithImpl;
@override @useResult
$Res call({
 String id, String? contentType, int? byteSize, String? sha256, String? storagePath, bool? deduplicated, String? capturedAt, String? uploadedAt, String? localPath
});




}
/// @nodoc
class __$FieldReportMediaCopyWithImpl<$Res>
    implements _$FieldReportMediaCopyWith<$Res> {
  __$FieldReportMediaCopyWithImpl(this._self, this._then);

  final _FieldReportMedia _self;
  final $Res Function(_FieldReportMedia) _then;

/// Create a copy of FieldReportMedia
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? contentType = freezed,Object? byteSize = freezed,Object? sha256 = freezed,Object? storagePath = freezed,Object? deduplicated = freezed,Object? capturedAt = freezed,Object? uploadedAt = freezed,Object? localPath = freezed,}) {
  return _then(_FieldReportMedia(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,contentType: freezed == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String?,byteSize: freezed == byteSize ? _self.byteSize : byteSize // ignore: cast_nullable_to_non_nullable
as int?,sha256: freezed == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String?,storagePath: freezed == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String?,deduplicated: freezed == deduplicated ? _self.deduplicated : deduplicated // ignore: cast_nullable_to_non_nullable
as bool?,capturedAt: freezed == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as String?,uploadedAt: freezed == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as String?,localPath: freezed == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$DraftMediaRef {

 String get clientRefId; String get localPath; String? get contentType; int? get sizeBytes; String? get sha256; String? get capturedAt;
/// Create a copy of DraftMediaRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DraftMediaRefCopyWith<DraftMediaRef> get copyWith => _$DraftMediaRefCopyWithImpl<DraftMediaRef>(this as DraftMediaRef, _$identity);

  /// Serializes this DraftMediaRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DraftMediaRef;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftMediaRef&&(identical(other.clientRefId, _this.clientRefId) || other.clientRefId == _this.clientRefId)&&(identical(other.localPath, _this.localPath) || other.localPath == _this.localPath)&&(identical(other.contentType, _this.contentType) || other.contentType == _this.contentType)&&(identical(other.sizeBytes, _this.sizeBytes) || other.sizeBytes == _this.sizeBytes)&&(identical(other.sha256, _this.sha256) || other.sha256 == _this.sha256)&&(identical(other.capturedAt, _this.capturedAt) || other.capturedAt == _this.capturedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DraftMediaRef;
  return Object.hash(runtimeType,_this.clientRefId,_this.localPath,_this.contentType,_this.sizeBytes,_this.sha256,_this.capturedAt);
}

@override
String toString() {
  final _this = this as DraftMediaRef;
  return 'DraftMediaRef(clientRefId: ${_this.clientRefId}, localPath: ${_this.localPath}, contentType: ${_this.contentType}, sizeBytes: ${_this.sizeBytes}, sha256: ${_this.sha256}, capturedAt: ${_this.capturedAt})';
}


}

/// @nodoc
abstract mixin class $DraftMediaRefCopyWith<$Res>  {
  factory $DraftMediaRefCopyWith(DraftMediaRef value, $Res Function(DraftMediaRef) _then) = _$DraftMediaRefCopyWithImpl;
@useResult
$Res call({
 String clientRefId, String localPath, String? contentType, int? sizeBytes, String? sha256, String? capturedAt
});




}
/// @nodoc
class _$DraftMediaRefCopyWithImpl<$Res>
    implements $DraftMediaRefCopyWith<$Res> {
  _$DraftMediaRefCopyWithImpl(this._self, this._then);

  final DraftMediaRef _self;
  final $Res Function(DraftMediaRef) _then;

/// Create a copy of DraftMediaRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientRefId = null,Object? localPath = null,Object? contentType = freezed,Object? sizeBytes = freezed,Object? sha256 = freezed,Object? capturedAt = freezed,}) {
  return _then(DraftMediaRef(
clientRefId: null == clientRefId ? _self.clientRefId : clientRefId // ignore: cast_nullable_to_non_nullable
as String,localPath: null == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String,contentType: freezed == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,sha256: freezed == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String?,capturedAt: freezed == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DraftMediaRef].
extension DraftMediaRefPatterns on DraftMediaRef {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DraftMediaRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DraftMediaRef() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DraftMediaRef value)  $default,){
final _that = this;
switch (_that) {
case _DraftMediaRef():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DraftMediaRef value)?  $default,){
final _that = this;
switch (_that) {
case _DraftMediaRef() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientRefId,  String localPath,  String? contentType,  int? sizeBytes,  String? sha256,  String? capturedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DraftMediaRef() when $default != null:
return $default(_that.clientRefId,_that.localPath,_that.contentType,_that.sizeBytes,_that.sha256,_that.capturedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientRefId,  String localPath,  String? contentType,  int? sizeBytes,  String? sha256,  String? capturedAt)  $default,) {final _that = this;
switch (_that) {
case _DraftMediaRef():
return $default(_that.clientRefId,_that.localPath,_that.contentType,_that.sizeBytes,_that.sha256,_that.capturedAt);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientRefId,  String localPath,  String? contentType,  int? sizeBytes,  String? sha256,  String? capturedAt)?  $default,) {final _that = this;
switch (_that) {
case _DraftMediaRef() when $default != null:
return $default(_that.clientRefId,_that.localPath,_that.contentType,_that.sizeBytes,_that.sha256,_that.capturedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DraftMediaRef implements DraftMediaRef {
  const _DraftMediaRef({required this.clientRefId, required this.localPath, this.contentType, this.sizeBytes, this.sha256, this.capturedAt});
  factory _DraftMediaRef.fromJson(Map<String, dynamic> json) => _$DraftMediaRefFromJson(json);

@override final  String clientRefId;
@override final  String localPath;
@override final  String? contentType;
@override final  int? sizeBytes;
@override final  String? sha256;
@override final  String? capturedAt;

/// Create a copy of DraftMediaRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DraftMediaRefCopyWith<_DraftMediaRef> get copyWith => __$DraftMediaRefCopyWithImpl<_DraftMediaRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DraftMediaRefToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DraftMediaRef&&(identical(other.clientRefId, clientRefId) || other.clientRefId == clientRefId)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.capturedAt, capturedAt) || other.capturedAt == capturedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,clientRefId,localPath,contentType,sizeBytes,sha256,capturedAt);
}

@override
String toString() {
    return 'DraftMediaRef(clientRefId: $clientRefId, localPath: $localPath, contentType: $contentType, sizeBytes: $sizeBytes, sha256: $sha256, capturedAt: $capturedAt)';
}


}

/// @nodoc
abstract mixin class _$DraftMediaRefCopyWith<$Res> implements $DraftMediaRefCopyWith<$Res> {
  factory _$DraftMediaRefCopyWith(_DraftMediaRef value, $Res Function(_DraftMediaRef) _then) = __$DraftMediaRefCopyWithImpl;
@override @useResult
$Res call({
 String clientRefId, String localPath, String? contentType, int? sizeBytes, String? sha256, String? capturedAt
});




}
/// @nodoc
class __$DraftMediaRefCopyWithImpl<$Res>
    implements _$DraftMediaRefCopyWith<$Res> {
  __$DraftMediaRefCopyWithImpl(this._self, this._then);

  final _DraftMediaRef _self;
  final $Res Function(_DraftMediaRef) _then;

/// Create a copy of DraftMediaRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientRefId = null,Object? localPath = null,Object? contentType = freezed,Object? sizeBytes = freezed,Object? sha256 = freezed,Object? capturedAt = freezed,}) {
  return _then(_DraftMediaRef(
clientRefId: null == clientRefId ? _self.clientRefId : clientRefId // ignore: cast_nullable_to_non_nullable
as String,localPath: null == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String,contentType: freezed == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,sha256: freezed == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String?,capturedAt: freezed == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$FieldReportDraft {

 String get clientDraftId; String? get incidentType; String? get severity; String? get description; String? get stateCode; String? get districtCode; String? get segmentId; String? get roadCode; String? get locationName; double? get lon; double? get lat; String? get createdAt; String? get updatedAt; List<String> get mediaPaths;/// Phase 2 — structured media refs (id + path + MIME + size + sha256).
/// Preferred over the raw `mediaPaths` list for new code; the legacy
/// list is kept for backwards compatibility with any code that still
/// reads the raw paths.
 List<DraftMediaRef> get mediaRefs;
/// Create a copy of FieldReportDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FieldReportDraftCopyWith<FieldReportDraft> get copyWith => _$FieldReportDraftCopyWithImpl<FieldReportDraft>(this as FieldReportDraft, _$identity);

  /// Serializes this FieldReportDraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FieldReportDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FieldReportDraft&&(identical(other.clientDraftId, _this.clientDraftId) || other.clientDraftId == _this.clientDraftId)&&(identical(other.incidentType, _this.incidentType) || other.incidentType == _this.incidentType)&&(identical(other.severity, _this.severity) || other.severity == _this.severity)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.stateCode, _this.stateCode) || other.stateCode == _this.stateCode)&&(identical(other.districtCode, _this.districtCode) || other.districtCode == _this.districtCode)&&(identical(other.segmentId, _this.segmentId) || other.segmentId == _this.segmentId)&&(identical(other.roadCode, _this.roadCode) || other.roadCode == _this.roadCode)&&(identical(other.locationName, _this.locationName) || other.locationName == _this.locationName)&&(identical(other.lon, _this.lon) || other.lon == _this.lon)&&(identical(other.lat, _this.lat) || other.lat == _this.lat)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&const DeepCollectionEquality().equals(other.mediaPaths, _this.mediaPaths)&&const DeepCollectionEquality().equals(other.mediaRefs, _this.mediaRefs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FieldReportDraft;
  return Object.hash(runtimeType,_this.clientDraftId,_this.incidentType,_this.severity,_this.description,_this.stateCode,_this.districtCode,_this.segmentId,_this.roadCode,_this.locationName,_this.lon,_this.lat,_this.createdAt,_this.updatedAt,const DeepCollectionEquality().hash(_this.mediaPaths),const DeepCollectionEquality().hash(_this.mediaRefs));
}

@override
String toString() {
  final _this = this as FieldReportDraft;
  return 'FieldReportDraft(clientDraftId: ${_this.clientDraftId}, incidentType: ${_this.incidentType}, severity: ${_this.severity}, description: ${_this.description}, stateCode: ${_this.stateCode}, districtCode: ${_this.districtCode}, segmentId: ${_this.segmentId}, roadCode: ${_this.roadCode}, locationName: ${_this.locationName}, lon: ${_this.lon}, lat: ${_this.lat}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, mediaPaths: ${_this.mediaPaths}, mediaRefs: ${_this.mediaRefs})';
}


}

/// @nodoc
abstract mixin class $FieldReportDraftCopyWith<$Res>  {
  factory $FieldReportDraftCopyWith(FieldReportDraft value, $Res Function(FieldReportDraft) _then) = _$FieldReportDraftCopyWithImpl;
@useResult
$Res call({
 String clientDraftId, String? incidentType, String? severity, String? description, String? stateCode, String? districtCode, String? segmentId, String? roadCode, String? locationName, double? lon, double? lat, String? createdAt, String? updatedAt, List<String> mediaPaths, List<DraftMediaRef> mediaRefs
});




}
/// @nodoc
class _$FieldReportDraftCopyWithImpl<$Res>
    implements $FieldReportDraftCopyWith<$Res> {
  _$FieldReportDraftCopyWithImpl(this._self, this._then);

  final FieldReportDraft _self;
  final $Res Function(FieldReportDraft) _then;

/// Create a copy of FieldReportDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientDraftId = null,Object? incidentType = freezed,Object? severity = freezed,Object? description = freezed,Object? stateCode = freezed,Object? districtCode = freezed,Object? segmentId = freezed,Object? roadCode = freezed,Object? locationName = freezed,Object? lon = freezed,Object? lat = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? mediaPaths = null,Object? mediaRefs = null,}) {
  return _then(FieldReportDraft(
clientDraftId: null == clientDraftId ? _self.clientDraftId : clientDraftId // ignore: cast_nullable_to_non_nullable
as String,incidentType: freezed == incidentType ? _self.incidentType : incidentType // ignore: cast_nullable_to_non_nullable
as String?,severity: freezed == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,stateCode: freezed == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String?,districtCode: freezed == districtCode ? _self.districtCode : districtCode // ignore: cast_nullable_to_non_nullable
as String?,segmentId: freezed == segmentId ? _self.segmentId : segmentId // ignore: cast_nullable_to_non_nullable
as String?,roadCode: freezed == roadCode ? _self.roadCode : roadCode // ignore: cast_nullable_to_non_nullable
as String?,locationName: freezed == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String?,lon: freezed == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,mediaPaths: null == mediaPaths ? _self.mediaPaths : mediaPaths // ignore: cast_nullable_to_non_nullable
as List<String>,mediaRefs: null == mediaRefs ? _self.mediaRefs : mediaRefs // ignore: cast_nullable_to_non_nullable
as List<DraftMediaRef>,
  ));
}

}


/// Adds pattern-matching-related methods to [FieldReportDraft].
extension FieldReportDraftPatterns on FieldReportDraft {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FieldReportDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FieldReportDraft() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FieldReportDraft value)  $default,){
final _that = this;
switch (_that) {
case _FieldReportDraft():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FieldReportDraft value)?  $default,){
final _that = this;
switch (_that) {
case _FieldReportDraft() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientDraftId,  String? incidentType,  String? severity,  String? description,  String? stateCode,  String? districtCode,  String? segmentId,  String? roadCode,  String? locationName,  double? lon,  double? lat,  String? createdAt,  String? updatedAt,  List<String> mediaPaths,  List<DraftMediaRef> mediaRefs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FieldReportDraft() when $default != null:
return $default(_that.clientDraftId,_that.incidentType,_that.severity,_that.description,_that.stateCode,_that.districtCode,_that.segmentId,_that.roadCode,_that.locationName,_that.lon,_that.lat,_that.createdAt,_that.updatedAt,_that.mediaPaths,_that.mediaRefs);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientDraftId,  String? incidentType,  String? severity,  String? description,  String? stateCode,  String? districtCode,  String? segmentId,  String? roadCode,  String? locationName,  double? lon,  double? lat,  String? createdAt,  String? updatedAt,  List<String> mediaPaths,  List<DraftMediaRef> mediaRefs)  $default,) {final _that = this;
switch (_that) {
case _FieldReportDraft():
return $default(_that.clientDraftId,_that.incidentType,_that.severity,_that.description,_that.stateCode,_that.districtCode,_that.segmentId,_that.roadCode,_that.locationName,_that.lon,_that.lat,_that.createdAt,_that.updatedAt,_that.mediaPaths,_that.mediaRefs);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientDraftId,  String? incidentType,  String? severity,  String? description,  String? stateCode,  String? districtCode,  String? segmentId,  String? roadCode,  String? locationName,  double? lon,  double? lat,  String? createdAt,  String? updatedAt,  List<String> mediaPaths,  List<DraftMediaRef> mediaRefs)?  $default,) {final _that = this;
switch (_that) {
case _FieldReportDraft() when $default != null:
return $default(_that.clientDraftId,_that.incidentType,_that.severity,_that.description,_that.stateCode,_that.districtCode,_that.segmentId,_that.roadCode,_that.locationName,_that.lon,_that.lat,_that.createdAt,_that.updatedAt,_that.mediaPaths,_that.mediaRefs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FieldReportDraft extends FieldReportDraft {
  const _FieldReportDraft({required this.clientDraftId, this.incidentType, this.severity, this.description, this.stateCode, this.districtCode, this.segmentId, this.roadCode, this.locationName, this.lon, this.lat, this.createdAt, this.updatedAt,  List<String> mediaPaths = const <String>[],  List<DraftMediaRef> mediaRefs = const <DraftMediaRef>[]}): _mediaPaths = mediaPaths,_mediaRefs = mediaRefs,super._();
  factory _FieldReportDraft.fromJson(Map<String, dynamic> json) => _$FieldReportDraftFromJson(json);

@override final  String clientDraftId;
@override final  String? incidentType;
@override final  String? severity;
@override final  String? description;
@override final  String? stateCode;
@override final  String? districtCode;
@override final  String? segmentId;
@override final  String? roadCode;
@override final  String? locationName;
@override final  double? lon;
@override final  double? lat;
@override final  String? createdAt;
@override final  String? updatedAt;
 final  List<String> _mediaPaths;
@override@JsonKey() List<String> get mediaPaths {
  if (_mediaPaths is EqualUnmodifiableListView) return _mediaPaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mediaPaths);
}

/// Phase 2 — structured media refs (id + path + MIME + size + sha256).
/// Preferred over the raw `mediaPaths` list for new code; the legacy
/// list is kept for backwards compatibility with any code that still
/// reads the raw paths.
 final  List<DraftMediaRef> _mediaRefs;
/// Phase 2 — structured media refs (id + path + MIME + size + sha256).
/// Preferred over the raw `mediaPaths` list for new code; the legacy
/// list is kept for backwards compatibility with any code that still
/// reads the raw paths.
@override@JsonKey() List<DraftMediaRef> get mediaRefs {
  if (_mediaRefs is EqualUnmodifiableListView) return _mediaRefs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mediaRefs);
}


/// Create a copy of FieldReportDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FieldReportDraftCopyWith<_FieldReportDraft> get copyWith => __$FieldReportDraftCopyWithImpl<_FieldReportDraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FieldReportDraftToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FieldReportDraft&&(identical(other.clientDraftId, clientDraftId) || other.clientDraftId == clientDraftId)&&(identical(other.incidentType, incidentType) || other.incidentType == incidentType)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.description, description) || other.description == description)&&(identical(other.stateCode, stateCode) || other.stateCode == stateCode)&&(identical(other.districtCode, districtCode) || other.districtCode == districtCode)&&(identical(other.segmentId, segmentId) || other.segmentId == segmentId)&&(identical(other.roadCode, roadCode) || other.roadCode == roadCode)&&(identical(other.locationName, locationName) || other.locationName == locationName)&&(identical(other.lon, lon) || other.lon == lon)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.mediaPaths, _mediaPaths)&&const DeepCollectionEquality().equals(other.mediaRefs, _mediaRefs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,clientDraftId,incidentType,severity,description,stateCode,districtCode,segmentId,roadCode,locationName,lon,lat,createdAt,updatedAt,const DeepCollectionEquality().hash(_mediaPaths),const DeepCollectionEquality().hash(_mediaRefs));
}

@override
String toString() {
    return 'FieldReportDraft(clientDraftId: $clientDraftId, incidentType: $incidentType, severity: $severity, description: $description, stateCode: $stateCode, districtCode: $districtCode, segmentId: $segmentId, roadCode: $roadCode, locationName: $locationName, lon: $lon, lat: $lat, createdAt: $createdAt, updatedAt: $updatedAt, mediaPaths: $mediaPaths, mediaRefs: $mediaRefs)';
}


}

/// @nodoc
abstract mixin class _$FieldReportDraftCopyWith<$Res> implements $FieldReportDraftCopyWith<$Res> {
  factory _$FieldReportDraftCopyWith(_FieldReportDraft value, $Res Function(_FieldReportDraft) _then) = __$FieldReportDraftCopyWithImpl;
@override @useResult
$Res call({
 String clientDraftId, String? incidentType, String? severity, String? description, String? stateCode, String? districtCode, String? segmentId, String? roadCode, String? locationName, double? lon, double? lat, String? createdAt, String? updatedAt, List<String> mediaPaths, List<DraftMediaRef> mediaRefs
});




}
/// @nodoc
class __$FieldReportDraftCopyWithImpl<$Res>
    implements _$FieldReportDraftCopyWith<$Res> {
  __$FieldReportDraftCopyWithImpl(this._self, this._then);

  final _FieldReportDraft _self;
  final $Res Function(_FieldReportDraft) _then;

/// Create a copy of FieldReportDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientDraftId = null,Object? incidentType = freezed,Object? severity = freezed,Object? description = freezed,Object? stateCode = freezed,Object? districtCode = freezed,Object? segmentId = freezed,Object? roadCode = freezed,Object? locationName = freezed,Object? lon = freezed,Object? lat = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? mediaPaths = null,Object? mediaRefs = null,}) {
  return _then(_FieldReportDraft(
clientDraftId: null == clientDraftId ? _self.clientDraftId : clientDraftId // ignore: cast_nullable_to_non_nullable
as String,incidentType: freezed == incidentType ? _self.incidentType : incidentType // ignore: cast_nullable_to_non_nullable
as String?,severity: freezed == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,stateCode: freezed == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String?,districtCode: freezed == districtCode ? _self.districtCode : districtCode // ignore: cast_nullable_to_non_nullable
as String?,segmentId: freezed == segmentId ? _self.segmentId : segmentId // ignore: cast_nullable_to_non_nullable
as String?,roadCode: freezed == roadCode ? _self.roadCode : roadCode // ignore: cast_nullable_to_non_nullable
as String?,locationName: freezed == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String?,lon: freezed == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,mediaPaths: null == mediaPaths ? _self._mediaPaths : mediaPaths // ignore: cast_nullable_to_non_nullable
as List<String>,mediaRefs: null == mediaRefs ? _self._mediaRefs : mediaRefs // ignore: cast_nullable_to_non_nullable
as List<DraftMediaRef>,
  ));
}


}

// dart format on
