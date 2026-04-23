class Country {
  Country({
    required this.ulkeAdi,
    required this.ulkeAdiEn,
    required this.ulkeId,
  });

  final String? ulkeAdi;
  final String? ulkeAdiEn;
  final int ulkeId;

  factory Country.fromJson(Map<String, dynamic> json){
    return Country(
      ulkeAdi: json["UlkeAdi"],
      ulkeAdiEn: json["UlkeAdiEn"],
      ulkeId: int.parse(json["UlkeID"].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    "UlkeAdi": ulkeAdi,
    "UlkeAdiEn": ulkeAdiEn,
    "UlkeId": ulkeId,
  };

}
