class AuthModel {
  const AuthModel({required this.email, required this.password});

  final String email;
  final String password;

  factory AuthModel.fromMap(Map<String, dynamic> map) {
    return AuthModel(
      email: map['email'] ?? '',
      password: map['password'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'email': email, 'password': password};
  }
}
