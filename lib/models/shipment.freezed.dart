// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shipment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Shipment {

 String get id; String? get code; String? get title; String? get commodity; String? get priority; String? get status; String? get originName; String? get destName; String? get vehicleCode; String? get destState; String? get destDistrict; String? get etaAt;
/// Create a copy of Shipment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShipmentCopyWith<Shipment> get copyWith => _$ShipmentCopyWithImpl<Shipment>(this as Shipment, _$identity);

  /// Serializes this Shipment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Shipment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Shipment&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.commodity, _this.commodity) || other.commodity == _this.commodity)&&(identical(other.priority, _this.priority) || other.priority == _this.priority)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.originName, _this.originName) || other.originName == _this.originName)&&(identical(other.destName, _this.destName) || other.destName == _this.destName)&&(identical(other.vehicleCode, _this.vehicleCode) || other.vehicleCode == _this.vehicleCode)&&(identical(other.destState, _this.destState) || other.destState == _this.destState)&&(identical(other.destDistrict, _this.destDistrict) || other.destDistrict == _this.destDistrict)&&(identical(other.etaAt, _this.etaAt) || other.etaAt == _this.etaAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Shipment;
  return Object.hash(runtimeType,_this.id,_this.code,_this.title,_this.commodity,_this.priority,_this.status,_this.originName,_this.destName,_this.vehicleCode,_this.destState,_this.destDistrict,_this.etaAt);
}

@override
String toString() {
  final _this = this as Shipment;
  return 'Shipment(id: ${_this.id}, code: ${_this.code}, title: ${_this.title}, commodity: ${_this.commodity}, priority: ${_this.priority}, status: ${_this.status}, originName: ${_this.originName}, destName: ${_this.destName}, vehicleCode: ${_this.vehicleCode}, destState: ${_this.destState}, destDistrict: ${_this.destDistrict}, etaAt: ${_this.etaAt})';
}


}

/// @nodoc
abstract mixin class $ShipmentCopyWith<$Res>  {
  factory $ShipmentCopyWith(Shipment value, $Res Function(Shipment) _then) = _$ShipmentCopyWithImpl;
@useResult
$Res call({
 String id, String? code, String? title, String? commodity, String? priority, String? status, String? originName, String? destName, String? vehicleCode, String? destState, String? destDistrict, String? etaAt
});




}
/// @nodoc
class _$ShipmentCopyWithImpl<$Res>
    implements $ShipmentCopyWith<$Res> {
  _$ShipmentCopyWithImpl(this._self, this._then);

  final Shipment _self;
  final $Res Function(Shipment) _then;

/// Create a copy of Shipment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = freezed,Object? title = freezed,Object? commodity = freezed,Object? priority = freezed,Object? status = freezed,Object? originName = freezed,Object? destName = freezed,Object? vehicleCode = freezed,Object? destState = freezed,Object? destDistrict = freezed,Object? etaAt = freezed,}) {
  return _then(Shipment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,commodity: freezed == commodity ? _self.commodity : commodity // ignore: cast_nullable_to_non_nullable
as String?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,originName: freezed == originName ? _self.originName : originName // ignore: cast_nullable_to_non_nullable
as String?,destName: freezed == destName ? _self.destName : destName // ignore: cast_nullable_to_non_nullable
as String?,vehicleCode: freezed == vehicleCode ? _self.vehicleCode : vehicleCode // ignore: cast_nullable_to_non_nullable
as String?,destState: freezed == destState ? _self.destState : destState // ignore: cast_nullable_to_non_nullable
as String?,destDistrict: freezed == destDistrict ? _self.destDistrict : destDistrict // ignore: cast_nullable_to_non_nullable
as String?,etaAt: freezed == etaAt ? _self.etaAt : etaAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Shipment].
extension ShipmentPatterns on Shipment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Shipment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Shipment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Shipment value)  $default,){
final _that = this;
switch (_that) {
case _Shipment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Shipment value)?  $default,){
final _that = this;
switch (_that) {
case _Shipment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? code,  String? title,  String? commodity,  String? priority,  String? status,  String? originName,  String? destName,  String? vehicleCode,  String? destState,  String? destDistrict,  String? etaAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Shipment() when $default != null:
return $default(_that.id,_that.code,_that.title,_that.commodity,_that.priority,_that.status,_that.originName,_that.destName,_that.vehicleCode,_that.destState,_that.destDistrict,_that.etaAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? code,  String? title,  String? commodity,  String? priority,  String? status,  String? originName,  String? destName,  String? vehicleCode,  String? destState,  String? destDistrict,  String? etaAt)  $default,) {final _that = this;
switch (_that) {
case _Shipment():
return $default(_that.id,_that.code,_that.title,_that.commodity,_that.priority,_that.status,_that.originName,_that.destName,_that.vehicleCode,_that.destState,_that.destDistrict,_that.etaAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? code,  String? title,  String? commodity,  String? priority,  String? status,  String? originName,  String? destName,  String? vehicleCode,  String? destState,  String? destDistrict,  String? etaAt)?  $default,) {final _that = this;
switch (_that) {
case _Shipment() when $default != null:
return $default(_that.id,_that.code,_that.title,_that.commodity,_that.priority,_that.status,_that.originName,_that.destName,_that.vehicleCode,_that.destState,_that.destDistrict,_that.etaAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Shipment extends Shipment {
  const _Shipment({required this.id, this.code, this.title, this.commodity, this.priority, this.status, this.originName, this.destName, this.vehicleCode, this.destState, this.destDistrict, this.etaAt}): super._();
  factory _Shipment.fromJson(Map<String, dynamic> json) => _$ShipmentFromJson(json);

@override final  String id;
@override final  String? code;
@override final  String? title;
@override final  String? commodity;
@override final  String? priority;
@override final  String? status;
@override final  String? originName;
@override final  String? destName;
@override final  String? vehicleCode;
@override final  String? destState;
@override final  String? destDistrict;
@override final  String? etaAt;

/// Create a copy of Shipment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShipmentCopyWith<_Shipment> get copyWith => __$ShipmentCopyWithImpl<_Shipment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShipmentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Shipment&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.title, title) || other.title == title)&&(identical(other.commodity, commodity) || other.commodity == commodity)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.status, status) || other.status == status)&&(identical(other.originName, originName) || other.originName == originName)&&(identical(other.destName, destName) || other.destName == destName)&&(identical(other.vehicleCode, vehicleCode) || other.vehicleCode == vehicleCode)&&(identical(other.destState, destState) || other.destState == destState)&&(identical(other.destDistrict, destDistrict) || other.destDistrict == destDistrict)&&(identical(other.etaAt, etaAt) || other.etaAt == etaAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,code,title,commodity,priority,status,originName,destName,vehicleCode,destState,destDistrict,etaAt);
}

@override
String toString() {
    return 'Shipment(id: $id, code: $code, title: $title, commodity: $commodity, priority: $priority, status: $status, originName: $originName, destName: $destName, vehicleCode: $vehicleCode, destState: $destState, destDistrict: $destDistrict, etaAt: $etaAt)';
}


}

/// @nodoc
abstract mixin class _$ShipmentCopyWith<$Res> implements $ShipmentCopyWith<$Res> {
  factory _$ShipmentCopyWith(_Shipment value, $Res Function(_Shipment) _then) = __$ShipmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String? code, String? title, String? commodity, String? priority, String? status, String? originName, String? destName, String? vehicleCode, String? destState, String? destDistrict, String? etaAt
});




}
/// @nodoc
class __$ShipmentCopyWithImpl<$Res>
    implements _$ShipmentCopyWith<$Res> {
  __$ShipmentCopyWithImpl(this._self, this._then);

  final _Shipment _self;
  final $Res Function(_Shipment) _then;

/// Create a copy of Shipment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = freezed,Object? title = freezed,Object? commodity = freezed,Object? priority = freezed,Object? status = freezed,Object? originName = freezed,Object? destName = freezed,Object? vehicleCode = freezed,Object? destState = freezed,Object? destDistrict = freezed,Object? etaAt = freezed,}) {
  return _then(_Shipment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,commodity: freezed == commodity ? _self.commodity : commodity // ignore: cast_nullable_to_non_nullable
as String?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,originName: freezed == originName ? _self.originName : originName // ignore: cast_nullable_to_non_nullable
as String?,destName: freezed == destName ? _self.destName : destName // ignore: cast_nullable_to_non_nullable
as String?,vehicleCode: freezed == vehicleCode ? _self.vehicleCode : vehicleCode // ignore: cast_nullable_to_non_nullable
as String?,destState: freezed == destState ? _self.destState : destState // ignore: cast_nullable_to_non_nullable
as String?,destDistrict: freezed == destDistrict ? _self.destDistrict : destDistrict // ignore: cast_nullable_to_non_nullable
as String?,etaAt: freezed == etaAt ? _self.etaAt : etaAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ShipmentEta {

 String get id; double? get etaMinutes; String? get calculatedAt;
/// Create a copy of ShipmentEta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShipmentEtaCopyWith<ShipmentEta> get copyWith => _$ShipmentEtaCopyWithImpl<ShipmentEta>(this as ShipmentEta, _$identity);

  /// Serializes this ShipmentEta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ShipmentEta;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShipmentEta&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.etaMinutes, _this.etaMinutes) || other.etaMinutes == _this.etaMinutes)&&(identical(other.calculatedAt, _this.calculatedAt) || other.calculatedAt == _this.calculatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ShipmentEta;
  return Object.hash(runtimeType,_this.id,_this.etaMinutes,_this.calculatedAt);
}

@override
String toString() {
  final _this = this as ShipmentEta;
  return 'ShipmentEta(id: ${_this.id}, etaMinutes: ${_this.etaMinutes}, calculatedAt: ${_this.calculatedAt})';
}


}

/// @nodoc
abstract mixin class $ShipmentEtaCopyWith<$Res>  {
  factory $ShipmentEtaCopyWith(ShipmentEta value, $Res Function(ShipmentEta) _then) = _$ShipmentEtaCopyWithImpl;
@useResult
$Res call({
 String id, double? etaMinutes, String? calculatedAt
});




}
/// @nodoc
class _$ShipmentEtaCopyWithImpl<$Res>
    implements $ShipmentEtaCopyWith<$Res> {
  _$ShipmentEtaCopyWithImpl(this._self, this._then);

  final ShipmentEta _self;
  final $Res Function(ShipmentEta) _then;

/// Create a copy of ShipmentEta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? etaMinutes = freezed,Object? calculatedAt = freezed,}) {
  return _then(ShipmentEta(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,etaMinutes: freezed == etaMinutes ? _self.etaMinutes : etaMinutes // ignore: cast_nullable_to_non_nullable
as double?,calculatedAt: freezed == calculatedAt ? _self.calculatedAt : calculatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShipmentEta].
extension ShipmentEtaPatterns on ShipmentEta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShipmentEta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShipmentEta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShipmentEta value)  $default,){
final _that = this;
switch (_that) {
case _ShipmentEta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShipmentEta value)?  $default,){
final _that = this;
switch (_that) {
case _ShipmentEta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  double? etaMinutes,  String? calculatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShipmentEta() when $default != null:
return $default(_that.id,_that.etaMinutes,_that.calculatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  double? etaMinutes,  String? calculatedAt)  $default,) {final _that = this;
switch (_that) {
case _ShipmentEta():
return $default(_that.id,_that.etaMinutes,_that.calculatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  double? etaMinutes,  String? calculatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ShipmentEta() when $default != null:
return $default(_that.id,_that.etaMinutes,_that.calculatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShipmentEta implements ShipmentEta {
  const _ShipmentEta({required this.id, this.etaMinutes, this.calculatedAt});
  factory _ShipmentEta.fromJson(Map<String, dynamic> json) => _$ShipmentEtaFromJson(json);

@override final  String id;
@override final  double? etaMinutes;
@override final  String? calculatedAt;

/// Create a copy of ShipmentEta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShipmentEtaCopyWith<_ShipmentEta> get copyWith => __$ShipmentEtaCopyWithImpl<_ShipmentEta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShipmentEtaToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShipmentEta&&(identical(other.id, id) || other.id == id)&&(identical(other.etaMinutes, etaMinutes) || other.etaMinutes == etaMinutes)&&(identical(other.calculatedAt, calculatedAt) || other.calculatedAt == calculatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,etaMinutes,calculatedAt);
}

@override
String toString() {
    return 'ShipmentEta(id: $id, etaMinutes: $etaMinutes, calculatedAt: $calculatedAt)';
}


}

/// @nodoc
abstract mixin class _$ShipmentEtaCopyWith<$Res> implements $ShipmentEtaCopyWith<$Res> {
  factory _$ShipmentEtaCopyWith(_ShipmentEta value, $Res Function(_ShipmentEta) _then) = __$ShipmentEtaCopyWithImpl;
@override @useResult
$Res call({
 String id, double? etaMinutes, String? calculatedAt
});




}
/// @nodoc
class __$ShipmentEtaCopyWithImpl<$Res>
    implements _$ShipmentEtaCopyWith<$Res> {
  __$ShipmentEtaCopyWithImpl(this._self, this._then);

  final _ShipmentEta _self;
  final $Res Function(_ShipmentEta) _then;

/// Create a copy of ShipmentEta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? etaMinutes = freezed,Object? calculatedAt = freezed,}) {
  return _then(_ShipmentEta(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,etaMinutes: freezed == etaMinutes ? _self.etaMinutes : etaMinutes // ignore: cast_nullable_to_non_nullable
as double?,calculatedAt: freezed == calculatedAt ? _self.calculatedAt : calculatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
