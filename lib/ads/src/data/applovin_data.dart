class ApplovinData {
  final String bannerId;
  final String interId;
  final String nativeId;
  final String rewardId;
  final String sdkKey;
  final String openAdsId;

  // Getter de compatibilité sans declencher l'avertissement du linter
  // ignore: non_constant_identifier_names
  String get sdk_key => sdkKey;

  ApplovinData.fromJson(Map<String, dynamic> json)
      : bannerId = json['bannerId'] ?? "",
        interId = json['interId'] ?? "",
        nativeId = json['nativeId'] ?? "",
        rewardId = json['rewardId'] ?? "",
        sdkKey = json['sdk_key'] ?? "",
        openAdsId = json['openAdsIds'] ?? "";
}