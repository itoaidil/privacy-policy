class BookingModel {
  final int? id;
  final int poId;
  final String namaPenumpang;
  final String nomorTelepon;
  final int jumlahPenumpang;
  final String tanggalKeberangkatan;
  final double totalHarga;
  final String status;

  BookingModel({
    this.id,
    required this.poId,
    required this.namaPenumpang,
    required this.nomorTelepon,
    required this.jumlahPenumpang,
    required this.tanggalKeberangkatan,
    required this.totalHarga,
    this.status = 'pending',
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      poId: json['po_id'] ?? 0,
      namaPenumpang: json['nama_penumpang'] ?? '',
      nomorTelepon: json['nomor_telepon'] ?? '',
      jumlahPenumpang: json['jumlah_penumpang'] ?? 0,
      tanggalKeberangkatan: json['tanggal_keberangkatan'] ?? '',
      totalHarga: (json['total_harga'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'po_id': poId,
      'nama_penumpang': namaPenumpang,
      'nomor_telepon': nomorTelepon,
      'jumlah_penumpang': jumlahPenumpang,
      'tanggal_keberangkatan': tanggalKeberangkatan,
      'total_harga': totalHarga,
      'status': status,
    };
  }
}
