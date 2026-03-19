class DailyReviewResponse {
  final int code;
  final String msg;
  final DailyReviewData? data;

  DailyReviewResponse({
    required this.code,
    required this.msg,
    this.data,
  });

  factory DailyReviewResponse.fromJson(Map<String, dynamic> json) {
    return DailyReviewResponse(
      code: json['code'],
      msg: json['msg'],
      data: json['data'] != null ? DailyReviewData.fromJson(json['data']) : null,
    );
  }
}

class DailyReviewData {
  final String? id;
  final String? userId;
  final String? reviewDate;
  final String? summary;
  final String? achievements;
  final String? nextSteps;
  final String? mood;
  final int? score;

  DailyReviewData({
    this.id,
    this.userId,
    this.reviewDate,
    this.summary,
    this.achievements,
    this.nextSteps,
    this.mood,
    this.score,
  });

  factory DailyReviewData.fromJson(Map<String, dynamic> json) {
    return DailyReviewData(
      id: json['id']?.toString(),
      userId: json['userId']?.toString(),
      reviewDate: json['reviewDate'],
      summary: json['summary'],
      achievements: json['achievements'],
      nextSteps: json['nextSteps'],
      mood: json['mood'],
      score: json['score'],
    );
  }
}
