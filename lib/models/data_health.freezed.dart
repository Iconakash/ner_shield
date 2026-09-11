// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'data_health.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DataHealth {

 String get title; List<DataSource>? get sources; DataHealthSummary? get summary;
/// Create a copy of DataHealth
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataHealthCopyWith<DataHealth> get copyWith => _$DataHealthCopyWithImpl<DataHealth>(this as DataHealth, _$identity);

  /// Serializes this DataHealth to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DataHealth;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataHealth&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.sources, _this.sources)&&(identical(other.summary, _this.summary) || other.summary == _this.summary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DataHealth;
  return Object.hash(runtimeType,_this.title,const DeepCollectionEquality().hash(_this.sources),_this.summary);
}

@override
String toString() {
  final _this = this as DataHealth;
  return 'DataHealth(title: ${_this.title}, sources: ${_this.sources}, summary: ${_this.summary})';
}


}

/// @nodoc
abstract mixin class $DataHealthCopyWith<$Res>  {
  factory $DataHealthCopyWith(DataHealth value, $Res Function(DataHealth) _then) = _$DataHealthCopyWithImpl;
@useResult
$Res call({
 String title, List<DataSource>? sources, DataHealthSummary? summary
});


$DataHealthSummaryCopyWith<$Res>? get summary;

}
/// @nodoc
class _$DataHealthCopyWithImpl<$Res>
    implements $DataHealthCopyWith<$Res> {
  _$DataHealthCopyWithImpl(this._self, this._then);

  final DataHealth _self;
  final $Res Function(DataHealth) _then;

/// Create a copy of DataHealth
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? sources = freezed,Object? summary = freezed,}) {
  return _then(DataHealth(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,sources: freezed == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as List<DataSource>?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as DataHealthSummary?,
  ));
}
/// Create a copy of DataHealth
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataHealthSummaryCopyWith<$Res>? get summary {
    if (_self.summary == null) {
    return null;
  }

  return $DataHealthSummaryCopyWith<$Res>(_self.summary!, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}


/// Adds pattern-matching-related methods to [DataHealth].
extension DataHealthPatterns on DataHealth {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DataHealth value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DataHealth() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DataHealth value)  $default,){
final _that = this;
switch (_that) {
case _DataHealth():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DataHealth value)?  $default,){
final _that = this;
switch (_that) {
case _DataHealth() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  List<DataSource>? sources,  DataHealthSummary? summary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DataHealth() when $default != null:
return $default(_that.title,_that.sources,_that.summary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  List<DataSource>? sources,  DataHealthSummary? summary)  $default,) {final _that = this;
switch (_that) {
case _DataHealth():
return $default(_that.title,_that.sources,_that.summary);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  List<DataSource>? sources,  DataHealthSummary? summary)?  $default,) {final _that = this;
switch (_that) {
case _DataHealth() when $default != null:
return $default(_that.title,_that.sources,_that.summary);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DataHealth implements DataHealth {
  const _DataHealth({required this.title,  List<DataSource>? sources, this.summary}): _sources = sources;
  factory _DataHealth.fromJson(Map<String, dynamic> json) => _$DataHealthFromJson(json);

@override final  String title;
 final  List<DataSource>? _sources;
@override List<DataSource>? get sources {
  final value = _sources;
  if (value == null) return null;
  if (_sources is EqualUnmodifiableListView) return _sources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  DataHealthSummary? summary;

/// Create a copy of DataHealth
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DataHealthCopyWith<_DataHealth> get copyWith => __$DataHealthCopyWithImpl<_DataHealth>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DataHealthToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DataHealth&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.sources, _sources)&&(identical(other.summary, summary) || other.summary == summary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title,const DeepCollectionEquality().hash(_sources),summary);
}

@override
String toString() {
    return 'DataHealth(title: $title, sources: $sources, summary: $summary)';
}


}

/// @nodoc
abstract mixin class _$DataHealthCopyWith<$Res> implements $DataHealthCopyWith<$Res> {
  factory _$DataHealthCopyWith(_DataHealth value, $Res Function(_DataHealth) _then) = __$DataHealthCopyWithImpl;
@override @useResult
$Res call({
 String title, List<DataSource>? sources, DataHealthSummary? summary
});


@override $DataHealthSummaryCopyWith<$Res>? get summary;

}
/// @nodoc
class __$DataHealthCopyWithImpl<$Res>
    implements _$DataHealthCopyWith<$Res> {
  __$DataHealthCopyWithImpl(this._self, this._then);

  final _DataHealth _self;
  final $Res Function(_DataHealth) _then;

/// Create a copy of DataHealth
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? sources = freezed,Object? summary = freezed,}) {
  return _then(_DataHealth(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,sources: freezed == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as List<DataSource>?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as DataHealthSummary?,
  ));
}

/// Create a copy of DataHealth
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataHealthSummaryCopyWith<$Res>? get summary {
    if (_self.summary == null) {
    return null;
  }

  return $DataHealthSummaryCopyWith<$Res>(_self.summary!, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}


/// @nodoc
mixin _$DataSource {

 String? get code; String? get name; bool? get enabled; String? get status; String? get freshness; double? get confidence; String? get licenseNote; String? get lastSuccessAt;
/// Create a copy of DataSource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataSourceCopyWith<DataSource> get copyWith => _$DataSourceCopyWithImpl<DataSource>(this as DataSource, _$identity);

  /// Serializes this DataSource to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DataSource;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataSource&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.freshness, _this.freshness) || other.freshness == _this.freshness)&&(identical(other.confidence, _this.confidence) || other.confidence == _this.confidence)&&(identical(other.licenseNote, _this.licenseNote) || other.licenseNote == _this.licenseNote)&&(identical(other.lastSuccessAt, _this.lastSuccessAt) || other.lastSuccessAt == _this.lastSuccessAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DataSource;
  return Object.hash(runtimeType,_this.code,_this.name,_this.enabled,_this.status,_this.freshness,_this.confidence,_this.licenseNote,_this.lastSuccessAt);
}

@override
String toString() {
  final _this = this as DataSource;
  return 'DataSource(code: ${_this.code}, name: ${_this.name}, enabled: ${_this.enabled}, status: ${_this.status}, freshness: ${_this.freshness}, confidence: ${_this.confidence}, licenseNote: ${_this.licenseNote}, lastSuccessAt: ${_this.lastSuccessAt})';
}


}

/// @nodoc
abstract mixin class $DataSourceCopyWith<$Res>  {
  factory $DataSourceCopyWith(DataSource value, $Res Function(DataSource) _then) = _$DataSourceCopyWithImpl;
@useResult
$Res call({
 String? code, String? name, bool? enabled, String? status, String? freshness, double? confidence, String? licenseNote, String? lastSuccessAt
});




}
/// @nodoc
class _$DataSourceCopyWithImpl<$Res>
    implements $DataSourceCopyWith<$Res> {
  _$DataSourceCopyWithImpl(this._self, this._then);

  final DataSource _self;
  final $Res Function(DataSource) _then;

/// Create a copy of DataSource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = freezed,Object? name = freezed,Object? enabled = freezed,Object? status = freezed,Object? freshness = freezed,Object? confidence = freezed,Object? licenseNote = freezed,Object? lastSuccessAt = freezed,}) {
  return _then(DataSource(
code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,enabled: freezed == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,freshness: freezed == freshness ? _self.freshness : freshness // ignore: cast_nullable_to_non_nullable
as String?,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,licenseNote: freezed == licenseNote ? _self.licenseNote : licenseNote // ignore: cast_nullable_to_non_nullable
as String?,lastSuccessAt: freezed == lastSuccessAt ? _self.lastSuccessAt : lastSuccessAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DataSource].
extension DataSourcePatterns on DataSource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DataSource value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DataSource() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DataSource value)  $default,){
final _that = this;
switch (_that) {
case _DataSource():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DataSource value)?  $default,){
final _that = this;
switch (_that) {
case _DataSource() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? code,  String? name,  bool? enabled,  String? status,  String? freshness,  double? confidence,  String? licenseNote,  String? lastSuccessAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DataSource() when $default != null:
return $default(_that.code,_that.name,_that.enabled,_that.status,_that.freshness,_that.confidence,_that.licenseNote,_that.lastSuccessAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? code,  String? name,  bool? enabled,  String? status,  String? freshness,  double? confidence,  String? licenseNote,  String? lastSuccessAt)  $default,) {final _that = this;
switch (_that) {
case _DataSource():
return $default(_that.code,_that.name,_that.enabled,_that.status,_that.freshness,_that.confidence,_that.licenseNote,_that.lastSuccessAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? code,  String? name,  bool? enabled,  String? status,  String? freshness,  double? confidence,  String? licenseNote,  String? lastSuccessAt)?  $default,) {final _that = this;
switch (_that) {
case _DataSource() when $default != null:
return $default(_that.code,_that.name,_that.enabled,_that.status,_that.freshness,_that.confidence,_that.licenseNote,_that.lastSuccessAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DataSource implements DataSource {
  const _DataSource({this.code, this.name, this.enabled, this.status, this.freshness, this.confidence, this.licenseNote, this.lastSuccessAt});
  factory _DataSource.fromJson(Map<String, dynamic> json) => _$DataSourceFromJson(json);

@override final  String? code;
@override final  String? name;
@override final  bool? enabled;
@override final  String? status;
@override final  String? freshness;
@override final  double? confidence;
@override final  String? licenseNote;
@override final  String? lastSuccessAt;

/// Create a copy of DataSource
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DataSourceCopyWith<_DataSource> get copyWith => __$DataSourceCopyWithImpl<_DataSource>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DataSourceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DataSource&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.status, status) || other.status == status)&&(identical(other.freshness, freshness) || other.freshness == freshness)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.licenseNote, licenseNote) || other.licenseNote == licenseNote)&&(identical(other.lastSuccessAt, lastSuccessAt) || other.lastSuccessAt == lastSuccessAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,code,name,enabled,status,freshness,confidence,licenseNote,lastSuccessAt);
}

@override
String toString() {
    return 'DataSource(code: $code, name: $name, enabled: $enabled, status: $status, freshness: $freshness, confidence: $confidence, licenseNote: $licenseNote, lastSuccessAt: $lastSuccessAt)';
}


}

/// @nodoc
abstract mixin class _$DataSourceCopyWith<$Res> implements $DataSourceCopyWith<$Res> {
  factory _$DataSourceCopyWith(_DataSource value, $Res Function(_DataSource) _then) = __$DataSourceCopyWithImpl;
@override @useResult
$Res call({
 String? code, String? name, bool? enabled, String? status, String? freshness, double? confidence, String? licenseNote, String? lastSuccessAt
});




}
/// @nodoc
class __$DataSourceCopyWithImpl<$Res>
    implements _$DataSourceCopyWith<$Res> {
  __$DataSourceCopyWithImpl(this._self, this._then);

  final _DataSource _self;
  final $Res Function(_DataSource) _then;

/// Create a copy of DataSource
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = freezed,Object? name = freezed,Object? enabled = freezed,Object? status = freezed,Object? freshness = freezed,Object? confidence = freezed,Object? licenseNote = freezed,Object? lastSuccessAt = freezed,}) {
  return _then(_DataSource(
code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,enabled: freezed == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,freshness: freezed == freshness ? _self.freshness : freshness // ignore: cast_nullable_to_non_nullable
as String?,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,licenseNote: freezed == licenseNote ? _self.licenseNote : licenseNote // ignore: cast_nullable_to_non_nullable
as String?,lastSuccessAt: freezed == lastSuccessAt ? _self.lastSuccessAt : lastSuccessAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$DataHealthSummary {

 int? get total; int? get live; int? get recent; int? get stale; int? get unavailable;
/// Create a copy of DataHealthSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataHealthSummaryCopyWith<DataHealthSummary> get copyWith => _$DataHealthSummaryCopyWithImpl<DataHealthSummary>(this as DataHealthSummary, _$identity);

  /// Serializes this DataHealthSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DataHealthSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataHealthSummary&&(identical(other.total, _this.total) || other.total == _this.total)&&(identical(other.live, _this.live) || other.live == _this.live)&&(identical(other.recent, _this.recent) || other.recent == _this.recent)&&(identical(other.stale, _this.stale) || other.stale == _this.stale)&&(identical(other.unavailable, _this.unavailable) || other.unavailable == _this.unavailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DataHealthSummary;
  return Object.hash(runtimeType,_this.total,_this.live,_this.recent,_this.stale,_this.unavailable);
}

@override
String toString() {
  final _this = this as DataHealthSummary;
  return 'DataHealthSummary(total: ${_this.total}, live: ${_this.live}, recent: ${_this.recent}, stale: ${_this.stale}, unavailable: ${_this.unavailable})';
}


}

/// @nodoc
abstract mixin class $DataHealthSummaryCopyWith<$Res>  {
  factory $DataHealthSummaryCopyWith(DataHealthSummary value, $Res Function(DataHealthSummary) _then) = _$DataHealthSummaryCopyWithImpl;
@useResult
$Res call({
 int? total, int? live, int? recent, int? stale, int? unavailable
});




}
/// @nodoc
class _$DataHealthSummaryCopyWithImpl<$Res>
    implements $DataHealthSummaryCopyWith<$Res> {
  _$DataHealthSummaryCopyWithImpl(this._self, this._then);

  final DataHealthSummary _self;
  final $Res Function(DataHealthSummary) _then;

/// Create a copy of DataHealthSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = freezed,Object? live = freezed,Object? recent = freezed,Object? stale = freezed,Object? unavailable = freezed,}) {
  return _then(DataHealthSummary(
total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int?,live: freezed == live ? _self.live : live // ignore: cast_nullable_to_non_nullable
as int?,recent: freezed == recent ? _self.recent : recent // ignore: cast_nullable_to_non_nullable
as int?,stale: freezed == stale ? _self.stale : stale // ignore: cast_nullable_to_non_nullable
as int?,unavailable: freezed == unavailable ? _self.unavailable : unavailable // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [DataHealthSummary].
extension DataHealthSummaryPatterns on DataHealthSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DataHealthSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DataHealthSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DataHealthSummary value)  $default,){
final _that = this;
switch (_that) {
case _DataHealthSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DataHealthSummary value)?  $default,){
final _that = this;
switch (_that) {
case _DataHealthSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? total,  int? live,  int? recent,  int? stale,  int? unavailable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DataHealthSummary() when $default != null:
return $default(_that.total,_that.live,_that.recent,_that.stale,_that.unavailable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? total,  int? live,  int? recent,  int? stale,  int? unavailable)  $default,) {final _that = this;
switch (_that) {
case _DataHealthSummary():
return $default(_that.total,_that.live,_that.recent,_that.stale,_that.unavailable);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? total,  int? live,  int? recent,  int? stale,  int? unavailable)?  $default,) {final _that = this;
switch (_that) {
case _DataHealthSummary() when $default != null:
return $default(_that.total,_that.live,_that.recent,_that.stale,_that.unavailable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DataHealthSummary implements DataHealthSummary {
  const _DataHealthSummary({this.total, this.live, this.recent, this.stale, this.unavailable});
  factory _DataHealthSummary.fromJson(Map<String, dynamic> json) => _$DataHealthSummaryFromJson(json);

@override final  int? total;
@override final  int? live;
@override final  int? recent;
@override final  int? stale;
@override final  int? unavailable;

/// Create a copy of DataHealthSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DataHealthSummaryCopyWith<_DataHealthSummary> get copyWith => __$DataHealthSummaryCopyWithImpl<_DataHealthSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DataHealthSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DataHealthSummary&&(identical(other.total, total) || other.total == total)&&(identical(other.live, live) || other.live == live)&&(identical(other.recent, recent) || other.recent == recent)&&(identical(other.stale, stale) || other.stale == stale)&&(identical(other.unavailable, unavailable) || other.unavailable == unavailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,total,live,recent,stale,unavailable);
}

@override
String toString() {
    return 'DataHealthSummary(total: $total, live: $live, recent: $recent, stale: $stale, unavailable: $unavailable)';
}


}

/// @nodoc
abstract mixin class _$DataHealthSummaryCopyWith<$Res> implements $DataHealthSummaryCopyWith<$Res> {
  factory _$DataHealthSummaryCopyWith(_DataHealthSummary value, $Res Function(_DataHealthSummary) _then) = __$DataHealthSummaryCopyWithImpl;
@override @useResult
$Res call({
 int? total, int? live, int? recent, int? stale, int? unavailable
});




}
/// @nodoc
class __$DataHealthSummaryCopyWithImpl<$Res>
    implements _$DataHealthSummaryCopyWith<$Res> {
  __$DataHealthSummaryCopyWithImpl(this._self, this._then);

  final _DataHealthSummary _self;
  final $Res Function(_DataHealthSummary) _then;

/// Create a copy of DataHealthSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = freezed,Object? live = freezed,Object? recent = freezed,Object? stale = freezed,Object? unavailable = freezed,}) {
  return _then(_DataHealthSummary(
total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int?,live: freezed == live ? _self.live : live // ignore: cast_nullable_to_non_nullable
as int?,recent: freezed == recent ? _self.recent : recent // ignore: cast_nullable_to_non_nullable
as int?,stale: freezed == stale ? _self.stale : stale // ignore: cast_nullable_to_non_nullable
as int?,unavailable: freezed == unavailable ? _self.unavailable : unavailable // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
