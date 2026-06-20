class UserAttribute {
  final String? id;

  // Datos físicos básicos
  final String? gender;
  final int? age;
  final double? stature;
  final double? weight;
  final String? bodyType;

  // Apariencia
  final String? skinTone;
  final String? faceType;
  final String? hairColor;
  final String? hairType;
  final String? eyeColor;

  // Estilo y preferencias
  final List<String> preferredStyles;
  final List<String> favoriteColors;
  final List<String> avoidColors;

  // Contexto de vida
  final String? profession;
  final String? climate;
  final String? clothingSize;
  final double? shoeSize;
  final String? budget;

  final String userId;

  UserAttribute({
    this.id,
    this.gender,
    this.age,
    this.stature,
    this.weight,
    this.bodyType,
    this.skinTone,
    this.faceType,
    this.hairColor,
    this.hairType,
    this.eyeColor,
    this.preferredStyles = const [],
    this.favoriteColors = const [],
    this.avoidColors = const [],
    this.profession,
    this.climate,
    this.clothingSize,
    this.shoeSize,
    this.budget,
    required this.userId,
  });

  factory UserAttribute.fromJson(Map<String, dynamic> json) {
    return UserAttribute(
      id: json['id'] as String?,
      gender: json['gender'] as String?,
      age: json['age'] as int?,
      stature: (json['stature'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      bodyType: json['bodyType'] as String?,
      skinTone: json['skinTone'] as String?,
      faceType: json['faceType'] as String?,
      hairColor: json['hairColor'] as String?,
      hairType: json['hairType'] as String?,
      eyeColor: json['eyeColor'] as String?,
      preferredStyles: List<String>.from(json['preferredStyles'] ?? []),
      favoriteColors: List<String>.from(json['favoriteColors'] ?? []),
      avoidColors: List<String>.from(json['avoidColors'] ?? []),
      profession: json['profession'] as String?,
      climate: json['climate'] as String?,
      clothingSize: json['clothingSize'] as String?,
      shoeSize: (json['shoeSize'] as num?)?.toDouble(),
      budget: json['budget'] as String?,
      userId: json['userId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (gender != null) 'gender': gender,
      if (age != null) 'age': age,
      if (stature != null) 'stature': stature,
      if (weight != null) 'weight': weight,
      if (bodyType != null) 'bodyType': bodyType,
      if (skinTone != null) 'skinTone': skinTone,
      if (faceType != null) 'faceType': faceType,
      if (hairColor != null) 'hairColor': hairColor,
      if (hairType != null) 'hairType': hairType,
      if (eyeColor != null) 'eyeColor': eyeColor,
      if (preferredStyles.isNotEmpty) 'preferredStyles': preferredStyles,
      if (favoriteColors.isNotEmpty) 'favoriteColors': favoriteColors,
      if (avoidColors.isNotEmpty) 'avoidColors': avoidColors,
      if (profession != null) 'profession': profession,
      if (climate != null) 'climate': climate,
      if (clothingSize != null) 'clothingSize': clothingSize,
      if (shoeSize != null) 'shoeSize': shoeSize,
      if (budget != null) 'budget': budget,
      'userId': userId,
    };
  }

  bool get isComplete =>
      gender != null &&
      age != null &&
      stature != null &&
      skinTone != null &&
      faceType != null &&
      preferredStyles.isNotEmpty;
}
