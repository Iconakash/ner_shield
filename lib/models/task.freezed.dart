// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaskItem {

 String get id; String? get title; String? get description; String? get priority; String? get status;@JsonKey(name: 'source_type') String? get sourceType;@JsonKey(name: 'source_id') String? get sourceId;@JsonKey(name: 'assignee_id') String? get assigneeId;@JsonKey(name: 'state_code') String? get stateCode;@JsonKey(name: 'district_code') String? get districtCode;@JsonKey(name: 'created_at') String? get createdAt;@JsonKey(name: 'completed_at') String? get completedAt;
/// Create a copy of TaskItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskItemCopyWith<TaskItem> get copyWith => _$TaskItemCopyWithImpl<TaskItem>(this as TaskItem, _$identity);

  /// Serializes this TaskItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TaskItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.priority, _this.priority) || other.priority == _this.priority)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.sourceType, _this.sourceType) || other.sourceType == _this.sourceType)&&(identical(other.sourceId, _this.sourceId) || other.sourceId == _this.sourceId)&&(identical(other.assigneeId, _this.assigneeId) || other.assigneeId == _this.assigneeId)&&(identical(other.stateCode, _this.stateCode) || other.stateCode == _this.stateCode)&&(identical(other.districtCode, _this.districtCode) || other.districtCode == _this.districtCode)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.completedAt, _this.completedAt) || other.completedAt == _this.completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TaskItem;
  return Object.hash(runtimeType,_this.id,_this.title,_this.description,_this.priority,_this.status,_this.sourceType,_this.sourceId,_this.assigneeId,_this.stateCode,_this.districtCode,_this.createdAt,_this.completedAt);
}

@override
String toString() {
  final _this = this as TaskItem;
  return 'TaskItem(id: ${_this.id}, title: ${_this.title}, description: ${_this.description}, priority: ${_this.priority}, status: ${_this.status}, sourceType: ${_this.sourceType}, sourceId: ${_this.sourceId}, assigneeId: ${_this.assigneeId}, stateCode: ${_this.stateCode}, districtCode: ${_this.districtCode}, createdAt: ${_this.createdAt}, completedAt: ${_this.completedAt})';
}


}

/// @nodoc
abstract mixin class $TaskItemCopyWith<$Res>  {
  factory $TaskItemCopyWith(TaskItem value, $Res Function(TaskItem) _then) = _$TaskItemCopyWithImpl;
@useResult
$Res call({
 String id, String? title, String? description, String? priority, String? status,@JsonKey(name: 'source_type') String? sourceType,@JsonKey(name: 'source_id') String? sourceId,@JsonKey(name: 'assignee_id') String? assigneeId,@JsonKey(name: 'state_code') String? stateCode,@JsonKey(name: 'district_code') String? districtCode,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'completed_at') String? completedAt
});




}
/// @nodoc
class _$TaskItemCopyWithImpl<$Res>
    implements $TaskItemCopyWith<$Res> {
  _$TaskItemCopyWithImpl(this._self, this._then);

  final TaskItem _self;
  final $Res Function(TaskItem) _then;

/// Create a copy of TaskItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = freezed,Object? description = freezed,Object? priority = freezed,Object? status = freezed,Object? sourceType = freezed,Object? sourceId = freezed,Object? assigneeId = freezed,Object? stateCode = freezed,Object? districtCode = freezed,Object? createdAt = freezed,Object? completedAt = freezed,}) {
  return _then(TaskItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,sourceType: freezed == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as String?,sourceId: freezed == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String?,assigneeId: freezed == assigneeId ? _self.assigneeId : assigneeId // ignore: cast_nullable_to_non_nullable
as String?,stateCode: freezed == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String?,districtCode: freezed == districtCode ? _self.districtCode : districtCode // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskItem].
extension TaskItemPatterns on TaskItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskItem value)  $default,){
final _that = this;
switch (_that) {
case _TaskItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskItem value)?  $default,){
final _that = this;
switch (_that) {
case _TaskItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? title,  String? description,  String? priority,  String? status, @JsonKey(name: 'source_type')  String? sourceType, @JsonKey(name: 'source_id')  String? sourceId, @JsonKey(name: 'assignee_id')  String? assigneeId, @JsonKey(name: 'state_code')  String? stateCode, @JsonKey(name: 'district_code')  String? districtCode, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'completed_at')  String? completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskItem() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.priority,_that.status,_that.sourceType,_that.sourceId,_that.assigneeId,_that.stateCode,_that.districtCode,_that.createdAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? title,  String? description,  String? priority,  String? status, @JsonKey(name: 'source_type')  String? sourceType, @JsonKey(name: 'source_id')  String? sourceId, @JsonKey(name: 'assignee_id')  String? assigneeId, @JsonKey(name: 'state_code')  String? stateCode, @JsonKey(name: 'district_code')  String? districtCode, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'completed_at')  String? completedAt)  $default,) {final _that = this;
switch (_that) {
case _TaskItem():
return $default(_that.id,_that.title,_that.description,_that.priority,_that.status,_that.sourceType,_that.sourceId,_that.assigneeId,_that.stateCode,_that.districtCode,_that.createdAt,_that.completedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? title,  String? description,  String? priority,  String? status, @JsonKey(name: 'source_type')  String? sourceType, @JsonKey(name: 'source_id')  String? sourceId, @JsonKey(name: 'assignee_id')  String? assigneeId, @JsonKey(name: 'state_code')  String? stateCode, @JsonKey(name: 'district_code')  String? districtCode, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'completed_at')  String? completedAt)?  $default,) {final _that = this;
switch (_that) {
case _TaskItem() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.priority,_that.status,_that.sourceType,_that.sourceId,_that.assigneeId,_that.stateCode,_that.districtCode,_that.createdAt,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskItem extends TaskItem {
  const _TaskItem({required this.id, this.title, this.description, this.priority, this.status, @JsonKey(name: 'source_type') this.sourceType, @JsonKey(name: 'source_id') this.sourceId, @JsonKey(name: 'assignee_id') this.assigneeId, @JsonKey(name: 'state_code') this.stateCode, @JsonKey(name: 'district_code') this.districtCode, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'completed_at') this.completedAt}): super._();
  factory _TaskItem.fromJson(Map<String, dynamic> json) => _$TaskItemFromJson(json);

@override final  String id;
@override final  String? title;
@override final  String? description;
@override final  String? priority;
@override final  String? status;
@override@JsonKey(name: 'source_type') final  String? sourceType;
@override@JsonKey(name: 'source_id') final  String? sourceId;
@override@JsonKey(name: 'assignee_id') final  String? assigneeId;
@override@JsonKey(name: 'state_code') final  String? stateCode;
@override@JsonKey(name: 'district_code') final  String? districtCode;
@override@JsonKey(name: 'created_at') final  String? createdAt;
@override@JsonKey(name: 'completed_at') final  String? completedAt;

/// Create a copy of TaskItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskItemCopyWith<_TaskItem> get copyWith => __$TaskItemCopyWithImpl<_TaskItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.status, status) || other.status == status)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.assigneeId, assigneeId) || other.assigneeId == assigneeId)&&(identical(other.stateCode, stateCode) || other.stateCode == stateCode)&&(identical(other.districtCode, districtCode) || other.districtCode == districtCode)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,description,priority,status,sourceType,sourceId,assigneeId,stateCode,districtCode,createdAt,completedAt);
}

@override
String toString() {
    return 'TaskItem(id: $id, title: $title, description: $description, priority: $priority, status: $status, sourceType: $sourceType, sourceId: $sourceId, assigneeId: $assigneeId, stateCode: $stateCode, districtCode: $districtCode, createdAt: $createdAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$TaskItemCopyWith<$Res> implements $TaskItemCopyWith<$Res> {
  factory _$TaskItemCopyWith(_TaskItem value, $Res Function(_TaskItem) _then) = __$TaskItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String? title, String? description, String? priority, String? status,@JsonKey(name: 'source_type') String? sourceType,@JsonKey(name: 'source_id') String? sourceId,@JsonKey(name: 'assignee_id') String? assigneeId,@JsonKey(name: 'state_code') String? stateCode,@JsonKey(name: 'district_code') String? districtCode,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'completed_at') String? completedAt
});




}
/// @nodoc
class __$TaskItemCopyWithImpl<$Res>
    implements _$TaskItemCopyWith<$Res> {
  __$TaskItemCopyWithImpl(this._self, this._then);

  final _TaskItem _self;
  final $Res Function(_TaskItem) _then;

/// Create a copy of TaskItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = freezed,Object? description = freezed,Object? priority = freezed,Object? status = freezed,Object? sourceType = freezed,Object? sourceId = freezed,Object? assigneeId = freezed,Object? stateCode = freezed,Object? districtCode = freezed,Object? createdAt = freezed,Object? completedAt = freezed,}) {
  return _then(_TaskItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,sourceType: freezed == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as String?,sourceId: freezed == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String?,assigneeId: freezed == assigneeId ? _self.assigneeId : assigneeId // ignore: cast_nullable_to_non_nullable
as String?,stateCode: freezed == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String?,districtCode: freezed == districtCode ? _self.districtCode : districtCode // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$FieldMedia {

 String get id; String? get kind; String? get filename;@JsonKey(name: 'mime_type') String? get mimeType; int? get sizeBytes;@JsonKey(name: 'uploaded_at') String? get uploadedAt; String? get signedUrl;@JsonKey(name: 'signed_url_expires_at') String? get signedUrlExpiresAt;
/// Create a copy of FieldMedia
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FieldMediaCopyWith<FieldMedia> get copyWith => _$FieldMediaCopyWithImpl<FieldMedia>(this as FieldMedia, _$identity);

  /// Serializes this FieldMedia to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FieldMedia;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FieldMedia&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.filename, _this.filename) || other.filename == _this.filename)&&(identical(other.mimeType, _this.mimeType) || other.mimeType == _this.mimeType)&&(identical(other.sizeBytes, _this.sizeBytes) || other.sizeBytes == _this.sizeBytes)&&(identical(other.uploadedAt, _this.uploadedAt) || other.uploadedAt == _this.uploadedAt)&&(identical(other.signedUrl, _this.signedUrl) || other.signedUrl == _this.signedUrl)&&(identical(other.signedUrlExpiresAt, _this.signedUrlExpiresAt) || other.signedUrlExpiresAt == _this.signedUrlExpiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FieldMedia;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.filename,_this.mimeType,_this.sizeBytes,_this.uploadedAt,_this.signedUrl,_this.signedUrlExpiresAt);
}

@override
String toString() {
  final _this = this as FieldMedia;
  return 'FieldMedia(id: ${_this.id}, kind: ${_this.kind}, filename: ${_this.filename}, mimeType: ${_this.mimeType}, sizeBytes: ${_this.sizeBytes}, uploadedAt: ${_this.uploadedAt}, signedUrl: ${_this.signedUrl}, signedUrlExpiresAt: ${_this.signedUrlExpiresAt})';
}


}

/// @nodoc
abstract mixin class $FieldMediaCopyWith<$Res>  {
  factory $FieldMediaCopyWith(FieldMedia value, $Res Function(FieldMedia) _then) = _$FieldMediaCopyWithImpl;
@useResult
$Res call({
 String id, String? kind, String? filename,@JsonKey(name: 'mime_type') String? mimeType, int? sizeBytes,@JsonKey(name: 'uploaded_at') String? uploadedAt, String? signedUrl,@JsonKey(name: 'signed_url_expires_at') String? signedUrlExpiresAt
});




}
/// @nodoc
class _$FieldMediaCopyWithImpl<$Res>
    implements $FieldMediaCopyWith<$Res> {
  _$FieldMediaCopyWithImpl(this._self, this._then);

  final FieldMedia _self;
  final $Res Function(FieldMedia) _then;

/// Create a copy of FieldMedia
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = freezed,Object? filename = freezed,Object? mimeType = freezed,Object? sizeBytes = freezed,Object? uploadedAt = freezed,Object? signedUrl = freezed,Object? signedUrlExpiresAt = freezed,}) {
  return _then(FieldMedia(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String?,filename: freezed == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,uploadedAt: freezed == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as String?,signedUrl: freezed == signedUrl ? _self.signedUrl : signedUrl // ignore: cast_nullable_to_non_nullable
as String?,signedUrlExpiresAt: freezed == signedUrlExpiresAt ? _self.signedUrlExpiresAt : signedUrlExpiresAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FieldMedia].
extension FieldMediaPatterns on FieldMedia {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FieldMedia value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FieldMedia() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FieldMedia value)  $default,){
final _that = this;
switch (_that) {
case _FieldMedia():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FieldMedia value)?  $default,){
final _that = this;
switch (_that) {
case _FieldMedia() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? kind,  String? filename, @JsonKey(name: 'mime_type')  String? mimeType,  int? sizeBytes, @JsonKey(name: 'uploaded_at')  String? uploadedAt,  String? signedUrl, @JsonKey(name: 'signed_url_expires_at')  String? signedUrlExpiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FieldMedia() when $default != null:
return $default(_that.id,_that.kind,_that.filename,_that.mimeType,_that.sizeBytes,_that.uploadedAt,_that.signedUrl,_that.signedUrlExpiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? kind,  String? filename, @JsonKey(name: 'mime_type')  String? mimeType,  int? sizeBytes, @JsonKey(name: 'uploaded_at')  String? uploadedAt,  String? signedUrl, @JsonKey(name: 'signed_url_expires_at')  String? signedUrlExpiresAt)  $default,) {final _that = this;
switch (_that) {
case _FieldMedia():
return $default(_that.id,_that.kind,_that.filename,_that.mimeType,_that.sizeBytes,_that.uploadedAt,_that.signedUrl,_that.signedUrlExpiresAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? kind,  String? filename, @JsonKey(name: 'mime_type')  String? mimeType,  int? sizeBytes, @JsonKey(name: 'uploaded_at')  String? uploadedAt,  String? signedUrl, @JsonKey(name: 'signed_url_expires_at')  String? signedUrlExpiresAt)?  $default,) {final _that = this;
switch (_that) {
case _FieldMedia() when $default != null:
return $default(_that.id,_that.kind,_that.filename,_that.mimeType,_that.sizeBytes,_that.uploadedAt,_that.signedUrl,_that.signedUrlExpiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FieldMedia implements FieldMedia {
  const _FieldMedia({required this.id, this.kind, this.filename, @JsonKey(name: 'mime_type') this.mimeType, this.sizeBytes, @JsonKey(name: 'uploaded_at') this.uploadedAt, this.signedUrl, @JsonKey(name: 'signed_url_expires_at') this.signedUrlExpiresAt});
  factory _FieldMedia.fromJson(Map<String, dynamic> json) => _$FieldMediaFromJson(json);

@override final  String id;
@override final  String? kind;
@override final  String? filename;
@override@JsonKey(name: 'mime_type') final  String? mimeType;
@override final  int? sizeBytes;
@override@JsonKey(name: 'uploaded_at') final  String? uploadedAt;
@override final  String? signedUrl;
@override@JsonKey(name: 'signed_url_expires_at') final  String? signedUrlExpiresAt;

/// Create a copy of FieldMedia
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FieldMediaCopyWith<_FieldMedia> get copyWith => __$FieldMediaCopyWithImpl<_FieldMedia>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FieldMediaToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FieldMedia&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.filename, filename) || other.filename == filename)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt)&&(identical(other.signedUrl, signedUrl) || other.signedUrl == signedUrl)&&(identical(other.signedUrlExpiresAt, signedUrlExpiresAt) || other.signedUrlExpiresAt == signedUrlExpiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,filename,mimeType,sizeBytes,uploadedAt,signedUrl,signedUrlExpiresAt);
}

@override
String toString() {
    return 'FieldMedia(id: $id, kind: $kind, filename: $filename, mimeType: $mimeType, sizeBytes: $sizeBytes, uploadedAt: $uploadedAt, signedUrl: $signedUrl, signedUrlExpiresAt: $signedUrlExpiresAt)';
}


}

/// @nodoc
abstract mixin class _$FieldMediaCopyWith<$Res> implements $FieldMediaCopyWith<$Res> {
  factory _$FieldMediaCopyWith(_FieldMedia value, $Res Function(_FieldMedia) _then) = __$FieldMediaCopyWithImpl;
@override @useResult
$Res call({
 String id, String? kind, String? filename,@JsonKey(name: 'mime_type') String? mimeType, int? sizeBytes,@JsonKey(name: 'uploaded_at') String? uploadedAt, String? signedUrl,@JsonKey(name: 'signed_url_expires_at') String? signedUrlExpiresAt
});




}
/// @nodoc
class __$FieldMediaCopyWithImpl<$Res>
    implements _$FieldMediaCopyWith<$Res> {
  __$FieldMediaCopyWithImpl(this._self, this._then);

  final _FieldMedia _self;
  final $Res Function(_FieldMedia) _then;

/// Create a copy of FieldMedia
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = freezed,Object? filename = freezed,Object? mimeType = freezed,Object? sizeBytes = freezed,Object? uploadedAt = freezed,Object? signedUrl = freezed,Object? signedUrlExpiresAt = freezed,}) {
  return _then(_FieldMedia(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String?,filename: freezed == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,uploadedAt: freezed == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as String?,signedUrl: freezed == signedUrl ? _self.signedUrl : signedUrl // ignore: cast_nullable_to_non_nullable
as String?,signedUrlExpiresAt: freezed == signedUrlExpiresAt ? _self.signedUrlExpiresAt : signedUrlExpiresAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SatelliteEvidence {

 String get id; String? get sceneId; String? get source;@JsonKey(name: 'captured_at') String? get capturedAt;@JsonKey(name: 'state_code') String? get stateCode;@JsonKey(name: 'district_code') String? get districtCode;@JsonKey(name: 'cloud_cover_pct') double? get cloudCoverPct; String? get productType; String? get signedUrl;@JsonKey(name: 'signed_url_expires_at') String? get signedUrlExpiresAt;
/// Create a copy of SatelliteEvidence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SatelliteEvidenceCopyWith<SatelliteEvidence> get copyWith => _$SatelliteEvidenceCopyWithImpl<SatelliteEvidence>(this as SatelliteEvidence, _$identity);

  /// Serializes this SatelliteEvidence to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SatelliteEvidence;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SatelliteEvidence&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.sceneId, _this.sceneId) || other.sceneId == _this.sceneId)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.capturedAt, _this.capturedAt) || other.capturedAt == _this.capturedAt)&&(identical(other.stateCode, _this.stateCode) || other.stateCode == _this.stateCode)&&(identical(other.districtCode, _this.districtCode) || other.districtCode == _this.districtCode)&&(identical(other.cloudCoverPct, _this.cloudCoverPct) || other.cloudCoverPct == _this.cloudCoverPct)&&(identical(other.productType, _this.productType) || other.productType == _this.productType)&&(identical(other.signedUrl, _this.signedUrl) || other.signedUrl == _this.signedUrl)&&(identical(other.signedUrlExpiresAt, _this.signedUrlExpiresAt) || other.signedUrlExpiresAt == _this.signedUrlExpiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SatelliteEvidence;
  return Object.hash(runtimeType,_this.id,_this.sceneId,_this.source,_this.capturedAt,_this.stateCode,_this.districtCode,_this.cloudCoverPct,_this.productType,_this.signedUrl,_this.signedUrlExpiresAt);
}

@override
String toString() {
  final _this = this as SatelliteEvidence;
  return 'SatelliteEvidence(id: ${_this.id}, sceneId: ${_this.sceneId}, source: ${_this.source}, capturedAt: ${_this.capturedAt}, stateCode: ${_this.stateCode}, districtCode: ${_this.districtCode}, cloudCoverPct: ${_this.cloudCoverPct}, productType: ${_this.productType}, signedUrl: ${_this.signedUrl}, signedUrlExpiresAt: ${_this.signedUrlExpiresAt})';
}


}

/// @nodoc
abstract mixin class $SatelliteEvidenceCopyWith<$Res>  {
  factory $SatelliteEvidenceCopyWith(SatelliteEvidence value, $Res Function(SatelliteEvidence) _then) = _$SatelliteEvidenceCopyWithImpl;
@useResult
$Res call({
 String id, String? sceneId, String? source,@JsonKey(name: 'captured_at') String? capturedAt,@JsonKey(name: 'state_code') String? stateCode,@JsonKey(name: 'district_code') String? districtCode,@JsonKey(name: 'cloud_cover_pct') double? cloudCoverPct, String? productType, String? signedUrl,@JsonKey(name: 'signed_url_expires_at') String? signedUrlExpiresAt
});




}
/// @nodoc
class _$SatelliteEvidenceCopyWithImpl<$Res>
    implements $SatelliteEvidenceCopyWith<$Res> {
  _$SatelliteEvidenceCopyWithImpl(this._self, this._then);

  final SatelliteEvidence _self;
  final $Res Function(SatelliteEvidence) _then;

/// Create a copy of SatelliteEvidence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sceneId = freezed,Object? source = freezed,Object? capturedAt = freezed,Object? stateCode = freezed,Object? districtCode = freezed,Object? cloudCoverPct = freezed,Object? productType = freezed,Object? signedUrl = freezed,Object? signedUrlExpiresAt = freezed,}) {
  return _then(SatelliteEvidence(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sceneId: freezed == sceneId ? _self.sceneId : sceneId // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,capturedAt: freezed == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as String?,stateCode: freezed == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String?,districtCode: freezed == districtCode ? _self.districtCode : districtCode // ignore: cast_nullable_to_non_nullable
as String?,cloudCoverPct: freezed == cloudCoverPct ? _self.cloudCoverPct : cloudCoverPct // ignore: cast_nullable_to_non_nullable
as double?,productType: freezed == productType ? _self.productType : productType // ignore: cast_nullable_to_non_nullable
as String?,signedUrl: freezed == signedUrl ? _self.signedUrl : signedUrl // ignore: cast_nullable_to_non_nullable
as String?,signedUrlExpiresAt: freezed == signedUrlExpiresAt ? _self.signedUrlExpiresAt : signedUrlExpiresAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SatelliteEvidence].
extension SatelliteEvidencePatterns on SatelliteEvidence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SatelliteEvidence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SatelliteEvidence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SatelliteEvidence value)  $default,){
final _that = this;
switch (_that) {
case _SatelliteEvidence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SatelliteEvidence value)?  $default,){
final _that = this;
switch (_that) {
case _SatelliteEvidence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? sceneId,  String? source, @JsonKey(name: 'captured_at')  String? capturedAt, @JsonKey(name: 'state_code')  String? stateCode, @JsonKey(name: 'district_code')  String? districtCode, @JsonKey(name: 'cloud_cover_pct')  double? cloudCoverPct,  String? productType,  String? signedUrl, @JsonKey(name: 'signed_url_expires_at')  String? signedUrlExpiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SatelliteEvidence() when $default != null:
return $default(_that.id,_that.sceneId,_that.source,_that.capturedAt,_that.stateCode,_that.districtCode,_that.cloudCoverPct,_that.productType,_that.signedUrl,_that.signedUrlExpiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? sceneId,  String? source, @JsonKey(name: 'captured_at')  String? capturedAt, @JsonKey(name: 'state_code')  String? stateCode, @JsonKey(name: 'district_code')  String? districtCode, @JsonKey(name: 'cloud_cover_pct')  double? cloudCoverPct,  String? productType,  String? signedUrl, @JsonKey(name: 'signed_url_expires_at')  String? signedUrlExpiresAt)  $default,) {final _that = this;
switch (_that) {
case _SatelliteEvidence():
return $default(_that.id,_that.sceneId,_that.source,_that.capturedAt,_that.stateCode,_that.districtCode,_that.cloudCoverPct,_that.productType,_that.signedUrl,_that.signedUrlExpiresAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? sceneId,  String? source, @JsonKey(name: 'captured_at')  String? capturedAt, @JsonKey(name: 'state_code')  String? stateCode, @JsonKey(name: 'district_code')  String? districtCode, @JsonKey(name: 'cloud_cover_pct')  double? cloudCoverPct,  String? productType,  String? signedUrl, @JsonKey(name: 'signed_url_expires_at')  String? signedUrlExpiresAt)?  $default,) {final _that = this;
switch (_that) {
case _SatelliteEvidence() when $default != null:
return $default(_that.id,_that.sceneId,_that.source,_that.capturedAt,_that.stateCode,_that.districtCode,_that.cloudCoverPct,_that.productType,_that.signedUrl,_that.signedUrlExpiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SatelliteEvidence implements SatelliteEvidence {
  const _SatelliteEvidence({required this.id, this.sceneId, this.source, @JsonKey(name: 'captured_at') this.capturedAt, @JsonKey(name: 'state_code') this.stateCode, @JsonKey(name: 'district_code') this.districtCode, @JsonKey(name: 'cloud_cover_pct') this.cloudCoverPct, this.productType, this.signedUrl, @JsonKey(name: 'signed_url_expires_at') this.signedUrlExpiresAt});
  factory _SatelliteEvidence.fromJson(Map<String, dynamic> json) => _$SatelliteEvidenceFromJson(json);

@override final  String id;
@override final  String? sceneId;
@override final  String? source;
@override@JsonKey(name: 'captured_at') final  String? capturedAt;
@override@JsonKey(name: 'state_code') final  String? stateCode;
@override@JsonKey(name: 'district_code') final  String? districtCode;
@override@JsonKey(name: 'cloud_cover_pct') final  double? cloudCoverPct;
@override final  String? productType;
@override final  String? signedUrl;
@override@JsonKey(name: 'signed_url_expires_at') final  String? signedUrlExpiresAt;

/// Create a copy of SatelliteEvidence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SatelliteEvidenceCopyWith<_SatelliteEvidence> get copyWith => __$SatelliteEvidenceCopyWithImpl<_SatelliteEvidence>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SatelliteEvidenceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SatelliteEvidence&&(identical(other.id, id) || other.id == id)&&(identical(other.sceneId, sceneId) || other.sceneId == sceneId)&&(identical(other.source, source) || other.source == source)&&(identical(other.capturedAt, capturedAt) || other.capturedAt == capturedAt)&&(identical(other.stateCode, stateCode) || other.stateCode == stateCode)&&(identical(other.districtCode, districtCode) || other.districtCode == districtCode)&&(identical(other.cloudCoverPct, cloudCoverPct) || other.cloudCoverPct == cloudCoverPct)&&(identical(other.productType, productType) || other.productType == productType)&&(identical(other.signedUrl, signedUrl) || other.signedUrl == signedUrl)&&(identical(other.signedUrlExpiresAt, signedUrlExpiresAt) || other.signedUrlExpiresAt == signedUrlExpiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,sceneId,source,capturedAt,stateCode,districtCode,cloudCoverPct,productType,signedUrl,signedUrlExpiresAt);
}

@override
String toString() {
    return 'SatelliteEvidence(id: $id, sceneId: $sceneId, source: $source, capturedAt: $capturedAt, stateCode: $stateCode, districtCode: $districtCode, cloudCoverPct: $cloudCoverPct, productType: $productType, signedUrl: $signedUrl, signedUrlExpiresAt: $signedUrlExpiresAt)';
}


}

/// @nodoc
abstract mixin class _$SatelliteEvidenceCopyWith<$Res> implements $SatelliteEvidenceCopyWith<$Res> {
  factory _$SatelliteEvidenceCopyWith(_SatelliteEvidence value, $Res Function(_SatelliteEvidence) _then) = __$SatelliteEvidenceCopyWithImpl;
@override @useResult
$Res call({
 String id, String? sceneId, String? source,@JsonKey(name: 'captured_at') String? capturedAt,@JsonKey(name: 'state_code') String? stateCode,@JsonKey(name: 'district_code') String? districtCode,@JsonKey(name: 'cloud_cover_pct') double? cloudCoverPct, String? productType, String? signedUrl,@JsonKey(name: 'signed_url_expires_at') String? signedUrlExpiresAt
});




}
/// @nodoc
class __$SatelliteEvidenceCopyWithImpl<$Res>
    implements _$SatelliteEvidenceCopyWith<$Res> {
  __$SatelliteEvidenceCopyWithImpl(this._self, this._then);

  final _SatelliteEvidence _self;
  final $Res Function(_SatelliteEvidence) _then;

/// Create a copy of SatelliteEvidence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sceneId = freezed,Object? source = freezed,Object? capturedAt = freezed,Object? stateCode = freezed,Object? districtCode = freezed,Object? cloudCoverPct = freezed,Object? productType = freezed,Object? signedUrl = freezed,Object? signedUrlExpiresAt = freezed,}) {
  return _then(_SatelliteEvidence(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sceneId: freezed == sceneId ? _self.sceneId : sceneId // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,capturedAt: freezed == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as String?,stateCode: freezed == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String?,districtCode: freezed == districtCode ? _self.districtCode : districtCode // ignore: cast_nullable_to_non_nullable
as String?,cloudCoverPct: freezed == cloudCoverPct ? _self.cloudCoverPct : cloudCoverPct // ignore: cast_nullable_to_non_nullable
as double?,productType: freezed == productType ? _self.productType : productType // ignore: cast_nullable_to_non_nullable
as String?,signedUrl: freezed == signedUrl ? _self.signedUrl : signedUrl // ignore: cast_nullable_to_non_nullable
as String?,signedUrlExpiresAt: freezed == signedUrlExpiresAt ? _self.signedUrlExpiresAt : signedUrlExpiresAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
