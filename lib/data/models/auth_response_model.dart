import 'user_model.dart';

class AuthResponse {
  final String token;
  final String? firebaseToken;
  final UserModel user;

  AuthResponse({required this.token, this.firebaseToken, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? json['accessToken'] ?? '',
      firebaseToken: json['firebase_token'], // NUEVO
      user: UserModel.fromJson(json['user'] ?? json['usuario'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'firebase_token': firebaseToken,
      'user': user.toJson(),
    };
  }
}
