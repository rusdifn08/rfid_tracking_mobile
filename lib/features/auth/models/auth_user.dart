class AuthUser {
  const AuthUser({
    required this.nik,
    required this.name,
    required this.jabatan,
    this.line = '',
    this.branch = '',
    this.rfidUser = '',
    this.telegram = '',
    this.noHp = '',
    required this.role,
    required this.token,
  });

  final String nik;
  final String name;
  final String jabatan;
  final String line;
  final String branch;
  final String rfidUser;
  final String telegram;
  final String noHp;
  final String role;
  final String token;

  factory AuthUser.fromApi(Map<String, dynamic> json, {required String token}) {
    return AuthUser(
      nik: (json['nik'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      jabatan: (json['jabatan'] ?? '').toString(),
      line: (json['line'] ?? '').toString(),
      branch: (json['branch'] ?? '').toString(),
      rfidUser: (json['rfid_user'] ?? '').toString(),
      telegram: (json['telegram'] ?? '').toString(),
      noHp: (json['no_hp'] ?? '').toString(),
      role: (json['role'] ?? 'user').toString(),
      token: token,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nik': nik,
      'name': name,
      'jabatan': jabatan,
      'line': line,
      'branch': branch,
      'rfid_user': rfidUser,
      'telegram': telegram,
      'no_hp': noHp,
      'role': role,
      'token': token,
    };
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      nik: (json['nik'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      jabatan: (json['jabatan'] ?? '').toString(),
      line: (json['line'] ?? '').toString(),
      branch: (json['branch'] ?? '').toString(),
      rfidUser: (json['rfid_user'] ?? '').toString(),
      telegram: (json['telegram'] ?? '').toString(),
      noHp: (json['no_hp'] ?? '').toString(),
      role: (json['role'] ?? 'user').toString(),
      token: (json['token'] ?? '').toString(),
    );
  }
}
