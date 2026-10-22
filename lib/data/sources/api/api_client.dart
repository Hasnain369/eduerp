class ApiClient {
  Future<Map<String, dynamic>> getUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'id': '1',
      'name': 'Demo User',
      'email': 'demo@example.com',
      'role': 'student',
    };
  }
}
