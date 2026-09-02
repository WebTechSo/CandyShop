class AmPaymentMethod {
  String? id;
  String? type; // 'stripe' | 'cod' | 'bank'
  String? name;
  String? paymentMode; // 'Test' or 'Live' (stripe)
  String? testSecretKey;
  String? testPublishableKey;
  String? liveSecretKey;
  String? livePublishableKey;
  bool? enabled; // for COD / Bank

  // Bank transfer fields
  String? bankName;
  String? accountHolderName;
  String? iban;
  String? bicSwift;
  String? paymentReference; // customer reference instructions
  String? bankAddress; // optional
  String? country; // optional

  AmPaymentMethod({
    this.id,
    this.type,
    this.name,
    this.paymentMode,
    this.testSecretKey,
    this.testPublishableKey,
    this.liveSecretKey,
    this.livePublishableKey,
    this.enabled,
    this.bankName,
    this.accountHolderName,
    this.iban,
    this.bicSwift,
    this.paymentReference,
    this.bankAddress,
    this.country,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'payment_mode': paymentMode,
      'test_secret_key': testSecretKey,
      'test_publishable_key': testPublishableKey,
      'live_secret_key': liveSecretKey,
      'live_publishable_key': livePublishableKey,
      'enabled': enabled,
      'bank_name': bankName,
      'account_holder_name': accountHolderName,
      'iban': iban,
      'bic_swift': bicSwift,
      'payment_reference': paymentReference,
      'bank_address': bankAddress,
      'country': country,
    };
  }

  factory AmPaymentMethod.fromJson(Map<String, dynamic> json) {
    return AmPaymentMethod(
      id: json['id'],
      type: json['type'] ?? 'cash on delivery',
      name: json['name'],
      paymentMode: json['payment_mode'],
      testSecretKey: json['test_secret_key'],
      testPublishableKey: json['test_publishable_key'],
      liveSecretKey: json['live_secret_key'],
      livePublishableKey: json['live_publishable_key'],
      enabled: json['enabled'],
      bankName: json['bank_name'],
      accountHolderName: json['account_holder_name'],
      iban: json['iban'],
      bicSwift: json['bic_swift'],
      paymentReference: json['payment_reference'],
      bankAddress: json['bank_address'],
      country: json['country'],
    );
  }
}
