import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:planly_ai/app/data/db.dart';
import 'package:planly_ai/app/services/api/planly_api_client.dart';
import 'package:planly_ai/main.dart';

class DailyReviewService {
  static Future<DailyReview?> getDailyReviewForDate(DateTime date) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    return await isar.dailyReviews.where().reviewDateEqualTo(dateString).findFirst();
  }

  static Future<DailyReview?> regenerateDailyReview() async {
    try {
      final dio = PlanlyApiClient.instance.dio;
      final url = '/api/v1/daily-reviews/today';

      final response = await dio.get(
        url,
      );

      if (response.statusCode == 200 && response.data['code'] == 200) {
        final data = response.data['data'];
        if (data == null) return null;

        final review = DailyReview(
          serverId: data['id']?.toString(),
          userId: data['userId']?.toString(),
          reviewDate: data['reviewDate'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
          summary: data['summary'] ?? '',
          achievements: data['achievements'] ?? '',
          nextSteps: data['nextSteps'] ?? '',
          mood: data['mood'] ?? 'NEUTRAL',
          score: data['score'] ?? 0,
          createdAt: DateTime.now(),
        );

        await isar.writeTxn(() async {
          // 先删除旧的当日记录
          await isar.dailyReviews.where().reviewDateEqualTo(review.reviewDate).deleteAll();
          await isar.dailyReviews.put(review);
        });

        return review;
      } else {
        debugPrint('[DailyReview] Failed to regenerate: ${response.data['msg']}');
        return null;
      }
    } catch (e) {
      debugPrint('[DailyReview] Exception regenerating: $e');
      return null;
    }
  }
}
