class POModel {
  final int id;
  final String nama;
  final String companyCode;
  final String email;
  final String phone;
  final String address;
  final int vehicleCount;

  POModel({
    required this.id,
    required this.nama,
    required this.companyCode,
    required this.email,
    required this.phone,
    required this.address,
    required this.vehicleCount,
  });

  factory POModel.fromJson(Map<String, dynamic> json) {
    return POModel(
      id: json['id'] ?? 0,
      nama: json['po_name'] ?? '',
      companyCode: json['company_code'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      vehicleCount: json['vehicle_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'po_name': nama,
      'company_code': companyCode,
      'email': email,
      'phone': phone,
      'address': address,
      'vehicle_count': vehicleCount,
    };
  }
}
