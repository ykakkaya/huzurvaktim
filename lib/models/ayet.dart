class Ayet {
  Ayet({
    required this.ayet,
    required this.sure,
    required this.text,
    required this.textAr,
    required this.textKelimeler,
    required this.textOkunus,
  });

  final int? ayet;
  final int? sure;
  final String? text;
  final String? textAr;
  final String? textKelimeler;
  final String? textOkunus;

  factory Ayet.fromJson(Map<String, dynamic> json){
    return Ayet(
      ayet: json["ayet"],
      sure: json["sure"],
      text: json["text"],
      textAr: json["text_ar"],
      textKelimeler: json["text_kelimeler"],
      textOkunus: json["text_okunus"],
    );
  }

  Map<String, dynamic> toJson() => {
    "ayet": ayet,
    "sure": sure,
    "text": text,
    "text_ar": textAr,
    "text_kelimeler": textKelimeler,
    "text_okunus": textOkunus,
  };

}
