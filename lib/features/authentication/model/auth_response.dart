class AuthResponse {
  final User? user;
  
  AuthResponse({this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user?.toJson(),
    };
  }
}

class User {
  final String id;
  final String? email;
  final Map<String, dynamic>? userMetadata;

  User({
    required this.id,
    this.email,
    this.userMetadata,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'],
      userMetadata: json['userMetadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (email != null) 'email': email,
      if (userMetadata != null) 'userMetadata': userMetadata,
    };
  }
}
