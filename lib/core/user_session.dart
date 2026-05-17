class UserSession {
  // Singleton pattern
  static final UserSession _instance = UserSession._internal();
  
  factory UserSession() {
    return _instance;
  }
  
  UserSession._internal();

  // Role IDs
  // 1 = User
  // 2 = Moderator
  // 3 = Admin
  // 4 = Secretary
  // 5 = Accounting
  int? role;
  String? fullName;

  bool get isAdmin => role == 3;
  bool get isModerator => role == 2;
  bool get isUser => role == 1;
  bool get isSecretary => role == 4;
  bool get isAccounting => role == 5;

  bool get canEditOrDelete => isAdmin || isModerator;

  void clear() {
    role = null;
    fullName = null;
  }
}
