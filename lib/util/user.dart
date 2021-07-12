class User {
  static final User _instance = User.internal();

  factory User() {
    return _instance;
  }

  User.internal();

  String id;
  String place;
}
