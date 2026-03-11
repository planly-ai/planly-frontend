class User {
  final String username;
  final bool isLoggedIn;

  User({required this.username, this.isLoggedIn = false});

  factory User.guest() => User(username: 'Guest', isLoggedIn: false);

  Map<String, dynamic> toJson() => {
    'username': username,
    'isLoggedIn': isLoggedIn,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    username: json['username'] ?? 'Guest',
    isLoggedIn: json['isLoggedIn'] ?? false,
  );

  User copyWith({String? username, bool? isLoggedIn}) {
    return User(
      username: username ?? this.username,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}
