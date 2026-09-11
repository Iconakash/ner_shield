// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'segment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AccessibilitySegment {

 String get segmentId; String? get accClassification; double? get accScore; List<Map<String, dynamic>>? get factors; String? get updatedAt;
/// Create a copy of AccessibilitySegment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccessibilitySegmentCopyWith<AccessibilitySegment> get copyWith => _$AccessibilitySegmentCopyWithImpl<AccessibilitySegment>(this as AccessibilitySegment, _$identity);

  /// Serializes this AccessibilitySegment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AccessibilitySegment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccessibilitySegment&&(identical(other.segmentId, _this.segmentId) || other.segmentId == _this.segmentId)&&(identical(other.accClassification, _this.accClassification) || other.accClassification == _this.accClassification)&&(identical(other.accScore, _this.accScore) || other.accScore == _this.accScore)&&const DeepCollectionEquality().equals(other.factors, _this.factors)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AccessibilitySegment;
  return Object.hash(runtimeType,_this.segmentId,_this.accClassification,_this.accScore,const DeepCollectionEquality().hash(_this.factors),_this.updatedAt);
}

@override
String toString() {
  final _this = this as AccessibilitySegment;
  return 'AccessibilitySegment(segmentId: ${_this.segmentId}, accClassification: ${_this.accClassification}, accScore: ${_this.accScore}, factors: ${_this.factors}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $AccessibilitySegmentCopyWith<$Res>  {
  factory $AccessibilitySegmentCopyWith(AccessibilitySegment value, $Res Function(AccessibilitySegment) _then) = _$AccessibilitySegmentCopyWithImpl;
@useResult
$Res call({
 String segmentId, String? accClassification, double? accScore, List<Map<String, dynamic>>? factors, String? updatedAt
});




}
/// @nodoc
class _$AccessibilitySegmentCopyWithImpl<$Res>
    implements $AccessibilitySegmentCopyWith<$Res> {
  _$AccessibilitySegmentCopyWithImpl(this._self, this._then);

  final AccessibilitySegment _self;
  final $Res Function(AccessibilitySegment) _then;

/// Create a copy of AccessibilitySegment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? segmentId = null,Object? accClassification = freezed,Object? accScore = freezed,Object? factors = freezed,Object? updatedAt = freezed,}) {
  return _then(AccessibilitySegment(
segmentId: null == segmentId ? _self.segmentId : segmentId // ignore: cast_nullable_to_non_nullable
as String,accClassification: freezed == accClassification ? _self.accClassification : accClassification // ignore: cast_nullable_to_non_nullable
as String?,accScore: freezed == accScore ? _self.accScore : accScore // ignore: cast_nullable_to_non_nullable
as double?,factors: freezed == factors ? _self.factors : factors // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AccessibilitySegment].
extension AccessibilitySegmentPatterns on AccessibilitySegment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccessibilitySegment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccessibilitySegment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccessibilitySegment value)  $default,){
final _that = this;
switch (_that) {
case _AccessibilitySegment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccessibilitySegment value)?  $default,){
final _that = this;
switch (_that) {
case _AccessibilitySegment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String segmentId,  String? accClassification,  double? accScore,  List<Map<String, dynamic>>? factors,  String? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccessibilitySegment() when $default != null:
return $default(_that.segmentId,_that.accClassification,_that.accScore,_that.factors,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String segmentId,  String? accClassification,  double? accScore,  List<Map<String, dynamic>>? factors,  String? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _AccessibilitySegment():
return $default(_that.segmentId,_that.accClassification,_that.accScore,_that.factors,_that.updatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String segmentId,  String? accClassification,  double? accScore,  List<Map<String, dynamic>>? factors,  String? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _AccessibilitySegment() when $default != null:
return $default(_that.segmentId,_that.accClassification,_that.accScore,_that.factors,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AccessibilitySegment implements AccessibilitySegment {
  const _AccessibilitySegment({required this.segmentId, this.accClassification, this.accScore,  List<Map<String, dynamic>>? factors, this.updatedAt}): _factors = factors;
  factory _AccessibilitySegment.fromJson(Map<String, dynamic> json) => _$AccessibilitySegmentFromJson(json);

@override final  String segmentId;
@override final  String? accClassification;
@override final  double? accScore;
 final  List<Map<String, dynamic>>? _factors;
@override List<Map<String, dynamic>>? get factors {
  final value = _factors;
  if (value == null) return null;
  if (_factors is EqualUnmodifiableListView) return _factors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? updatedAt;

/// Create a copy of AccessibilitySegment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccessibilitySegmentCopyWith<_AccessibilitySegment> get copyWith => __$AccessibilitySegmentCopyWithImpl<_AccessibilitySegment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccessibilitySegmentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccessibilitySegment&&(identical(other.segmentId, segmentId) || other.segmentId == segmentId)&&(identical(other.accClassification, accClassification) || other.accClassification == accClassification)&&(identical(other.accScore, accScore) || other.accScore == accScore)&&const DeepCollectionEquality().equals(other.factors, _factors)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,segmentId,accClassification,accScore,const DeepCollectionEquality().hash(_factors),updatedAt);
}

@override
String toString() {
    return 'AccessibilitySegment(segmentId: $segmentId, accClassification: $accClassification, accScore: $accScore, factors: $factors, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AccessibilitySegmentCopyWith<$Res> implements $AccessibilitySegmentCopyWith<$Res> {
  factory _$AccessibilitySegmentCopyWith(_AccessibilitySegment value, $Res Function(_AccessibilitySegment) _then) = __$AccessibilitySegmentCopyWithImpl;
@override @useResult
$Res call({
 String segmentId, String? accClassification, double? accScore, List<Map<String, dynamic>>? factors, String? updatedAt
});




}
/// @nodoc
class __$AccessibilitySegmentCopyWithImpl<$Res>
    implements _$AccessibilitySegmentCopyWith<$Res> {
  __$AccessibilitySegmentCopyWithImpl(this._self, this._then);

  final _AccessibilitySegment _self;
  final $Res Function(_AccessibilitySegment) _then;

/// Create a copy of AccessibilitySegment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? segmentId = null,Object? accClassification = freezed,Object? accScore = freezed,Object? factors = freezed,Object? updatedAt = freezed,}) {
  return _then(_AccessibilitySegment(
segmentId: null == segmentId ? _self.segmentId : segmentId // ignore: cast_nullable_to_non_nullable
as String,accClassification: freezed == accClassification ? _self.accClassification : accClassification // ignore: cast_nullable_to_non_nullable
as String?,accScore: freezed == accScore ? _self.accScore : accScore // ignore: cast_nullable_to_non_nullable
as double?,factors: freezed == factors ? _self._factors : factors // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
