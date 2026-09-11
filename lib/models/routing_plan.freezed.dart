// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'routing_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RoutePlanRequest {

 RouteEndpoint get origin; RouteEndpoint get destination; String? get priority; double? get riskAversion; int? get k; String? get mode;@JsonKey(name: 'avoid_segment_ids') List<String>? get avoidSegmentIds;
/// Create a copy of RoutePlanRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoutePlanRequestCopyWith<RoutePlanRequest> get copyWith => _$RoutePlanRequestCopyWithImpl<RoutePlanRequest>(this as RoutePlanRequest, _$identity);

  /// Serializes this RoutePlanRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RoutePlanRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutePlanRequest&&(identical(other.origin, _this.origin) || other.origin == _this.origin)&&(identical(other.destination, _this.destination) || other.destination == _this.destination)&&(identical(other.priority, _this.priority) || other.priority == _this.priority)&&(identical(other.riskAversion, _this.riskAversion) || other.riskAversion == _this.riskAversion)&&(identical(other.k, _this.k) || other.k == _this.k)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&const DeepCollectionEquality().equals(other.avoidSegmentIds, _this.avoidSegmentIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RoutePlanRequest;
  return Object.hash(runtimeType,_this.origin,_this.destination,_this.priority,_this.riskAversion,_this.k,_this.mode,const DeepCollectionEquality().hash(_this.avoidSegmentIds));
}

@override
String toString() {
  final _this = this as RoutePlanRequest;
  return 'RoutePlanRequest(origin: ${_this.origin}, destination: ${_this.destination}, priority: ${_this.priority}, riskAversion: ${_this.riskAversion}, k: ${_this.k}, mode: ${_this.mode}, avoidSegmentIds: ${_this.avoidSegmentIds})';
}


}

/// @nodoc
abstract mixin class $RoutePlanRequestCopyWith<$Res>  {
  factory $RoutePlanRequestCopyWith(RoutePlanRequest value, $Res Function(RoutePlanRequest) _then) = _$RoutePlanRequestCopyWithImpl;
@useResult
$Res call({
 RouteEndpoint origin, RouteEndpoint destination, String? priority, double? riskAversion, int? k, String? mode,@JsonKey(name: 'avoid_segment_ids') List<String>? avoidSegmentIds
});


$RouteEndpointCopyWith<$Res> get origin;$RouteEndpointCopyWith<$Res> get destination;

}
/// @nodoc
class _$RoutePlanRequestCopyWithImpl<$Res>
    implements $RoutePlanRequestCopyWith<$Res> {
  _$RoutePlanRequestCopyWithImpl(this._self, this._then);

  final RoutePlanRequest _self;
  final $Res Function(RoutePlanRequest) _then;

/// Create a copy of RoutePlanRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? origin = null,Object? destination = null,Object? priority = freezed,Object? riskAversion = freezed,Object? k = freezed,Object? mode = freezed,Object? avoidSegmentIds = freezed,}) {
  return _then(RoutePlanRequest(
origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as RouteEndpoint,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as RouteEndpoint,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String?,riskAversion: freezed == riskAversion ? _self.riskAversion : riskAversion // ignore: cast_nullable_to_non_nullable
as double?,k: freezed == k ? _self.k : k // ignore: cast_nullable_to_non_nullable
as int?,mode: freezed == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String?,avoidSegmentIds: freezed == avoidSegmentIds ? _self.avoidSegmentIds : avoidSegmentIds // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}
/// Create a copy of RoutePlanRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RouteEndpointCopyWith<$Res> get origin {
  
  return $RouteEndpointCopyWith<$Res>(_self.origin, (value) {
    return _then(_self.copyWith(origin: value));
  });
}/// Create a copy of RoutePlanRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RouteEndpointCopyWith<$Res> get destination {
  
  return $RouteEndpointCopyWith<$Res>(_self.destination, (value) {
    return _then(_self.copyWith(destination: value));
  });
}
}


/// Adds pattern-matching-related methods to [RoutePlanRequest].
extension RoutePlanRequestPatterns on RoutePlanRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoutePlanRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoutePlanRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoutePlanRequest value)  $default,){
final _that = this;
switch (_that) {
case _RoutePlanRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoutePlanRequest value)?  $default,){
final _that = this;
switch (_that) {
case _RoutePlanRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RouteEndpoint origin,  RouteEndpoint destination,  String? priority,  double? riskAversion,  int? k,  String? mode, @JsonKey(name: 'avoid_segment_ids')  List<String>? avoidSegmentIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoutePlanRequest() when $default != null:
return $default(_that.origin,_that.destination,_that.priority,_that.riskAversion,_that.k,_that.mode,_that.avoidSegmentIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RouteEndpoint origin,  RouteEndpoint destination,  String? priority,  double? riskAversion,  int? k,  String? mode, @JsonKey(name: 'avoid_segment_ids')  List<String>? avoidSegmentIds)  $default,) {final _that = this;
switch (_that) {
case _RoutePlanRequest():
return $default(_that.origin,_that.destination,_that.priority,_that.riskAversion,_that.k,_that.mode,_that.avoidSegmentIds);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RouteEndpoint origin,  RouteEndpoint destination,  String? priority,  double? riskAversion,  int? k,  String? mode, @JsonKey(name: 'avoid_segment_ids')  List<String>? avoidSegmentIds)?  $default,) {final _that = this;
switch (_that) {
case _RoutePlanRequest() when $default != null:
return $default(_that.origin,_that.destination,_that.priority,_that.riskAversion,_that.k,_that.mode,_that.avoidSegmentIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoutePlanRequest implements RoutePlanRequest {
  const _RoutePlanRequest({required this.origin, required this.destination, this.priority, this.riskAversion, this.k, this.mode, @JsonKey(name: 'avoid_segment_ids')  List<String>? avoidSegmentIds}): _avoidSegmentIds = avoidSegmentIds;
  factory _RoutePlanRequest.fromJson(Map<String, dynamic> json) => _$RoutePlanRequestFromJson(json);

@override final  RouteEndpoint origin;
@override final  RouteEndpoint destination;
@override final  String? priority;
@override final  double? riskAversion;
@override final  int? k;
@override final  String? mode;
 final  List<String>? _avoidSegmentIds;
@override@JsonKey(name: 'avoid_segment_ids') List<String>? get avoidSegmentIds {
  final value = _avoidSegmentIds;
  if (value == null) return null;
  if (_avoidSegmentIds is EqualUnmodifiableListView) return _avoidSegmentIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of RoutePlanRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoutePlanRequestCopyWith<_RoutePlanRequest> get copyWith => __$RoutePlanRequestCopyWithImpl<_RoutePlanRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoutePlanRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoutePlanRequest&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.riskAversion, riskAversion) || other.riskAversion == riskAversion)&&(identical(other.k, k) || other.k == k)&&(identical(other.mode, mode) || other.mode == mode)&&const DeepCollectionEquality().equals(other.avoidSegmentIds, _avoidSegmentIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,origin,destination,priority,riskAversion,k,mode,const DeepCollectionEquality().hash(_avoidSegmentIds));
}

@override
String toString() {
    return 'RoutePlanRequest(origin: $origin, destination: $destination, priority: $priority, riskAversion: $riskAversion, k: $k, mode: $mode, avoidSegmentIds: $avoidSegmentIds)';
}


}

/// @nodoc
abstract mixin class _$RoutePlanRequestCopyWith<$Res> implements $RoutePlanRequestCopyWith<$Res> {
  factory _$RoutePlanRequestCopyWith(_RoutePlanRequest value, $Res Function(_RoutePlanRequest) _then) = __$RoutePlanRequestCopyWithImpl;
@override @useResult
$Res call({
 RouteEndpoint origin, RouteEndpoint destination, String? priority, double? riskAversion, int? k, String? mode,@JsonKey(name: 'avoid_segment_ids') List<String>? avoidSegmentIds
});


@override $RouteEndpointCopyWith<$Res> get origin;@override $RouteEndpointCopyWith<$Res> get destination;

}
/// @nodoc
class __$RoutePlanRequestCopyWithImpl<$Res>
    implements _$RoutePlanRequestCopyWith<$Res> {
  __$RoutePlanRequestCopyWithImpl(this._self, this._then);

  final _RoutePlanRequest _self;
  final $Res Function(_RoutePlanRequest) _then;

/// Create a copy of RoutePlanRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? origin = null,Object? destination = null,Object? priority = freezed,Object? riskAversion = freezed,Object? k = freezed,Object? mode = freezed,Object? avoidSegmentIds = freezed,}) {
  return _then(_RoutePlanRequest(
origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as RouteEndpoint,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as RouteEndpoint,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String?,riskAversion: freezed == riskAversion ? _self.riskAversion : riskAversion // ignore: cast_nullable_to_non_nullable
as double?,k: freezed == k ? _self.k : k // ignore: cast_nullable_to_non_nullable
as int?,mode: freezed == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String?,avoidSegmentIds: freezed == avoidSegmentIds ? _self._avoidSegmentIds : avoidSegmentIds // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

/// Create a copy of RoutePlanRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RouteEndpointCopyWith<$Res> get origin {
  
  return $RouteEndpointCopyWith<$Res>(_self.origin, (value) {
    return _then(_self.copyWith(origin: value));
  });
}/// Create a copy of RoutePlanRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RouteEndpointCopyWith<$Res> get destination {
  
  return $RouteEndpointCopyWith<$Res>(_self.destination, (value) {
    return _then(_self.copyWith(destination: value));
  });
}
}


/// @nodoc
mixin _$RouteEndpoint {

 String? get facilityCode; double? get lon; double? get lat;
/// Create a copy of RouteEndpoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteEndpointCopyWith<RouteEndpoint> get copyWith => _$RouteEndpointCopyWithImpl<RouteEndpoint>(this as RouteEndpoint, _$identity);

  /// Serializes this RouteEndpoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RouteEndpoint;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteEndpoint&&(identical(other.facilityCode, _this.facilityCode) || other.facilityCode == _this.facilityCode)&&(identical(other.lon, _this.lon) || other.lon == _this.lon)&&(identical(other.lat, _this.lat) || other.lat == _this.lat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RouteEndpoint;
  return Object.hash(runtimeType,_this.facilityCode,_this.lon,_this.lat);
}

@override
String toString() {
  final _this = this as RouteEndpoint;
  return 'RouteEndpoint(facilityCode: ${_this.facilityCode}, lon: ${_this.lon}, lat: ${_this.lat})';
}


}

/// @nodoc
abstract mixin class $RouteEndpointCopyWith<$Res>  {
  factory $RouteEndpointCopyWith(RouteEndpoint value, $Res Function(RouteEndpoint) _then) = _$RouteEndpointCopyWithImpl;
@useResult
$Res call({
 String? facilityCode, double? lon, double? lat
});




}
/// @nodoc
class _$RouteEndpointCopyWithImpl<$Res>
    implements $RouteEndpointCopyWith<$Res> {
  _$RouteEndpointCopyWithImpl(this._self, this._then);

  final RouteEndpoint _self;
  final $Res Function(RouteEndpoint) _then;

/// Create a copy of RouteEndpoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? facilityCode = freezed,Object? lon = freezed,Object? lat = freezed,}) {
  return _then(RouteEndpoint(
facilityCode: freezed == facilityCode ? _self.facilityCode : facilityCode // ignore: cast_nullable_to_non_nullable
as String?,lon: freezed == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteEndpoint].
extension RouteEndpointPatterns on RouteEndpoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteEndpoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteEndpoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteEndpoint value)  $default,){
final _that = this;
switch (_that) {
case _RouteEndpoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteEndpoint value)?  $default,){
final _that = this;
switch (_that) {
case _RouteEndpoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? facilityCode,  double? lon,  double? lat)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteEndpoint() when $default != null:
return $default(_that.facilityCode,_that.lon,_that.lat);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? facilityCode,  double? lon,  double? lat)  $default,) {final _that = this;
switch (_that) {
case _RouteEndpoint():
return $default(_that.facilityCode,_that.lon,_that.lat);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? facilityCode,  double? lon,  double? lat)?  $default,) {final _that = this;
switch (_that) {
case _RouteEndpoint() when $default != null:
return $default(_that.facilityCode,_that.lon,_that.lat);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RouteEndpoint extends RouteEndpoint {
  const _RouteEndpoint({this.facilityCode, this.lon, this.lat}): super._();
  factory _RouteEndpoint.fromJson(Map<String, dynamic> json) => _$RouteEndpointFromJson(json);

@override final  String? facilityCode;
@override final  double? lon;
@override final  double? lat;

/// Create a copy of RouteEndpoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteEndpointCopyWith<_RouteEndpoint> get copyWith => __$RouteEndpointCopyWithImpl<_RouteEndpoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RouteEndpointToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteEndpoint&&(identical(other.facilityCode, facilityCode) || other.facilityCode == facilityCode)&&(identical(other.lon, lon) || other.lon == lon)&&(identical(other.lat, lat) || other.lat == lat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,facilityCode,lon,lat);
}

@override
String toString() {
    return 'RouteEndpoint(facilityCode: $facilityCode, lon: $lon, lat: $lat)';
}


}

/// @nodoc
abstract mixin class _$RouteEndpointCopyWith<$Res> implements $RouteEndpointCopyWith<$Res> {
  factory _$RouteEndpointCopyWith(_RouteEndpoint value, $Res Function(_RouteEndpoint) _then) = __$RouteEndpointCopyWithImpl;
@override @useResult
$Res call({
 String? facilityCode, double? lon, double? lat
});




}
/// @nodoc
class __$RouteEndpointCopyWithImpl<$Res>
    implements _$RouteEndpointCopyWith<$Res> {
  __$RouteEndpointCopyWithImpl(this._self, this._then);

  final _RouteEndpoint _self;
  final $Res Function(_RouteEndpoint) _then;

/// Create a copy of RouteEndpoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? facilityCode = freezed,Object? lon = freezed,Object? lat = freezed,}) {
  return _then(_RouteEndpoint(
facilityCode: freezed == facilityCode ? _self.facilityCode : facilityCode // ignore: cast_nullable_to_non_nullable
as String?,lon: freezed == lon ? _self.lon : lon // ignore: cast_nullable_to_non_nullable
as double?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$PlannedRoute {

 int get rank; String? get mode;@JsonKey(name: 'segments') List<Map<String, dynamic>> get segments;@JsonKey(name: 'total_distance_km') double? get totalDistanceKm;@JsonKey(name: 'total_eta_minutes') double? get totalEtaMinutes;@JsonKey(name: 'aggregate_risk') double? get aggregateRisk;@JsonKey(name: 'aggregate_risk_label') String? get aggregateRiskLabel; String? get narrative;
/// Create a copy of PlannedRoute
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlannedRouteCopyWith<PlannedRoute> get copyWith => _$PlannedRouteCopyWithImpl<PlannedRoute>(this as PlannedRoute, _$identity);

  /// Serializes this PlannedRoute to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlannedRoute;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlannedRoute&&(identical(other.rank, _this.rank) || other.rank == _this.rank)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&const DeepCollectionEquality().equals(other.segments, _this.segments)&&(identical(other.totalDistanceKm, _this.totalDistanceKm) || other.totalDistanceKm == _this.totalDistanceKm)&&(identical(other.totalEtaMinutes, _this.totalEtaMinutes) || other.totalEtaMinutes == _this.totalEtaMinutes)&&(identical(other.aggregateRisk, _this.aggregateRisk) || other.aggregateRisk == _this.aggregateRisk)&&(identical(other.aggregateRiskLabel, _this.aggregateRiskLabel) || other.aggregateRiskLabel == _this.aggregateRiskLabel)&&(identical(other.narrative, _this.narrative) || other.narrative == _this.narrative));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlannedRoute;
  return Object.hash(runtimeType,_this.rank,_this.mode,const DeepCollectionEquality().hash(_this.segments),_this.totalDistanceKm,_this.totalEtaMinutes,_this.aggregateRisk,_this.aggregateRiskLabel,_this.narrative);
}

@override
String toString() {
  final _this = this as PlannedRoute;
  return 'PlannedRoute(rank: ${_this.rank}, mode: ${_this.mode}, segments: ${_this.segments}, totalDistanceKm: ${_this.totalDistanceKm}, totalEtaMinutes: ${_this.totalEtaMinutes}, aggregateRisk: ${_this.aggregateRisk}, aggregateRiskLabel: ${_this.aggregateRiskLabel}, narrative: ${_this.narrative})';
}


}

/// @nodoc
abstract mixin class $PlannedRouteCopyWith<$Res>  {
  factory $PlannedRouteCopyWith(PlannedRoute value, $Res Function(PlannedRoute) _then) = _$PlannedRouteCopyWithImpl;
@useResult
$Res call({
 int rank, String? mode,@JsonKey(name: 'segments') List<Map<String, dynamic>> segments,@JsonKey(name: 'total_distance_km') double? totalDistanceKm,@JsonKey(name: 'total_eta_minutes') double? totalEtaMinutes,@JsonKey(name: 'aggregate_risk') double? aggregateRisk,@JsonKey(name: 'aggregate_risk_label') String? aggregateRiskLabel, String? narrative
});




}
/// @nodoc
class _$PlannedRouteCopyWithImpl<$Res>
    implements $PlannedRouteCopyWith<$Res> {
  _$PlannedRouteCopyWithImpl(this._self, this._then);

  final PlannedRoute _self;
  final $Res Function(PlannedRoute) _then;

/// Create a copy of PlannedRoute
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rank = null,Object? mode = freezed,Object? segments = null,Object? totalDistanceKm = freezed,Object? totalEtaMinutes = freezed,Object? aggregateRisk = freezed,Object? aggregateRiskLabel = freezed,Object? narrative = freezed,}) {
  return _then(PlannedRoute(
rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,mode: freezed == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String?,segments: null == segments ? _self.segments : segments // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,totalDistanceKm: freezed == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double?,totalEtaMinutes: freezed == totalEtaMinutes ? _self.totalEtaMinutes : totalEtaMinutes // ignore: cast_nullable_to_non_nullable
as double?,aggregateRisk: freezed == aggregateRisk ? _self.aggregateRisk : aggregateRisk // ignore: cast_nullable_to_non_nullable
as double?,aggregateRiskLabel: freezed == aggregateRiskLabel ? _self.aggregateRiskLabel : aggregateRiskLabel // ignore: cast_nullable_to_non_nullable
as String?,narrative: freezed == narrative ? _self.narrative : narrative // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlannedRoute].
extension PlannedRoutePatterns on PlannedRoute {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlannedRoute value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlannedRoute() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlannedRoute value)  $default,){
final _that = this;
switch (_that) {
case _PlannedRoute():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlannedRoute value)?  $default,){
final _that = this;
switch (_that) {
case _PlannedRoute() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rank,  String? mode, @JsonKey(name: 'segments')  List<Map<String, dynamic>> segments, @JsonKey(name: 'total_distance_km')  double? totalDistanceKm, @JsonKey(name: 'total_eta_minutes')  double? totalEtaMinutes, @JsonKey(name: 'aggregate_risk')  double? aggregateRisk, @JsonKey(name: 'aggregate_risk_label')  String? aggregateRiskLabel,  String? narrative)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlannedRoute() when $default != null:
return $default(_that.rank,_that.mode,_that.segments,_that.totalDistanceKm,_that.totalEtaMinutes,_that.aggregateRisk,_that.aggregateRiskLabel,_that.narrative);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rank,  String? mode, @JsonKey(name: 'segments')  List<Map<String, dynamic>> segments, @JsonKey(name: 'total_distance_km')  double? totalDistanceKm, @JsonKey(name: 'total_eta_minutes')  double? totalEtaMinutes, @JsonKey(name: 'aggregate_risk')  double? aggregateRisk, @JsonKey(name: 'aggregate_risk_label')  String? aggregateRiskLabel,  String? narrative)  $default,) {final _that = this;
switch (_that) {
case _PlannedRoute():
return $default(_that.rank,_that.mode,_that.segments,_that.totalDistanceKm,_that.totalEtaMinutes,_that.aggregateRisk,_that.aggregateRiskLabel,_that.narrative);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rank,  String? mode, @JsonKey(name: 'segments')  List<Map<String, dynamic>> segments, @JsonKey(name: 'total_distance_km')  double? totalDistanceKm, @JsonKey(name: 'total_eta_minutes')  double? totalEtaMinutes, @JsonKey(name: 'aggregate_risk')  double? aggregateRisk, @JsonKey(name: 'aggregate_risk_label')  String? aggregateRiskLabel,  String? narrative)?  $default,) {final _that = this;
switch (_that) {
case _PlannedRoute() when $default != null:
return $default(_that.rank,_that.mode,_that.segments,_that.totalDistanceKm,_that.totalEtaMinutes,_that.aggregateRisk,_that.aggregateRiskLabel,_that.narrative);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlannedRoute extends PlannedRoute {
  const _PlannedRoute({required this.rank, this.mode, @JsonKey(name: 'segments')  List<Map<String, dynamic>> segments = const <Map<String, dynamic>>[], @JsonKey(name: 'total_distance_km') this.totalDistanceKm, @JsonKey(name: 'total_eta_minutes') this.totalEtaMinutes, @JsonKey(name: 'aggregate_risk') this.aggregateRisk, @JsonKey(name: 'aggregate_risk_label') this.aggregateRiskLabel, this.narrative}): _segments = segments,super._();
  factory _PlannedRoute.fromJson(Map<String, dynamic> json) => _$PlannedRouteFromJson(json);

@override final  int rank;
@override final  String? mode;
 final  List<Map<String, dynamic>> _segments;
@override@JsonKey(name: 'segments') List<Map<String, dynamic>> get segments {
  if (_segments is EqualUnmodifiableListView) return _segments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_segments);
}

@override@JsonKey(name: 'total_distance_km') final  double? totalDistanceKm;
@override@JsonKey(name: 'total_eta_minutes') final  double? totalEtaMinutes;
@override@JsonKey(name: 'aggregate_risk') final  double? aggregateRisk;
@override@JsonKey(name: 'aggregate_risk_label') final  String? aggregateRiskLabel;
@override final  String? narrative;

/// Create a copy of PlannedRoute
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlannedRouteCopyWith<_PlannedRoute> get copyWith => __$PlannedRouteCopyWithImpl<_PlannedRoute>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlannedRouteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlannedRoute&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.mode, mode) || other.mode == mode)&&const DeepCollectionEquality().equals(other.segments, _segments)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm)&&(identical(other.totalEtaMinutes, totalEtaMinutes) || other.totalEtaMinutes == totalEtaMinutes)&&(identical(other.aggregateRisk, aggregateRisk) || other.aggregateRisk == aggregateRisk)&&(identical(other.aggregateRiskLabel, aggregateRiskLabel) || other.aggregateRiskLabel == aggregateRiskLabel)&&(identical(other.narrative, narrative) || other.narrative == narrative));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,rank,mode,const DeepCollectionEquality().hash(_segments),totalDistanceKm,totalEtaMinutes,aggregateRisk,aggregateRiskLabel,narrative);
}

@override
String toString() {
    return 'PlannedRoute(rank: $rank, mode: $mode, segments: $segments, totalDistanceKm: $totalDistanceKm, totalEtaMinutes: $totalEtaMinutes, aggregateRisk: $aggregateRisk, aggregateRiskLabel: $aggregateRiskLabel, narrative: $narrative)';
}


}

/// @nodoc
abstract mixin class _$PlannedRouteCopyWith<$Res> implements $PlannedRouteCopyWith<$Res> {
  factory _$PlannedRouteCopyWith(_PlannedRoute value, $Res Function(_PlannedRoute) _then) = __$PlannedRouteCopyWithImpl;
@override @useResult
$Res call({
 int rank, String? mode,@JsonKey(name: 'segments') List<Map<String, dynamic>> segments,@JsonKey(name: 'total_distance_km') double? totalDistanceKm,@JsonKey(name: 'total_eta_minutes') double? totalEtaMinutes,@JsonKey(name: 'aggregate_risk') double? aggregateRisk,@JsonKey(name: 'aggregate_risk_label') String? aggregateRiskLabel, String? narrative
});




}
/// @nodoc
class __$PlannedRouteCopyWithImpl<$Res>
    implements _$PlannedRouteCopyWith<$Res> {
  __$PlannedRouteCopyWithImpl(this._self, this._then);

  final _PlannedRoute _self;
  final $Res Function(_PlannedRoute) _then;

/// Create a copy of PlannedRoute
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rank = null,Object? mode = freezed,Object? segments = null,Object? totalDistanceKm = freezed,Object? totalEtaMinutes = freezed,Object? aggregateRisk = freezed,Object? aggregateRiskLabel = freezed,Object? narrative = freezed,}) {
  return _then(_PlannedRoute(
rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,mode: freezed == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String?,segments: null == segments ? _self._segments : segments // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,totalDistanceKm: freezed == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double?,totalEtaMinutes: freezed == totalEtaMinutes ? _self.totalEtaMinutes : totalEtaMinutes // ignore: cast_nullable_to_non_nullable
as double?,aggregateRisk: freezed == aggregateRisk ? _self.aggregateRisk : aggregateRisk // ignore: cast_nullable_to_non_nullable
as double?,aggregateRiskLabel: freezed == aggregateRiskLabel ? _self.aggregateRiskLabel : aggregateRiskLabel // ignore: cast_nullable_to_non_nullable
as String?,narrative: freezed == narrative ? _self.narrative : narrative // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$RoutingMode {

 String get id; String get description;
/// Create a copy of RoutingMode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoutingModeCopyWith<RoutingMode> get copyWith => _$RoutingModeCopyWithImpl<RoutingMode>(this as RoutingMode, _$identity);

  /// Serializes this RoutingMode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RoutingMode;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingMode&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.description, _this.description) || other.description == _this.description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RoutingMode;
  return Object.hash(runtimeType,_this.id,_this.description);
}

@override
String toString() {
  final _this = this as RoutingMode;
  return 'RoutingMode(id: ${_this.id}, description: ${_this.description})';
}


}

/// @nodoc
abstract mixin class $RoutingModeCopyWith<$Res>  {
  factory $RoutingModeCopyWith(RoutingMode value, $Res Function(RoutingMode) _then) = _$RoutingModeCopyWithImpl;
@useResult
$Res call({
 String id, String description
});




}
/// @nodoc
class _$RoutingModeCopyWithImpl<$Res>
    implements $RoutingModeCopyWith<$Res> {
  _$RoutingModeCopyWithImpl(this._self, this._then);

  final RoutingMode _self;
  final $Res Function(RoutingMode) _then;

/// Create a copy of RoutingMode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? description = null,}) {
  return _then(RoutingMode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RoutingMode].
extension RoutingModePatterns on RoutingMode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoutingMode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoutingMode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoutingMode value)  $default,){
final _that = this;
switch (_that) {
case _RoutingMode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoutingMode value)?  $default,){
final _that = this;
switch (_that) {
case _RoutingMode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoutingMode() when $default != null:
return $default(_that.id,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String description)  $default,) {final _that = this;
switch (_that) {
case _RoutingMode():
return $default(_that.id,_that.description);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String description)?  $default,) {final _that = this;
switch (_that) {
case _RoutingMode() when $default != null:
return $default(_that.id,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoutingMode implements RoutingMode {
  const _RoutingMode({required this.id, required this.description});
  factory _RoutingMode.fromJson(Map<String, dynamic> json) => _$RoutingModeFromJson(json);

@override final  String id;
@override final  String description;

/// Create a copy of RoutingMode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoutingModeCopyWith<_RoutingMode> get copyWith => __$RoutingModeCopyWithImpl<_RoutingMode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoutingModeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoutingMode&&(identical(other.id, id) || other.id == id)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,description);
}

@override
String toString() {
    return 'RoutingMode(id: $id, description: $description)';
}


}

/// @nodoc
abstract mixin class _$RoutingModeCopyWith<$Res> implements $RoutingModeCopyWith<$Res> {
  factory _$RoutingModeCopyWith(_RoutingMode value, $Res Function(_RoutingMode) _then) = __$RoutingModeCopyWithImpl;
@override @useResult
$Res call({
 String id, String description
});




}
/// @nodoc
class __$RoutingModeCopyWithImpl<$Res>
    implements _$RoutingModeCopyWith<$Res> {
  __$RoutingModeCopyWithImpl(this._self, this._then);

  final _RoutingMode _self;
  final $Res Function(_RoutingMode) _then;

/// Create a copy of RoutingMode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? description = null,}) {
  return _then(_RoutingMode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$RoutePlanResponse {

@JsonKey(name: 'routes') List<PlannedRoute> get routes;
/// Create a copy of RoutePlanResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoutePlanResponseCopyWith<RoutePlanResponse> get copyWith => _$RoutePlanResponseCopyWithImpl<RoutePlanResponse>(this as RoutePlanResponse, _$identity);

  /// Serializes this RoutePlanResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RoutePlanResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutePlanResponse&&const DeepCollectionEquality().equals(other.routes, _this.routes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RoutePlanResponse;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.routes));
}

@override
String toString() {
  final _this = this as RoutePlanResponse;
  return 'RoutePlanResponse(routes: ${_this.routes})';
}


}

/// @nodoc
abstract mixin class $RoutePlanResponseCopyWith<$Res>  {
  factory $RoutePlanResponseCopyWith(RoutePlanResponse value, $Res Function(RoutePlanResponse) _then) = _$RoutePlanResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'routes') List<PlannedRoute> routes
});




}
/// @nodoc
class _$RoutePlanResponseCopyWithImpl<$Res>
    implements $RoutePlanResponseCopyWith<$Res> {
  _$RoutePlanResponseCopyWithImpl(this._self, this._then);

  final RoutePlanResponse _self;
  final $Res Function(RoutePlanResponse) _then;

/// Create a copy of RoutePlanResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? routes = null,}) {
  return _then(RoutePlanResponse(
routes: null == routes ? _self.routes : routes // ignore: cast_nullable_to_non_nullable
as List<PlannedRoute>,
  ));
}

}


/// Adds pattern-matching-related methods to [RoutePlanResponse].
extension RoutePlanResponsePatterns on RoutePlanResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoutePlanResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoutePlanResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoutePlanResponse value)  $default,){
final _that = this;
switch (_that) {
case _RoutePlanResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoutePlanResponse value)?  $default,){
final _that = this;
switch (_that) {
case _RoutePlanResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'routes')  List<PlannedRoute> routes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoutePlanResponse() when $default != null:
return $default(_that.routes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'routes')  List<PlannedRoute> routes)  $default,) {final _that = this;
switch (_that) {
case _RoutePlanResponse():
return $default(_that.routes);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'routes')  List<PlannedRoute> routes)?  $default,) {final _that = this;
switch (_that) {
case _RoutePlanResponse() when $default != null:
return $default(_that.routes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoutePlanResponse extends RoutePlanResponse {
  const _RoutePlanResponse({@JsonKey(name: 'routes')  List<PlannedRoute> routes = const <PlannedRoute>[]}): _routes = routes,super._();
  factory _RoutePlanResponse.fromJson(Map<String, dynamic> json) => _$RoutePlanResponseFromJson(json);

 final  List<PlannedRoute> _routes;
@override@JsonKey(name: 'routes') List<PlannedRoute> get routes {
  if (_routes is EqualUnmodifiableListView) return _routes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_routes);
}


/// Create a copy of RoutePlanResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoutePlanResponseCopyWith<_RoutePlanResponse> get copyWith => __$RoutePlanResponseCopyWithImpl<_RoutePlanResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoutePlanResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoutePlanResponse&&const DeepCollectionEquality().equals(other.routes, _routes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_routes));
}

@override
String toString() {
    return 'RoutePlanResponse(routes: $routes)';
}


}

/// @nodoc
abstract mixin class _$RoutePlanResponseCopyWith<$Res> implements $RoutePlanResponseCopyWith<$Res> {
  factory _$RoutePlanResponseCopyWith(_RoutePlanResponse value, $Res Function(_RoutePlanResponse) _then) = __$RoutePlanResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'routes') List<PlannedRoute> routes
});




}
/// @nodoc
class __$RoutePlanResponseCopyWithImpl<$Res>
    implements _$RoutePlanResponseCopyWith<$Res> {
  __$RoutePlanResponseCopyWithImpl(this._self, this._then);

  final _RoutePlanResponse _self;
  final $Res Function(_RoutePlanResponse) _then;

/// Create a copy of RoutePlanResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? routes = null,}) {
  return _then(_RoutePlanResponse(
routes: null == routes ? _self._routes : routes // ignore: cast_nullable_to_non_nullable
as List<PlannedRoute>,
  ));
}


}

// dart format on
