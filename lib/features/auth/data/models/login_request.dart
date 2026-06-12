import 'package:json_annotation/json_annotation.dart';

part 'login_request.g.dart';

@JsonSerializable()
class LoginRequest {
  final String nrp;
  final String password;

  @JsonKey(name: 'fcm_token')
  final String fcmToken;

  const LoginRequest({
    required this.nrp,
    required this.password,
    required this.fcmToken,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}
