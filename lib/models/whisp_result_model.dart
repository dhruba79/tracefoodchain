class AnalysisResult {
  final dynamic data;
  final String token;

  AnalysisResult({required this.data, required this.token});

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      data: json['data'],
      token: json['token'],
    );
  }
}
