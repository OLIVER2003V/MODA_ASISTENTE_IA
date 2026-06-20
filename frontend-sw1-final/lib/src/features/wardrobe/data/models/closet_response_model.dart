import 'closet_model.dart';
import 'garment_model.dart';

class ClosetResponse {
  final Closet closet;
  final List<Garment> garments;

  ClosetResponse({
    required this.closet,
    required this.garments,
  });

  factory ClosetResponse.fromJson(Map<String, dynamic> json) {
    return ClosetResponse(
      closet: Closet.fromJson(json['closet'] as Map<String, dynamic>),
      garments: (json['garments'] as List<dynamic>)
          .map((g) => Garment.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }
}
