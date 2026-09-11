// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alert.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Alert {

 String get id; String? get level; String? get alertType; String? get title; String? get message; String? get status; String? get currentRole; String? get stateCode; String? get districtCode; String? get segmentId; String? get shipmentId; String? get createdAt; String? get actedAt; String? get localizedTitle; String? get localizedMessage; String? get emergencyInstruction;
/// Create a copy of Alert
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlertCopyWith<Alert> get copyWith => _$AlertCopyWithImpl<Alert>(this as Alert, _$identity);

  /// Serializes this Alert to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Alert;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Alert&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.level, _this.level) || other.level == _this.level)&&(identical(other.alertType, _this.alertType) || other.alertType == _this.alertType)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.currentRole, _this.currentRole) || other.currentRole == _this.currentRole)&&(identical(other.stateCode, _this.stateCode) || other.stateCode == _this.stateCode)&&(identical(other.districtCode, _this.districtCode) || other.districtCode == _this.districtCode)&&(identical(other.segmentId, _this.segmentId) || other.segmentId == _this.segmentId)&&(identical(other.shipmentId, _this.shipmentId) || other.shipmentId == _this.shipmentId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.actedAt, _this.actedAt) || other.actedAt == _this.actedAt)&&(identical(other.localizedTitle, _this.localizedTitle) || other.localizedTitle == _this.localizedTitle)&&(identical(other.localizedMessage, _this.localizedMessage) || other.localizedMessage == _this.localizedMessage)&&(identical(other.emergencyInstruction, _this.emergencyInstruction) || other.emergencyInstruction == _this.emergencyInstruction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Alert;
  return Object.hash(runtimeType,_this.id,_this.level,_this.alertType,_this.title,_this.message,_this.status,_this.currentRole,_this.stateCode,_this.districtCode,_this.segmentId,_this.shipmentId,_this.createdAt,_this.actedAt,_this.localizedTitle,_this.localizedMessage,_this.emergencyInstruction);
}

@override
String toString() {
  final _this = this as Alert;
  return 'Alert(id: ${_this.id}, level: ${_this.level}, alertType: ${_this.alertType}, title: ${_this.title}, message: ${_this.message}, status: ${_this.status}, currentRole: ${_this.currentRole}, stateCode: ${_this.stateCode}, districtCode: ${_this.districtCode}, segmentId: ${_this.segmentId}, shipmentId: ${_this.shipmentId}, createdAt: ${_this.createdAt}, actedAt: ${_this.actedAt}, localizedTitle: ${_this.localizedTitle}, localizedMessage: ${_this.localizedMessage}, emergencyInstruction: ${_this.emergencyInstruction})';
}


}

/// @nodoc
abstract mixin class $AlertCopyWith<$Res>  {
  factory $AlertCopyWith(Alert value, $Res Function(Alert) _then) = _$AlertCopyWithImpl;
@useResult
$Res call({
 String id, String? level, String? alertType, String? title, String? message, String? status, String? currentRole, String? stateCode, String? districtCode, String? segmentId, String? shipmentId, String? createdAt, String? actedAt, String? localizedTitle, String? localizedMessage, String? emergencyInstruction
});




}
/// @nodoc
class _$AlertCopyWithImpl<$Res>
    implements $AlertCopyWith<$Res> {
  _$AlertCopyWithImpl(this._self, this._then);

  final Alert _self;
  final $Res Function(Alert) _then;

/// Create a copy of Alert
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? level = freezed,Object? alertType = freezed,Object? title = freezed,Object? message = freezed,Object? status = freezed,Object? currentRole = freezed,Object? stateCode = freezed,Object? districtCode = freezed,Object? segmentId = freezed,Object? shipmentId = freezed,Object? createdAt = freezed,Object? actedAt = freezed,Object? localizedTitle = freezed,Object? localizedMessage = freezed,Object? emergencyInstruction = freezed,}) {
  return _then(Alert(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String?,alertType: freezed == alertType ? _self.alertType : alertType // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,currentRole: freezed == currentRole ? _self.currentRole : currentRole // ignore: cast_nullable_to_non_nullable
as String?,stateCode: freezed == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String?,districtCode: freezed == districtCode ? _self.districtCode : districtCode // ignore: cast_nullable_to_non_nullable
as String?,segmentId: freezed == segmentId ? _self.segmentId : segmentId // ignore: cast_nullable_to_non_nullable
as String?,shipmentId: freezed == shipmentId ? _self.shipmentId : shipmentId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,actedAt: freezed == actedAt ? _self.actedAt : actedAt // ignore: cast_nullable_to_non_nullable
as String?,localizedTitle: freezed == localizedTitle ? _self.localizedTitle : localizedTitle // ignore: cast_nullable_to_non_nullable
as String?,localizedMessage: freezed == localizedMessage ? _self.localizedMessage : localizedMessage // ignore: cast_nullable_to_non_nullable
as String?,emergencyInstruction: freezed == emergencyInstruction ? _self.emergencyInstruction : emergencyInstruction // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Alert].
extension AlertPatterns on Alert {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Alert value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Alert() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Alert value)  $default,){
final _that = this;
switch (_that) {
case _Alert():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Alert value)?  $default,){
final _that = this;
switch (_that) {
case _Alert() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? level,  String? alertType,  String? title,  String? message,  String? status,  String? currentRole,  String? stateCode,  String? districtCode,  String? segmentId,  String? shipmentId,  String? createdAt,  String? actedAt,  String? localizedTitle,  String? localizedMessage,  String? emergencyInstruction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Alert() when $default != null:
return $default(_that.id,_that.level,_that.alertType,_that.title,_that.message,_that.status,_that.currentRole,_that.stateCode,_that.districtCode,_that.segmentId,_that.shipmentId,_that.createdAt,_that.actedAt,_that.localizedTitle,_that.localizedMessage,_that.emergencyInstruction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? level,  String? alertType,  String? title,  String? message,  String? status,  String? currentRole,  String? stateCode,  String? districtCode,  String? segmentId,  String? shipmentId,  String? createdAt,  String? actedAt,  String? localizedTitle,  String? localizedMessage,  String? emergencyInstruction)  $default,) {final _that = this;
switch (_that) {
case _Alert():
return $default(_that.id,_that.level,_that.alertType,_that.title,_that.message,_that.status,_that.currentRole,_that.stateCode,_that.districtCode,_that.segmentId,_that.shipmentId,_that.createdAt,_that.actedAt,_that.localizedTitle,_that.localizedMessage,_that.emergencyInstruction);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? level,  String? alertType,  String? title,  String? message,  String? status,  String? currentRole,  String? stateCode,  String? districtCode,  String? segmentId,  String? shipmentId,  String? createdAt,  String? actedAt,  String? localizedTitle,  String? localizedMessage,  String? emergencyInstruction)?  $default,) {final _that = this;
switch (_that) {
case _Alert() when $default != null:
return $default(_that.id,_that.level,_that.alertType,_that.title,_that.message,_that.status,_that.currentRole,_that.stateCode,_that.districtCode,_that.segmentId,_that.shipmentId,_that.createdAt,_that.actedAt,_that.localizedTitle,_that.localizedMessage,_that.emergencyInstruction);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Alert extends Alert {
  const _Alert({required this.id, this.level, this.alertType, this.title, this.message, this.status, this.currentRole, this.stateCode, this.districtCode, this.segmentId, this.shipmentId, this.createdAt, this.actedAt, this.localizedTitle, this.localizedMessage, this.emergencyInstruction}): super._();
  factory _Alert.fromJson(Map<String, dynamic> json) => _$AlertFromJson(json);

@override final  String id;
@override final  String? level;
@override final  String? alertType;
@override final  String? title;
@override final  String? message;
@override final  String? status;
@override final  String? currentRole;
@override final  String? stateCode;
@override final  String? districtCode;
@override final  String? segmentId;
@override final  String? shipmentId;
@override final  String? createdAt;
@override final  String? actedAt;
@override final  String? localizedTitle;
@override final  String? localizedMessage;
@override final  String? emergencyInstruction;

/// Create a copy of Alert
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlertCopyWith<_Alert> get copyWith => __$AlertCopyWithImpl<_Alert>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AlertToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Alert&&(identical(other.id, id) || other.id == id)&&(identical(other.level, level) || other.level == level)&&(identical(other.alertType, alertType) || other.alertType == alertType)&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.status, status) || other.status == status)&&(identical(other.currentRole, currentRole) || other.currentRole == currentRole)&&(identical(other.stateCode, stateCode) || other.stateCode == stateCode)&&(identical(other.districtCode, districtCode) || other.districtCode == districtCode)&&(identical(other.segmentId, segmentId) || other.segmentId == segmentId)&&(identical(other.shipmentId, shipmentId) || other.shipmentId == shipmentId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.actedAt, actedAt) || other.actedAt == actedAt)&&(identical(other.localizedTitle, localizedTitle) || other.localizedTitle == localizedTitle)&&(identical(other.localizedMessage, localizedMessage) || other.localizedMessage == localizedMessage)&&(identical(other.emergencyInstruction, emergencyInstruction) || other.emergencyInstruction == emergencyInstruction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,level,alertType,title,message,status,currentRole,stateCode,districtCode,segmentId,shipmentId,createdAt,actedAt,localizedTitle,localizedMessage,emergencyInstruction);
}

@override
String toString() {
    return 'Alert(id: $id, level: $level, alertType: $alertType, title: $title, message: $message, status: $status, currentRole: $currentRole, stateCode: $stateCode, districtCode: $districtCode, segmentId: $segmentId, shipmentId: $shipmentId, createdAt: $createdAt, actedAt: $actedAt, localizedTitle: $localizedTitle, localizedMessage: $localizedMessage, emergencyInstruction: $emergencyInstruction)';
}


}

/// @nodoc
abstract mixin class _$AlertCopyWith<$Res> implements $AlertCopyWith<$Res> {
  factory _$AlertCopyWith(_Alert value, $Res Function(_Alert) _then) = __$AlertCopyWithImpl;
@override @useResult
$Res call({
 String id, String? level, String? alertType, String? title, String? message, String? status, String? currentRole, String? stateCode, String? districtCode, String? segmentId, String? shipmentId, String? createdAt, String? actedAt, String? localizedTitle, String? localizedMessage, String? emergencyInstruction
});




}
/// @nodoc
class __$AlertCopyWithImpl<$Res>
    implements _$AlertCopyWith<$Res> {
  __$AlertCopyWithImpl(this._self, this._then);

  final _Alert _self;
  final $Res Function(_Alert) _then;

/// Create a copy of Alert
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? level = freezed,Object? alertType = freezed,Object? title = freezed,Object? message = freezed,Object? status = freezed,Object? currentRole = freezed,Object? stateCode = freezed,Object? districtCode = freezed,Object? segmentId = freezed,Object? shipmentId = freezed,Object? createdAt = freezed,Object? actedAt = freezed,Object? localizedTitle = freezed,Object? localizedMessage = freezed,Object? emergencyInstruction = freezed,}) {
  return _then(_Alert(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String?,alertType: freezed == alertType ? _self.alertType : alertType // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,currentRole: freezed == currentRole ? _self.currentRole : currentRole // ignore: cast_nullable_to_non_nullable
as String?,stateCode: freezed == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String?,districtCode: freezed == districtCode ? _self.districtCode : districtCode // ignore: cast_nullable_to_non_nullable
as String?,segmentId: freezed == segmentId ? _self.segmentId : segmentId // ignore: cast_nullable_to_non_nullable
as String?,shipmentId: freezed == shipmentId ? _self.shipmentId : shipmentId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,actedAt: freezed == actedAt ? _self.actedAt : actedAt // ignore: cast_nullable_to_non_nullable
as String?,localizedTitle: freezed == localizedTitle ? _self.localizedTitle : localizedTitle // ignore: cast_nullable_to_non_nullable
as String?,localizedMessage: freezed == localizedMessage ? _self.localizedMessage : localizedMessage // ignore: cast_nullable_to_non_nullable
as String?,emergencyInstruction: freezed == emergencyInstruction ? _self.emergencyInstruction : emergencyInstruction // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
