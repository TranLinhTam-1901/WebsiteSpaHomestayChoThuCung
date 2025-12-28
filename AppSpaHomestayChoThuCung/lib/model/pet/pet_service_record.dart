class PetServiceRecord {
  final String serviceName;
  final DateTime? dateUsed;
  final String? notes;
  final double? price;
  final String? aiFeedback;

  PetServiceRecord({
    required this.serviceName,
    this.dateUsed,
    this.notes,
    this.price,
    this.aiFeedback,
  });

  factory PetServiceRecord.fromJson(Map<String, dynamic> json) {
    return PetServiceRecord(
      serviceName: json['serviceName']
          ?? json['ServiceName']
          ?? 'N/A',

      dateUsed: _parseDate(json['dateUsed'] ?? json['DateUsed']),

      notes: json['notes']
          ?? json['Notes'],

      price: _parseDouble(
        json['price']
            ?? json['PriceAtThatTime'],
      ),

      aiFeedback: json['aiFeedback']
          ?? json['AI_Feedback'],
    );
  }

  /// ======================
  /// helpers
  /// ======================

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
