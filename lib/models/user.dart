class User {
  final String email;
  final String password;
  final String role;

  User({
    required this.email,
    required this.password,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['username'],
      password: json['password'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': email,
      'password': password,
      'role': role,
    };
  }

  User copyWith({
    String? email,
    String? password,
    String? role,
  }) {
    return User(
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
    );
  }
}
