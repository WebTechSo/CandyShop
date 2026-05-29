class AmAddressModel {
  int? id;
  String? full_name;
  String? address;
  String? city;
  String? state;
  String? zip_code;
  String? country;
  String? phone;
  String? address_type;
  String? user_id;
  bool? default_address;

  AmAddressModel({
    this.id,
    this.full_name,
    this.address,
    this.city,
    this.state,
    this.zip_code,
    this.country,
    this.phone,
    this.address_type,
    this.user_id,
    this.default_address,
  });

  factory AmAddressModel.fromJson(Map<String, dynamic> json) {
    return AmAddressModel(
      id: json['id'],
      full_name: json['full_name'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      zip_code: json['zip_code'],
      country: json['country'],
      phone: json['phone'],
      address_type: json['address_type'],
      user_id: json['user_id'],
      default_address: json['default_address'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['full_name'] = this.full_name;
    data['address'] = this.address;
    data['city'] = this.city;
    data['state'] = this.state;
    data['zip_code'] = this.zip_code;
    data['country'] = this.country;
    data['phone'] = this.phone;
    data['address_type'] = this.address_type;
    data['user_id'] = this.user_id;
    data['default_address'] = this.default_address;
    return data;
  }
}
