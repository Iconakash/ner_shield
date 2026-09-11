// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'risk_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RiskPrediction {

 String get segmentId; String? get roadCode; String? get districtCode; String? get districtName; double? get riskCurrent; double? get risk6h; double? get risk12h; double? get risk24h; double? get risk72h; String? get overallLabel; String? get severity; List<Map<String, dynamic>>? get topFactors; String? get summarySentence; double? get baseValue; String? get mode; String? get modelName; String? get modelVersion; String? get computedAt;
/// Create a copy of RiskPrediction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RiskPredictionCopyWith<RiskPrediction> get copyWith => _$RiskPredictionCopyWithImpl<RiskPrediction>(this as RiskPrediction, _$identity);

  /// Serializes this RiskPrediction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RiskPrediction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RiskPrediction&&(identical(other.segmentId, _this.segmentId) || other.segmentId == _this.segmentId)&&(identical(other.roadCode, _this.roadCode) || other.roadCode == _this.roadCode)&&(identical(other.districtCode, _this.districtCode) || other.districtCode == _this.districtCode)&&(identical(other.districtName, _this.districtName) || other.districtName == _this.districtName)&&(identical(other.riskCurrent, _this.riskCurrent) || other.riskCurrent == _this.riskCurrent)&&(identical(other.risk6h, _this.risk6h) || other.risk6h == _this.risk6h)&&(identical(other.risk12h, _this.risk12h) || other.risk12h == _this.risk12h)&&(identical(other.risk24h, _this.risk24h) || other.risk24h == _this.risk24h)&&(identical(other.risk72h, _this.risk72h) || other.risk72h == _this.risk72h)&&(identical(other.overallLabel, _this.overallLabel) || other.overallLabel == _this.overallLabel)&&(identical(other.severity, _this.severity) || other.severity == _this.severity)&&const DeepCollectionEquality().equals(other.topFactors, _this.topFactors)&&(identical(other.summarySentence, _this.summarySentence) || other.summarySentence == _this.summarySentence)&&(identical(other.baseValue, _this.baseValue) || other.baseValue == _this.baseValue)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.modelName, _this.modelName) || other.modelName == _this.modelName)&&(identical(other.modelVersion, _this.modelVersion) || other.modelVersion == _this.modelVersion)&&(identical(other.computedAt, _this.computedAt) || other.computedAt == _this.computedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RiskPrediction;
  return Object.hash(runtimeType,_this.segmentId,_this.roadCode,_this.districtCode,_this.districtName,_this.riskCurrent,_this.risk6h,_this.risk12h,_this.risk24h,_this.risk72h,_this.overallLabel,_this.severity,const DeepCollectionEquality().hash(_this.topFactors),_this.summarySentence,_this.baseValue,_this.mode,_this.modelName,_this.modelVersion,_this.computedAt);
}

@override
String toString() {
  final _this = this as RiskPrediction;
  return 'RiskPrediction(segmentId: ${_this.segmentId}, roadCode: ${_this.roadCode}, districtCode: ${_this.districtCode}, districtName: ${_this.districtName}, riskCurrent: ${_this.riskCurrent}, risk6h: ${_this.risk6h}, risk12h: ${_this.risk12h}, risk24h: ${_this.risk24h}, risk72h: ${_this.risk72h}, overallLabel: ${_this.overallLabel}, severity: ${_this.severity}, topFactors: ${_this.topFactors}, summarySentence: ${_this.summarySentence}, baseValue: ${_this.baseValue}, mode: ${_this.mode}, modelName: ${_this.modelName}, modelVersion: ${_this.modelVersion}, computedAt: ${_this.computedAt})';
}


}

/// @nodoc
abstract mixin class $RiskPredictionCopyWith<$Res>  {
  factory $RiskPredictionCopyWith(RiskPrediction value, $Res Function(RiskPrediction) _then) = _$RiskPredictionCopyWithImpl;
@useResult
$Res call({
 String segmentId, String? roadCode, String? districtCode, String? districtName, double? riskCurrent, double? risk6h, double? risk12h, double? risk24h, double? risk72h, String? overallLabel, String? severity, List<Map<String, dynamic>>? topFactors, String? summarySentence, double? baseValue, String? mode, String? modelName, String? modelVersion, String? computedAt
});




}
/// @nodoc
class _$RiskPredictionCopyWithImpl<$Res>
    implements $RiskPredictionCopyWith<$Res> {
  _$RiskPredictionCopyWithImpl(this._self, this._then);

  final RiskPrediction _self;
  final $Res Function(RiskPrediction) _then;

/// Create a copy of RiskPrediction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? segmentId = null,Object? roadCode = freezed,Object? districtCode = freezed,Object? districtName = freezed,Object? riskCurrent = freezed,Object? risk6h = freezed,Object? risk12h = freezed,Object? risk24h = freezed,Object? risk72h = freezed,Object? overallLabel = freezed,Object? severity = freezed,Object? topFactors = freezed,Object? summarySentence = freezed,Object? baseValue = freezed,Object? mode = freezed,Object? modelName = freezed,Object? modelVersion = freezed,Object? computedAt = freezed,}) {
  return _then(RiskPrediction(
segmentId: null == segmentId ? _self.segmentId : segmentId // ignore: cast_nullable_to_non_nullable
as String,roadCode: freezed == roadCode ? _self.roadCode : roadCode // ignore: cast_nullable_to_non_nullable
as String?,districtCode: freezed == districtCode ? _self.districtCode : districtCode // ignore: cast_nullable_to_non_nullable
as String?,districtName: freezed == districtName ? _self.districtName : districtName // ignore: cast_nullable_to_non_nullable
as String?,riskCurrent: freezed == riskCurrent ? _self.riskCurrent : riskCurrent // ignore: cast_nullable_to_non_nullable
as double?,risk6h: freezed == risk6h ? _self.risk6h : risk6h // ignore: cast_nullable_to_non_nullable
as double?,risk12h: freezed == risk12h ? _self.risk12h : risk12h // ignore: cast_nullable_to_non_nullable
as double?,risk24h: freezed == risk24h ? _self.risk24h : risk24h // ignore: cast_nullable_to_non_nullable
as double?,risk72h: freezed == risk72h ? _self.risk72h : risk72h // ignore: cast_nullable_to_non_nullable
as double?,overallLabel: freezed == overallLabel ? _self.overallLabel : overallLabel // ignore: cast_nullable_to_non_nullable
as String?,severity: freezed == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String?,topFactors: freezed == topFactors ? _self.topFactors : topFactors // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>?,summarySentence: freezed == summarySentence ? _self.summarySentence : summarySentence // ignore: cast_nullable_to_non_nullable
as String?,baseValue: freezed == baseValue ? _self.baseValue : baseValue // ignore: cast_nullable_to_non_nullable
as double?,mode: freezed == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String?,modelName: freezed == modelName ? _self.modelName : modelName // ignore: cast_nullable_to_non_nullable
as String?,modelVersion: freezed == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String?,computedAt: freezed == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RiskPrediction].
extension RiskPredictionPatterns on RiskPrediction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RiskPrediction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RiskPrediction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RiskPrediction value)  $default,){
final _that = this;
switch (_that) {
case _RiskPrediction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RiskPrediction value)?  $default,){
final _that = this;
switch (_that) {
case _RiskPrediction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String segmentId,  String? roadCode,  String? districtCode,  String? districtName,  double? riskCurrent,  double? risk6h,  double? risk12h,  double? risk24h,  double? risk72h,  String? overallLabel,  String? severity,  List<Map<String, dynamic>>? topFactors,  String? summarySentence,  double? baseValue,  String? mode,  String? modelName,  String? modelVersion,  String? computedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RiskPrediction() when $default != null:
return $default(_that.segmentId,_that.roadCode,_that.districtCode,_that.districtName,_that.riskCurrent,_that.risk6h,_that.risk12h,_that.risk24h,_that.risk72h,_that.overallLabel,_that.severity,_that.topFactors,_that.summarySentence,_that.baseValue,_that.mode,_that.modelName,_that.modelVersion,_that.computedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String segmentId,  String? roadCode,  String? districtCode,  String? districtName,  double? riskCurrent,  double? risk6h,  double? risk12h,  double? risk24h,  double? risk72h,  String? overallLabel,  String? severity,  List<Map<String, dynamic>>? topFactors,  String? summarySentence,  double? baseValue,  String? mode,  String? modelName,  String? modelVersion,  String? computedAt)  $default,) {final _that = this;
switch (_that) {
case _RiskPrediction():
return $default(_that.segmentId,_that.roadCode,_that.districtCode,_that.districtName,_that.riskCurrent,_that.risk6h,_that.risk12h,_that.risk24h,_that.risk72h,_that.overallLabel,_that.severity,_that.topFactors,_that.summarySentence,_that.baseValue,_that.mode,_that.modelName,_that.modelVersion,_that.computedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String segmentId,  String? roadCode,  String? districtCode,  String? districtName,  double? riskCurrent,  double? risk6h,  double? risk12h,  double? risk24h,  double? risk72h,  String? overallLabel,  String? severity,  List<Map<String, dynamic>>? topFactors,  String? summarySentence,  double? baseValue,  String? mode,  String? modelName,  String? modelVersion,  String? computedAt)?  $default,) {final _that = this;
switch (_that) {
case _RiskPrediction() when $default != null:
return $default(_that.segmentId,_that.roadCode,_that.districtCode,_that.districtName,_that.riskCurrent,_that.risk6h,_that.risk12h,_that.risk24h,_that.risk72h,_that.overallLabel,_that.severity,_that.topFactors,_that.summarySentence,_that.baseValue,_that.mode,_that.modelName,_that.modelVersion,_that.computedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RiskPrediction extends RiskPrediction {
  const _RiskPrediction({required this.segmentId, this.roadCode, this.districtCode, this.districtName, this.riskCurrent, this.risk6h, this.risk12h, this.risk24h, this.risk72h, this.overallLabel, this.severity,  List<Map<String, dynamic>>? topFactors, this.summarySentence, this.baseValue, this.mode, this.modelName, this.modelVersion, this.computedAt}): _topFactors = topFactors,super._();
  factory _RiskPrediction.fromJson(Map<String, dynamic> json) => _$RiskPredictionFromJson(json);

@override final  String segmentId;
@override final  String? roadCode;
@override final  String? districtCode;
@override final  String? districtName;
@override final  double? riskCurrent;
@override final  double? risk6h;
@override final  double? risk12h;
@override final  double? risk24h;
@override final  double? risk72h;
@override final  String? overallLabel;
@override final  String? severity;
 final  List<Map<String, dynamic>>? _topFactors;
@override List<Map<String, dynamic>>? get topFactors {
  final value = _topFactors;
  if (value == null) return null;
  if (_topFactors is EqualUnmodifiableListView) return _topFactors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? summarySentence;
@override final  double? baseValue;
@override final  String? mode;
@override final  String? modelName;
@override final  String? modelVersion;
@override final  String? computedAt;

/// Create a copy of RiskPrediction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RiskPredictionCopyWith<_RiskPrediction> get copyWith => __$RiskPredictionCopyWithImpl<_RiskPrediction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RiskPredictionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RiskPrediction&&(identical(other.segmentId, segmentId) || other.segmentId == segmentId)&&(identical(other.roadCode, roadCode) || other.roadCode == roadCode)&&(identical(other.districtCode, districtCode) || other.districtCode == districtCode)&&(identical(other.districtName, districtName) || other.districtName == districtName)&&(identical(other.riskCurrent, riskCurrent) || other.riskCurrent == riskCurrent)&&(identical(other.risk6h, risk6h) || other.risk6h == risk6h)&&(identical(other.risk12h, risk12h) || other.risk12h == risk12h)&&(identical(other.risk24h, risk24h) || other.risk24h == risk24h)&&(identical(other.risk72h, risk72h) || other.risk72h == risk72h)&&(identical(other.overallLabel, overallLabel) || other.overallLabel == overallLabel)&&(identical(other.severity, severity) || other.severity == severity)&&const DeepCollectionEquality().equals(other.topFactors, _topFactors)&&(identical(other.summarySentence, summarySentence) || other.summarySentence == summarySentence)&&(identical(other.baseValue, baseValue) || other.baseValue == baseValue)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.modelName, modelName) || other.modelName == modelName)&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.computedAt, computedAt) || other.computedAt == computedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,segmentId,roadCode,districtCode,districtName,riskCurrent,risk6h,risk12h,risk24h,risk72h,overallLabel,severity,const DeepCollectionEquality().hash(_topFactors),summarySentence,baseValue,mode,modelName,modelVersion,computedAt);
}

@override
String toString() {
    return 'RiskPrediction(segmentId: $segmentId, roadCode: $roadCode, districtCode: $districtCode, districtName: $districtName, riskCurrent: $riskCurrent, risk6h: $risk6h, risk12h: $risk12h, risk24h: $risk24h, risk72h: $risk72h, overallLabel: $overallLabel, severity: $severity, topFactors: $topFactors, summarySentence: $summarySentence, baseValue: $baseValue, mode: $mode, modelName: $modelName, modelVersion: $modelVersion, computedAt: $computedAt)';
}


}

/// @nodoc
abstract mixin class _$RiskPredictionCopyWith<$Res> implements $RiskPredictionCopyWith<$Res> {
  factory _$RiskPredictionCopyWith(_RiskPrediction value, $Res Function(_RiskPrediction) _then) = __$RiskPredictionCopyWithImpl;
@override @useResult
$Res call({
 String segmentId, String? roadCode, String? districtCode, String? districtName, double? riskCurrent, double? risk6h, double? risk12h, double? risk24h, double? risk72h, String? overallLabel, String? severity, List<Map<String, dynamic>>? topFactors, String? summarySentence, double? baseValue, String? mode, String? modelName, String? modelVersion, String? computedAt
});




}
/// @nodoc
class __$RiskPredictionCopyWithImpl<$Res>
    implements _$RiskPredictionCopyWith<$Res> {
  __$RiskPredictionCopyWithImpl(this._self, this._then);

  final _RiskPrediction _self;
  final $Res Function(_RiskPrediction) _then;

/// Create a copy of RiskPrediction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? segmentId = null,Object? roadCode = freezed,Object? districtCode = freezed,Object? districtName = freezed,Object? riskCurrent = freezed,Object? risk6h = freezed,Object? risk12h = freezed,Object? risk24h = freezed,Object? risk72h = freezed,Object? overallLabel = freezed,Object? severity = freezed,Object? topFactors = freezed,Object? summarySentence = freezed,Object? baseValue = freezed,Object? mode = freezed,Object? modelName = freezed,Object? modelVersion = freezed,Object? computedAt = freezed,}) {
  return _then(_RiskPrediction(
segmentId: null == segmentId ? _self.segmentId : segmentId // ignore: cast_nullable_to_non_nullable
as String,roadCode: freezed == roadCode ? _self.roadCode : roadCode // ignore: cast_nullable_to_non_nullable
as String?,districtCode: freezed == districtCode ? _self.districtCode : districtCode // ignore: cast_nullable_to_non_nullable
as String?,districtName: freezed == districtName ? _self.districtName : districtName // ignore: cast_nullable_to_non_nullable
as String?,riskCurrent: freezed == riskCurrent ? _self.riskCurrent : riskCurrent // ignore: cast_nullable_to_non_nullable
as double?,risk6h: freezed == risk6h ? _self.risk6h : risk6h // ignore: cast_nullable_to_non_nullable
as double?,risk12h: freezed == risk12h ? _self.risk12h : risk12h // ignore: cast_nullable_to_non_nullable
as double?,risk24h: freezed == risk24h ? _self.risk24h : risk24h // ignore: cast_nullable_to_non_nullable
as double?,risk72h: freezed == risk72h ? _self.risk72h : risk72h // ignore: cast_nullable_to_non_nullable
as double?,overallLabel: freezed == overallLabel ? _self.overallLabel : overallLabel // ignore: cast_nullable_to_non_nullable
as String?,severity: freezed == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String?,topFactors: freezed == topFactors ? _self._topFactors : topFactors // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>?,summarySentence: freezed == summarySentence ? _self.summarySentence : summarySentence // ignore: cast_nullable_to_non_nullable
as String?,baseValue: freezed == baseValue ? _self.baseValue : baseValue // ignore: cast_nullable_to_non_nullable
as double?,mode: freezed == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String?,modelName: freezed == modelName ? _self.modelName : modelName // ignore: cast_nullable_to_non_nullable
as String?,modelVersion: freezed == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String?,computedAt: freezed == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$RiskFactor {

 String get feature; double? get contribution; String? get label;
/// Create a copy of RiskFactor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RiskFactorCopyWith<RiskFactor> get copyWith => _$RiskFactorCopyWithImpl<RiskFactor>(this as RiskFactor, _$identity);

  /// Serializes this RiskFactor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RiskFactor;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RiskFactor&&(identical(other.feature, _this.feature) || other.feature == _this.feature)&&(identical(other.contribution, _this.contribution) || other.contribution == _this.contribution)&&(identical(other.label, _this.label) || other.label == _this.label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RiskFactor;
  return Object.hash(runtimeType,_this.feature,_this.contribution,_this.label);
}

@override
String toString() {
  final _this = this as RiskFactor;
  return 'RiskFactor(feature: ${_this.feature}, contribution: ${_this.contribution}, label: ${_this.label})';
}


}

/// @nodoc
abstract mixin class $RiskFactorCopyWith<$Res>  {
  factory $RiskFactorCopyWith(RiskFactor value, $Res Function(RiskFactor) _then) = _$RiskFactorCopyWithImpl;
@useResult
$Res call({
 String feature, double? contribution, String? label
});




}
/// @nodoc
class _$RiskFactorCopyWithImpl<$Res>
    implements $RiskFactorCopyWith<$Res> {
  _$RiskFactorCopyWithImpl(this._self, this._then);

  final RiskFactor _self;
  final $Res Function(RiskFactor) _then;

/// Create a copy of RiskFactor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? feature = null,Object? contribution = freezed,Object? label = freezed,}) {
  return _then(RiskFactor(
feature: null == feature ? _self.feature : feature // ignore: cast_nullable_to_non_nullable
as String,contribution: freezed == contribution ? _self.contribution : contribution // ignore: cast_nullable_to_non_nullable
as double?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RiskFactor].
extension RiskFactorPatterns on RiskFactor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RiskFactor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RiskFactor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RiskFactor value)  $default,){
final _that = this;
switch (_that) {
case _RiskFactor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RiskFactor value)?  $default,){
final _that = this;
switch (_that) {
case _RiskFactor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String feature,  double? contribution,  String? label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RiskFactor() when $default != null:
return $default(_that.feature,_that.contribution,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String feature,  double? contribution,  String? label)  $default,) {final _that = this;
switch (_that) {
case _RiskFactor():
return $default(_that.feature,_that.contribution,_that.label);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String feature,  double? contribution,  String? label)?  $default,) {final _that = this;
switch (_that) {
case _RiskFactor() when $default != null:
return $default(_that.feature,_that.contribution,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RiskFactor implements RiskFactor {
  const _RiskFactor({required this.feature, this.contribution, this.label});
  factory _RiskFactor.fromJson(Map<String, dynamic> json) => _$RiskFactorFromJson(json);

@override final  String feature;
@override final  double? contribution;
@override final  String? label;

/// Create a copy of RiskFactor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RiskFactorCopyWith<_RiskFactor> get copyWith => __$RiskFactorCopyWithImpl<_RiskFactor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RiskFactorToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RiskFactor&&(identical(other.feature, feature) || other.feature == feature)&&(identical(other.contribution, contribution) || other.contribution == contribution)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,feature,contribution,label);
}

@override
String toString() {
    return 'RiskFactor(feature: $feature, contribution: $contribution, label: $label)';
}


}

/// @nodoc
abstract mixin class _$RiskFactorCopyWith<$Res> implements $RiskFactorCopyWith<$Res> {
  factory _$RiskFactorCopyWith(_RiskFactor value, $Res Function(_RiskFactor) _then) = __$RiskFactorCopyWithImpl;
@override @useResult
$Res call({
 String feature, double? contribution, String? label
});




}
/// @nodoc
class __$RiskFactorCopyWithImpl<$Res>
    implements _$RiskFactorCopyWith<$Res> {
  __$RiskFactorCopyWithImpl(this._self, this._then);

  final _RiskFactor _self;
  final $Res Function(_RiskFactor) _then;

/// Create a copy of RiskFactor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? feature = null,Object? contribution = freezed,Object? label = freezed,}) {
  return _then(_RiskFactor(
feature: null == feature ? _self.feature : feature // ignore: cast_nullable_to_non_nullable
as String,contribution: freezed == contribution ? _self.contribution : contribution // ignore: cast_nullable_to_non_nullable
as double?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$RiskExplain {

 String get segmentId; double? get baseValue; List<RiskFactor>? get factors; String? get narrative;
/// Create a copy of RiskExplain
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RiskExplainCopyWith<RiskExplain> get copyWith => _$RiskExplainCopyWithImpl<RiskExplain>(this as RiskExplain, _$identity);

  /// Serializes this RiskExplain to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RiskExplain;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RiskExplain&&(identical(other.segmentId, _this.segmentId) || other.segmentId == _this.segmentId)&&(identical(other.baseValue, _this.baseValue) || other.baseValue == _this.baseValue)&&const DeepCollectionEquality().equals(other.factors, _this.factors)&&(identical(other.narrative, _this.narrative) || other.narrative == _this.narrative));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RiskExplain;
  return Object.hash(runtimeType,_this.segmentId,_this.baseValue,const DeepCollectionEquality().hash(_this.factors),_this.narrative);
}

@override
String toString() {
  final _this = this as RiskExplain;
  return 'RiskExplain(segmentId: ${_this.segmentId}, baseValue: ${_this.baseValue}, factors: ${_this.factors}, narrative: ${_this.narrative})';
}


}

/// @nodoc
abstract mixin class $RiskExplainCopyWith<$Res>  {
  factory $RiskExplainCopyWith(RiskExplain value, $Res Function(RiskExplain) _then) = _$RiskExplainCopyWithImpl;
@useResult
$Res call({
 String segmentId, double? baseValue, List<RiskFactor>? factors, String? narrative
});




}
/// @nodoc
class _$RiskExplainCopyWithImpl<$Res>
    implements $RiskExplainCopyWith<$Res> {
  _$RiskExplainCopyWithImpl(this._self, this._then);

  final RiskExplain _self;
  final $Res Function(RiskExplain) _then;

/// Create a copy of RiskExplain
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? segmentId = null,Object? baseValue = freezed,Object? factors = freezed,Object? narrative = freezed,}) {
  return _then(RiskExplain(
segmentId: null == segmentId ? _self.segmentId : segmentId // ignore: cast_nullable_to_non_nullable
as String,baseValue: freezed == baseValue ? _self.baseValue : baseValue // ignore: cast_nullable_to_non_nullable
as double?,factors: freezed == factors ? _self.factors : factors // ignore: cast_nullable_to_non_nullable
as List<RiskFactor>?,narrative: freezed == narrative ? _self.narrative : narrative // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RiskExplain].
extension RiskExplainPatterns on RiskExplain {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RiskExplain value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RiskExplain() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RiskExplain value)  $default,){
final _that = this;
switch (_that) {
case _RiskExplain():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RiskExplain value)?  $default,){
final _that = this;
switch (_that) {
case _RiskExplain() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String segmentId,  double? baseValue,  List<RiskFactor>? factors,  String? narrative)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RiskExplain() when $default != null:
return $default(_that.segmentId,_that.baseValue,_that.factors,_that.narrative);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String segmentId,  double? baseValue,  List<RiskFactor>? factors,  String? narrative)  $default,) {final _that = this;
switch (_that) {
case _RiskExplain():
return $default(_that.segmentId,_that.baseValue,_that.factors,_that.narrative);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String segmentId,  double? baseValue,  List<RiskFactor>? factors,  String? narrative)?  $default,) {final _that = this;
switch (_that) {
case _RiskExplain() when $default != null:
return $default(_that.segmentId,_that.baseValue,_that.factors,_that.narrative);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RiskExplain implements RiskExplain {
  const _RiskExplain({required this.segmentId, this.baseValue,  List<RiskFactor>? factors, this.narrative}): _factors = factors;
  factory _RiskExplain.fromJson(Map<String, dynamic> json) => _$RiskExplainFromJson(json);

@override final  String segmentId;
@override final  double? baseValue;
 final  List<RiskFactor>? _factors;
@override List<RiskFactor>? get factors {
  final value = _factors;
  if (value == null) return null;
  if (_factors is EqualUnmodifiableListView) return _factors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? narrative;

/// Create a copy of RiskExplain
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RiskExplainCopyWith<_RiskExplain> get copyWith => __$RiskExplainCopyWithImpl<_RiskExplain>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RiskExplainToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RiskExplain&&(identical(other.segmentId, segmentId) || other.segmentId == segmentId)&&(identical(other.baseValue, baseValue) || other.baseValue == baseValue)&&const DeepCollectionEquality().equals(other.factors, _factors)&&(identical(other.narrative, narrative) || other.narrative == narrative));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,segmentId,baseValue,const DeepCollectionEquality().hash(_factors),narrative);
}

@override
String toString() {
    return 'RiskExplain(segmentId: $segmentId, baseValue: $baseValue, factors: $factors, narrative: $narrative)';
}


}

/// @nodoc
abstract mixin class _$RiskExplainCopyWith<$Res> implements $RiskExplainCopyWith<$Res> {
  factory _$RiskExplainCopyWith(_RiskExplain value, $Res Function(_RiskExplain) _then) = __$RiskExplainCopyWithImpl;
@override @useResult
$Res call({
 String segmentId, double? baseValue, List<RiskFactor>? factors, String? narrative
});




}
/// @nodoc
class __$RiskExplainCopyWithImpl<$Res>
    implements _$RiskExplainCopyWith<$Res> {
  __$RiskExplainCopyWithImpl(this._self, this._then);

  final _RiskExplain _self;
  final $Res Function(_RiskExplain) _then;

/// Create a copy of RiskExplain
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? segmentId = null,Object? baseValue = freezed,Object? factors = freezed,Object? narrative = freezed,}) {
  return _then(_RiskExplain(
segmentId: null == segmentId ? _self.segmentId : segmentId // ignore: cast_nullable_to_non_nullable
as String,baseValue: freezed == baseValue ? _self.baseValue : baseValue // ignore: cast_nullable_to_non_nullable
as double?,factors: freezed == factors ? _self._factors : factors // ignore: cast_nullable_to_non_nullable
as List<RiskFactor>?,narrative: freezed == narrative ? _self.narrative : narrative // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
