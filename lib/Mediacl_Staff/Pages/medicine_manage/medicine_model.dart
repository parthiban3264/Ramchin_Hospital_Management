class Medicine {
  int id;
  String name;
  String category;
  String genericName;
  String manufacturer;
  String batchNo;
  String hsnCode;
  String location;
  String rxType; // OTC or Rx
  int quantity;
  String unit;
  int reorderLevel;
  String mfgDate;
  String expiryDate;
  double mrp;
  double costPrice;
  double gstPercent;
  double discountPercent;
  String supplierName;
  String invoiceNo;
  String purchaseDate;
  String notes;

  Medicine({
    required this.id,
    required this.name,
    this.category = '',
    this.genericName = '',
    this.manufacturer = '',
    required this.batchNo,
    this.hsnCode = '',
    this.location = '',
    this.rxType = 'OTC',
    this.quantity = 0,
    this.unit = 'Strips',
    this.reorderLevel = 10,
    this.mfgDate = '',
    required this.expiryDate,
    required this.mrp,
    this.costPrice = 0,
    this.gstPercent = 12,
    this.discountPercent = 0,
    this.supplierName = '',
    this.invoiceNo = '',
    this.purchaseDate = '',
    this.notes = '',
  });

  String get status {
    if (quantity == 0) return 'Out of Stock';
    if (quantity <= reorderLevel) return 'Low Stock';
    return 'In Stock';
  }

  bool get isExpired {
    try {
      final parts = expiryDate.split('-');
      if (parts.length < 2) return false;
      final expiry = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      return expiry.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  bool get isExpiringSoon {
    try {
      final parts = expiryDate.split('-');
      if (parts.length < 2) return false;
      final expiry = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      final soon = DateTime.now().add(const Duration(days: 90));
      return expiry.isBefore(soon) && expiry.isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Medicine copyWith({
    String? name, String? category, String? genericName, String? manufacturer,
    String? batchNo, String? hsnCode, String? location, String? rxType,
    int? quantity, String? unit, int? reorderLevel, String? mfgDate,
    String? expiryDate, double? mrp, double? costPrice, double? gstPercent,
    double? discountPercent, String? supplierName, String? invoiceNo,
    String? purchaseDate, String? notes,
  }) {
    return Medicine(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      genericName: genericName ?? this.genericName,
      manufacturer: manufacturer ?? this.manufacturer,
      batchNo: batchNo ?? this.batchNo,
      hsnCode: hsnCode ?? this.hsnCode,
      location: location ?? this.location,
      rxType: rxType ?? this.rxType,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      mfgDate: mfgDate ?? this.mfgDate,
      expiryDate: expiryDate ?? this.expiryDate,
      mrp: mrp ?? this.mrp,
      costPrice: costPrice ?? this.costPrice,
      gstPercent: gstPercent ?? this.gstPercent,
      discountPercent: discountPercent ?? this.discountPercent,
      supplierName: supplierName ?? this.supplierName,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      notes: notes ?? this.notes,
    );
  }
}
