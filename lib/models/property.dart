
class Property {
  const Property({
    required this.id,
    required this.title,
    required this.area,
    required this.rent,
    required this.type,
    this.image,
    this.status = 'pending',
  });

  final String id;
  final String title;
  final String area;
  final String type;
  final int rent;
  final String? image;
  final String status;

  @override
  bool operator ==(Object other) =>
      other is Property && other.id == id;

  @override
  int get hashCode => id.hashCode;

  factory Property.fromJson(Map<String, dynamic> json) {
    final images = json['image_urls'];
    String? image;

    if (images is List && images.isNotEmpty) {
      image = images.first?.toString();
    } else if (json['image_url'] != null) {
      image = json['image_url'].toString();
    }

    return Property(
      id: '${json['id'] ?? json['_id'] ?? ''}',
      title: '${json['title'] ?? 'Rental property'}',
      area: '${json['area'] ?? json['location'] ?? 'Rourkela'}',
      rent: (json['rent'] as num?)?.toInt() ??
          (json['monthly_rent'] as num?)?.toInt() ??
          0,
      type: '${json['property_type'] ?? json['type'] ?? 'Room'}',
      image: image,
      status: '${json['status'] ?? 'pending'}',
    );
  }
}
