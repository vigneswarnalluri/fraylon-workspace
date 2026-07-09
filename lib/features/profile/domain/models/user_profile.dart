class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? photo;
  final String role;
  final String organizationId;
  final String departmentId;
  final String designation;
  final String phone;
  final DateTime createdAt;
  final DateTime lastLogin;
  final String status;

  // Compatibility fields
  final String department;
  final String organization;
  final String employeeId;
  final DateTime joinedDate;
  final String? imageUrl;
  final String language;
  final bool notificationsEnabled;

  UserProfile({
    String? uid,
    required this.name,
    required this.email,
    this.photo,
    required this.role,
    String? organizationId,
    String? departmentId,
    String? designation,
    required this.phone,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? status,
    String? department,
    String? organization,
    String? employeeId,
    DateTime? joinedDate,
    String? imageUrl,
    this.language = 'English',
    this.notificationsEnabled = true,
  })  : uid = uid ?? 'mock_user_uid',
        organizationId = organizationId ?? 'org_fraylon',
        departmentId = departmentId ?? 'dept_rd',
        designation = designation ?? role,
        createdAt = createdAt ?? joinedDate ?? DateTime.now(),
        lastLogin = lastLogin ?? DateTime.now(),
        status = status ?? 'Active',
        department = department ?? 'Research & Development',
        organization = organization ?? 'Fraylon Technologies LLP',
        employeeId = employeeId ?? 'EMP-2026-884',
        joinedDate = joinedDate ?? createdAt ?? DateTime.now(),
        imageUrl = imageUrl ?? photo;

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? photo,
    String? role,
    String? organizationId,
    String? departmentId,
    String? designation,
    String? phone,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? status,
    String? department,
    String? organization,
    String? employeeId,
    DateTime? joinedDate,
    String? imageUrl,
    String? language,
    bool? notificationsEnabled,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photo: photo ?? this.photo,
      role: role ?? this.role,
      organizationId: organizationId ?? this.organizationId,
      departmentId: departmentId ?? this.departmentId,
      designation: designation ?? this.designation,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      status: status ?? this.status,
      department: department ?? this.department,
      organization: organization ?? this.organization,
      employeeId: employeeId ?? this.employeeId,
      joinedDate: joinedDate ?? this.joinedDate,
      imageUrl: imageUrl ?? this.imageUrl,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photo': photo,
      'role': role,
      'organizationId': organizationId,
      'departmentId': departmentId,
      'designation': designation,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'status': status,
      'department': department,
      'organization': organization,
      'employeeId': employeeId,
      'joinedDate': joinedDate.toIso8601String(),
      'imageUrl': imageUrl,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    
    DateTime parseDate(dynamic val) {
      if (val == null) return now;
      if (val is DateTime) return val;
      if (val is String) {
        return DateTime.tryParse(val) ?? now;
      }
      try {
        return (val as dynamic).toDate() as DateTime;
      } catch (_) {}
      return now;
    }

    final created = parseDate(map['createdAt'] ?? map['joinedDate']);
    final lastLog = parseDate(map['lastLogin']);
    final roleVal = map['role'] ?? 'Employee';
    
    return UserProfile(
      uid: map['uid'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photo: map['photo'] ?? map['imageUrl'],
      role: roleVal,
      organizationId: map['organizationId'] ?? 'org_fraylon',
      departmentId: map['departmentId'] ?? 'dept_rd',
      designation: map['designation'] ?? roleVal,
      phone: map['phone'] ?? '',
      createdAt: created,
      lastLogin: lastLog,
      status: map['status'] ?? 'Active',
      department: map['department'] ?? 'Research & Development',
      organization: map['organization'] ?? 'Fraylon Technologies LLP',
      employeeId: map['employeeId'] ?? 'EMP-2026-884',
      joinedDate: created,
      imageUrl: map['imageUrl'] ?? map['photo'],
      language: map['language'] ?? 'English',
      notificationsEnabled: map['notificationsEnabled'] ?? true,
    );
  }
}
