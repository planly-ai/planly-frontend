class User {
  final String username;
  final bool isLoggedIn;
  final String? userId;
  final String? userType;
  final String? tenantId;
  final String? loginDate;

  User({
    required this.username,
    this.isLoggedIn = false,
    this.userId,
    this.userType,
    this.tenantId,
    this.loginDate,
  });

  factory User.guest() => User(username: 'Guest', isLoggedIn: false);

  Map<String, dynamic> toJson() => {
        'username': username,
        'isLoggedIn': isLoggedIn,
        'userId': userId,
        'userType': userType,
        'tenantId': tenantId,
        'loginDate': loginDate,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        username: json['username'] ?? 'Guest',
        isLoggedIn: json['isLoggedIn'] ?? false,
        userId: json['userId'],
        userType: json['userType'],
        tenantId: json['tenantId'],
        loginDate: json['loginDate'],
      );

  User copyWith({
    String? username,
    bool? isLoggedIn,
    String? userId,
    String? userType,
    String? tenantId,
    String? loginDate,
  }) {
    return User(
      username: username ?? this.username,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      tenantId: tenantId ?? this.tenantId,
      loginDate: loginDate ?? this.loginDate,
    );
  }
}
