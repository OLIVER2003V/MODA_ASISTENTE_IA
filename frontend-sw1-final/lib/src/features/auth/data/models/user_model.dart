class User {
  final String id;
  final String email;
  final String? name;
  final String role; // 'ADMIN' | 'CLIENT'
  final bool isActive;
  final String? profilePhoto;
  final String? avatarStyle;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    this.name,
    this.role = 'CLIENT',
    required this.isActive,
    this.profilePhoto,
    this.avatarStyle,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAdmin => role == 'ADMIN';

  String get displayName => name?.isNotEmpty == true ? name! : email.split('@').first;

  String get initials {
    final n = name?.trim() ?? email;
    final parts = n.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  // Devuelve la URL de imagen a mostrar:
  // 1. Foto de perfil real
  // 2. Avatar DiceBear
  // 3. null → mostrar iniciales
  String? get avatarUrl {
    if (profilePhoto != null && profilePhoto!.isNotEmpty) return profilePhoto;
    if (avatarStyle != null && avatarStyle!.isNotEmpty) {
      return 'https://api.dicebear.com/9.x/$avatarStyle/png?seed=$id';
    }
    return null;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      role: (json['role'] as String?) ?? 'CLIENT',
      isActive: json['isActive'] as bool? ?? true,
      profilePhoto: json['profilePhoto'] as String?,
      avatarStyle: json['avatarStyle'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'isActive': isActive,
      'profilePhoto': profilePhoto,
      'avatarStyle': avatarStyle,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? name,
    String? profilePhoto,
    String? avatarStyle,
    bool clearPhoto = false,
    bool clearAvatar = false,
  }) {
    return User(
      id: id,
      email: email,
      name: name ?? this.name,
      role: role,
      isActive: isActive,
      profilePhoto: clearPhoto ? null : (profilePhoto ?? this.profilePhoto),
      avatarStyle: clearAvatar ? null : (avatarStyle ?? this.avatarStyle),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
