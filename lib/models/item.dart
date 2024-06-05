class Item {
  final String id;
  final String name;
  final String brand;
  final int availableQuantity;
  final String? nameInUrdu;
  final String? miniUnit;
  final String? packaging;
  final double purchaseRate;
  final double saleRate;
  final int minStock;
  final DateTime addedEditDate;
  final String? location;
  final String? picture;

  Item({
    required this.id,
    required this.name,
    required this.brand,
    required this.availableQuantity,
    this.nameInUrdu,
    this.miniUnit,
    this.packaging,
    required this.purchaseRate,
    required this.saleRate,
    required this.minStock,
    required this.addedEditDate,
    this.location,
    this.picture,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['_id'],
      name: json['name'],
      brand: json['brand'],
      availableQuantity: json['availableQuantity'],
      nameInUrdu: json['nameInUrdu'],
      miniUnit: json['miniUnit'],
      packaging: json['packaging'],
      purchaseRate: json['purchaseRate'].toDouble(),
      saleRate: json['saleRate'].toDouble(),
      minStock: json['minStock'],
      addedEditDate: DateTime.parse(json['addedEditDate']),
      location: json['location'],
      picture: json['picture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'brand': brand,
      'availableQuantity': availableQuantity,
      'nameInUrdu': nameInUrdu,
      'miniUnit': miniUnit,
      'packaging': packaging,
      'purchaseRate': purchaseRate,
      'saleRate': saleRate,
      'minStock': minStock,
      'addedEditDate': addedEditDate.toIso8601String(),
      'location': location,
      'picture': picture,
    };
  }
}
