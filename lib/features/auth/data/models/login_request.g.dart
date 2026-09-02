// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
  nrp: json['nrp'] as String,
  password: json['password'] as String,
  fcmToken: json['fcm_token'] as String,
  force: json['force'] as bool? ?? false,
);

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'nrp': instance.nrp,
      'password': instance.password,
      'fcm_token': instance.fcmToken,
      'force': instance.force,
    };
