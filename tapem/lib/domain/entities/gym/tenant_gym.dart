import 'package:equatable/equatable.dart';

class TenantGym extends Equatable {
  const TenantGym({
    required this.id,
    required this.name,
    required this.slug,
    required this.region,
    this.logoUrl,
    this.addressLine1,
    this.city,
    this.countryCode = 'DE',
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String slug;
  final String region;
  final String? logoUrl;
  final String? addressLine1;
  final String? city;
  final String countryCode;
  final bool isActive;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id];
}
