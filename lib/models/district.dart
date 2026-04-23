class District {
  District({
    required this.ilceAdi,
    required this.ilceAdiEn,
    required this.ilceId,required this.sehirId
  });

  final String? ilceAdi;
  final String? ilceAdiEn;
  final int ilceId;
  final int sehirId;

  factory District.fromJson(Map<String, dynamic> json){
    return District(
      ilceAdi: json["IlceAdi"],
      ilceAdiEn: json["IlceAdiEn"],
      ilceId: int.parse(json["IlceID"].toString()),
      sehirId:int.parse( json["sehirId"].toString())
    );
  }

  Map<String, dynamic> toJson() => {
    "IlceAdi": ilceAdi,
    "IlceAdiEn": ilceAdiEn,
    "IlceID": ilceId,
    "sehirId": sehirId
  };

}
