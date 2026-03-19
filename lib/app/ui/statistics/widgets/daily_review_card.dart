import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/data/db.dart';
import 'package:planly_ai/app/services/daily_review_service.dart';

class DailyReviewCard extends StatefulWidget {
  const DailyReviewCard({super.key});

  @override
  State<DailyReviewCard> createState() => _DailyReviewCardState();
}

class _DailyReviewCardState extends State<DailyReviewCard> {
  DailyReview? _review;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReview();
  }

  Future<void> _loadReview() async {
    setState(() => _isLoading = true);
    final review = await DailyReviewService.getDailyReviewForDate(DateTime.now());
    setState(() {
      _review = review;
      _isLoading = false;
    });
  }

  Future<void> _regenerate() async {
    setState(() => _isLoading = true);
    final review = await DailyReviewService.regenerateDailyReview();
    setState(() {
      if (review != null) {
        _review = review;
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: AppConstants.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Container(
        height: 220, // To match WeeklyProgressChart's total height approximately
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      IconsaxPlusBold.note_2,
                      color: colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: AppConstants.spacingXS),
                    Text(
                      'dailyReview'.tr,
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Opacity(
                  opacity: _isLoading ? 0 : 1,
                  child: GestureDetector(
                    onTap: _isLoading ? null : _regenerate,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingXS),
                      child: Icon(
                        IconsaxPlusLinear.refresh,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _review == null
                      ? _buildEmptyState(colorScheme, textTheme)
                      : _buildReviewContent(colorScheme, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Text(
        'noDailyReview'.tr,
        textAlign: TextAlign.center,
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildReviewContent(ColorScheme colorScheme, TextTheme textTheme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('reviewSummary'.tr, _review!.summary, colorScheme, textTheme),
          const SizedBox(height: AppConstants.spacingM),
          _buildSection('achievements'.tr, _review!.achievements, colorScheme, textTheme),
          const SizedBox(height: AppConstants.spacingM),
          _buildSection('nextSteps'.tr, _review!.nextSteps, colorScheme, textTheme),
          const SizedBox(height: AppConstants.spacingS),
          Row(
            children: [
              _buildBadge('mood'.tr, _review!.mood, colorScheme, textTheme),
              const SizedBox(width: AppConstants.spacingS),
              _buildBadge('score'.tr, _review!.score.toString(), colorScheme, textTheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.labelLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacingXS),
        Text(
          content,
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildBadge(String label, String value, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Text(
        '$label: $value',
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
