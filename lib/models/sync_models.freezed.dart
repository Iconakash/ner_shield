// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncPolicy {

 List<String>? get connectivityClasses; Map<String, SyncPolicyClass>? get policy;
/// Create a copy of SyncPolicy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncPolicyCopyWith<SyncPolicy> get copyWith => _$SyncPolicyCopyWithImpl<SyncPolicy>(this as SyncPolicy, _$identity);

  /// Serializes this SyncPolicy to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SyncPolicy;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncPolicy&&const DeepCollectionEquality().equals(other.connectivityClasses, _this.connectivityClasses)&&const DeepCollectionEquality().equals(other.policy, _this.policy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SyncPolicy;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.connectivityClasses),const DeepCollectionEquality().hash(_this.policy));
}

@override
String toString() {
  final _this = this as SyncPolicy;
  return 'SyncPolicy(connectivityClasses: ${_this.connectivityClasses}, policy: ${_this.policy})';
}


}

/// @nodoc
abstract mixin class $SyncPolicyCopyWith<$Res>  {
  factory $SyncPolicyCopyWith(SyncPolicy value, $Res Function(SyncPolicy) _then) = _$SyncPolicyCopyWithImpl;
@useResult
$Res call({
 List<String>? connectivityClasses, Map<String, SyncPolicyClass>? policy
});




}
/// @nodoc
class _$SyncPolicyCopyWithImpl<$Res>
    implements $SyncPolicyCopyWith<$Res> {
  _$SyncPolicyCopyWithImpl(this._self, this._then);

  final SyncPolicy _self;
  final $Res Function(SyncPolicy) _then;

/// Create a copy of SyncPolicy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? connectivityClasses = freezed,Object? policy = freezed,}) {
  return _then(SyncPolicy(
connectivityClasses: freezed == connectivityClasses ? _self.connectivityClasses : connectivityClasses // ignore: cast_nullable_to_non_nullable
as List<String>?,policy: freezed == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as Map<String, SyncPolicyClass>?,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncPolicy].
extension SyncPolicyPatterns on SyncPolicy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncPolicy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncPolicy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncPolicy value)  $default,){
final _that = this;
switch (_that) {
case _SyncPolicy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncPolicy value)?  $default,){
final _that = this;
switch (_that) {
case _SyncPolicy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String>? connectivityClasses,  Map<String, SyncPolicyClass>? policy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncPolicy() when $default != null:
return $default(_that.connectivityClasses,_that.policy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String>? connectivityClasses,  Map<String, SyncPolicyClass>? policy)  $default,) {final _that = this;
switch (_that) {
case _SyncPolicy():
return $default(_that.connectivityClasses,_that.policy);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String>? connectivityClasses,  Map<String, SyncPolicyClass>? policy)?  $default,) {final _that = this;
switch (_that) {
case _SyncPolicy() when $default != null:
return $default(_that.connectivityClasses,_that.policy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncPolicy implements SyncPolicy {
  const _SyncPolicy({ List<String>? connectivityClasses,  Map<String, SyncPolicyClass>? policy}): _connectivityClasses = connectivityClasses,_policy = policy;
  factory _SyncPolicy.fromJson(Map<String, dynamic> json) => _$SyncPolicyFromJson(json);

 final  List<String>? _connectivityClasses;
@override List<String>? get connectivityClasses {
  final value = _connectivityClasses;
  if (value == null) return null;
  if (_connectivityClasses is EqualUnmodifiableListView) return _connectivityClasses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  Map<String, SyncPolicyClass>? _policy;
@override Map<String, SyncPolicyClass>? get policy {
  final value = _policy;
  if (value == null) return null;
  if (_policy is EqualUnmodifiableMapView) return _policy;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of SyncPolicy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncPolicyCopyWith<_SyncPolicy> get copyWith => __$SyncPolicyCopyWithImpl<_SyncPolicy>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncPolicyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncPolicy&&const DeepCollectionEquality().equals(other.connectivityClasses, _connectivityClasses)&&const DeepCollectionEquality().equals(other.policy, _policy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_connectivityClasses),const DeepCollectionEquality().hash(_policy));
}

@override
String toString() {
    return 'SyncPolicy(connectivityClasses: $connectivityClasses, policy: $policy)';
}


}

/// @nodoc
abstract mixin class _$SyncPolicyCopyWith<$Res> implements $SyncPolicyCopyWith<$Res> {
  factory _$SyncPolicyCopyWith(_SyncPolicy value, $Res Function(_SyncPolicy) _then) = __$SyncPolicyCopyWithImpl;
@override @useResult
$Res call({
 List<String>? connectivityClasses, Map<String, SyncPolicyClass>? policy
});




}
/// @nodoc
class __$SyncPolicyCopyWithImpl<$Res>
    implements _$SyncPolicyCopyWith<$Res> {
  __$SyncPolicyCopyWithImpl(this._self, this._then);

  final _SyncPolicy _self;
  final $Res Function(_SyncPolicy) _then;

/// Create a copy of SyncPolicy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? connectivityClasses = freezed,Object? policy = freezed,}) {
  return _then(_SyncPolicy(
connectivityClasses: freezed == connectivityClasses ? _self._connectivityClasses : connectivityClasses // ignore: cast_nullable_to_non_nullable
as List<String>?,policy: freezed == policy ? _self._policy : policy // ignore: cast_nullable_to_non_nullable
as Map<String, SyncPolicyClass>?,
  ));
}


}


/// @nodoc
mixin _$SyncPolicyClass {

 int get maxOps; bool get allowPhotos; List<String>? get allowedTypes; int? get gpsBeaconS;
/// Create a copy of SyncPolicyClass
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncPolicyClassCopyWith<SyncPolicyClass> get copyWith => _$SyncPolicyClassCopyWithImpl<SyncPolicyClass>(this as SyncPolicyClass, _$identity);

  /// Serializes this SyncPolicyClass to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SyncPolicyClass;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncPolicyClass&&(identical(other.maxOps, _this.maxOps) || other.maxOps == _this.maxOps)&&(identical(other.allowPhotos, _this.allowPhotos) || other.allowPhotos == _this.allowPhotos)&&const DeepCollectionEquality().equals(other.allowedTypes, _this.allowedTypes)&&(identical(other.gpsBeaconS, _this.gpsBeaconS) || other.gpsBeaconS == _this.gpsBeaconS));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SyncPolicyClass;
  return Object.hash(runtimeType,_this.maxOps,_this.allowPhotos,const DeepCollectionEquality().hash(_this.allowedTypes),_this.gpsBeaconS);
}

@override
String toString() {
  final _this = this as SyncPolicyClass;
  return 'SyncPolicyClass(maxOps: ${_this.maxOps}, allowPhotos: ${_this.allowPhotos}, allowedTypes: ${_this.allowedTypes}, gpsBeaconS: ${_this.gpsBeaconS})';
}


}

/// @nodoc
abstract mixin class $SyncPolicyClassCopyWith<$Res>  {
  factory $SyncPolicyClassCopyWith(SyncPolicyClass value, $Res Function(SyncPolicyClass) _then) = _$SyncPolicyClassCopyWithImpl;
@useResult
$Res call({
 int maxOps, bool allowPhotos, List<String>? allowedTypes, int? gpsBeaconS
});




}
/// @nodoc
class _$SyncPolicyClassCopyWithImpl<$Res>
    implements $SyncPolicyClassCopyWith<$Res> {
  _$SyncPolicyClassCopyWithImpl(this._self, this._then);

  final SyncPolicyClass _self;
  final $Res Function(SyncPolicyClass) _then;

/// Create a copy of SyncPolicyClass
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? maxOps = null,Object? allowPhotos = null,Object? allowedTypes = freezed,Object? gpsBeaconS = freezed,}) {
  return _then(SyncPolicyClass(
maxOps: null == maxOps ? _self.maxOps : maxOps // ignore: cast_nullable_to_non_nullable
as int,allowPhotos: null == allowPhotos ? _self.allowPhotos : allowPhotos // ignore: cast_nullable_to_non_nullable
as bool,allowedTypes: freezed == allowedTypes ? _self.allowedTypes : allowedTypes // ignore: cast_nullable_to_non_nullable
as List<String>?,gpsBeaconS: freezed == gpsBeaconS ? _self.gpsBeaconS : gpsBeaconS // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncPolicyClass].
extension SyncPolicyClassPatterns on SyncPolicyClass {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncPolicyClass value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncPolicyClass() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncPolicyClass value)  $default,){
final _that = this;
switch (_that) {
case _SyncPolicyClass():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncPolicyClass value)?  $default,){
final _that = this;
switch (_that) {
case _SyncPolicyClass() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int maxOps,  bool allowPhotos,  List<String>? allowedTypes,  int? gpsBeaconS)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncPolicyClass() when $default != null:
return $default(_that.maxOps,_that.allowPhotos,_that.allowedTypes,_that.gpsBeaconS);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int maxOps,  bool allowPhotos,  List<String>? allowedTypes,  int? gpsBeaconS)  $default,) {final _that = this;
switch (_that) {
case _SyncPolicyClass():
return $default(_that.maxOps,_that.allowPhotos,_that.allowedTypes,_that.gpsBeaconS);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int maxOps,  bool allowPhotos,  List<String>? allowedTypes,  int? gpsBeaconS)?  $default,) {final _that = this;
switch (_that) {
case _SyncPolicyClass() when $default != null:
return $default(_that.maxOps,_that.allowPhotos,_that.allowedTypes,_that.gpsBeaconS);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncPolicyClass implements SyncPolicyClass {
  const _SyncPolicyClass({this.maxOps = 0, this.allowPhotos = false,  List<String>? allowedTypes, this.gpsBeaconS}): _allowedTypes = allowedTypes;
  factory _SyncPolicyClass.fromJson(Map<String, dynamic> json) => _$SyncPolicyClassFromJson(json);

@override@JsonKey() final  int maxOps;
@override@JsonKey() final  bool allowPhotos;
 final  List<String>? _allowedTypes;
@override List<String>? get allowedTypes {
  final value = _allowedTypes;
  if (value == null) return null;
  if (_allowedTypes is EqualUnmodifiableListView) return _allowedTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  int? gpsBeaconS;

/// Create a copy of SyncPolicyClass
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncPolicyClassCopyWith<_SyncPolicyClass> get copyWith => __$SyncPolicyClassCopyWithImpl<_SyncPolicyClass>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncPolicyClassToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncPolicyClass&&(identical(other.maxOps, maxOps) || other.maxOps == maxOps)&&(identical(other.allowPhotos, allowPhotos) || other.allowPhotos == allowPhotos)&&const DeepCollectionEquality().equals(other.allowedTypes, _allowedTypes)&&(identical(other.gpsBeaconS, gpsBeaconS) || other.gpsBeaconS == gpsBeaconS));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,maxOps,allowPhotos,const DeepCollectionEquality().hash(_allowedTypes),gpsBeaconS);
}

@override
String toString() {
    return 'SyncPolicyClass(maxOps: $maxOps, allowPhotos: $allowPhotos, allowedTypes: $allowedTypes, gpsBeaconS: $gpsBeaconS)';
}


}

/// @nodoc
abstract mixin class _$SyncPolicyClassCopyWith<$Res> implements $SyncPolicyClassCopyWith<$Res> {
  factory _$SyncPolicyClassCopyWith(_SyncPolicyClass value, $Res Function(_SyncPolicyClass) _then) = __$SyncPolicyClassCopyWithImpl;
@override @useResult
$Res call({
 int maxOps, bool allowPhotos, List<String>? allowedTypes, int? gpsBeaconS
});




}
/// @nodoc
class __$SyncPolicyClassCopyWithImpl<$Res>
    implements _$SyncPolicyClassCopyWith<$Res> {
  __$SyncPolicyClassCopyWithImpl(this._self, this._then);

  final _SyncPolicyClass _self;
  final $Res Function(_SyncPolicyClass) _then;

/// Create a copy of SyncPolicyClass
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? maxOps = null,Object? allowPhotos = null,Object? allowedTypes = freezed,Object? gpsBeaconS = freezed,}) {
  return _then(_SyncPolicyClass(
maxOps: null == maxOps ? _self.maxOps : maxOps // ignore: cast_nullable_to_non_nullable
as int,allowPhotos: null == allowPhotos ? _self.allowPhotos : allowPhotos // ignore: cast_nullable_to_non_nullable
as bool,allowedTypes: freezed == allowedTypes ? _self._allowedTypes : allowedTypes // ignore: cast_nullable_to_non_nullable
as List<String>?,gpsBeaconS: freezed == gpsBeaconS ? _self.gpsBeaconS : gpsBeaconS // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$SyncPushOp {

 String get clientOpId; String get opType; Map<String, dynamic>? get payload;
/// Create a copy of SyncPushOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncPushOpCopyWith<SyncPushOp> get copyWith => _$SyncPushOpCopyWithImpl<SyncPushOp>(this as SyncPushOp, _$identity);

  /// Serializes this SyncPushOp to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SyncPushOp;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncPushOp&&(identical(other.clientOpId, _this.clientOpId) || other.clientOpId == _this.clientOpId)&&(identical(other.opType, _this.opType) || other.opType == _this.opType)&&const DeepCollectionEquality().equals(other.payload, _this.payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SyncPushOp;
  return Object.hash(runtimeType,_this.clientOpId,_this.opType,const DeepCollectionEquality().hash(_this.payload));
}

@override
String toString() {
  final _this = this as SyncPushOp;
  return 'SyncPushOp(clientOpId: ${_this.clientOpId}, opType: ${_this.opType}, payload: ${_this.payload})';
}


}

/// @nodoc
abstract mixin class $SyncPushOpCopyWith<$Res>  {
  factory $SyncPushOpCopyWith(SyncPushOp value, $Res Function(SyncPushOp) _then) = _$SyncPushOpCopyWithImpl;
@useResult
$Res call({
 String clientOpId, String opType, Map<String, dynamic>? payload
});




}
/// @nodoc
class _$SyncPushOpCopyWithImpl<$Res>
    implements $SyncPushOpCopyWith<$Res> {
  _$SyncPushOpCopyWithImpl(this._self, this._then);

  final SyncPushOp _self;
  final $Res Function(SyncPushOp) _then;

/// Create a copy of SyncPushOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientOpId = null,Object? opType = null,Object? payload = freezed,}) {
  return _then(SyncPushOp(
clientOpId: null == clientOpId ? _self.clientOpId : clientOpId // ignore: cast_nullable_to_non_nullable
as String,opType: null == opType ? _self.opType : opType // ignore: cast_nullable_to_non_nullable
as String,payload: freezed == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncPushOp].
extension SyncPushOpPatterns on SyncPushOp {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncPushOp value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncPushOp() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncPushOp value)  $default,){
final _that = this;
switch (_that) {
case _SyncPushOp():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncPushOp value)?  $default,){
final _that = this;
switch (_that) {
case _SyncPushOp() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientOpId,  String opType,  Map<String, dynamic>? payload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncPushOp() when $default != null:
return $default(_that.clientOpId,_that.opType,_that.payload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientOpId,  String opType,  Map<String, dynamic>? payload)  $default,) {final _that = this;
switch (_that) {
case _SyncPushOp():
return $default(_that.clientOpId,_that.opType,_that.payload);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientOpId,  String opType,  Map<String, dynamic>? payload)?  $default,) {final _that = this;
switch (_that) {
case _SyncPushOp() when $default != null:
return $default(_that.clientOpId,_that.opType,_that.payload);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncPushOp implements SyncPushOp {
  const _SyncPushOp({required this.clientOpId, required this.opType,  Map<String, dynamic>? payload}): _payload = payload;
  factory _SyncPushOp.fromJson(Map<String, dynamic> json) => _$SyncPushOpFromJson(json);

@override final  String clientOpId;
@override final  String opType;
 final  Map<String, dynamic>? _payload;
@override Map<String, dynamic>? get payload {
  final value = _payload;
  if (value == null) return null;
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of SyncPushOp
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncPushOpCopyWith<_SyncPushOp> get copyWith => __$SyncPushOpCopyWithImpl<_SyncPushOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncPushOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncPushOp&&(identical(other.clientOpId, clientOpId) || other.clientOpId == clientOpId)&&(identical(other.opType, opType) || other.opType == opType)&&const DeepCollectionEquality().equals(other.payload, _payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,clientOpId,opType,const DeepCollectionEquality().hash(_payload));
}

@override
String toString() {
    return 'SyncPushOp(clientOpId: $clientOpId, opType: $opType, payload: $payload)';
}


}

/// @nodoc
abstract mixin class _$SyncPushOpCopyWith<$Res> implements $SyncPushOpCopyWith<$Res> {
  factory _$SyncPushOpCopyWith(_SyncPushOp value, $Res Function(_SyncPushOp) _then) = __$SyncPushOpCopyWithImpl;
@override @useResult
$Res call({
 String clientOpId, String opType, Map<String, dynamic>? payload
});




}
/// @nodoc
class __$SyncPushOpCopyWithImpl<$Res>
    implements _$SyncPushOpCopyWith<$Res> {
  __$SyncPushOpCopyWithImpl(this._self, this._then);

  final _SyncPushOp _self;
  final $Res Function(_SyncPushOp) _then;

/// Create a copy of SyncPushOp
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientOpId = null,Object? opType = null,Object? payload = freezed,}) {
  return _then(_SyncPushOp(
clientOpId: null == clientOpId ? _self.clientOpId : clientOpId // ignore: cast_nullable_to_non_nullable
as String,opType: null == opType ? _self.opType : opType // ignore: cast_nullable_to_non_nullable
as String,payload: freezed == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}


/// @nodoc
mixin _$SyncOpResult {

 String get clientOpId; String get status; String? get reason; String? get resourceId;
/// Create a copy of SyncOpResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncOpResultCopyWith<SyncOpResult> get copyWith => _$SyncOpResultCopyWithImpl<SyncOpResult>(this as SyncOpResult, _$identity);

  /// Serializes this SyncOpResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SyncOpResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncOpResult&&(identical(other.clientOpId, _this.clientOpId) || other.clientOpId == _this.clientOpId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&(identical(other.resourceId, _this.resourceId) || other.resourceId == _this.resourceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SyncOpResult;
  return Object.hash(runtimeType,_this.clientOpId,_this.status,_this.reason,_this.resourceId);
}

@override
String toString() {
  final _this = this as SyncOpResult;
  return 'SyncOpResult(clientOpId: ${_this.clientOpId}, status: ${_this.status}, reason: ${_this.reason}, resourceId: ${_this.resourceId})';
}


}

/// @nodoc
abstract mixin class $SyncOpResultCopyWith<$Res>  {
  factory $SyncOpResultCopyWith(SyncOpResult value, $Res Function(SyncOpResult) _then) = _$SyncOpResultCopyWithImpl;
@useResult
$Res call({
 String clientOpId, String status, String? reason, String? resourceId
});




}
/// @nodoc
class _$SyncOpResultCopyWithImpl<$Res>
    implements $SyncOpResultCopyWith<$Res> {
  _$SyncOpResultCopyWithImpl(this._self, this._then);

  final SyncOpResult _self;
  final $Res Function(SyncOpResult) _then;

/// Create a copy of SyncOpResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientOpId = null,Object? status = null,Object? reason = freezed,Object? resourceId = freezed,}) {
  return _then(SyncOpResult(
clientOpId: null == clientOpId ? _self.clientOpId : clientOpId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,resourceId: freezed == resourceId ? _self.resourceId : resourceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncOpResult].
extension SyncOpResultPatterns on SyncOpResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncOpResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncOpResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncOpResult value)  $default,){
final _that = this;
switch (_that) {
case _SyncOpResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncOpResult value)?  $default,){
final _that = this;
switch (_that) {
case _SyncOpResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientOpId,  String status,  String? reason,  String? resourceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncOpResult() when $default != null:
return $default(_that.clientOpId,_that.status,_that.reason,_that.resourceId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientOpId,  String status,  String? reason,  String? resourceId)  $default,) {final _that = this;
switch (_that) {
case _SyncOpResult():
return $default(_that.clientOpId,_that.status,_that.reason,_that.resourceId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientOpId,  String status,  String? reason,  String? resourceId)?  $default,) {final _that = this;
switch (_that) {
case _SyncOpResult() when $default != null:
return $default(_that.clientOpId,_that.status,_that.reason,_that.resourceId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncOpResult implements SyncOpResult {
  const _SyncOpResult({required this.clientOpId, required this.status, this.reason, this.resourceId});
  factory _SyncOpResult.fromJson(Map<String, dynamic> json) => _$SyncOpResultFromJson(json);

@override final  String clientOpId;
@override final  String status;
@override final  String? reason;
@override final  String? resourceId;

/// Create a copy of SyncOpResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncOpResultCopyWith<_SyncOpResult> get copyWith => __$SyncOpResultCopyWithImpl<_SyncOpResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncOpResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncOpResult&&(identical(other.clientOpId, clientOpId) || other.clientOpId == clientOpId)&&(identical(other.status, status) || other.status == status)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.resourceId, resourceId) || other.resourceId == resourceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,clientOpId,status,reason,resourceId);
}

@override
String toString() {
    return 'SyncOpResult(clientOpId: $clientOpId, status: $status, reason: $reason, resourceId: $resourceId)';
}


}

/// @nodoc
abstract mixin class _$SyncOpResultCopyWith<$Res> implements $SyncOpResultCopyWith<$Res> {
  factory _$SyncOpResultCopyWith(_SyncOpResult value, $Res Function(_SyncOpResult) _then) = __$SyncOpResultCopyWithImpl;
@override @useResult
$Res call({
 String clientOpId, String status, String? reason, String? resourceId
});




}
/// @nodoc
class __$SyncOpResultCopyWithImpl<$Res>
    implements _$SyncOpResultCopyWith<$Res> {
  __$SyncOpResultCopyWithImpl(this._self, this._then);

  final _SyncOpResult _self;
  final $Res Function(_SyncOpResult) _then;

/// Create a copy of SyncOpResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientOpId = null,Object? status = null,Object? reason = freezed,Object? resourceId = freezed,}) {
  return _then(_SyncOpResult(
clientOpId: null == clientOpId ? _self.clientOpId : clientOpId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,resourceId: freezed == resourceId ? _self.resourceId : resourceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SyncPushResponse {

 List<SyncOpResult>? get results; int get accepted; int get total;
/// Create a copy of SyncPushResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncPushResponseCopyWith<SyncPushResponse> get copyWith => _$SyncPushResponseCopyWithImpl<SyncPushResponse>(this as SyncPushResponse, _$identity);

  /// Serializes this SyncPushResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SyncPushResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncPushResponse&&const DeepCollectionEquality().equals(other.results, _this.results)&&(identical(other.accepted, _this.accepted) || other.accepted == _this.accepted)&&(identical(other.total, _this.total) || other.total == _this.total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SyncPushResponse;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.results),_this.accepted,_this.total);
}

@override
String toString() {
  final _this = this as SyncPushResponse;
  return 'SyncPushResponse(results: ${_this.results}, accepted: ${_this.accepted}, total: ${_this.total})';
}


}

/// @nodoc
abstract mixin class $SyncPushResponseCopyWith<$Res>  {
  factory $SyncPushResponseCopyWith(SyncPushResponse value, $Res Function(SyncPushResponse) _then) = _$SyncPushResponseCopyWithImpl;
@useResult
$Res call({
 List<SyncOpResult>? results, int accepted, int total
});




}
/// @nodoc
class _$SyncPushResponseCopyWithImpl<$Res>
    implements $SyncPushResponseCopyWith<$Res> {
  _$SyncPushResponseCopyWithImpl(this._self, this._then);

  final SyncPushResponse _self;
  final $Res Function(SyncPushResponse) _then;

/// Create a copy of SyncPushResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? results = freezed,Object? accepted = null,Object? total = null,}) {
  return _then(SyncPushResponse(
results: freezed == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<SyncOpResult>?,accepted: null == accepted ? _self.accepted : accepted // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncPushResponse].
extension SyncPushResponsePatterns on SyncPushResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncPushResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncPushResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncPushResponse value)  $default,){
final _that = this;
switch (_that) {
case _SyncPushResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncPushResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SyncPushResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SyncOpResult>? results,  int accepted,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncPushResponse() when $default != null:
return $default(_that.results,_that.accepted,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SyncOpResult>? results,  int accepted,  int total)  $default,) {final _that = this;
switch (_that) {
case _SyncPushResponse():
return $default(_that.results,_that.accepted,_that.total);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SyncOpResult>? results,  int accepted,  int total)?  $default,) {final _that = this;
switch (_that) {
case _SyncPushResponse() when $default != null:
return $default(_that.results,_that.accepted,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncPushResponse implements SyncPushResponse {
  const _SyncPushResponse({ List<SyncOpResult>? results, this.accepted = 0, this.total = 0}): _results = results;
  factory _SyncPushResponse.fromJson(Map<String, dynamic> json) => _$SyncPushResponseFromJson(json);

 final  List<SyncOpResult>? _results;
@override List<SyncOpResult>? get results {
  final value = _results;
  if (value == null) return null;
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey() final  int accepted;
@override@JsonKey() final  int total;

/// Create a copy of SyncPushResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncPushResponseCopyWith<_SyncPushResponse> get copyWith => __$SyncPushResponseCopyWithImpl<_SyncPushResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncPushResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncPushResponse&&const DeepCollectionEquality().equals(other.results, _results)&&(identical(other.accepted, accepted) || other.accepted == accepted)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_results),accepted,total);
}

@override
String toString() {
    return 'SyncPushResponse(results: $results, accepted: $accepted, total: $total)';
}


}

/// @nodoc
abstract mixin class _$SyncPushResponseCopyWith<$Res> implements $SyncPushResponseCopyWith<$Res> {
  factory _$SyncPushResponseCopyWith(_SyncPushResponse value, $Res Function(_SyncPushResponse) _then) = __$SyncPushResponseCopyWithImpl;
@override @useResult
$Res call({
 List<SyncOpResult>? results, int accepted, int total
});




}
/// @nodoc
class __$SyncPushResponseCopyWithImpl<$Res>
    implements _$SyncPushResponseCopyWith<$Res> {
  __$SyncPushResponseCopyWithImpl(this._self, this._then);

  final _SyncPushResponse _self;
  final $Res Function(_SyncPushResponse) _then;

/// Create a copy of SyncPushResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? results = freezed,Object? accepted = null,Object? total = null,}) {
  return _then(_SyncPushResponse(
results: freezed == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<SyncOpResult>?,accepted: null == accepted ? _self.accepted : accepted // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SyncPullDelta {

 String get entityType; String get entityId; String get action; Map<String, dynamic>? get payload;
/// Create a copy of SyncPullDelta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncPullDeltaCopyWith<SyncPullDelta> get copyWith => _$SyncPullDeltaCopyWithImpl<SyncPullDelta>(this as SyncPullDelta, _$identity);

  /// Serializes this SyncPullDelta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SyncPullDelta;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncPullDelta&&(identical(other.entityType, _this.entityType) || other.entityType == _this.entityType)&&(identical(other.entityId, _this.entityId) || other.entityId == _this.entityId)&&(identical(other.action, _this.action) || other.action == _this.action)&&const DeepCollectionEquality().equals(other.payload, _this.payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SyncPullDelta;
  return Object.hash(runtimeType,_this.entityType,_this.entityId,_this.action,const DeepCollectionEquality().hash(_this.payload));
}

@override
String toString() {
  final _this = this as SyncPullDelta;
  return 'SyncPullDelta(entityType: ${_this.entityType}, entityId: ${_this.entityId}, action: ${_this.action}, payload: ${_this.payload})';
}


}

/// @nodoc
abstract mixin class $SyncPullDeltaCopyWith<$Res>  {
  factory $SyncPullDeltaCopyWith(SyncPullDelta value, $Res Function(SyncPullDelta) _then) = _$SyncPullDeltaCopyWithImpl;
@useResult
$Res call({
 String entityType, String entityId, String action, Map<String, dynamic>? payload
});




}
/// @nodoc
class _$SyncPullDeltaCopyWithImpl<$Res>
    implements $SyncPullDeltaCopyWith<$Res> {
  _$SyncPullDeltaCopyWithImpl(this._self, this._then);

  final SyncPullDelta _self;
  final $Res Function(SyncPullDelta) _then;

/// Create a copy of SyncPullDelta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entityType = null,Object? entityId = null,Object? action = null,Object? payload = freezed,}) {
  return _then(SyncPullDelta(
entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,payload: freezed == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncPullDelta].
extension SyncPullDeltaPatterns on SyncPullDelta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncPullDelta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncPullDelta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncPullDelta value)  $default,){
final _that = this;
switch (_that) {
case _SyncPullDelta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncPullDelta value)?  $default,){
final _that = this;
switch (_that) {
case _SyncPullDelta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String entityType,  String entityId,  String action,  Map<String, dynamic>? payload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncPullDelta() when $default != null:
return $default(_that.entityType,_that.entityId,_that.action,_that.payload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String entityType,  String entityId,  String action,  Map<String, dynamic>? payload)  $default,) {final _that = this;
switch (_that) {
case _SyncPullDelta():
return $default(_that.entityType,_that.entityId,_that.action,_that.payload);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String entityType,  String entityId,  String action,  Map<String, dynamic>? payload)?  $default,) {final _that = this;
switch (_that) {
case _SyncPullDelta() when $default != null:
return $default(_that.entityType,_that.entityId,_that.action,_that.payload);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncPullDelta implements SyncPullDelta {
  const _SyncPullDelta({required this.entityType, required this.entityId, required this.action,  Map<String, dynamic>? payload}): _payload = payload;
  factory _SyncPullDelta.fromJson(Map<String, dynamic> json) => _$SyncPullDeltaFromJson(json);

@override final  String entityType;
@override final  String entityId;
@override final  String action;
 final  Map<String, dynamic>? _payload;
@override Map<String, dynamic>? get payload {
  final value = _payload;
  if (value == null) return null;
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of SyncPullDelta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncPullDeltaCopyWith<_SyncPullDelta> get copyWith => __$SyncPullDeltaCopyWithImpl<_SyncPullDelta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncPullDeltaToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncPullDelta&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.action, action) || other.action == action)&&const DeepCollectionEquality().equals(other.payload, _payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,entityType,entityId,action,const DeepCollectionEquality().hash(_payload));
}

@override
String toString() {
    return 'SyncPullDelta(entityType: $entityType, entityId: $entityId, action: $action, payload: $payload)';
}


}

/// @nodoc
abstract mixin class _$SyncPullDeltaCopyWith<$Res> implements $SyncPullDeltaCopyWith<$Res> {
  factory _$SyncPullDeltaCopyWith(_SyncPullDelta value, $Res Function(_SyncPullDelta) _then) = __$SyncPullDeltaCopyWithImpl;
@override @useResult
$Res call({
 String entityType, String entityId, String action, Map<String, dynamic>? payload
});




}
/// @nodoc
class __$SyncPullDeltaCopyWithImpl<$Res>
    implements _$SyncPullDeltaCopyWith<$Res> {
  __$SyncPullDeltaCopyWithImpl(this._self, this._then);

  final _SyncPullDelta _self;
  final $Res Function(_SyncPullDelta) _then;

/// Create a copy of SyncPullDelta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entityType = null,Object? entityId = null,Object? action = null,Object? payload = freezed,}) {
  return _then(_SyncPullDelta(
entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,payload: freezed == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}


/// @nodoc
mixin _$SyncPullResponse {

 int get cursor; int get nextCursor; List<SyncPullDelta>? get deltas;
/// Create a copy of SyncPullResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncPullResponseCopyWith<SyncPullResponse> get copyWith => _$SyncPullResponseCopyWithImpl<SyncPullResponse>(this as SyncPullResponse, _$identity);

  /// Serializes this SyncPullResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SyncPullResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncPullResponse&&(identical(other.cursor, _this.cursor) || other.cursor == _this.cursor)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor)&&const DeepCollectionEquality().equals(other.deltas, _this.deltas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SyncPullResponse;
  return Object.hash(runtimeType,_this.cursor,_this.nextCursor,const DeepCollectionEquality().hash(_this.deltas));
}

@override
String toString() {
  final _this = this as SyncPullResponse;
  return 'SyncPullResponse(cursor: ${_this.cursor}, nextCursor: ${_this.nextCursor}, deltas: ${_this.deltas})';
}


}

/// @nodoc
abstract mixin class $SyncPullResponseCopyWith<$Res>  {
  factory $SyncPullResponseCopyWith(SyncPullResponse value, $Res Function(SyncPullResponse) _then) = _$SyncPullResponseCopyWithImpl;
@useResult
$Res call({
 int cursor, int nextCursor, List<SyncPullDelta>? deltas
});




}
/// @nodoc
class _$SyncPullResponseCopyWithImpl<$Res>
    implements $SyncPullResponseCopyWith<$Res> {
  _$SyncPullResponseCopyWithImpl(this._self, this._then);

  final SyncPullResponse _self;
  final $Res Function(SyncPullResponse) _then;

/// Create a copy of SyncPullResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cursor = null,Object? nextCursor = null,Object? deltas = freezed,}) {
  return _then(SyncPullResponse(
cursor: null == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as int,nextCursor: null == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as int,deltas: freezed == deltas ? _self.deltas : deltas // ignore: cast_nullable_to_non_nullable
as List<SyncPullDelta>?,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncPullResponse].
extension SyncPullResponsePatterns on SyncPullResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncPullResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncPullResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncPullResponse value)  $default,){
final _that = this;
switch (_that) {
case _SyncPullResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncPullResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SyncPullResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int cursor,  int nextCursor,  List<SyncPullDelta>? deltas)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncPullResponse() when $default != null:
return $default(_that.cursor,_that.nextCursor,_that.deltas);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int cursor,  int nextCursor,  List<SyncPullDelta>? deltas)  $default,) {final _that = this;
switch (_that) {
case _SyncPullResponse():
return $default(_that.cursor,_that.nextCursor,_that.deltas);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int cursor,  int nextCursor,  List<SyncPullDelta>? deltas)?  $default,) {final _that = this;
switch (_that) {
case _SyncPullResponse() when $default != null:
return $default(_that.cursor,_that.nextCursor,_that.deltas);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncPullResponse implements SyncPullResponse {
  const _SyncPullResponse({this.cursor = 0, this.nextCursor = 0,  List<SyncPullDelta>? deltas}): _deltas = deltas;
  factory _SyncPullResponse.fromJson(Map<String, dynamic> json) => _$SyncPullResponseFromJson(json);

@override@JsonKey() final  int cursor;
@override@JsonKey() final  int nextCursor;
 final  List<SyncPullDelta>? _deltas;
@override List<SyncPullDelta>? get deltas {
  final value = _deltas;
  if (value == null) return null;
  if (_deltas is EqualUnmodifiableListView) return _deltas;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of SyncPullResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncPullResponseCopyWith<_SyncPullResponse> get copyWith => __$SyncPullResponseCopyWithImpl<_SyncPullResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncPullResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncPullResponse&&(identical(other.cursor, cursor) || other.cursor == cursor)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&const DeepCollectionEquality().equals(other.deltas, _deltas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,cursor,nextCursor,const DeepCollectionEquality().hash(_deltas));
}

@override
String toString() {
    return 'SyncPullResponse(cursor: $cursor, nextCursor: $nextCursor, deltas: $deltas)';
}


}

/// @nodoc
abstract mixin class _$SyncPullResponseCopyWith<$Res> implements $SyncPullResponseCopyWith<$Res> {
  factory _$SyncPullResponseCopyWith(_SyncPullResponse value, $Res Function(_SyncPullResponse) _then) = __$SyncPullResponseCopyWithImpl;
@override @useResult
$Res call({
 int cursor, int nextCursor, List<SyncPullDelta>? deltas
});




}
/// @nodoc
class __$SyncPullResponseCopyWithImpl<$Res>
    implements _$SyncPullResponseCopyWith<$Res> {
  __$SyncPullResponseCopyWithImpl(this._self, this._then);

  final _SyncPullResponse _self;
  final $Res Function(_SyncPullResponse) _then;

/// Create a copy of SyncPullResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cursor = null,Object? nextCursor = null,Object? deltas = freezed,}) {
  return _then(_SyncPullResponse(
cursor: null == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as int,nextCursor: null == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as int,deltas: freezed == deltas ? _self._deltas : deltas // ignore: cast_nullable_to_non_nullable
as List<SyncPullDelta>?,
  ));
}


}

// dart format on
