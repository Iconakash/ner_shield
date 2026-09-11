// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'command_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CommandKpi {

 String get id; int get count; String get description;
/// Create a copy of CommandKpi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommandKpiCopyWith<CommandKpi> get copyWith => _$CommandKpiCopyWithImpl<CommandKpi>(this as CommandKpi, _$identity);

  /// Serializes this CommandKpi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CommandKpi;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommandKpi&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.count, _this.count) || other.count == _this.count)&&(identical(other.description, _this.description) || other.description == _this.description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CommandKpi;
  return Object.hash(runtimeType,_this.id,_this.count,_this.description);
}

@override
String toString() {
  final _this = this as CommandKpi;
  return 'CommandKpi(id: ${_this.id}, count: ${_this.count}, description: ${_this.description})';
}


}

/// @nodoc
abstract mixin class $CommandKpiCopyWith<$Res>  {
  factory $CommandKpiCopyWith(CommandKpi value, $Res Function(CommandKpi) _then) = _$CommandKpiCopyWithImpl;
@useResult
$Res call({
 String id, int count, String description
});




}
/// @nodoc
class _$CommandKpiCopyWithImpl<$Res>
    implements $CommandKpiCopyWith<$Res> {
  _$CommandKpiCopyWithImpl(this._self, this._then);

  final CommandKpi _self;
  final $Res Function(CommandKpi) _then;

/// Create a copy of CommandKpi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? count = null,Object? description = null,}) {
  return _then(CommandKpi(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CommandKpi].
extension CommandKpiPatterns on CommandKpi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommandKpi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommandKpi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommandKpi value)  $default,){
final _that = this;
switch (_that) {
case _CommandKpi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommandKpi value)?  $default,){
final _that = this;
switch (_that) {
case _CommandKpi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int count,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommandKpi() when $default != null:
return $default(_that.id,_that.count,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int count,  String description)  $default,) {final _that = this;
switch (_that) {
case _CommandKpi():
return $default(_that.id,_that.count,_that.description);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int count,  String description)?  $default,) {final _that = this;
switch (_that) {
case _CommandKpi() when $default != null:
return $default(_that.id,_that.count,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommandKpi implements CommandKpi {
  const _CommandKpi({required this.id, required this.count, required this.description});
  factory _CommandKpi.fromJson(Map<String, dynamic> json) => _$CommandKpiFromJson(json);

@override final  String id;
@override final  int count;
@override final  String description;

/// Create a copy of CommandKpi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommandKpiCopyWith<_CommandKpi> get copyWith => __$CommandKpiCopyWithImpl<_CommandKpi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommandKpiToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommandKpi&&(identical(other.id, id) || other.id == id)&&(identical(other.count, count) || other.count == count)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,count,description);
}

@override
String toString() {
    return 'CommandKpi(id: $id, count: $count, description: $description)';
}


}

/// @nodoc
abstract mixin class _$CommandKpiCopyWith<$Res> implements $CommandKpiCopyWith<$Res> {
  factory _$CommandKpiCopyWith(_CommandKpi value, $Res Function(_CommandKpi) _then) = __$CommandKpiCopyWithImpl;
@override @useResult
$Res call({
 String id, int count, String description
});




}
/// @nodoc
class __$CommandKpiCopyWithImpl<$Res>
    implements _$CommandKpiCopyWith<$Res> {
  __$CommandKpiCopyWithImpl(this._self, this._then);

  final _CommandKpi _self;
  final $Res Function(_CommandKpi) _then;

/// Create a copy of CommandKpi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? count = null,Object? description = null,}) {
  return _then(_CommandKpi(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CommandSummary {

 int get criticalAlerts; int get highRiskRoads; int get activeShipments; int get criticalShipments; int get supplyRiskDistricts; int get predictedDisruptions; String? get generatedAt;
/// Create a copy of CommandSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommandSummaryCopyWith<CommandSummary> get copyWith => _$CommandSummaryCopyWithImpl<CommandSummary>(this as CommandSummary, _$identity);

  /// Serializes this CommandSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CommandSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommandSummary&&(identical(other.criticalAlerts, _this.criticalAlerts) || other.criticalAlerts == _this.criticalAlerts)&&(identical(other.highRiskRoads, _this.highRiskRoads) || other.highRiskRoads == _this.highRiskRoads)&&(identical(other.activeShipments, _this.activeShipments) || other.activeShipments == _this.activeShipments)&&(identical(other.criticalShipments, _this.criticalShipments) || other.criticalShipments == _this.criticalShipments)&&(identical(other.supplyRiskDistricts, _this.supplyRiskDistricts) || other.supplyRiskDistricts == _this.supplyRiskDistricts)&&(identical(other.predictedDisruptions, _this.predictedDisruptions) || other.predictedDisruptions == _this.predictedDisruptions)&&(identical(other.generatedAt, _this.generatedAt) || other.generatedAt == _this.generatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CommandSummary;
  return Object.hash(runtimeType,_this.criticalAlerts,_this.highRiskRoads,_this.activeShipments,_this.criticalShipments,_this.supplyRiskDistricts,_this.predictedDisruptions,_this.generatedAt);
}

@override
String toString() {
  final _this = this as CommandSummary;
  return 'CommandSummary(criticalAlerts: ${_this.criticalAlerts}, highRiskRoads: ${_this.highRiskRoads}, activeShipments: ${_this.activeShipments}, criticalShipments: ${_this.criticalShipments}, supplyRiskDistricts: ${_this.supplyRiskDistricts}, predictedDisruptions: ${_this.predictedDisruptions}, generatedAt: ${_this.generatedAt})';
}


}

/// @nodoc
abstract mixin class $CommandSummaryCopyWith<$Res>  {
  factory $CommandSummaryCopyWith(CommandSummary value, $Res Function(CommandSummary) _then) = _$CommandSummaryCopyWithImpl;
@useResult
$Res call({
 int criticalAlerts, int highRiskRoads, int activeShipments, int criticalShipments, int supplyRiskDistricts, int predictedDisruptions, String? generatedAt
});




}
/// @nodoc
class _$CommandSummaryCopyWithImpl<$Res>
    implements $CommandSummaryCopyWith<$Res> {
  _$CommandSummaryCopyWithImpl(this._self, this._then);

  final CommandSummary _self;
  final $Res Function(CommandSummary) _then;

/// Create a copy of CommandSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? criticalAlerts = null,Object? highRiskRoads = null,Object? activeShipments = null,Object? criticalShipments = null,Object? supplyRiskDistricts = null,Object? predictedDisruptions = null,Object? generatedAt = freezed,}) {
  return _then(CommandSummary(
criticalAlerts: null == criticalAlerts ? _self.criticalAlerts : criticalAlerts // ignore: cast_nullable_to_non_nullable
as int,highRiskRoads: null == highRiskRoads ? _self.highRiskRoads : highRiskRoads // ignore: cast_nullable_to_non_nullable
as int,activeShipments: null == activeShipments ? _self.activeShipments : activeShipments // ignore: cast_nullable_to_non_nullable
as int,criticalShipments: null == criticalShipments ? _self.criticalShipments : criticalShipments // ignore: cast_nullable_to_non_nullable
as int,supplyRiskDistricts: null == supplyRiskDistricts ? _self.supplyRiskDistricts : supplyRiskDistricts // ignore: cast_nullable_to_non_nullable
as int,predictedDisruptions: null == predictedDisruptions ? _self.predictedDisruptions : predictedDisruptions // ignore: cast_nullable_to_non_nullable
as int,generatedAt: freezed == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CommandSummary].
extension CommandSummaryPatterns on CommandSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommandSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommandSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommandSummary value)  $default,){
final _that = this;
switch (_that) {
case _CommandSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommandSummary value)?  $default,){
final _that = this;
switch (_that) {
case _CommandSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int criticalAlerts,  int highRiskRoads,  int activeShipments,  int criticalShipments,  int supplyRiskDistricts,  int predictedDisruptions,  String? generatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommandSummary() when $default != null:
return $default(_that.criticalAlerts,_that.highRiskRoads,_that.activeShipments,_that.criticalShipments,_that.supplyRiskDistricts,_that.predictedDisruptions,_that.generatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int criticalAlerts,  int highRiskRoads,  int activeShipments,  int criticalShipments,  int supplyRiskDistricts,  int predictedDisruptions,  String? generatedAt)  $default,) {final _that = this;
switch (_that) {
case _CommandSummary():
return $default(_that.criticalAlerts,_that.highRiskRoads,_that.activeShipments,_that.criticalShipments,_that.supplyRiskDistricts,_that.predictedDisruptions,_that.generatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int criticalAlerts,  int highRiskRoads,  int activeShipments,  int criticalShipments,  int supplyRiskDistricts,  int predictedDisruptions,  String? generatedAt)?  $default,) {final _that = this;
switch (_that) {
case _CommandSummary() when $default != null:
return $default(_that.criticalAlerts,_that.highRiskRoads,_that.activeShipments,_that.criticalShipments,_that.supplyRiskDistricts,_that.predictedDisruptions,_that.generatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommandSummary extends CommandSummary {
  const _CommandSummary({this.criticalAlerts = 0, this.highRiskRoads = 0, this.activeShipments = 0, this.criticalShipments = 0, this.supplyRiskDistricts = 0, this.predictedDisruptions = 0, this.generatedAt}): super._();
  factory _CommandSummary.fromJson(Map<String, dynamic> json) => _$CommandSummaryFromJson(json);

@override@JsonKey() final  int criticalAlerts;
@override@JsonKey() final  int highRiskRoads;
@override@JsonKey() final  int activeShipments;
@override@JsonKey() final  int criticalShipments;
@override@JsonKey() final  int supplyRiskDistricts;
@override@JsonKey() final  int predictedDisruptions;
@override final  String? generatedAt;

/// Create a copy of CommandSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommandSummaryCopyWith<_CommandSummary> get copyWith => __$CommandSummaryCopyWithImpl<_CommandSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommandSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommandSummary&&(identical(other.criticalAlerts, criticalAlerts) || other.criticalAlerts == criticalAlerts)&&(identical(other.highRiskRoads, highRiskRoads) || other.highRiskRoads == highRiskRoads)&&(identical(other.activeShipments, activeShipments) || other.activeShipments == activeShipments)&&(identical(other.criticalShipments, criticalShipments) || other.criticalShipments == criticalShipments)&&(identical(other.supplyRiskDistricts, supplyRiskDistricts) || other.supplyRiskDistricts == supplyRiskDistricts)&&(identical(other.predictedDisruptions, predictedDisruptions) || other.predictedDisruptions == predictedDisruptions)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,criticalAlerts,highRiskRoads,activeShipments,criticalShipments,supplyRiskDistricts,predictedDisruptions,generatedAt);
}

@override
String toString() {
    return 'CommandSummary(criticalAlerts: $criticalAlerts, highRiskRoads: $highRiskRoads, activeShipments: $activeShipments, criticalShipments: $criticalShipments, supplyRiskDistricts: $supplyRiskDistricts, predictedDisruptions: $predictedDisruptions, generatedAt: $generatedAt)';
}


}

/// @nodoc
abstract mixin class _$CommandSummaryCopyWith<$Res> implements $CommandSummaryCopyWith<$Res> {
  factory _$CommandSummaryCopyWith(_CommandSummary value, $Res Function(_CommandSummary) _then) = __$CommandSummaryCopyWithImpl;
@override @useResult
$Res call({
 int criticalAlerts, int highRiskRoads, int activeShipments, int criticalShipments, int supplyRiskDistricts, int predictedDisruptions, String? generatedAt
});




}
/// @nodoc
class __$CommandSummaryCopyWithImpl<$Res>
    implements _$CommandSummaryCopyWith<$Res> {
  __$CommandSummaryCopyWithImpl(this._self, this._then);

  final _CommandSummary _self;
  final $Res Function(_CommandSummary) _then;

/// Create a copy of CommandSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? criticalAlerts = null,Object? highRiskRoads = null,Object? activeShipments = null,Object? criticalShipments = null,Object? supplyRiskDistricts = null,Object? predictedDisruptions = null,Object? generatedAt = freezed,}) {
  return _then(_CommandSummary(
criticalAlerts: null == criticalAlerts ? _self.criticalAlerts : criticalAlerts // ignore: cast_nullable_to_non_nullable
as int,highRiskRoads: null == highRiskRoads ? _self.highRiskRoads : highRiskRoads // ignore: cast_nullable_to_non_nullable
as int,activeShipments: null == activeShipments ? _self.activeShipments : activeShipments // ignore: cast_nullable_to_non_nullable
as int,criticalShipments: null == criticalShipments ? _self.criticalShipments : criticalShipments // ignore: cast_nullable_to_non_nullable
as int,supplyRiskDistricts: null == supplyRiskDistricts ? _self.supplyRiskDistricts : supplyRiskDistricts // ignore: cast_nullable_to_non_nullable
as int,predictedDisruptions: null == predictedDisruptions ? _self.predictedDisruptions : predictedDisruptions // ignore: cast_nullable_to_non_nullable
as int,generatedAt: freezed == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
