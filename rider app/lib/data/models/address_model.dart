class AddressModel {
  final String fullAddress;
  final String city;
  final String zip;
  final double latitude;
  final double longitude;
  final bool isInsideDhaka;

  const AddressModel({
    required this.fullAddress,
    required this.city,
    required this.zip,
    required this.latitude,
    required this.longitude,
    required this.isInsideDhaka,
  });
}
