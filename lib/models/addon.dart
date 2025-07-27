class AddOn {
  final String name;
  final int price;
  bool selected;

  AddOn({
    required this.name,
    required this.price,
    this.selected = false,
  });

  factory AddOn.fromJson(Map<String, dynamic> json) => AddOn(
        name: json['name'],
        price: json['price'],
        selected: json['selected'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'selected': selected,
      };
}